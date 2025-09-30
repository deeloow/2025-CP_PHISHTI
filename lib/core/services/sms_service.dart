import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
  
  final SmsQuery _smsQuery = SmsQuery();
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
      // Listen for incoming SMS
      _smsQuery.onSmsReceived.listen(_handleIncomingSms);
      
      // Listen for SMS status changes
      _smsQuery.onSmsStatusChanged.listen(_handleSmsStatusChange);
      
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
        sender: sms.sender,
        body: sms.body,
        timestamp: sms.date,
      );
      
      // Check if sender is whitelisted
      final isWhitelisted = await DatabaseService.instance.isWhitelisted('sender', message.sender);
      if (isWhitelisted) {
        _smsController.add(message);
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
        );
        
        // Generate signature for cloud sync
        final signature = await MLService.instance.generateSignature(phishingMessage);
        final messageWithSignature = phishingMessage.copyWith(signature: signature);
        
        // Store in database
        await DatabaseService.instance.insertSmsMessage(messageWithSignature);
        await DatabaseService.instance.insertPhishingDetection(detection);
        
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
        await DatabaseService.instance.insertSmsMessage(message);
        _smsController.add(message);
      }
    } catch (e) {
      print('Error handling incoming SMS: $e');
    }
  }
  
  Future<void> _handleSmsStatusChange(SmsMessage sms) async {
    // Handle SMS status changes (sent, delivered, etc.)
    print('SMS status changed: ${sms.status}');
  }
  
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
  
  Future<Map<String, int>> getStatistics() async {
    return await DatabaseService.instance.getStatistics();
  }
  
  Future<void> sendSms(String phoneNumber, String message) async {
    try {
      await _smsQuery.sendSMS(
        recipients: [phoneNumber],
        message: message,
      );
    } catch (e) {
      print('Error sending SMS: $e');
      throw Exception('Failed to send SMS: $e');
    }
  }
  
  Future<void> deleteMessage(String messageId) async {
    await DatabaseService.instance.deleteSmsMessage(messageId);
  }
  
  Future<void> stopListening() async {
    _isListening = false;
  }
  
  Future<void> dispose() async {
    await _smsController.close();
    await _phishingController.close();
  }
}
