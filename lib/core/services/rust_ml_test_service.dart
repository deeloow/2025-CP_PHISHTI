import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';
import 'rust_ml_service.dart';

/// Test service for Rust ML integration
class RustMLTestService {
  static final RustMLTestService _instance = RustMLTestService._internal();
  static RustMLTestService get instance => _instance;
  
  RustMLTestService._internal();
  
  final RustMLService _rustMLService = RustMLService.instance;
  
  /// Run comprehensive tests on the Rust DistilBERT model
  Future<Map<String, dynamic>> runComprehensiveTests() async {
    if (kDebugMode) {
      print('Starting Rust DistilBERT comprehensive tests...');
    }
    
    final results = <String, dynamic>{
      'total_tests': 0,
      'passed_tests': 0,
      'failed_tests': 0,
      'accuracy': 0.0,
      'average_processing_time': 0.0,
      'test_results': <Map<String, dynamic>>[],
      'errors': <String>[],
    };
    
    try {
      // Initialize the service
      await _rustMLService.initialize();
      
      // Test cases with expected results
      final testCases = _getTestCases();
      results['total_tests'] = testCases.length;
      
      int totalProcessingTime = 0;
      int correctPredictions = 0;
      
      for (int i = 0; i < testCases.length; i++) {
        final testCase = testCases[i];
        final message = SmsMessage(
          id: 'test_$i',
          body: testCase['message'] as String,
          sender: 'Test Sender',
          timestamp: DateTime.now(),
          isRead: false,
        );
        
        try {
          final startTime = DateTime.now();
          final detection = await _rustMLService.analyzeSms(message);
          final processingTime = DateTime.now().difference(startTime).inMilliseconds;
          
          final isCorrect = detection.confidence > 0.5 == testCase['expected_phishing'];
          if (isCorrect) {
            correctPredictions++;
          }
          
          totalProcessingTime += processingTime;
          
          final testResult = {
            'test_id': i + 1,
            'message': testCase['message'],
            'expected_phishing': testCase['expected_phishing'],
            'predicted_phishing': detection.confidence > 0.5,
            'confidence': detection.confidence,
            'processing_time_ms': processingTime,
            'indicators': detection.indicators,
            'correct': isCorrect,
            'error': null,
          };
          
          results['test_results'].add(testResult);
          
          if (kDebugMode) {
            print('Test ${i + 1}: ${isCorrect ? "✓" : "✗"} - ${testCase['message']}');
          }
          
        } catch (e) {
          results['failed_tests']++;
          results['errors'].add('Test ${i + 1}: $e');
          
          final testResult = {
            'test_id': i + 1,
            'message': testCase['message'],
            'expected_phishing': testCase['expected_phishing'],
            'predicted_phishing': null,
            'confidence': null,
            'processing_time_ms': null,
            'indicators': null,
            'correct': false,
            'error': e.toString(),
          };
          
          results['test_results'].add(testResult);
        }
      }
      
      // Calculate final metrics
      results['passed_tests'] = correctPredictions;
      results['failed_tests'] = testCases.length - correctPredictions;
      results['accuracy'] = (correctPredictions / testCases.length) * 100;
      results['average_processing_time'] = totalProcessingTime / testCases.length;
      
      // Get detector stats
      results['detector_stats'] = _rustMLService.getDetectorStats();
      
    } catch (e) {
      results['errors'].add('Service initialization failed: $e');
    }
    
    if (kDebugMode) {
      print('Rust DistilBERT tests completed:');
      print('Accuracy: ${results['accuracy']}%');
      print('Average processing time: ${results['average_processing_time']}ms');
    }
    
    return results;
  }
  
  /// Get test cases for comprehensive testing
  List<Map<String, dynamic>> _getTestCases() {
    return [
      // Phishing messages (expected: true)
      {
        'message': 'URGENT: Your account will be suspended. Click here to verify immediately!',
        'expected_phishing': true,
      },
      {
        'message': 'Your credit card has been blocked. Verify now: http://fake-bank.com',
        'expected_phishing': true,
      },
      {
        'message': 'Congratulations! You\'ve won $1000. Claim now by clicking: http://scam-lottery.com',
        'expected_phishing': true,
      },
      {
        'message': 'Your PayPal account is limited. Restore access: http://fake-paypal.com/restore',
        'expected_phishing': true,
      },
      {
        'message': 'Bank security notice: Update your details now: http://scam-bank.com/update',
        'expected_phishing': true,
      },
      {
        'message': 'Your package is held at customs. Pay fee: http://fake-shipping.com/pay',
        'expected_phishing': true,
      },
      {
        'message': 'Tax refund available. Claim $500: http://fake-irs.com/refund',
        'expected_phishing': true,
      },
      {
        'message': 'Your Netflix subscription expired. Renew: http://fake-netflix.com/renew',
        'expected_phishing': true,
      },
      {
        'message': 'Amazon security alert. Verify account: http://fake-amazon.com/verify',
        'expected_phishing': true,
      },
      {
        'message': 'Your phone bill is overdue. Pay now: http://scam-telecom.com/pay',
        'expected_phishing': true,
      },
      
      // Legitimate messages (expected: false)
      {
        'message': 'Hi, how are you doing today? Hope you\'re well.',
        'expected_phishing': false,
      },
      {
        'message': 'Thanks for the meeting yesterday. Let\'s follow up next week.',
        'expected_phishing': false,
      },
      {
        'message': 'Don\'t forget about dinner tonight at 7 PM.',
        'expected_phishing': false,
      },
      {
        'message': 'Happy birthday! Hope you have a wonderful day.',
        'expected_phishing': false,
      },
      {
        'message': 'The weather is beautiful today. Perfect for a walk.',
        'expected_phishing': false,
      },
      {
        'message': 'Can you pick up milk on your way home?',
        'expected_phishing': false,
      },
      {
        'message': 'Great job on the presentation today!',
        'expected_phishing': false,
      },
      {
        'message': 'See you at the gym tomorrow morning.',
        'expected_phishing': false,
      },
      {
        'message': 'The movie starts at 8 PM. Don\'t be late!',
        'expected_phishing': false,
      },
      {
        'message': 'Thanks for helping me move last weekend.',
        'expected_phishing': false,
      },
    ];
  }
  
  /// Test specific message
  Future<Map<String, dynamic>> testMessage(String message) async {
    try {
      await _rustMLService.initialize();
      
      final smsMessage = SmsMessage(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        body: message,
        sender: 'Test Sender',
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      final startTime = DateTime.now();
      final detection = await _rustMLService.analyzeSms(smsMessage);
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      
      return {
        'message': message,
        'is_phishing': detection.confidence > 0.5,
        'confidence': detection.confidence,
        'indicators': detection.indicators,
        'processing_time_ms': processingTime,
        'detector_stats': _rustMLService.getDetectorStats(),
        'error': null,
      };
    } catch (e) {
      return {
        'message': message,
        'is_phishing': null,
        'confidence': null,
        'indicators': null,
        'processing_time_ms': null,
        'detector_stats': null,
        'error': e.toString(),
      };
    }
  }
}
