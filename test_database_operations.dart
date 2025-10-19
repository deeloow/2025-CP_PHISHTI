import 'package:flutter_test/flutter_test.dart';
import 'package:phishti_detector/core/services/database_service.dart';
import 'package:phishti_detector/models/sms_message.dart';
import 'package:phishti_detector/models/phishing_detection.dart';

void main() {
  group('Database Operations Tests', () {
    late DatabaseService databaseService;
    
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    
    setUp(() async {
      databaseService = DatabaseService.instance;
      await databaseService.initialize();
    });
    
    test('should initialize database service', () async {
      expect(databaseService, isNotNull);
      print('✅ Database service initialized successfully');
    });
    
    test('should insert and retrieve SMS message', () async {
      final testMessage = SmsMessage(
        id: 'test-1',
        sender: 'Test Sender',
        body: 'This is a test message',
        timestamp: DateTime.now(),
        isPhishing: false,
        phishingScore: 0.0,
        extractedUrls: [],
      );
      
      // Insert message
      await databaseService.insertSmsMessage(testMessage);
      print('✅ SMS message inserted successfully');
      
      // Retrieve message
      final retrievedMessage = await databaseService.getSmsMessageById('test-1');
      expect(retrievedMessage, isNotNull);
      expect(retrievedMessage!.id, equals('test-1'));
      expect(retrievedMessage.sender, equals('Test Sender'));
      expect(retrievedMessage.body, equals('This is a test message'));
      print('✅ SMS message retrieved successfully');
    });
    
    test('should insert and retrieve phishing detection', () async {
      final testDetection = PhishingDetection(
        id: 'detection-1',
        messageId: 'test-1',
        confidence: 0.85,
        type: PhishingType.content,
        indicators: ['Suspicious keywords', 'Urgent language'],
        reason: 'Test detection',
        detectedAt: DateTime.now(),
      );
      
      // Insert detection
      await databaseService.insertPhishingDetection(testDetection);
      print('✅ Phishing detection inserted successfully');
      
      // Retrieve detections
      final detections = await databaseService.getPhishingDetections();
      expect(detections, isNotEmpty);
      expect(detections.first.id, equals('detection-1'));
      print('✅ Phishing detection retrieved successfully');
    });
    
    test('should get statistics', () async {
      final stats = await databaseService.getStatistics();
      expect(stats, isNotNull);
      expect(stats['totalMessages'], isA<int>());
      expect(stats['phishingMessages'], isA<int>());
      expect(stats['legitimateMessages'], isA<int>());
      print('✅ Statistics retrieved successfully');
      print('   - Total Messages: ${stats['totalMessages']}');
      print('   - Phishing Messages: ${stats['phishingMessages']}');
      print('   - Legitimate Messages: ${stats['legitimateMessages']}');
    });
    
    test('should block and unblock sender', () async {
      const testSender = 'spam@example.com';
      
      // Block sender
      await databaseService.blockSender(testSender);
      print('✅ Sender blocked successfully');
      
      // Check if blocked
      final isBlocked = await databaseService.isSenderBlocked(testSender);
      expect(isBlocked, isTrue);
      print('✅ Sender is blocked');
      
      // Unblock sender
      await databaseService.unblockSender(testSender);
      print('✅ Sender unblocked successfully');
      
      // Check if unblocked
      final isUnblocked = await databaseService.isSenderBlocked(testSender);
      expect(isUnblocked, isFalse);
      print('✅ Sender is unblocked');
    });
    
    test('should block and unblock URL', () async {
      const testUrl = 'http://malicious-site.com';
      
      // Block URL
      await databaseService.blockUrl(testUrl);
      print('✅ URL blocked successfully');
      
      // Check if blocked
      final isBlocked = await databaseService.isUrlBlocked(testUrl);
      expect(isBlocked, isTrue);
      print('✅ URL is blocked');
      
      // Unblock URL
      await databaseService.unblockUrl(testUrl);
      print('✅ URL unblocked successfully');
      
      // Check if unblocked
      final isUnblocked = await databaseService.isUrlBlocked(testUrl);
      expect(isUnblocked, isFalse);
      print('✅ URL is unblocked');
    });
    
    test('should get blocked senders and URLs', () async {
      // Get blocked senders
      final blockedSenders = await databaseService.getBlockedSenders();
      expect(blockedSenders, isA<List<String>>());
      print('✅ Blocked senders retrieved: ${blockedSenders.length}');
      
      // Get blocked URLs
      final blockedUrls = await databaseService.getBlockedUrls();
      expect(blockedUrls, isA<List<String>>());
      print('✅ Blocked URLs retrieved: ${blockedUrls.length}');
    });
    
    test('should generate message signature', () async {
      const testSender = 'test@example.com';
      const testMessage = 'This is a test message for signature generation';
      final signature = await databaseService.generateMessageSignature(testSender, testMessage);
      expect(signature, isNotNull);
      expect(signature, isNotEmpty);
      print('✅ Message signature generated: ${signature.substring(0, 20)}...');
    });
    
    test('should check for duplicate messages', () async {
      const testSender = 'test@example.com';
      const testMessage = 'This is a duplicate test message';
      final isDuplicate = await databaseService.isDuplicateMessage(testSender, testMessage);
      expect(isDuplicate, isA<bool>());
      print('✅ Duplicate check completed: $isDuplicate');
    });
    
    tearDown(() async {
      // Clean up test data
      try {
        await databaseService.deleteSmsMessage('test-1');
        print('✅ Test data cleaned up');
      } catch (e) {
        print('⚠️ Cleanup warning: $e');
      }
    });
  });
}
