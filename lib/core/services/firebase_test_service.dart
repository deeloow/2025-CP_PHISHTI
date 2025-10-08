import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseTestService {
  static Future<bool> testFirebaseConnection() async {
    try {
      // Test Firebase Core
      print('🔥 Testing Firebase Core...');
      await Firebase.initializeApp();
      print('✅ Firebase Core initialized successfully!');
      
      // Test Firebase Auth
      print('🔥 Testing Firebase Auth...');
      final auth = FirebaseAuth.instance;
      print('✅ Firebase Auth initialized successfully!');
      
      // Test Firestore
      print('🔥 Testing Firestore...');
      final firestore = FirebaseFirestore.instance;
      print('✅ Firestore initialized successfully!');
      
      // Test Firebase Messaging
      print('🔥 Testing Firebase Messaging...');
      final messaging = FirebaseMessaging.instance;
      print('✅ Firebase Messaging initialized successfully!');
      
      return true;
    } catch (e) {
      print('❌ Firebase connection failed: $e');
      return false;
    }
  }
  
  static Future<void> testFirestoreConnection() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Test write operation
      await firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase connection test successful',
      });
      
      print('✅ Firestore write test successful!');
      
      // Test read operation
      final doc = await firestore.collection('test').doc('connection').get();
      if (doc.exists) {
        print('✅ Firestore read test successful!');
        print('📄 Document data: ${doc.data()}');
      }
      
    } catch (e) {
      print('❌ Firestore test failed: $e');
    }
  }
  
  static Future<void> testFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      
      // Test anonymous sign-in
      final userCredential = await auth.signInAnonymously();
      print('✅ Anonymous authentication successful!');
      print('👤 User ID: ${userCredential.user?.uid}');
      
      // Sign out
      await auth.signOut();
      print('✅ Sign out successful!');
      
    } catch (e) {
      print('❌ Firebase Auth test failed: $e');
    }
  }
  
  static Future<void> testFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      print('✅ Firebase Messaging permission: ${settings.authorizationStatus}');
      
      // Get FCM token
      final token = await messaging.getToken();
      print('✅ FCM Token: $token');
      
    } catch (e) {
      print('❌ Firebase Messaging test failed: $e');
    }
  }
  
  static Future<void> runAllTests() async {
    print('🚀 Starting Firebase connection tests...\n');
    
    // Test basic connection
    final isConnected = await testFirebaseConnection();
    if (!isConnected) {
      print('❌ Firebase connection failed. Please check your configuration.');
      return;
    }
    
    print('\n🔥 Running individual service tests...\n');
    
    // Test Firestore
    await testFirestoreConnection();
    
    // Test Auth
    await testFirebaseAuth();
    
    // Test Messaging
    await testFirebaseMessaging();
    
    print('\n🎉 All Firebase tests completed!');
  }
}
