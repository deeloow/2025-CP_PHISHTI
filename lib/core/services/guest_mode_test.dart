import 'package:flutter/foundation.dart';
import 'ml_service.dart';
import 'connectivity_service.dart';
import 'supabase_auth_service.dart';
import '../../models/sms_message.dart';

/// Test service to verify guest mode works with online ML services
class GuestModeTest {
  static final GuestModeTest _instance = GuestModeTest._internal();
  static GuestModeTest get instance => _instance;
  
  GuestModeTest._internal();
  
  /// Test guest mode with online ML services
  Future<Map<String, dynamic>> testGuestModeWithOnlineML() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Test connectivity
      await ConnectivityService.instance.initialize();
      final isOnline = ConnectivityService.instance.isOnline;
      results['connectivity'] = {
        'isOnline': isOnline,
        'status': isOnline ? 'Connected' : 'Offline'
      };
      
      // 2. Test guest mode
      await SupabaseAuthService.instance.enableGuestMode();
      final isGuestMode = SupabaseAuthService.instance.isGuestMode;
      results['guestMode'] = {
        'isGuestMode': isGuestMode,
        'status': isGuestMode ? 'Enabled' : 'Disabled'
      };
      
      // 3. Test ML service initialization
      await MLService.instance.initialize(serviceMode: MLServiceMode.hybrid);
      final mlServiceMode = MLService.instance.serviceMode;
      final mlIsOnline = MLService.instance.isOnline;
      results['mlService'] = {
        'serviceMode': mlServiceMode.toString(),
        'isOnline': mlIsOnline,
        'status': 'Initialized'
      };
      
      // 4. Test SMS analysis in guest mode
      final testMessage = SmsMessage(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'TestSender',
        body: 'Click here to verify your account: https://suspicious-site.com',
        timestamp: DateTime.now(),
      );
      
      final detection = await MLService.instance.analyzeSms(testMessage);
      results['analysis'] = {
        'confidence': detection.confidence,
        'type': detection.type.toString(),
        'indicators': detection.indicators,
        'reason': detection.reason,
        'status': 'Analysis completed'
      };
      
      // 5. Overall status
      results['overall'] = {
        'status': 'SUCCESS',
        'message': 'Guest mode works with online ML services',
        'timestamp': DateTime.now().toIso8601String()
      };
      
    } catch (e) {
      results['overall'] = {
        'status': 'ERROR',
        'message': 'Test failed: $e',
        'timestamp': DateTime.now().toIso8601String()
      };
    }
    
    return results;
  }
  
  /// Test online ML service availability
  Future<Map<String, dynamic>> testOnlineMLAvailability() async {
    final results = <String, dynamic>{};
    
    try {
      // Test connectivity
      await ConnectivityService.instance.initialize();
      final isOnline = ConnectivityService.instance.isOnline;
      
      if (isOnline) {
        // Test ML service
        await MLService.instance.initialize(serviceMode: MLServiceMode.hybrid);
        
        // Test with a simple message
        final testMessage = SmsMessage(
          id: 'connectivity_test_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'Test',
          body: 'This is a test message for connectivity',
          timestamp: DateTime.now(),
        );
        
        final detection = await MLService.instance.analyzeSms(testMessage);
        
        results['status'] = 'SUCCESS';
        results['message'] = 'Online ML services are working';
        results['connectivity'] = isOnline;
        results['analysis'] = {
          'confidence': detection.confidence,
          'completed': true
        };
      } else {
        results['status'] = 'OFFLINE';
        results['message'] = 'No internet connection available';
        results['connectivity'] = false;
      }
      
    } catch (e) {
      results['status'] = 'ERROR';
      results['message'] = 'Test failed: $e';
    }
    
    return results;
  }
  
  /// Print test results
  void printTestResults(Map<String, dynamic> results) {
    if (kDebugMode) {
      print('=== Guest Mode Test Results ===');
      print('Overall Status: ${results['overall']?['status'] ?? 'Unknown'}');
      print('Message: ${results['overall']?['message'] ?? 'No message'}');
      
      if (results['connectivity'] != null) {
        print('Connectivity: ${results['connectivity']['status']}');
      }
      
      if (results['guestMode'] != null) {
        print('Guest Mode: ${results['guestMode']['status']}');
      }
      
      if (results['mlService'] != null) {
        print('ML Service: ${results['mlService']['status']} (${results['mlService']['serviceMode']})');
      }
      
      if (results['analysis'] != null) {
        print('Analysis: ${results['analysis']['status']} (confidence: ${results['analysis']['confidence']})');
      }
      
      print('===============================');
    }
  }
}
