import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';
import 'database_service.dart';
import 'ml_service.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  static SmsService get instance => _instance;
  
  SmsService._internal();
  
  // SMS integration will be implemented with proper permissions
  final StreamController<SmsMessage> _smsController = StreamController<SmsMessage>.broadcast();
  final StreamController<PhishingDetection> _phishingController = StreamController<PhishingDetection>.broadcast();
  
  Stream<SmsMessage> get smsStream => _smsController.stream;
  Stream<PhishingDetection> get phishingStream => _phishingController.stream;
  
  bool _isListening = false;
  
  Future<void> initialize() async {
    await _checkPermissions();
    await _startListening();
  }
  
  Future<void> _checkPermissions() async {
    final smsPermission = await Permission.sms.status;
    if (!smsPermission.isGranted) {
      await Permission.sms.request();
    }
  }
  
  
  Future<void> _startListening() async {
    if (_isListening) return;
    
    try {
      // SMS listening will be implemented with proper Android integration
      // For now, we focus on manual analysis
      print('SMS listening initialized (manual mode)');
      _isListening = true;
    } catch (e) {
      print('Error starting SMS listener: $e');
    }
  }
  
  // TODO: Remove this method as it's not used
  /*
  Future<void> _handleIncomingSms(SmsMessage sms) async {
    try {
      // Convert to our SmsMessage model
      final message = SmsMessage(
        id: const Uuid().v4(),
        sender: 'Unknown', // Will be updated when SMS integration is complete
        body: 'Sample message', // Will be updated when SMS integration is complete
        timestamp: DateTime.now(),
      );
      
      // Check if sender is blocked
      final isSenderBlocked = await DatabaseService.instance.isSenderBlocked(message.sender);
      if (isSenderBlocked) {
        // Auto-archive blocked sender messages
        final blockedMessage = message.copyWith(
          isPhishing: true,
          isArchived: true,
          archivedAt: DateTime.now(),
          reason: 'Sender is blocked',
        );
        await DatabaseService.instance.insertSmsMessage(blockedMessage);
        print('Message from blocked sender ${message.sender} auto-archived');
        return;
      }
      
      // Check if sender is whitelisted
      final isWhitelisted = await DatabaseService.instance.isWhitelisted('sender', message.sender);
      if (isWhitelisted) {
        await DatabaseService.instance.insertSmsMessage(message);
        _smsController.add(message);
        return;
      }
      
      // Check for duplicate messages
      final isDuplicate = await DatabaseService.instance.isDuplicateMessage(message.sender, message.body);
      if (isDuplicate) {
        // Check if this is a known phishing signature
        final isKnownPhishing = await DatabaseService.instance.isKnownPhishingSignature(message.sender, message.body);
        if (isKnownPhishing) {
          // Auto-archive duplicate phishing message
          final duplicatePhishingMessage = message.copyWith(
            isPhishing: true,
            isArchived: true,
            archivedAt: DateTime.now(),
            reason: 'Duplicate phishing message',
          );
          await DatabaseService.instance.insertSmsMessage(duplicatePhishingMessage);
          print('Duplicate phishing message auto-archived');
          return;
        }
      }
      
      // Extract URLs using simple regex
      final urls = _extractUrls(message.body);
      bool hasBlockedUrl = false;
      for (final url in urls) {
        if (await DatabaseService.instance.isUrlBlocked(url)) {
          hasBlockedUrl = true;
          break;
        }
      }
      
      if (hasBlockedUrl) {
        // Auto-archive message with blocked URL
        final blockedUrlMessage = message.copyWith(
          isPhishing: true,
          isArchived: true,
          archivedAt: DateTime.now(),
          reason: 'Contains blocked URL',
          extractedUrls: urls,
        );
        await DatabaseService.instance.insertSmsMessage(blockedUrlMessage);
        print('Message with blocked URL auto-archived');
        return;
      }
      
      // Use ML service for phishing detection (preferred)
      PhishingDetection detection;
      try {
        // Try to initialize ML service if not already initialized
        if (!MLService.instance.isInitialized) {
          await MLService.instance.initialize();
        }
        
        // Use ML service for analysis
        detection = await MLService.instance.analyzeSms(message);
        
        if (kDebugMode) {
          print('✅ ML analysis completed: ${detection.confidence} confidence');
        }
      } catch (e) {
        // ML service is required - throw error if unavailable
        if (kDebugMode) {
          print('❌ ML service unavailable: $e');
          print('💡 ML service is required. Make sure the API server is running on VPS: http://72.61.148.38:5000');
        }
        rethrow; // Don't continue without ML service
      }
      
      if (detection.confidence > 0.5) {
        // Check if auto-archive is enabled (default: true)
        final autoArchiveEnabled = await _getAutoArchiveSetting();
        
        // Mark as phishing and AUTO-ARCHIVE if enabled
        final phishingMessage = message.copyWith(
          isPhishing: true,
          phishingScore: detection.confidence,
          reason: detection.reason,
          extractedUrls: urls,
          isArchived: autoArchiveEnabled,
          archivedAt: autoArchiveEnabled ? DateTime.now() : null,
        );
        
        // Store in database (already archived)
        await DatabaseService.instance.insertSmsMessage(phishingMessage);
        await DatabaseService.instance.insertPhishingDetection(detection);
        
        // Mark message signature as phishing for future duplicate detection
        await DatabaseService.instance.markSignatureAsPhishing(message.sender, message.body);
        
        // Auto-block sender if high confidence phishing
        if (detection.confidence > 0.8) {
          await DatabaseService.instance.blockSender(
            message.sender,
            reason: 'Auto-blocked: High confidence phishing detection',
            autoBlocked: true,
          );
        }
        
        // Auto-block URLs in phishing messages
        for (final url in urls) {
          await DatabaseService.instance.blockUrl(
            url,
            reason: 'Auto-blocked: URL in phishing message',
            threatLevel: 'high',
            autoBlocked: true,
          );
        }
        
        // Send notification
        final notificationMessage = autoArchiveEnabled 
          ? 'Phishing message detected and auto-archived: ${detection.reason}'
          : 'Phishing message detected: ${detection.reason}';
        
        await NotificationService.instance.showPhishingDetectedNotification(
          sender: message.sender,
          reason: notificationMessage,
        );
        
        // Emit to streams
        _phishingController.add(detection);
        
        print('🚨 Phishing message ${autoArchiveEnabled ? 'auto-archived' : 'detected'}: ${message.sender} - ${detection.reason}');
      } else {
        // Safe message, add to inbox
        final safeMessage = message.copyWith(extractedUrls: urls);
        await DatabaseService.instance.insertSmsMessage(safeMessage);
        _smsController.add(safeMessage);
      }
    } catch (e) {
      print('Error handling incoming SMS: $e');
    }
  }
  */
  
  // Remove the status change handler as telephony package handles this differently
  
  
  Future<List<SmsMessage>> getInboxMessages({int? limit, int? offset}) async {
    return await DatabaseService.instance.getSmsMessages(
      isPhishing: false,
      isArchived: false,
      limit: limit,
      offset: offset,
    );
  }
  
  Future<List<SmsMessage>> getArchivedMessages({int? limit, int? offset}) async {
    return await DatabaseService.instance.getSmsMessages(
      isPhishing: true,
      isArchived: true,
      limit: limit,
      offset: offset,
    );
  }
  
  Future<List<SmsMessage>> getAllMessages({int? limit, int? offset}) async {
    return await DatabaseService.instance.getSmsMessages(
      limit: limit,
      offset: offset,
    );
  }
  
  Future<void> restoreMessage(String messageId) async {
    final message = await DatabaseService.instance.getSmsMessageById(messageId);
    if (message != null) {
      final restoredMessage = message.copyWith(
        isArchived: false,
        archivedAt: null,
      );
      await DatabaseService.instance.updateSmsMessage(restoredMessage);
    }
  }
  
  Future<void> whitelistSender(String sender) async {
    await DatabaseService.instance.addToWhitelist('sender', sender);
  }
  
  Future<void> whitelistUrl(String url) async {
    await DatabaseService.instance.addToWhitelist('url', url);
  }
  
  Future<void> reportFalsePositive(String messageId) async {
    final message = await DatabaseService.instance.getSmsMessageById(messageId);
    if (message != null) {
      final updatedMessage = message.copyWith(
        isPhishing: false,
        isWhitelisted: true,
      );
      await DatabaseService.instance.updateSmsMessage(updatedMessage);
    }
  }
  
  Future<void> reportFalseNegative(String messageId) async {
    final message = await DatabaseService.instance.getSmsMessageById(messageId);
    if (message != null) {
      final updatedMessage = message.copyWith(
        isPhishing: true,
        isArchived: true,
        archivedAt: DateTime.now(),
      );
      await DatabaseService.instance.updateSmsMessage(updatedMessage);
    }
  }
  
  // Blocking management methods
  Future<void> blockSender(String sender, {String? reason}) async {
    await DatabaseService.instance.blockSender(sender, reason: reason);
    
    // Archive all existing messages from this sender
    final existingMessages = await DatabaseService.instance.getSmsMessages();
    for (final message in existingMessages) {
      if (message.sender == sender && !message.isArchived) {
        final archivedMessage = message.copyWith(
          isArchived: true,
          archivedAt: DateTime.now(),
          reason: 'Sender blocked by user',
        );
        await DatabaseService.instance.updateSmsMessage(archivedMessage);
      }
    }
  }
  
  Future<void> unblockSender(String sender) async {
    await DatabaseService.instance.unblockSender(sender);
  }
  
  Future<List<Map<String, dynamic>>> getBlockedSenders() async {
    return await DatabaseService.instance.getBlockedSenders();
  }
  
  Future<void> blockUrl(String url, {String? reason, String threatLevel = 'medium'}) async {
    await DatabaseService.instance.blockUrl(url, reason: reason, threatLevel: threatLevel);
    
    // Archive all existing messages containing this URL
    final existingMessages = await DatabaseService.instance.getSmsMessages();
    for (final message in existingMessages) {
      if (message.extractedUrls.contains(url) && !message.isArchived) {
        final archivedMessage = message.copyWith(
          isArchived: true,
          archivedAt: DateTime.now(),
          reason: 'Contains blocked URL',
        );
        await DatabaseService.instance.updateSmsMessage(archivedMessage);
      }
    }
  }
  
  Future<void> unblockUrl(String url) async {
    await DatabaseService.instance.unblockUrl(url);
  }
  
  Future<List<Map<String, dynamic>>> getBlockedUrls() async {
    return await DatabaseService.instance.getBlockedUrls();
  }
  
  Future<bool> isSenderBlocked(String sender) async {
    return await DatabaseService.instance.isSenderBlocked(sender);
  }
  
  Future<bool> isUrlBlocked(String url) async {
    return await DatabaseService.instance.isUrlBlocked(url);
  }
  
  Future<Map<String, int>> getStatistics() async {
    return await DatabaseService.instance.getStatistics();
  }
  
  
  Future<void> deleteMessage(String messageId) async {
    await DatabaseService.instance.deleteSmsMessage(messageId);
  }
  
  /// Get auto-archive setting from user preferences
  Future<bool> _getAutoArchiveSetting() async {
    try {
      // Try to get from user preferences (authenticated users)
      // For now, default to true (auto-archive enabled)
      // This can be enhanced to read from actual user settings
      return true; // Default: auto-archive enabled
    } catch (e) {
      print('Error getting auto-archive setting: $e');
      return true; // Default: auto-archive enabled
    }
  }
  
  /// Manually analyze a message for phishing detection
  Future<PhishingDetection> analyzeMessage(String messageBody, {String? sender}) async {
    try {
      // Create SMS message object
      final message = SmsMessage(
        id: const Uuid().v4(),
        sender: sender ?? 'Unknown',
        body: messageBody,
        timestamp: DateTime.now(),
      );
      
      // Use ML service for phishing detection (preferred)
      PhishingDetection detection;
      final urls = _extractUrls(messageBody);
      
      try {
        // Try to initialize ML service if not already initialized
        if (!MLService.instance.isInitialized) {
          await MLService.instance.initialize();
        }
        
        // Use ML service for analysis
        detection = await MLService.instance.analyzeSms(message);
        
        if (kDebugMode) {
          print('✅ ML analysis completed: ${detection.confidence} confidence');
        }
      } catch (e) {
        // ML service unavailable - throw error instead of using fallback
        if (kDebugMode) {
          print('❌ ML service unavailable: $e');
          print('💡 To enable ML detection, start the API server: python ml_training/sms_spam_api_sklearn.py');
        }
        rethrow;
      }
      
      // Store in database if phishing detected
      if (detection.confidence > 0.5) {
        // Check if auto-archive is enabled
        final autoArchiveEnabled = await _getAutoArchiveSetting();
        
        final phishingMessage = message.copyWith(
          isPhishing: true,
          phishingScore: detection.confidence,
          reason: detection.reason,
          extractedUrls: urls,
          isArchived: autoArchiveEnabled,
          archivedAt: autoArchiveEnabled ? DateTime.now() : null,
        );
        
        await DatabaseService.instance.insertSmsMessage(phishingMessage);
        await DatabaseService.instance.insertPhishingDetection(detection);
        
        // Auto-block sender if high confidence phishing
        if (detection.confidence > 0.8) {
          await DatabaseService.instance.blockSender(
            message.sender,
            reason: 'Auto-blocked: High confidence phishing detection',
            autoBlocked: true,
          );
        }
        
        print('🚨 Manual analysis: Phishing message ${autoArchiveEnabled ? 'auto-archived' : 'detected'}: ${message.sender} - ${detection.reason}');
      } else {
        // Store as safe message
        final safeMessage = message.copyWith(extractedUrls: urls);
        await DatabaseService.instance.insertSmsMessage(safeMessage);
      }
      
      return detection;
    } catch (e) {
      print('Error analyzing message: $e');
      rethrow;
    }
  }
  
  Future<void> stopListening() async {
    _isListening = false;
  }
  
  Future<void> dispose() async {
    await _smsController.close();
    await _phishingController.close();
  }
  
  /// Extract URLs from text using regex
  List<String> _extractUrls(String text) {
    final urlRegex = RegExp(
      r'https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*',
      caseSensitive: false,
    );
    return urlRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }
  
}

