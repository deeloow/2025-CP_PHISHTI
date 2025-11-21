import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance; // Temporarily disabled
  
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _initializeLocalNotifications();
    // await _initializeFirebaseMessaging(); // Temporarily disabled
    _isInitialized = true;
  }
  
  Future<void> _initializeLocalNotifications() async {
    // Request notification permission
    final permission = await Permission.notification.request();
    if (!permission.isGranted) {
      print('Notification permission not granted');
      return;
    }
    
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channel for Android
    await _createNotificationChannel();
  }
  
  // ignore: unused_element
  Future<void> _initializeFirebaseMessaging() async {
    // Temporarily disabled Firebase messaging
    /*
    // Request FCM permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Listen for FCM messages
      // _messageSubscription = FirebaseMessaging.onMessage.listen(_handleFirebaseMessage); // Removed Firebase
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    */
  }
  
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'phishti_detector',
      'PhishTi Detector',
      description: 'Notifications for phishing detection',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }
  
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }
  
  // ignore: unused_element
  Future<void> _handleFirebaseMessage(Map<String, dynamic> message) async {
    // Handle FCM message
    print('Received message: ${message['notification']?['title']}');
  }
  
  Future<void> showPhishingDetectedNotification({
    required String sender,
    required String reason,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'phishti_detector',
      'PhishTi Detector',
      channelDescription: 'Notifications for phishing detection',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00FF88),
      playSound: true,
      enableVibration: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Phishing SMS Detected',
      'Suspicious message from $sender has been archived safely.',
      notificationDetails,
      payload: 'phishing_detected',
    );
  }
  
  Future<void> showSystemStatusNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'system_status',
      'System Status',
      channelDescription: 'System status notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: 'system_status',
    );
  }
  
  Future<void> showThreatLevelNotification({
    required String level,
    required int count,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'threat_level',
      'Threat Level',
      channelDescription: 'Threat level notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF6B6B),
      playSound: true,
      enableVibration: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Threat Level: $level',
      '$count phishing attempts detected this week',
      notificationDetails,
      payload: 'threat_level',
    );
  }
  
  Future<void> showSyncNotification({
    required String status,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sync_status',
      'Sync Status',
      channelDescription: 'Cloud sync status notifications',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Cloud Sync',
      'Sync status: $status',
      notificationDetails,
      payload: 'sync_status',
    );
  }
  
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
  
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
  
  Future<String?> getFCMToken() async {
    // Temporarily disabled Firebase messaging
    /*
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
    */
    return null;
  }
  
  Future<void> subscribeToTopic(String topic) async {
    // Temporarily disabled Firebase messaging
    /*
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
    */
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    // Temporarily disabled Firebase messaging
    /*
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
    */
  }
  
  Future<void> dispose() async {
    // await _messageSubscription?.cancel(); // Removed Firebase messaging
  }
}

// Background message handler
/*
Future<void> _firebaseMessagingBackgroundHandler(Map<String, dynamic> message) async {
  print('Handling background message: ${message.messageId}');
}
*/
