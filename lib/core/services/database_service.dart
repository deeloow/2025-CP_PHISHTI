import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';
import 'database_service_interface.dart';

class DatabaseService implements DatabaseServiceInterface {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  
  DatabaseService._internal();
  
  Database? _database;
  late encrypt.Encrypter _encrypter;
  late encrypt.Key _key;
  SharedPreferences? _prefs;
  
  @override
  Future<void> initialize() async {
    if (kIsWeb) {
      // Web: use SharedPreferences as fallback
      _prefs = await SharedPreferences.getInstance();
      print('Database Service initialized (web mode with SharedPreferences)');
      return;
    }
    
    try {
      final key = await _getOrCreateEncryptionKey();
      _key = encrypt.Key(Uint8List.fromList(key.codeUnits));
      _encrypter = encrypt.Encrypter(encrypt.AES(_key));
      
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'phishti_detector.db');
      
      _database = await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Error initializing database: $e');
      // Fallback to SharedPreferences
      _prefs = await SharedPreferences.getInstance();
    }
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
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Migration from version 1 to 2: Update column names to match model
      await db.execute('ALTER TABLE sms_messages RENAME TO sms_messages_old');
      
      // Create new table with correct column names
      await db.execute('''
        CREATE TABLE sms_messages (
          id TEXT PRIMARY KEY,
          sender TEXT NOT NULL,
          body TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          isPhishing INTEGER NOT NULL DEFAULT 0,
          phishingScore REAL NOT NULL DEFAULT 0.0,
          extractedUrls TEXT,
          signature TEXT,
          isArchived INTEGER NOT NULL DEFAULT 0,
          isWhitelisted INTEGER NOT NULL DEFAULT 0,
          archivedAt TEXT,
          reason TEXT,
          threadId TEXT,
          isRead INTEGER NOT NULL DEFAULT 0,
          messageType TEXT NOT NULL DEFAULT 'sms',
          contactName TEXT,
          userClassification TEXT,
          analyzedAt TEXT,
          userNotes TEXT,
          needsUserReview INTEGER NOT NULL DEFAULT 0,
          userTags TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');
      
      // Migrate data from old table
      await db.execute('''
        INSERT INTO sms_messages (
          id, sender, body, timestamp, isPhishing, phishingScore, 
          extractedUrls, signature, isArchived, isWhitelisted, 
          archivedAt, reason, created_at
        )
        SELECT 
          id, sender, body, 
          CASE 
            WHEN timestamp IS NULL THEN datetime('now')
            ELSE datetime(timestamp, 'unixepoch')
          END,
          COALESCE(isPhishing, 0),
          COALESCE(phishingScore, 0.0),
          COALESCE(extractedUrls, '[]'),
          signature,
          COALESCE(isArchived, 0),
          COALESCE(isWhitelisted, 0),
          CASE 
            WHEN archivedAt IS NULL THEN NULL
            ELSE datetime(archivedAt, 'unixepoch')
          END,
          reason,
          COALESCE(created_at, strftime('%s', 'now'))
        FROM sms_messages_old
      ''');
      
      // Drop old table
      await db.execute('DROP TABLE sms_messages_old');
    }
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // SMS Messages table
    await db.execute('''
      CREATE TABLE sms_messages (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isPhishing INTEGER NOT NULL DEFAULT 0,
        phishingScore REAL NOT NULL DEFAULT 0.0,
        extractedUrls TEXT,
        signature TEXT,
        isArchived INTEGER NOT NULL DEFAULT 0,
        isWhitelisted INTEGER NOT NULL DEFAULT 0,
        archivedAt TEXT,
        reason TEXT,
        threadId TEXT,
        isRead INTEGER NOT NULL DEFAULT 0,
        messageType TEXT NOT NULL DEFAULT 'sms',
        contactName TEXT,
        userClassification TEXT,
        analyzedAt TEXT,
        userNotes TEXT,
        needsUserReview INTEGER NOT NULL DEFAULT 0,
        userTags TEXT,
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
        isPhishing INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_sms_timestamp ON sms_messages(timestamp)');
    await db.execute('CREATE INDEX idx_sms_phishing ON sms_messages(isPhishing)');
    await db.execute('CREATE INDEX idx_sms_archived ON sms_messages(isArchived)');
    await db.execute('CREATE INDEX idx_detections_message ON phishing_detections(message_id)');
    await db.execute('CREATE INDEX idx_signatures_hash ON phishing_signatures(hash)');
    await db.execute('CREATE INDEX idx_blocked_senders ON blocked_senders(sender)');
    await db.execute('CREATE INDEX idx_blocked_urls ON blocked_urls(url)');
    await db.execute('CREATE INDEX idx_blocked_urls_domain ON blocked_urls(domain)');
    await db.execute('CREATE INDEX idx_message_signatures_content ON message_signatures(content_hash)');
    await db.execute('CREATE INDEX idx_message_signatures_sender ON message_signatures(sender_hash)');
  }
  
  // SMS Messages operations
  @override
  Future<void> insertSmsMessage(SmsMessage message) async {
    if (kIsWeb) {
      // Web: store in SharedPreferences as JSON
      final messages = await getSmsMessages();
      messages.add(message);
      final messagesJson = messages.map((m) => m.toJson()).toList();
      await _prefs!.setString('sms_messages', jsonEncode(messagesJson));
      return;
    }
    
    final db = _database!;
    final messageJson = _encryptSmsMessage(message).toJson();
    
    // Convert List fields to JSON strings for SQLite
    final dbData = Map<String, dynamic>.from(messageJson);
    if (messageJson['extractedUrls'] != null) {
      dbData['extractedUrls'] = jsonEncode(messageJson['extractedUrls']);
    }
    if (messageJson['userTags'] != null) {
      dbData['userTags'] = jsonEncode(messageJson['userTags']);
    }
    // Convert DateTime to ISO string (toJson() already returns Strings, but handle both cases)
    if (messageJson['timestamp'] != null) {
      if (messageJson['timestamp'] is String) {
        dbData['timestamp'] = messageJson['timestamp'];
      } else if (messageJson['timestamp'] is DateTime) {
        dbData['timestamp'] = (messageJson['timestamp'] as DateTime).toIso8601String();
      }
    }
    if (messageJson['archivedAt'] != null) {
      if (messageJson['archivedAt'] is String) {
        dbData['archivedAt'] = messageJson['archivedAt'];
      } else if (messageJson['archivedAt'] is DateTime) {
        dbData['archivedAt'] = (messageJson['archivedAt'] as DateTime).toIso8601String();
      }
    }
    if (messageJson['analyzedAt'] != null) {
      if (messageJson['analyzedAt'] is String) {
        dbData['analyzedAt'] = messageJson['analyzedAt'];
      } else if (messageJson['analyzedAt'] is DateTime) {
        dbData['analyzedAt'] = (messageJson['analyzedAt'] as DateTime).toIso8601String();
      }
    }
    // Convert enum to string
    if (messageJson['messageType'] != null) {
      dbData['messageType'] = messageJson['messageType'].toString().split('.').last;
    }
    if (messageJson['userClassification'] != null) {
      dbData['userClassification'] = messageJson['userClassification'].toString().split('.').last;
    }
    
    await db.insert(
      'sms_messages',
      dbData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  @override
  Future<List<SmsMessage>> getSmsMessages({
    bool? isPhishing,
    bool? isArchived,
    int? limit,
    int? offset,
  }) async {
    if (kIsWeb) {
      // Web: get from SharedPreferences
      final messagesJson = _prefs!.getString('sms_messages');
      if (messagesJson == null) return [];
      
      final List<dynamic> messagesList = jsonDecode(messagesJson);
      List<SmsMessage> messages = messagesList.map((json) => SmsMessage.fromJson(json)).toList();
      
      // Apply filters
      if (isPhishing != null) {
        messages = messages.where((m) => m.isPhishing == isPhishing).toList();
      }
      if (isArchived != null) {
        messages = messages.where((m) => m.isArchived == isArchived).toList();
      }
      
      // Sort by timestamp
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Apply limit and offset
      if (offset != null && offset > 0) {
        messages = messages.skip(offset).toList();
      }
      if (limit != null && limit > 0) {
        messages = messages.take(limit).toList();
      }
      
      return messages;
    }
    
    final db = _database!;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (isPhishing != null) {
      whereClause += ' AND isPhishing = ?';
      whereArgs.add(isPhishing ? 1 : 0);
    }
    
    if (isArchived != null) {
      whereClause += ' AND isArchived = ?';
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
    
    return results.map((row) => _decryptSmsMessage(SmsMessage.fromJson(_convertDbRowToJson(row)))).toList();
  }
  
  @override
  Future<SmsMessage?> getSmsMessageById(String id) async {
    if (kIsWeb) {
      final messages = await getSmsMessages();
      try {
        return messages.firstWhere((m) => m.id == id);
      } catch (e) {
        return null;
      }
    }
    
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
  
  /// Get recent analyzed messages (both phishing and safe)
  Future<List<SmsMessage>> getRecentAnalyzedMessages({int limit = 10}) async {
    if (kIsWeb) {
      // Web: get from SharedPreferences
      final messagesJson = _prefs!.getString('sms_messages');
      if (messagesJson == null) return [];
      
      final List<dynamic> messagesList = jsonDecode(messagesJson);
      List<SmsMessage> messages = messagesList.map((json) => SmsMessage.fromJson(json)).toList();
      
      // Filter messages that have been analyzed (have phishing score > 0 or are explicitly marked as safe)
      messages = messages.where((m) => m.phishingScore > 0 || m.userClassification != null).toList();
      
      // Sort by timestamp (most recent first)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Apply limit
      return messages.take(limit).toList();
    }
    
    final db = _database!;
    final results = await db.query(
      'sms_messages',
      where: 'phishingScore > 0 OR userClassification IS NOT NULL',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return results.map((json) => _decryptSmsMessage(SmsMessage.fromJson(json))).toList();
  }
  
  @override
  Future<void> updateSmsMessage(SmsMessage message) async {
    if (kIsWeb) {
      final messages = await getSmsMessages();
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index] = message;
        final messagesJson = messages.map((m) => m.toJson()).toList();
        await _prefs!.setString('sms_messages', jsonEncode(messagesJson));
      }
      return;
    }
    
    final db = _database!;
    final messageJson = _encryptSmsMessage(message).toJson();
    
    // Convert List fields to JSON strings for SQLite
    final dbData = Map<String, dynamic>.from(messageJson);
    if (messageJson['extractedUrls'] != null) {
      dbData['extractedUrls'] = jsonEncode(messageJson['extractedUrls']);
    }
    if (messageJson['userTags'] != null) {
      dbData['userTags'] = jsonEncode(messageJson['userTags']);
    }
    // Convert DateTime to ISO string (toJson() already returns Strings, but handle both cases)
    if (messageJson['timestamp'] != null) {
      if (messageJson['timestamp'] is String) {
        dbData['timestamp'] = messageJson['timestamp'];
      } else if (messageJson['timestamp'] is DateTime) {
        dbData['timestamp'] = (messageJson['timestamp'] as DateTime).toIso8601String();
      }
    }
    if (messageJson['archivedAt'] != null) {
      if (messageJson['archivedAt'] is String) {
        dbData['archivedAt'] = messageJson['archivedAt'];
      } else if (messageJson['archivedAt'] is DateTime) {
        dbData['archivedAt'] = (messageJson['archivedAt'] as DateTime).toIso8601String();
      }
    }
    if (messageJson['analyzedAt'] != null) {
      if (messageJson['analyzedAt'] is String) {
        dbData['analyzedAt'] = messageJson['analyzedAt'];
      } else if (messageJson['analyzedAt'] is DateTime) {
        dbData['analyzedAt'] = (messageJson['analyzedAt'] as DateTime).toIso8601String();
      }
    }
    // Convert enum to string
    if (messageJson['messageType'] != null) {
      dbData['messageType'] = messageJson['messageType'].toString().split('.').last;
    }
    if (messageJson['userClassification'] != null) {
      dbData['userClassification'] = messageJson['userClassification'].toString().split('.').last;
    }
    
    await db.update(
      'sms_messages',
      dbData,
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }
  
  @override
  Future<void> deleteSmsMessage(String id) async {
    if (kIsWeb) {
      final messages = await getSmsMessages();
      messages.removeWhere((m) => m.id == id);
      final messagesJson = messages.map((m) => m.toJson()).toList();
      await _prefs!.setString('sms_messages', jsonEncode(messagesJson));
      return;
    }
    
    final db = _database!;
    await db.delete(
      'sms_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Phishing Detection operations
  @override
  Future<void> insertPhishingDetection(PhishingDetection detection) async {
    final db = _database!;
    await db.insert(
      'phishing_detections',
      detection.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  @override
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
  @override
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
  
  @override
  Future<List<Map<String, dynamic>>> getWhitelist() async {
    final db = _database!;
    return await db.query('whitelist', orderBy: 'created_at DESC');
  }
  
  @override
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
  
  @override
  Future<void> removeFromWhitelist(String id) async {
    final db = _database!;
    await db.delete(
      'whitelist',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Statistics
  @override
  Future<Map<String, int>> getStatistics() async {
    if (kIsWeb) {
      final messages = await getSmsMessages();
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      return {
        'totalMessages': messages.length,
        'phishingMessages': messages.where((m) => m.isPhishing).length,
        'archivedMessages': messages.where((m) => m.isArchived).length,
        'weeklyDetections': messages.where((m) => m.isPhishing && m.timestamp.isAfter(weekAgo)).length,
      };
    }
    
    final db = _database!;
    
    final totalMessages = await db.rawQuery('SELECT COUNT(*) as count FROM sms_messages');
    final phishingMessages = await db.rawQuery('SELECT COUNT(*) as count FROM sms_messages WHERE isPhishing = 1');
    final archivedMessages = await db.rawQuery('SELECT COUNT(*) as count FROM sms_messages WHERE isArchived = 1');
    final weeklyDetections = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sms_messages 
      WHERE isPhishing = 1 AND timestamp > strftime('%s', 'now', '-7 days')
    ''');
    
    return {
      'totalMessages': totalMessages.first['count'] as int,
      'phishingMessages': phishingMessages.first['count'] as int,
      'archivedMessages': archivedMessages.first['count'] as int,
      'weeklyDetections': weeklyDetections.first['count'] as int,
    };
  }
  
  // Encryption/Decryption helpers
  /// Convert database row to SmsMessage-compatible JSON
  Map<String, dynamic> _convertDbRowToJson(Map<String, dynamic> row) {
    final json = Map<String, dynamic>.from(row);
    
    // Convert JSON strings back to Lists
    if (row['extractedUrls'] != null && row['extractedUrls'] is String) {
      json['extractedUrls'] = jsonDecode(row['extractedUrls'] as String);
    }
    if (row['userTags'] != null && row['userTags'] is String) {
      json['userTags'] = jsonDecode(row['userTags'] as String);
    }
    
    // Convert ISO strings back to DateTime
    // Handle both String and already-parsed DateTime objects
    if (row['timestamp'] != null) {
      if (row['timestamp'] is String) {
        json['timestamp'] = DateTime.parse(row['timestamp'] as String);
      } else if (row['timestamp'] is DateTime) {
        json['timestamp'] = row['timestamp'];
      } else {
        // Try to parse as int (Unix timestamp)
        try {
          json['timestamp'] = DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int);
        } catch (e) {
          // If all fails, use current time
          json['timestamp'] = DateTime.now();
        }
      }
    }
    if (row['archivedAt'] != null) {
      if (row['archivedAt'] is String) {
        json['archivedAt'] = DateTime.parse(row['archivedAt'] as String);
      } else if (row['archivedAt'] is DateTime) {
        json['archivedAt'] = row['archivedAt'];
      }
    }
    if (row['analyzedAt'] != null) {
      if (row['analyzedAt'] is String) {
        json['analyzedAt'] = DateTime.parse(row['analyzedAt'] as String);
      } else if (row['analyzedAt'] is DateTime) {
        json['analyzedAt'] = row['analyzedAt'];
      }
    }
    
    // Convert string enums back to enum values
    if (row['messageType'] != null && row['messageType'] is String) {
      json['messageType'] = MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == row['messageType'],
        orElse: () => MessageType.sms,
      );
    }
    if (row['userClassification'] != null && row['userClassification'] is String) {
      json['userClassification'] = UserClassification.values.firstWhere(
        (e) => e.toString().split('.').last == row['userClassification'],
        orElse: () => UserClassification.unknown,
      );
    }
    
    return json;
  }
  
  SmsMessage _encryptSmsMessage(SmsMessage message) {
    if (kIsWeb) return message; // Skip encryption on web
    final encryptedBody = _encrypter.encrypt(message.body, iv: encrypt.IV.fromLength(16));
    return message.copyWith(body: encryptedBody.base64);
  }
  
  SmsMessage _decryptSmsMessage(SmsMessage message) {
    if (kIsWeb) return message; // Skip decryption on web
    try {
      final encrypted = encrypt.Encrypted.fromBase64(message.body);
      final decrypted = _encrypter.decrypt(encrypted, iv: encrypt.IV.fromLength(16));
      return message.copyWith(body: decrypted);
    } catch (e) {
      // If decryption fails, return the original message
      return message;
    }
  }
  
  // Blocked senders operations
  @override
  Future<void> blockSender(String sender, {String? reason, bool autoBlocked = false}) async {
    if (kIsWeb) {
      final blockedSenders = await getBlockedSenders();
      blockedSenders.add({
        'id': const Uuid().v4(),
        'sender': sender,
        'reason': reason,
        'auto_blocked': autoBlocked,
        'blocked_at': DateTime.now().millisecondsSinceEpoch,
      });
      await _prefs!.setString('blocked_senders', jsonEncode(blockedSenders));
      return;
    }
    
    final db = _database!;
    await db.insert(
      'blocked_senders',
      {
        'id': const Uuid().v4(),
        'sender': sender,
        'reason': reason,
        'auto_blocked': autoBlocked ? 1 : 0,
        'blocked_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  @override
  Future<bool> isSenderBlocked(String sender) async {
    if (kIsWeb) {
      final blockedSenders = await getBlockedSenders();
      return blockedSenders.any((blocked) => blocked['sender'] == sender);
    }
    
    final db = _database!;
    final result = await db.query(
      'blocked_senders',
      where: 'sender = ?',
      whereArgs: [sender],
      limit: 1,
    );
    return result.isNotEmpty;
  }
  
  @override
  Future<void> unblockSender(String sender) async {
    final db = _database!;
    await db.delete(
      'blocked_senders',
      where: 'sender = ?',
      whereArgs: [sender],
    );
  }
  
  @override
  Future<List<Map<String, dynamic>>> getBlockedSenders() async {
    if (kIsWeb) {
      final blockedSendersJson = _prefs!.getString('blocked_senders');
      if (blockedSendersJson == null) return [];
      final List<dynamic> blockedSendersList = jsonDecode(blockedSendersJson);
      return blockedSendersList.cast<Map<String, dynamic>>();
    }
    
    final db = _database!;
    return await db.query('blocked_senders', orderBy: 'blocked_at DESC');
  }
  
  // Blocked URLs operations
  @override
  Future<void> blockUrl(String url, {String? reason, String threatLevel = 'medium', bool autoBlocked = false}) async {
    final db = _database!;
    final domain = _extractDomain(url);
    await db.insert(
      'blocked_urls',
      {
        'id': const Uuid().v4(),
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
  
  @override
  Future<bool> isUrlBlocked(String url) async {
    if (kIsWeb) {
      final blockedUrls = await getBlockedUrls();
      final domain = _extractDomain(url);
      return blockedUrls.any((blocked) => blocked['url'] == url || blocked['domain'] == domain);
    }
    
    final db = _database!;
    final result = await db.query(
      'blocked_urls',
      where: 'url = ? OR domain = ?',
      whereArgs: [url, _extractDomain(url)],
      limit: 1,
    );
    return result.isNotEmpty;
  }
  
  @override
  Future<void> unblockUrl(String url) async {
    final db = _database!;
    await db.delete(
      'blocked_urls',
      where: 'url = ?',
      whereArgs: [url],
    );
  }
  
  @override
  Future<List<Map<String, dynamic>>> getBlockedUrls() async {
    if (kIsWeb) {
      final blockedUrlsJson = _prefs!.getString('blocked_urls');
      if (blockedUrlsJson == null) return [];
      final List<dynamic> blockedUrlsList = jsonDecode(blockedUrlsJson);
      return blockedUrlsList.cast<Map<String, dynamic>>();
    }
    
    final db = _database!;
    return await db.query('blocked_urls', orderBy: 'blocked_at DESC');
  }
  
  // Message signature operations for duplicate detection
  @override
  Future<String> generateMessageSignature(String sender, String body) async {
    final content = '$sender:${body.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim()}';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  @override
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
        'id': const Uuid().v4(),
        'content_hash': signature,
        'sender_hash': senderHash,
        'first_seen': DateTime.now().millisecondsSinceEpoch,
        'occurrence_count': 1,
        'isPhishing': 0,
      },
    );
    
    return false;
  }
  
  @override
  Future<void> markSignatureAsPhishing(String sender, String body) async {
    final db = _database!;
    final signature = await generateMessageSignature(sender, body);
    final senderHash = sha256.convert(utf8.encode(sender)).toString();
    
    await db.update(
      'message_signatures',
      {'isPhishing': 1},
      where: 'content_hash = ? AND sender_hash = ?',
      whereArgs: [signature, senderHash],
    );
  }
  
  @override
  Future<bool> isKnownPhishingSignature(String sender, String body) async {
    final db = _database!;
    final signature = await generateMessageSignature(sender, body);
    final senderHash = sha256.convert(utf8.encode(sender)).toString();
    
    final result = await db.query(
      'message_signatures',
      where: 'content_hash = ? AND sender_hash = ? AND isPhishing = 1',
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

  @override
  Future<void> close() async {
    await _database?.close();
  }
}
