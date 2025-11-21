import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';

/// Enhanced Online ML Service for SMS Phishing Detection
/// Supports multiple AI providers with fallback mechanism
class EnhancedOnlineMLService {
  static final EnhancedOnlineMLService _instance = EnhancedOnlineMLService._internal();
  static EnhancedOnlineMLService get instance => _instance;
  
  EnhancedOnlineMLService._internal();
  
  bool _isInitialized = false;
  // TODO: Implement provider management
  // ignore: unused_field
  String? _primaryProvider;
  // ignore: unused_field
  final Map<String, String> _apiKeys = {};
  
  /// Initialize the enhanced online ML service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Try to initialize with available providers
    // For now, use the same API endpoint as MLService
    _isInitialized = true;
    
    if (kDebugMode) {
      print('✅ Enhanced Online ML Service initialized');
    }
  }
  
  /// Analyze SMS message for phishing using online ML services
  Future<PhishingDetection> analyzeSms(SmsMessage message) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Use the same MLService API endpoint
      const apiBaseUrl = 'http://localhost:5000';
      final requestBody = json.encode({'message': message.body});
      
      final response = await http.post(
        Uri.parse('$apiBaseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double phishingConfidence = (data['phishing_confidence'] as num?)?.toDouble() ?? (data['confidence'] as num).toDouble();
        
        return PhishingDetection(
          id: const Uuid().v4(),
          messageId: message.id,
          confidence: phishingConfidence,
          type: data['is_phishing'] == true 
              ? PhishingType.content 
              : PhishingType.content,
          reason: data['reason'] ?? 'Enhanced online ML model prediction',
          indicators: List<String>.from(data['indicators'] ?? []),
          detectedAt: DateTime.now(),
        );
      } else {
        throw Exception('Prediction failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Enhanced Online ML Service error: $e');
      }
      // Return a default detection with low confidence
      return PhishingDetection(
        id: const Uuid().v4(),
        messageId: message.id,
        confidence: 0.0,
        type: PhishingType.content,
        reason: 'Enhanced online ML service unavailable - using fallback',
        indicators: [],
        detectedAt: DateTime.now(),
      );
    }
  }
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Dispose resources
  Future<void> dispose() async {
    _isInitialized = false;
    if (kDebugMode) {
      print('🧹 Enhanced Online ML Service disposed');
    }
  }
}

