import 'dart:async';
import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import '../../models/sms_message.dart';
import '../../models/user.dart';
import '../../models/phishing_detection.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  
  DatabaseService._internal();
  
  Database? _database;
  late Encrypter _encrypter;
  late Key _key;
  
  Future<void> initialize() async {
    final key = await _getOrCreateEncryptionKey();
    _key = Key(key);
    _encrypter = Encrypter(AES(_key));
    
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'phishti_detector.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      password: key,
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
    
    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_sms_timestamp ON sms_messages(timestamp)');
    await db.execute('CREATE INDEX idx_sms_phishing ON sms_messages(is_phishing)');
    await db.execute('CREATE INDEX idx_sms_archived ON sms_messages(is_archived)');
    await db.execute('CREATE INDEX idx_detections_message ON phishing_detections(message_id)');
    await db.execute('CREATE INDEX idx_signatures_hash ON phishing_signatures(hash)');
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
  
  Future<void> close() async {
    await _database?.close();
  }
}
