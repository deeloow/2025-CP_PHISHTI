import 'package:flutter/foundation.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';

/// Mock Rust DistilBERT ML service for testing
class MockRustMLService {
  static final MockRustMLService _instance = MockRustMLService._internal();
  static MockRustMLService get instance => _instance;
  
  MockRustMLService._internal();
  
  bool _isInitialized = false;
  
  /// Initialize the mock Rust ML service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (kDebugMode) {
        print('Initializing Mock Rust DistilBERT ML Service...');
      }
      
      // Simulate initialization delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      _isInitialized = true;
      if (kDebugMode) {
        print('Mock Rust DistilBERT ML Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Mock Rust ML Service: $e');
      }
      _isInitialized = true;
    }
  }
  
  /// Analyze SMS message using mock DistilBERT behavior
  Future<PhishingDetection> analyzeSms(SmsMessage message) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final startTime = DateTime.now();
      
      // Mock ML analysis - simulate DistilBERT behavior
      final result = _mockMLAnalysis(message.body);
      
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      
      return PhishingDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        messageId: message.id,
        confidence: result['confidence'],
        type: result['type'],
        indicators: result['indicators'],
        reason: 'Mock DistilBERT ML analysis - ${processingTime}ms',
        detectedAt: DateTime.now(),
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('Error in Mock Rust ML analysis: $e');
      }
      return PhishingDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        messageId: message.id,
        confidence: 0.0,
        type: PhishingType.content,
        indicators: ['Mock DistilBERT analysis error'],
        reason: 'Mock DistilBERT analysis failed - ML analysis unavailable',
        detectedAt: DateTime.now(),
      );
    }
  }
  
  /// Mock ML analysis that simulates DistilBERT behavior
  Map<String, dynamic> _mockMLAnalysis(String message) {
    final List<String> indicators = [];
    final lowerMessage = message.toLowerCase();
    
    double phishingScore = 0.0;
    
    // Urgent language detection (high weight)
    const urgentKeywords = [
      'urgent', 'immediately', 'act now', 'limited time', 'expires',
      'verify', 'confirm', 'suspended', 'blocked', 'security', 'click here'
    ];
    
    for (final keyword in urgentKeywords) {
      if (lowerMessage.contains(keyword)) {
        phishingScore += 0.3;
        indicators.add("Urgent language: '$keyword'");
      }
    }

    // Financial keywords (high weight)
    const financialKeywords = [
      'password', 'pin', 'ssn', 'credit card', 'bank account',
      'wire transfer', 'gift card', 'bitcoin', 'cryptocurrency',
      'account', 'login', 'verify account'
    ];
    
    for (final keyword in financialKeywords) {
      if (lowerMessage.contains(keyword)) {
        phishingScore += 0.25;
        indicators.add("Financial request: '$keyword'");
      }
    }

    // Suspicious URLs (medium weight)
    if (lowerMessage.contains('http') || lowerMessage.contains('www.') || lowerMessage.contains('.com')) {
      phishingScore += 0.2;
      indicators.add('Contains URL');
    }

    // Suspicious sender patterns
    if (lowerMessage.contains('bank') || lowerMessage.contains('paypal') || lowerMessage.contains('amazon')) {
      phishingScore += 0.15;
      indicators.add('Suspicious sender pattern');
    }

    // Add some randomness to simulate ML uncertainty
    final randomFactor = (message.length % 10) / 100.0;
    phishingScore += randomFactor;
    
    // Cap the score
    phishingScore = phishingScore.clamp(0.0, 1.0);
    
    // Determine if phishing based on threshold
    final isPhishing = phishingScore > 0.6;
    
    // Add ML confidence indicator
    if (phishingScore > 0.9) {
      indicators.add('Very high ML confidence');
    } else if (phishingScore > 0.8) {
      indicators.add('High ML confidence');
    } else if (phishingScore > 0.7) {
      indicators.add('Moderate ML confidence');
    }

    return {
      'confidence': phishingScore,
      'type': isPhishing ? PhishingType.content : PhishingType.content,
      'indicators': indicators,
    };
  }
  
  /// Check if the detector is initialized
  bool get isInitialized {
    return _isInitialized;
  }
  
  /// Get detector statistics
  Map<String, dynamic> getDetectorStats() {
    return {
      'model_type': 'Mock DistilBERT',
      'version': '0.1.0',
      'is_initialized': _isInitialized,
      'max_sequence_length': 512,
      'vocab_size': 30522,
      'note': 'Mock implementation for testing - simulates DistilBERT behavior'
    };
  }
}
