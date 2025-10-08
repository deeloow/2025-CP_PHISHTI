import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:uuid/uuid.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';
import 'database_service_interface.dart';

class DatabaseService implements DatabaseServiceInterface {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  
  DatabaseService._internal();
  
  Database? _database;
  late Encrypter _encrypter;
  late Key _key;
  
  Future<void> initialize() async {
    final key = await _getOrCreateEncryptionKey();
    _key = Key(Uint8List.fromList(key.codeUnits));
    _encrypter = Encrypter(AES(_key));
    
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'phishti_detector.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  Future<String> _getOrCreateEncryptionKey() async {
    // In production, this should be stored securely using flutter_secure_storage
    // For now, we'll generate a key based on device info
    final deviceInfo = await _getDeviceInfo();
    final bytes = utf8.encode(deviceInfo);
    return sha256.convert(bytes).toString().substring(0, 32);
  }
  
  Future<String> _getDeviceInfo() async {
    // This is a simplified version - in production, use device_info_plus
    return 'phishti_device_key_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // SMS Messages table
    await db.execute('''
      CREATE TABLE sms_messages (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_phishing INTEGER NOT NULL DEFAULT 0,
        phishing_score REAL NOT NULL DEFAULT 0.0,
        extracted_urls TEXT,
        signature TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_whitelisted INTEGER NOT NULL DEFAULT 0,
        archived_at INTEGER,
        reason TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');
    
    // Phishing Detections table
    await db.execute('''
      CREATE TABLE phishing_detections (
        id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        confidence REAL NOT NULL,
        type TEXT NOT NULL,
        indicators TEXT NOT NULL,
        reason TEXT NOT NULL,
        detected_at INTEGER NOT NULL,
        is_false_positive INTEGER NOT NULL DEFAULT 0,
        is_user_reported INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (message_id) REFERENCES sms_messages (id)
      )
    ''');
    
    // Phishing Signatures table (for cloud sync)
    await db.execute('''
      CREATE TABLE phishing_signatures (
        hash TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_confirmed INTEGER NOT NULL DEFAULT 0,
        report_count INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (message_id) REFERENCES sms_messages (id)
      )
    ''');
    
    // User Settings table
    await db.execute('''
      CREATE TABLE user_settings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        settings TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');
    
    // Whitelist table
    await db.execute('''
      CREATE TABLE whitelist (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');
    
    // Blocked senders table
    await db.execute('''
      CREATE TABLE blocked_senders (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL UNIQUE,
        reason TEXT,
        blocked_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        auto_blocked INTEGER NOT NULL DEFAULT 0,
        message_count INTEGER NOT NULL DEFAULT 1
      )
    ''');
    
    // Blocked URLs table
    await db.execute('''
      CREATE TABLE blocked_urls (
        id TEXT PRIMARY KEY,
        url TEXT NOT NULL UNIQUE,
        domain TEXT NOT NULL,
        reason TEXT,
        threat_level TEXT NOT NULL DEFAULT 'medium',
        blocked_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        auto_blocked INTEGER NOT NULL DEFAULT 0,
        detection_count INTEGER NOT NULL DEFAULT 1
      )
    ''');
    
    // Message signatures for duplicate detection
    await db.execute('''
      CREATE TABLE message_signatures (
        id TEXT PRIMARY KEY,
        content_hash TEXT NOT NULL UNIQUE,
        sender_hash TEXT NOT NULL,
        first_seen INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        occurrence_count INTEGER NOT NULL DEFAULT 1,
        is_phishing INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_sms_timestamp ON sms_messages(timestamp)');
    await db.execute('CREATE INDEX idx_sms_phishing ON sms_messages(is_phishing)');
    await db.execute('CREATE INDEX idx_sms_archived ON sms_messages(is_archived)');
    await db.execute('CREATE INDEX idx_detections_message ON phishing_detections(message_id)');
    await db.execute('CREATE INDEX idx_signatures_hash ON phishing_signatures(hash)');
    await db.execute('CREATE INDEX idx_blocked_senders ON blocked_senders(sender)');
    await db.execute('CREATE INDEX idx_blocked_urls ON blocked_urls(url)');
    await db.execute('CREATE INDEX idx_blocked_urls_domain ON blocked_urls(domain)');
    await db.execute('CREATE INDEX idx_message_signatures_content ON message_signatures(content_hash)');
    await db.execute('CREATE INDEX idx_message_signatures_sender ON message_signatures(sender_hash)');
  }
  
  // SMS Messages operations
  Future<void> insertSmsMessage(SmsMessage message) async {
    final db = _database!;
    await db.insert(
      'sms_messages',
      _encryptSmsMessage(message).toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<SmsMessage>> getSmsMessages({
    bool? isPhishing,
    bool? isArchived,
    int? limit,
    int? offset,
  }) async {
    final db = _database!;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (isPhishing != null) {
      whereClause += ' AND is_phishing = ?';
      whereArgs.add(isPhishing ? 1 : 0);
    }
    
    if (isArchived != null) {
      whereClause += ' AND is_archived = ?';
      whereArgs.add(isArchived ? 1 : 0);
    }
    
    final results = await db.query(
      'sms_messages',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    
    return results.map((row) => _decryptSmsMessage(SmsMessage.fromJson(row))).toList();
  }
  
  Future<SmsMessage?> getSmsMessageById(String id) async {
    final db = _database!;
    final results = await db.query(
      'sms_messages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    return _decryptSmsMessage(SmsMessage.fromJson(results.first));
  }
  
  Future<void> updateSmsMessage(SmsMessage message) async {
    final db = _database!;
    await db.update(
      'sms_messages',
      _encryptSmsMessage(message).toJson(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }
  
  Future<void> deleteSmsMessage(String id) async {
    final db = _database!;
    await db.delete(
      'sms_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Phishing Detection operations
  Future<void> insertPhishingDetection(PhishingDetection detection) async {
    final db = _database!;
    await db.insert(
      'phishing_detections',
      detection.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<PhishingDetection>> getPhishingDetections({
    String? messageId,
    int? limit,
    int? offset,
  }) async {
    final db = _database!;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (messageId != null) {
      whereClause += ' AND message_id = ?';
      whereArgs.add(messageId);
    }
    
    final results = await db.query(
      'phishing_detections',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'detected_at DESC',
      limit: limit,
      offset: offset,
    );
    
    return results.map((row) => PhishingDetection.fromJson(row)).toList();
  }
  
  // Phishing Signatures operations
  Future<void> insertPhishingSignature(PhishingSignature signature) async {
    final db = _database!;
    await db.insert(
      'phishing_signatures',
      signature.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<PhishingSignature>> getPhishingSignatures() async {
    final db = _database!;
    final results = await db.query('phishing_signatures');
    return results.map((row) => PhishingSignature.fromJson(row)).toList();
  }
  
  Future<bool> isSignatureKnown(String hash) async {
    final db = _database!;
    final results = await db.query(
      'phishing_signatures',
      where: 'hash = ?',
      whereArgs: [hash],
      limit: 1,
    );
    return results.isNotEmpty;
  }
  
  // Whitelist operations
  Future<void> addToWhitelist(String type, String value) async {
    final db = _database!;
    await db.insert(
      'whitelist',
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'value': value,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<Map<String, dynamic>>> getWhitelist() async {
    final db = _database!;
    return await db.query('whitelist', orderBy: 'created_at DESC');
  }
  
  Future<bool> isWhitelisted(String type, String value) async {
    final db = _database!;
    final results = await db.query(
      'whitelist',
      where: 'type = ? AND value = ?',
      whereArgs: [type, value],
      limit: 1,
    );
    return results.isNotEmpty;
  }
  
  Future<void> removeFromWhitelist(String id) async {
    final db = _database!;
    await db.delete(
      'whitelist',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Statistics
  Future<Map<String, int>> getStatistics() async {
    final db = _database!;
    
    final totalMessages = await db.rawQuery('SELECT COUNT(*) as count FROM sms_messages');
    final phishingMessages = await db.rawQuery('SELECT COUNT(*) as count FROM sms_messages WHERE is_phishing = 1');
    final archivedMessages = await db.rawQuery('SELECT COUNT(*) as count FROM sms_messages WHERE is_archived = 1');
    final weeklyDetections = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sms_messages 
      WHERE is_phishing = 1 AND timestamp > strftime('%s', 'now', '-7 days')
    ''');
    
    return {
      'totalMessages': totalMessages.first['count'] as int,
      'phishingMessages': phishingMessages.first['count'] as int,
      'archivedMessages': archivedMessages.first['count'] as int,
      'weeklyDetections': weeklyDetections.first['count'] as int,
    };
  }
  
  // Encryption/Decryption helpers
  SmsMessage _encryptSmsMessage(SmsMessage message) {
    final encryptedBody = _encrypter.encrypt(message.body, iv: IV.fromLength(16));
    return message.copyWith(body: encryptedBody.base64);
  }
  
  SmsMessage _decryptSmsMessage(SmsMessage message) {
    try {
      final encrypted = Encrypted.fromBase64(message.body);
      final decrypted = _encrypter.decrypt(encrypted, iv: IV.fromLength(16));
      return message.copyWith(body: decrypted);
    } catch (e) {
      // If decryption fails, return the original message
      return message;
    }
  }
  
  // Blocked senders operations
  Future<void> blockSender(String sender, {String? reason, bool autoBlocked = false}) async {
    final db = _database!;
    await db.insert(
      'blocked_senders',
      {
        'id': Uuid().v4(),
        'sender': sender,
        'reason': reason,
        'auto_blocked': autoBlocked ? 1 : 0,
        'blocked_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<bool> isSenderBlocked(String sender) async {
    final db = _database!;
    final result = await db.query(
      'blocked_senders',
      where: 'sender = ?',
      whereArgs: [sender],
      limit: 1,
    );
    return result.isNotEmpty;
  }
  
  Future<void> unblockSender(String sender) async {
    final db = _database!;
    await db.delete(
      'blocked_senders',
      where: 'sender = ?',
      whereArgs: [sender],
    );
  }
  
  Future<List<Map<String, dynamic>>> getBlockedSenders() async {
    final db = _database!;
    return await db.query('blocked_senders', orderBy: 'blocked_at DESC');
  }
  
  // Blocked URLs operations
  Future<void> blockUrl(String url, {String? reason, String threatLevel = 'medium', bool autoBlocked = false}) async {
    final db = _database!;
    final domain = _extractDomain(url);
    await db.insert(
      'blocked_urls',
      {
        'id': Uuid().v4(),
        'url': url,
        'domain': domain,
        'reason': reason,
        'threat_level': threatLevel,
        'auto_blocked': autoBlocked ? 1 : 0,
        'blocked_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<bool> isUrlBlocked(String url) async {
    final db = _database!;
    final result = await db.query(
      'blocked_urls',
      where: 'url = ? OR domain = ?',
      whereArgs: [url, _extractDomain(url)],
      limit: 1,
    );
    return result.isNotEmpty;
  }
  
  Future<void> unblockUrl(String url) async {
    final db = _database!;
    await db.delete(
      'blocked_urls',
      where: 'url = ?',
      whereArgs: [url],
    );
  }
  
  Future<List<Map<String, dynamic>>> getBlockedUrls() async {
    final db = _database!;
    return await db.query('blocked_urls', orderBy: 'blocked_at DESC');
  }
  
  // Message signature operations for duplicate detection
  Future<String> generateMessageSignature(String sender, String body) async {
    final content = '$sender:${body.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim()}';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  Future<bool> isDuplicateMessage(String sender, String body) async {
    final db = _database!;
    final signature = await generateMessageSignature(sender, body);
    final senderHash = sha256.convert(utf8.encode(sender)).toString();
    
    final result = await db.query(
      'message_signatures',
      where: 'content_hash = ? AND sender_hash = ?',
      whereArgs: [signature, senderHash],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      // Update occurrence count
      await db.update(
        'message_signatures',
        {'occurrence_count': (result.first['occurrence_count'] as int) + 1},
        where: 'content_hash = ? AND sender_hash = ?',
        whereArgs: [signature, senderHash],
      );
      return true;
    }
    
    // Store new signature
    await db.insert(
      'message_signatures',
      {
        'id': Uuid().v4(),
        'content_hash': signature,
        'sender_hash': senderHash,
        'first_seen': DateTime.now().millisecondsSinceEpoch,
        'occurrence_count': 1,
        'is_phishing': 0,
      },
    );
    
    return false;
  }
  
  Future<void> markSignatureAsPhishing(String sender, String body) async {
    final db = _database!;
    final signature = await generateMessageSignature(sender, body);
    final senderHash = sha256.convert(utf8.encode(sender)).toString();
    
    await db.update(
      'message_signatures',
      {'is_phishing': 1},
      where: 'content_hash = ? AND sender_hash = ?',
      whereArgs: [signature, senderHash],
    );
  }
  
  Future<bool> isKnownPhishingSignature(String sender, String body) async {
    final db = _database!;
    final signature = await generateMessageSignature(sender, body);
    final senderHash = sha256.convert(utf8.encode(sender)).toString();
    
    final result = await db.query(
      'message_signatures',
      where: 'content_hash = ? AND sender_hash = ? AND is_phishing = 1',
      whereArgs: [signature, senderHash],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }
  
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'http://$url');
      return uri.host;
    } catch (e) {
      // If parsing fails, try to extract domain manually
      final cleanUrl = url.replaceAll(RegExp(r'https?://'), '');
      final parts = cleanUrl.split('/');
      return parts.isNotEmpty ? parts[0] : url;
    }
  }

  Future<void> close() async {
    await _database?.close();
  }
}
