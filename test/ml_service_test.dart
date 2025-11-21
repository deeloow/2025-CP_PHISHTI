import 'package:flutter_test/flutter_test.dart';
import 'package:phishti_detector/core/services/ml_service.dart';
import 'package:phishti_detector/models/sms_message.dart';

void main() {
  group('MLService Tests', () {
    late MLService mlService;

    setUp(() {
      mlService = MLService.instance;
    });

    test('should initialize ML service successfully', () async {
      // Test initialization
      await mlService.initialize(modelType: ModelType.lstm);
      
      final stats = mlService.getModelStats();
      expect(stats['isInitialized'], true);
      expect(stats['currentModel'], contains('lstm'));
    });

    test('should detect phishing SMS messages', () async {
      await mlService.initialize(modelType: ModelType.lstm);
      
      // Test phishing message
      final phishingMessage = SmsMessage(
        id: '1',
        sender: '12345',
        body: 'URGENT: Your account will be suspended. Click here to verify: http://fake-bank.com/verify',
        timestamp: DateTime.now(),
      );
      
      final detection = await mlService.analyzeSms(phishingMessage);
      
      expect(detection.confidence, greaterThan(0.5));
      expect(detection.indicators.isNotEmpty, true);
    });

    test('should identify legitimate SMS messages', () async {
      await mlService.initialize(modelType: ModelType.lstm);
      
      // Test legitimate message
      final legitimateMessage = SmsMessage(
        id: '2',
        sender: 'Friend',
        body: 'Hi, how are you doing today? Hope you are well.',
        timestamp: DateTime.now(),
      );
      
      final detection = await mlService.analyzeSms(legitimateMessage);
      
      // Should have low confidence for phishing
      expect(detection.confidence, lessThan(0.7));
    });

    test('should switch between different model types', () async {
      await mlService.initialize(modelType: ModelType.lstm);
      
      // Verify initial model
      expect(mlService.currentModelType, ModelType.lstm);
      
      // Switch to BERT model (if available)
      await mlService.switchModel(ModelType.bert);
      expect(mlService.currentModelType, ModelType.bert);
      
      // Switch back to LSTM
      await mlService.switchModel(ModelType.lstm);
      expect(mlService.currentModelType, ModelType.lstm);
    });

    test('should handle various phishing patterns', () async {
      await mlService.initialize(modelType: ModelType.lstm);
      
      final testCases = [
        // Banking phishing
        'Your account has been suspended. Verify now: http://fake-bank.com',
        // Prize scam
        'Congratulations! You won \$1000. Claim here: http://scam-lottery.com',
        // Tech support scam
        'Your computer is infected. Download fix: http://fake-antivirus.com',
        // Urgent language
        'IMMEDIATE ACTION REQUIRED: Update your payment information',
        // Financial scam
        'Tax refund available. Claim \$500 now: http://fake-irs.com',
      ];
      
      for (final messageBody in testCases) {
        final message = SmsMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: '12345',
          body: messageBody,
          timestamp: DateTime.now(),
        );
        
        final detection = await mlService.analyzeSms(message);
        
        // Should detect as suspicious
        expect(detection.confidence, greaterThan(0.3), 
               reason: 'Failed to detect phishing in: $messageBody');
      }
    });

    test('should handle legitimate message patterns', () async {
      await mlService.initialize(modelType: ModelType.lstm);
      
      final testCases = [
        'Hi, how are you doing today?',
        'Thanks for the meeting yesterday.',
        'Your appointment is confirmed for tomorrow at 2 PM.',
        'The package was delivered successfully.',
        'Happy birthday! Hope you have a wonderful day.',
      ];
      
      for (final messageBody in testCases) {
        final message = SmsMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: 'Friend',
          body: messageBody,
          timestamp: DateTime.now(),
        );
        
        final detection = await mlService.analyzeSms(message);
        
        // Should have low phishing confidence
        expect(detection.confidence, lessThan(0.8), 
               reason: 'False positive for legitimate message: $messageBody');
      }
    });

    test('should extract relevant indicators', () async {
      await mlService.initialize(modelType: ModelType.lstm);
      
      final message = SmsMessage(
        id: '1',
        sender: '12345',
        body: 'URGENT: Your credit card is blocked. Verify immediately: http://fake-visa.com/verify',
        timestamp: DateTime.now(),
      );
      
      final detection = await mlService.analyzeSms(message);
      
      // Should extract relevant indicators
      expect(detection.indicators.any((indicator) => 
             indicator.toLowerCase().contains('urgent')), true);
      expect(detection.indicators.any((indicator) => 
             indicator.toLowerCase().contains('url') || 
             indicator.toLowerCase().contains('link')), true);
    });

    test('should generate message signatures', () async {
      await mlService.initialize(modelType: ModelType.lstm);
      
      final message = SmsMessage(
        id: '1',
        sender: 'TestSender',
        body: 'Test message content',
        timestamp: DateTime.now(),
      );
      
      final signature1 = await mlService.generateSignature(message);
      final signature2 = await mlService.generateSignature(message);
      
      // Same message should generate same signature
      expect(signature1, equals(signature2));
      expect(signature1.isNotEmpty, true);
    });

    test('should provide model statistics', () async {
      await mlService.initialize(modelType: ModelType.lstm);
      
      final stats = mlService.getModelStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('currentModel'), true);
      expect(stats.containsKey('isInitialized'), true);
      expect(stats.containsKey('vocabLoaded'), true);
      expect(stats.containsKey('modelsLoaded'), true);
    });

    tearDown(() async {
      await mlService.dispose();
    });
  });

  group('Model Performance Tests', () {
    test('should meet minimum accuracy requirements', () async {
      final mlService = MLService.instance;
      await mlService.initialize(modelType: ModelType.lstm);
      
      // Test with known phishing and legitimate messages
      final testCases = [
        {'message': 'URGENT: Your account suspended. Verify: http://fake.com', 'isPhishing': true},
        {'message': 'Hi, how are you today?', 'isPhishing': false},
        {'message': 'You won \$1000! Claim now: http://scam.com', 'isPhishing': true},
        {'message': 'Thanks for the meeting yesterday.', 'isPhishing': false},
        {'message': 'Your credit card blocked. Verify: http://fake-bank.com', 'isPhishing': true},
        {'message': 'Your appointment confirmed for tomorrow.', 'isPhishing': false},
      ];
      
      int correctPredictions = 0;
      
      for (final testCase in testCases) {
        final message = SmsMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: '12345',
          body: testCase['message'] as String,
          timestamp: DateTime.now(),
        );
        
        final detection = await mlService.analyzeSms(message);
        final isPhishing = testCase['isPhishing'] as bool;
        
        // Consider prediction correct if confidence aligns with expectation
        final predictedPhishing = detection.confidence > 0.5;
        if (predictedPhishing == isPhishing) {
          correctPredictions++;
        }
      }
      
      final accuracy = correctPredictions / testCases.length;
      
      // Should achieve at least 70% accuracy on basic test cases
      expect(accuracy, greaterThanOrEqualTo(0.7), 
             reason: 'Model accuracy ($accuracy) below minimum threshold');
    });
  });
}
