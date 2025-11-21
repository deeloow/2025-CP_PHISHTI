import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/sms_message.dart';

class SmsIntegrationService {
  static final SmsIntegrationService _instance = SmsIntegrationService._internal();
  static SmsIntegrationService get instance => _instance;

  SmsIntegrationService._internal();

  static const MethodChannel _channel = MethodChannel('sms_integration');
  static const EventChannel _smsEventChannel = EventChannel('sms_events');

  StreamSubscription? _smsSubscription;
  final StreamController<List<SmsMessage>> _smsController = StreamController<List<SmsMessage>>.broadcast();
  final StreamController<SmsMessage> _newSmsController = StreamController<SmsMessage>.broadcast();

  Stream<List<SmsMessage>> get smsStream => _smsController.stream;
  Stream<SmsMessage> get newSmsStream => _newSmsController.stream;

  /// Initialize SMS integration service
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // Web: no permissions or native channels
        print('SMS Integration Service initialized (web stub)');
      } else {
        // Request SMS permissions
        await _requestSmsPermissions();
        // Set up SMS event listener
        _setupSmsEventListener();
      }
      
      print('SMS Integration Service initialized successfully');
    } catch (e) {
      print('Error initializing SMS Integration Service: $e');
    }
  }

  /// Request SMS permissions
  Future<bool> _requestSmsPermissions() async {
    try {
      if (kIsWeb) return true; // Web: always allowed
      // Check if we have SMS permissions
      final smsStatus = await Permission.sms.status;
      final phoneStatus = await Permission.phone.status;

      if (smsStatus.isGranted && phoneStatus.isGranted) {
        return true;
      }

      // Request permissions
      final permissions = await [
        Permission.sms,
        Permission.phone,
      ].request();

      return permissions[Permission.sms]?.isGranted == true &&
             permissions[Permission.phone]?.isGranted == true;
    } catch (e) {
      print('Error requesting SMS permissions: $e');
      return false;
    }
  }

  /// Set up SMS event listener
  void _setupSmsEventListener() {
    try {
      if (kIsWeb) return; // Web: no-op
      _smsSubscription = _smsEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final smsData = event.cast<String, dynamic>();
            final smsMessage = _parseSmsFromEvent(smsData);
            if (smsMessage != null) {
              _newSmsController.add(smsMessage);
            }
          }
        },
        onError: (error) {
          print('SMS event error: $error');
        },
      );
    } catch (e) {
      print('Error setting up SMS event listener: $e');
    }
  }

  /// Parse SMS from event data
  SmsMessage? _parseSmsFromEvent(Map<String, dynamic> data) {
    try {
      return SmsMessage(
        id: data['id'] ?? '',
        sender: data['sender'] ?? '',
        body: data['body'] ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(data['timestamp']?.toString() ?? '0') ?? 0,
        ),
        isPhishing: data['isPhishing'] == true,
        phishingScore: (data['phishingScore'] ?? 0.0).toDouble(),
        reason: data['reason'] ?? '',
      );
    } catch (e) {
      print('Error parsing SMS from event: $e');
      return null;
    }
  }

  /// Get all SMS messages from device
  Future<List<SmsMessage>> getAllSmsMessages() async {
    try {
      if (kIsWeb) {
        final messages = _demoMessages();
        _smsController.add(messages);
        return messages;
      }
      // Check permissions first (mobile)
      final hasPermissions = await _checkSmsPermissions();
      if (!hasPermissions) {
        print('SMS permissions not granted');
        return [];
      }

      final result = await _channel.invokeMethod('getAllSms');
      if (result is List) {
        final messages = result.map((data) => _parseSmsFromMap(data)).whereType<SmsMessage>().toList();
        _smsController.add(messages);
        print('Retrieved ${messages.length} SMS messages from device');
        return messages;
      }
      return [];
    } catch (e) {
      print('Error getting all SMS messages: $e');
      return [];
    }
  }

  /// Sync SMS messages from device
  Future<bool> syncSmsMessages() async {
    try {
      print('Starting SMS sync...');
      final messages = await getAllSmsMessages();
      if (messages.isNotEmpty) {
        print('SMS sync completed: ${messages.length} messages synced');
        return true;
      }
      return false;
    } catch (e) {
      print('Error syncing SMS messages: $e');
      return false;
    }
  }

  /// Get all SMS messages with sender details (both analyzed and unanalyzed)
  Future<List<SmsMessage>> getAnalyzedSmsMessages() async {
    try {
      // Get all SMS messages from device (with sender details)
      return await getAllSmsMessages();
    } catch (e) {
      print('Error getting SMS messages with sender details: $e');
      return [];
    }
  }

  /// Get SMS messages by thread ID (conversation)
  Future<List<SmsMessage>> getSmsByThread(String threadId) async {
    try {
      if (kIsWeb) {
        return _demoMessages().where((m) => m.threadId == threadId).toList();
      }
      final result = await _channel.invokeMethod('getSmsByThread', {'threadId': threadId});
      if (result is List) {
        return result.map((data) => _parseSmsFromMap(data)).whereType<SmsMessage>().toList();
      }
      return [];
    } catch (e) {
      print('Error getting SMS by thread: $e');
      return [];
    }
  }

  /// Get all SMS threads (conversations)
  Future<List<SmsThread>> getAllSmsThreads() async {
    try {
      if (kIsWeb) {
        return _demoThreads();
      }
      final result = await _channel.invokeMethod('getAllSmsThreads');
      if (result is List) {
        return result.map((data) => _parseThreadFromMap(data)).whereType<SmsThread>().toList();
      }
      return [];
    } catch (e) {
      print('Error getting SMS threads: $e');
      return [];
    }
  }



  /// Delete SMS message
  Future<bool> deleteSms(String messageId) async {
    try {
      if (kIsWeb) {
        print('deleteSms (web stub): $messageId');
        return true;
      }
      final result = await _channel.invokeMethod('deleteSms', {'messageId': messageId});
      return result == true;
    } catch (e) {
      print('Error deleting SMS: $e');
      return false;
    }
  }

  /// Mark SMS as read
  Future<bool> markSmsAsRead(String messageId) async {
    try {
      if (kIsWeb) {
        print('markSmsAsRead (web stub): $messageId');
        return true;
      }
      final result = await _channel.invokeMethod('markSmsAsRead', {'messageId': messageId});
      return result == true;
    } catch (e) {
      print('Error marking SMS as read: $e');
      return false;
    }
  }

  /// Get SMS permissions status
  Future<bool> hasSmsPermissions() async {
    try {
      if (kIsWeb) return true; // Web: always granted
      final smsStatus = await Permission.sms.status;
      final phoneStatus = await Permission.phone.status;
      return smsStatus.isGranted && phoneStatus.isGranted;
    } catch (e) {
      print('Error checking SMS permissions: $e');
      return false;
    }
  }


  /// Get all contacts
  Future<List<Contact>> getContacts() async {
    try {
      if (kIsWeb) {
        return [
          Contact(id: '1', name: 'Alice', phoneNumber: '+1234567890', photoUri: ''),
          Contact(id: '2', name: 'Bob', phoneNumber: '+1098765432', photoUri: ''),
        ];
      }
      final result = await _channel.invokeMethod('getContacts');
      if (result is List) {
        return result.map((data) => _parseContactFromMap(data)).whereType<Contact>().toList();
      }
      return [];
    } catch (e) {
      print('Error getting contacts: $e');
      return [];
    }
  }

  /// Get contact by phone number
  Future<Contact?> getContactByPhone(String phoneNumber) async {
    try {
      if (kIsWeb) {
        final contacts = await getContacts();
        return contacts.firstWhere((c) => c.phoneNumber == phoneNumber, orElse: () => Contact(id: '0', name: 'Unknown', phoneNumber: phoneNumber, photoUri: ''));
      }
      final result = await _channel.invokeMethod('getContactByPhone', {'phoneNumber': phoneNumber});
      if (result is Map<String, dynamic>) {
        return _parseContactFromMap(result);
      }
      return null;
    } catch (e) {
      print('Error getting contact by phone: $e');
      return null;
    }
  }


  /// Check contacts permissions
  Future<bool> hasContactsPermissions() async {
    try {
      if (kIsWeb) return true;
      final contactsStatus = await Permission.contacts.status;
      return contactsStatus.isGranted;
    } catch (e) {
      print('Error checking contacts permissions: $e');
      return false;
    }
  }

  /// Request contacts permissions
  Future<bool> requestContactsPermissions() async {
    try {
      if (kIsWeb) return true;
      final status = await Permission.contacts.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting contacts permissions: $e');
      return false;
    }
  }

  /// Request SMS permissions
  Future<bool> requestSmsPermissions() async {
    try {
      if (kIsWeb) return true;
      final smsStatus = await Permission.sms.request();
      final phoneStatus = await Permission.phone.request();
      return smsStatus.isGranted && phoneStatus.isGranted;
    } catch (e) {
      print('Error requesting SMS permissions: $e');
      return false;
    }
  }

  /// Check if SMS permissions are granted
  Future<bool> _checkSmsPermissions() async {
    try {
      if (kIsWeb) return true;
      final smsStatus = await Permission.sms.status;
      final phoneStatus = await Permission.phone.status;
      return smsStatus.isGranted && phoneStatus.isGranted;
    } catch (e) {
      print('Error checking SMS permissions: $e');
      return false;
    }
  }

  /// Get SMS threads (conversations)
  Future<List<SmsThread>> getSmsThreads() async {
    try {
      if (kIsWeb) {
        return _demoThreads();
      }
      final hasPermissions = await _checkSmsPermissions();
      if (!hasPermissions) {
        print('SMS permissions not granted');
        return [];
      }

      final result = await _channel.invokeMethod('getSmsThreads');
      if (result is List) {
        final threads = result.map((data) => _parseThreadFromMap(data)).whereType<SmsThread>().toList();
        print('Retrieved ${threads.length} SMS threads from device');
        return threads;
      }
      return [];
    } catch (e) {
      print('Error getting SMS threads: $e');
      return [];
    }
  }

  // ----- Demo data for web -----
  List<SmsMessage> _demoMessages() {
    final now = DateTime.now();
    return [
      SmsMessage(
        id: 'm1',
        sender: 'Bank Alert',
        body: 'Your account has been suspended. Verify now: http://fake-bank.com',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isPhishing: true,
        phishingScore: 0.92,
        extractedUrls: const ['http://fake-bank.com'],
        threadId: 't1',
        isRead: false,
      ),
      SmsMessage(
        id: 'm2',
        sender: 'Courier',
        body: 'Your parcel is arriving today. Track: https://courier.example/track/123',
        timestamp: now.subtract(const Duration(hours: 2)),
        isPhishing: false,
        phishingScore: 0.03,
        extractedUrls: const ['https://courier.example/track/123'],
        threadId: 't2',
        isRead: true,
      ),
      SmsMessage(
        id: 'm3',
        sender: 'Lottery',
        body: 'Congratulations! You won \$1000. Claim here: http://scam-lottery.com',
        timestamp: now.subtract(const Duration(days: 1)),
        isPhishing: true,
        phishingScore: 0.88,
        extractedUrls: const ['http://scam-lottery.com'],
        threadId: 't3',
        isRead: true,
      ),
    ];
  }

  List<SmsThread> _demoThreads() {
    final messages = _demoMessages();
    return [
      SmsThread(
        id: 't1',
        contactName: 'Bank Alert',
        phoneNumber: '+100000000',
        lastMessage: messages.firstWhere((m) => m.threadId == 't1').body,
        lastMessageTime: messages.firstWhere((m) => m.threadId == 't1').timestamp,
        unreadCount: 1,
        isPhishing: true,
      ),
      SmsThread(
        id: 't2',
        contactName: 'Courier',
        phoneNumber: '+200000000',
        lastMessage: messages.firstWhere((m) => m.threadId == 't2').body,
        lastMessageTime: messages.firstWhere((m) => m.threadId == 't2').timestamp,
        unreadCount: 0,
        isPhishing: false,
      ),
      SmsThread(
        id: 't3',
        contactName: 'Lottery',
        phoneNumber: '+300000000',
        lastMessage: messages.firstWhere((m) => m.threadId == 't3').body,
        lastMessageTime: messages.firstWhere((m) => m.threadId == 't3').timestamp,
        unreadCount: 0,
        isPhishing: true,
      ),
    ];
  }


  /// Parse SMS from map data
  SmsMessage? _parseSmsFromMap(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return SmsMessage(
          id: data['id'] ?? '',
          sender: data['sender'] ?? '',
          body: data['body'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(data['timestamp']?.toString() ?? '0') ?? 0,
          ),
          isPhishing: data['isPhishing'] == true,
          phishingScore: (data['phishingScore'] ?? 0.0).toDouble(),
          reason: data['reason'] ?? '',
          threadId: data['threadId'] ?? '',
          isRead: data['isRead'] == true,
          messageType: _parseMessageType(data['messageType']),
        );
      }
      return null;
    } catch (e) {
      print('Error parsing SMS from map: $e');
      return null;
    }
  }

  /// Parse thread from map data
  SmsThread? _parseThreadFromMap(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return SmsThread(
          id: data['id'] ?? '',
          contactName: data['contactName'] ?? 'Unknown',
          phoneNumber: data['phoneNumber'] ?? '',
          lastMessage: data['snippet'] ?? '',
          lastMessageTime: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
          unreadCount: data['unreadCount'] ?? 0,
          isPhishing: data['isPhishing'] ?? false,
        );
      }
      return null;
    } catch (e) {
      print('Error parsing thread from map: $e');
      return null;
    }
  }

  /// Parse message type
  MessageType _parseMessageType(dynamic type) {
    if (type == 'SMS') return MessageType.sms;
    if (type == 'MMS') return MessageType.mms;
    return MessageType.sms;
  }

  /// Dispose resources
  void dispose() {
    _smsSubscription?.cancel();
    _smsController.close();
    _newSmsController.close();
  }

  /// Parse contact from map data
  Contact? _parseContactFromMap(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return Contact(
          id: data['id'] ?? '',
          name: data['name'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          photoUri: data['photoUri'] ?? '',
        );
      }
      return null;
    } catch (e) {
      print('Error parsing contact from map: $e');
      return null;
    }
  }
}

/// Contact model
class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String photoUri;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.photoUri,
  });
}

/// SMS Thread model for conversations
class SmsThread {
  final String id;
  final String contactName;
  final String phoneNumber;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isPhishing;

  SmsThread({
    required this.id,
    required this.contactName,
    required this.phoneNumber,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isPhishing,
  });
}

