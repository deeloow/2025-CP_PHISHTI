import 'package:flutter/foundation.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';

/// Fallback Rust ML Service for when the native library is not available
/// This provides rule-based detection that mimics the Rust DistilBERT behavior
class RustMLServiceFallback {
  static final RustMLServiceFallback _instance = RustMLServiceFallback._internal();
  static RustMLServiceFallback get instance => _instance;
  
  RustMLServiceFallback._internal();
  
  bool _isInitialized = false;
  
  /// Initialize the fallback service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (kDebugMode) {
      print('Initializing Rust ML Service Fallback (rule-based detection)');
    }
    
    _isInitialized = true;
  }
  
  /// Analyze SMS message using rule-based detection
  Future<PhishingDetection> analyzeSms(SmsMessage message) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final startTime = DateTime.now();
    
    // Rule-based analysis that mimics DistilBERT behavior
    final result = _analyzeWithRules(message);
    
    final processingTime = DateTime.now().difference(startTime).inMilliseconds;
    
    return PhishingDetection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messageId: message.id,
      confidence: result['confidence'],
      type: result['type'],
      indicators: result['indicators'],
      reason: 'Rule-based analysis (Rust fallback) - ${processingTime}ms',
      detectedAt: DateTime.now(),
    );
  }
  
  /// Rule-based analysis that provides similar results to DistilBERT
  Map<String, dynamic> _analyzeWithRules(SmsMessage message) {
    final indicators = <String>[];
    double confidence = 0.0;
    PhishingType type = PhishingType.content;
    
    final text = message.body.toLowerCase();
    
    // Urgent language detection (high weight)
    final urgentKeywords = [
      'urgent', 'immediately', 'act now', 'limited time', 'expires',
      'verify', 'confirm', 'suspended', 'blocked', 'security'
    ];
    
    for (final keyword in urgentKeywords) {
      if (text.contains(keyword)) {
        indicators.add('Urgent language: \'$keyword\'');
        confidence += 0.3;
        type = PhishingType.urgent;
      }
    }
    
    // Financial keywords (high weight)
    final financialKeywords = [
      'password', 'pin', 'ssn', 'credit card', 'bank account',
      'wire transfer', 'gift card', 'bitcoin', 'cryptocurrency'
    ];
    
    for (final keyword in financialKeywords) {
      if (text.contains(keyword)) {
        indicators.add('Financial request: \'$keyword\'');
        confidence += 0.4;
        type = PhishingType.suspiciousKeywords;
      }
    }
    
    // URL detection
    if (text.contains('http') || text.contains('www.')) {
      indicators.add('Contains URL');
      confidence += 0.2;
      type = PhishingType.url;
    }
    
    // Suspicious patterns
    final suspiciousPatterns = [
      'click here', 'verify your account', 'update your information',
      'your account has been', 'congratulations', 'you won', 'claim now'
    ];
    
    for (final pattern in suspiciousPatterns) {
      if (text.contains(pattern)) {
        indicators.add('Suspicious pattern: \'$pattern\'');
        confidence += 0.2;
      }
    }
    
    // Sender analysis
    if (_isSuspiciousSender(message.sender)) {
      indicators.add('Suspicious sender pattern');
      confidence += 0.2;
      type = PhishingType.sender;
    }
    
    // Normalize confidence to 0-1 range
    confidence = confidence.clamp(0.0, 1.0);
    
    return {
      'confidence': confidence,
      'type': type,
      'indicators': indicators,
    };
  }
  
  /// Check if sender is suspicious
  bool _isSuspiciousSender(String sender) {
    // Check for suspicious sender patterns
    final suspiciousPatterns = [
      RegExp(r'^\d{4,}$'), // Only numbers
      RegExp(r'^[A-Z]{2,}$'), // Only uppercase letters
      RegExp(r'.*@.*\..*'), // Email-like patterns in SMS
    ];
    
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(sender));
  }
  
  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Get service statistics
  Map<String, dynamic> getDetectorStats() {
    return {
      'model_type': 'Rule-based Fallback',
      'version': '0.1.0',
      'is_initialized': _isInitialized,
      'max_sequence_length': 512,
      'vocab_size': 0,
      'fallback_mode': true,
    };
  }
  
  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}
