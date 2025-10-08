import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';
import 'ml_service.dart';
import 'database_service.dart';
import 'notification_service.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  static SmsService get instance => _instance;
  
  SmsService._internal();
  
  // SMS integration will be implemented with proper permissions
  
  // Placeholder for SMS query functionality
  final _SmsQueryPlaceholder _smsQuery = _SmsQueryPlaceholder();
  final StreamController<SmsMessage> _smsController = StreamController<SmsMessage>.broadcast();
  final StreamController<PhishingDetection> _phishingController = StreamController<PhishingDetection>.broadcast();
  
  Stream<SmsMessage> get smsStream => _smsController.stream;
  Stream<PhishingDetection> get phishingStream => _phishingController.stream;
  
  bool _isListening = false;
  bool _isDefaultSmsApp = false;
  
  Future<void> initialize() async {
    await _checkPermissions();
    await _checkDefaultSmsApp();
    await _startListening();
  }
  
  Future<void> _checkPermissions() async {
    final smsPermission = await Permission.sms.status;
    if (!smsPermission.isGranted) {
      await Permission.sms.request();
    }
  }
  
  Future<void> _checkDefaultSmsApp() async {
    try {
      _isDefaultSmsApp = await _smsQuery.isDefaultSmsApp;
    } catch (e) {
      print('Error checking default SMS app status: $e');
      _isDefaultSmsApp = false;
    }
  }
  
  Future<bool> requestDefaultSmsApp() async {
    try {
      final result = await _smsQuery.setAsDefaultSmsApp;
      _isDefaultSmsApp = result;
      return result;
    } catch (e) {
      print('Error setting as default SMS app: $e');
      return false;
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
      
      // Extract and check URLs
      final urls = MLService.instance.extractUrls(message.body);
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
      
      // Analyze with ML
      final detection = await MLService.instance.analyzeSms(message);
      
      if (detection.confidence > 0.5) {
        // Mark as phishing
        final phishingMessage = message.copyWith(
          isPhishing: true,
          phishingScore: detection.confidence,
          reason: detection.reason,
          extractedUrls: urls,
        );
        
        // Generate signature for cloud sync
        final signature = await MLService.instance.generateSignature(phishingMessage);
        final messageWithSignature = phishingMessage.copyWith(signature: signature);
        
        // Store in database
        await DatabaseService.instance.insertSmsMessage(messageWithSignature);
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
        
        // Auto-block suspicious URLs
        for (final url in urls) {
          final urlAnalysis = await MLService.instance.analyzeUrl(url);
          if (urlAnalysis['isSuspicious'] && urlAnalysis['confidence'] > 0.7) {
            await DatabaseService.instance.blockUrl(
              url,
              reason: 'Auto-blocked: Suspicious URL in phishing message',
              threatLevel: urlAnalysis['threatLevel'],
              autoBlocked: true,
            );
          }
        }
        
        // Store signature for cloud sync
        final phishingSignature = PhishingSignature(
          hash: signature,
          messageId: message.id,
          createdAt: DateTime.now(),
        );
        await DatabaseService.instance.insertPhishingSignature(phishingSignature);
        
        // Archive the message
        await _archivePhishingMessage(messageWithSignature);
        
        // Send notification
        await NotificationService.instance.showPhishingDetectedNotification(
          sender: message.sender,
          reason: detection.reason,
        );
        
        // Emit to streams
        _phishingController.add(detection);
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
  
  // Remove the status change handler as telephony package handles this differently
  
  Future<void> _archivePhishingMessage(SmsMessage message) async {
    final archivedMessage = message.copyWith(
      isArchived: true,
      archivedAt: DateTime.now(),
    );
    
    await DatabaseService.instance.updateSmsMessage(archivedMessage);
  }
  
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
  
  Future<void> sendSms(String phoneNumber, String message) async {
    try {
      await _smsQuery.sendSMS(phoneNumber, message);
    } catch (e) {
      print('Error sending SMS: $e');
      throw Exception('Failed to send SMS: $e');
    }
  }
  
  Future<void> deleteMessage(String messageId) async {
    await DatabaseService.instance.deleteSmsMessage(messageId);
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
      
      // Analyze with ML
      final detection = await MLService.instance.analyzeSms(message);
      
      // Store in database if phishing detected
      if (detection.confidence > 0.5) {
        final phishingMessage = message.copyWith(
          isPhishing: true,
          phishingScore: detection.confidence,
          reason: detection.reason,
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
      } else {
        // Store as safe message
        await DatabaseService.instance.insertSmsMessage(message);
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
}

// Placeholder class for SMS query functionality (since telephony is disabled)
class _SmsQueryPlaceholder {
  Future<bool> get isDefaultSmsApp async => false;
  Future<bool> get setAsDefaultSmsApp async => false;
  
  Future<void> sendSMS(String address, String message) async {
    print('SMS send placeholder: to=$address, message=$message');
  }
}
