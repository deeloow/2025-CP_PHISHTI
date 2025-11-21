import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';

abstract class DatabaseServiceInterface {
  static DatabaseServiceInterface get instance => throw UnimplementedError();
  
  Future<void> initialize();
  
  // SMS Messages operations
  Future<void> insertSmsMessage(SmsMessage message);
  Future<List<SmsMessage>> getSmsMessages({
    bool? isPhishing,
    bool? isArchived,
    int? limit,
    int? offset,
  });
  Future<SmsMessage?> getSmsMessageById(String id);
  Future<void> updateSmsMessage(SmsMessage message);
  Future<void> deleteSmsMessage(String id);
  
  // Phishing Detection operations
  Future<void> insertPhishingDetection(PhishingDetection detection);
  Future<List<PhishingDetection>> getPhishingDetections({
    String? messageId,
    int? limit,
    int? offset,
  });
  
  // Whitelist operations
  Future<void> addToWhitelist(String type, String value);
  Future<List<Map<String, dynamic>>> getWhitelist();
  Future<bool> isWhitelisted(String type, String value);
  Future<void> removeFromWhitelist(String id);
  
  // Statistics
  Future<Map<String, int>> getStatistics();
  
  // Blocked senders operations
  Future<void> blockSender(String sender, {String? reason, bool autoBlocked = false});
  Future<bool> isSenderBlocked(String sender);
  Future<void> unblockSender(String sender);
  Future<List<Map<String, dynamic>>> getBlockedSenders();
  
  // Blocked URLs operations
  Future<void> blockUrl(String url, {String? reason, String threatLevel = 'medium', bool autoBlocked = false});
  Future<bool> isUrlBlocked(String url);
  Future<void> unblockUrl(String url);
  Future<List<Map<String, dynamic>>> getBlockedUrls();
  
  // Message signature operations for duplicate detection
  Future<String> generateMessageSignature(String sender, String body);
  Future<bool> isDuplicateMessage(String sender, String body);
  Future<void> markSignatureAsPhishing(String sender, String body);
  Future<bool> isKnownPhishingSignature(String sender, String body);
  
  Future<void> close();
}
