import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';
import 'database_service.dart';
import 'ml_service.dart';

/// Service to handle SMS sharing integration
class SmsShareService {
  static final SmsShareService _instance = SmsShareService._internal();
  static SmsShareService get instance => _instance;
  
  SmsShareService._internal();
  
  static const MethodChannel _channel = MethodChannel('sms_integration');
  final StreamController<SharedSmsData> _sharedSmsController = StreamController<SharedSmsData>.broadcast();
  
  Stream<SharedSmsData> get sharedSmsStream => _sharedSmsController.stream;
  
  bool _isInitialized = false;
  
  /// Initialize the SMS share service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set up method call handler for shared text
      _channel.setMethodCallHandler(_handleMethodCall);
      
      _isInitialized = true;
      if (kDebugMode) {
        print('SMS Share Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SMS Share Service: $e');
      }
    }
  }
  
  /// Handle method calls from native Android
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'analyzeSharedText':
        final text = call.arguments['text'] as String?;
        final timestamp = call.arguments['timestamp'] as int?;
        
        if (text != null) {
          final sharedData = SharedSmsData(
            text: text,
            timestamp: timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : DateTime.now(),
            sender: 'Shared from SMS app',
          );
          
          _sharedSmsController.add(sharedData);
          
          // Navigate to analysis screen
          _navigateToAnalysisScreen(text, 'Shared from SMS app');
          
          if (kDebugMode) {
            print('📱 Received shared SMS text: $text');
          }
        }
        break;
      default:
        if (kDebugMode) {
          print('Unknown method call: ${call.method}');
        }
    }
  }
  
  /// Analyze shared SMS text using ML service with fallback
  Future<PhishingDetection> analyzeSharedText(String text, {String? sender}) async {
    try {
      // Create SMS message object for analysis
      final message = SmsMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: sender ?? 'Shared from SMS app',
        body: text,
        timestamp: DateTime.now(),
      );
      
      // Use ML service for analysis
      PhishingDetection detection;
      try {
        detection = await MLService.instance.analyzeSms(message);
      } catch (e) {
        if (kDebugMode) {
          print('❌ ML service failed: $e');
          print('💡 To enable ML detection, start the API server: python ml_training/sms_spam_api_sklearn.py');
        }
        rethrow;
      }
      
      if (kDebugMode) {
        print('🔍 Shared text analysis completed: ${detection.confidence} confidence');
      }
      
      return detection;
    } catch (e) {
      if (kDebugMode) {
        print('Error analyzing shared text: $e');
      }
      rethrow;
    }
  }
  
  /// Store shared SMS analysis result
  Future<void> storeSharedAnalysis(SharedSmsData sharedData, PhishingDetection detection) async {
    try {
      // Create SMS message object
      final message = SmsMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: sharedData.sender,
        body: sharedData.text,
        timestamp: sharedData.timestamp,
        isPhishing: detection.confidence > 0.5,
        phishingScore: detection.confidence,
        reason: detection.reason,
        isArchived: detection.confidence > 0.5, // Auto-archive if phishing
        archivedAt: detection.confidence > 0.5 ? DateTime.now() : null,
      );
      
      // Store in database
      await DatabaseService.instance.insertSmsMessage(message);
      
      if (detection.confidence > 0.5) {
        await DatabaseService.instance.insertPhishingDetection(detection);
        
        if (kDebugMode) {
          print('🚨 Shared SMS detected as phishing and auto-archived');
        }
      } else {
        if (kDebugMode) {
          print('✅ Shared SMS appears to be legitimate');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error storing shared analysis: $e');
      }
    }
  }
  
  /// Navigate to analysis screen for shared text
  void _navigateToAnalysisScreen(String text, String sender) {
    try {
      // Use a global navigator key or context to navigate
      // This will be handled by the main app when the service is initialized
      if (kDebugMode) {
        print('🔄 Navigating to analysis screen for shared text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to analysis screen: $e');
      }
    }
  }
  
  void dispose() {
    _sharedSmsController.close();
  }
}

/// Data class for shared SMS content
class SharedSmsData {
  final String text;
  final DateTime timestamp;
  final String sender;
  
  const SharedSmsData({
    required this.text,
    required this.timestamp,
    required this.sender,
  });
}
