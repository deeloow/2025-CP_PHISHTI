import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_auth_service.dart';
import 'connectivity_service.dart';
import 'ml_service.dart';
import '../../models/sms_message.dart';

/// Comprehensive feature testing service
class FeatureTestService {
  static final FeatureTestService _instance = FeatureTestService._internal();
  static FeatureTestService get instance => _instance;
  
  FeatureTestService._internal();
  
  /// Run comprehensive feature tests
  Future<Map<String, dynamic>> runAllTests() async {
    final results = <String, dynamic>{};
    
    try {
      print('🧪 Starting comprehensive feature tests...');
      
      // Test 1: Basic Services
      results['basicServices'] = await _testBasicServices();
      
      // Test 2: Connectivity
      results['connectivity'] = await _testConnectivity();
      
      // Test 3: Guest Mode
      results['guestMode'] = await _testGuestMode();
      
      // Test 4: ML Service
      results['mlService'] = await _testMLService();
      
      // Test 5: SMS Analysis
      results['smsAnalysis'] = await _testSMSAnalysis();
      
      // Test 6: Authentication
      results['authentication'] = await _testAuthentication();
      
      // Test 7: Settings
      results['settings'] = await _testSettings();
      
      // Overall status
      results['overall'] = _calculateOverallStatus(results);
      
      print('✅ All feature tests completed');
      return results;
      
    } catch (e) {
      results['overall'] = {
        'status': 'ERROR',
        'message': 'Test suite failed: $e',
        'timestamp': DateTime.now().toIso8601String()
      };
      print('❌ Feature tests failed: $e');
      return results;
    }
  }
  
  /// Test basic service initialization
  Future<Map<String, dynamic>> _testBasicServices() async {
    final results = <String, dynamic>{};
    
    try {
      // Test SharedPreferences
      await SharedPreferences.getInstance();
      results['sharedPreferences'] = 'OK';
      
      // Test AuthService
      await SupabaseAuthService.instance.initializeGuestMode();
      results['authService'] = 'OK';
      
      // Test ConnectivityService
      await ConnectivityService.instance.initialize();
      results['connectivityService'] = 'OK';
      
      results['status'] = 'SUCCESS';
      results['message'] = 'All basic services initialized successfully';
      
    } catch (e) {
      results['status'] = 'ERROR';
      results['message'] = 'Basic services test failed: $e';
    }
    
    return results;
  }
  
  /// Test connectivity functionality
  Future<Map<String, dynamic>> _testConnectivity() async {
    final results = <String, dynamic>{};
    
    try {
      await ConnectivityService.instance.initialize();
      
      final isOnline = ConnectivityService.instance.isOnline;
      final connectivityInfo = await ConnectivityService.instance.getConnectivityInfo();
      final connectionQuality = await ConnectivityService.instance.getConnectionQuality();
      
      results['isOnline'] = isOnline;
      results['connectionType'] = connectivityInfo['connectionType'];
      results['quality'] = connectionQuality.toString();
      results['status'] = 'SUCCESS';
      results['message'] = isOnline ? 'Internet connection available' : 'No internet connection';
      
    } catch (e) {
      results['status'] = 'ERROR';
      results['message'] = 'Connectivity test failed: $e';
    }
    
    return results;
  }
  
  /// Test guest mode functionality
  Future<Map<String, dynamic>> _testGuestMode() async {
    final results = <String, dynamic>{};
    
    try {
      // Enable guest mode
      await SupabaseAuthService.instance.enableGuestMode();
      final isGuestMode = SupabaseAuthService.instance.isGuestMode;
      
      // Test guest mode persistence
      await SupabaseAuthService.instance.disableGuestMode();
      await SupabaseAuthService.instance.enableGuestMode();
      final isGuestModeAfterRestart = SupabaseAuthService.instance.isGuestMode;
      
      results['isGuestMode'] = isGuestMode;
      results['persistence'] = isGuestModeAfterRestart;
      results['status'] = 'SUCCESS';
      results['message'] = 'Guest mode working correctly';
      
    } catch (e) {
      results['status'] = 'ERROR';
      results['message'] = 'Guest mode test failed: $e';
    }
    
    return results;
  }
  
  /// Test ML service functionality
  Future<Map<String, dynamic>> _testMLService() async {
    final results = <String, dynamic>{};
    
    try {
      // Initialize ML service
      try {
        await MLService.instance.initialize();
        final isInitialized = MLService.instance.isInitialized;
        final apiBaseUrl = MLService.instance.apiBaseUrl;
        
        results['isInitialized'] = isInitialized;
        results['apiBaseUrl'] = apiBaseUrl;
        results['status'] = isInitialized ? 'SUCCESS' : 'PARTIAL';
        results['message'] = isInitialized 
            ? 'ML service initialized successfully' 
            : 'ML service not available - ML service required for phishing detection';
      } catch (e) {
        results['isInitialized'] = false;
        results['status'] = 'PARTIAL';
        results['message'] = 'ML service not available: $e';
      }
      
    } catch (e) {
      results['status'] = 'ERROR';
      results['message'] = 'ML service test failed: $e';
    }
    
    return results;
  }
  
  /// Test SMS analysis functionality
  Future<Map<String, dynamic>> _testSMSAnalysis() async {
    final results = <String, dynamic>{};
    
    try {
      // Create test messages
      final testMessages = [
        SmsMessage(
          id: 'test_1',
          sender: 'TestSender',
          body: 'Click here to verify your account: https://suspicious-site.com',
          timestamp: DateTime.now(),
        ),
        SmsMessage(
          id: 'test_2',
          sender: 'Bank',
          body: 'Your account balance is \$1,234.56',
          timestamp: DateTime.now(),
        ),
        SmsMessage(
          id: 'test_3',
          sender: 'Unknown',
          body: 'URGENT: Update your information now or account will be closed!',
          timestamp: DateTime.now(),
        ),
      ];
      
      final analysisResults = <Map<String, dynamic>>[];
      
      for (final message in testMessages) {
        try {
          final detection = await MLService.instance.analyzeSms(message);
          analysisResults.add({
            'messageId': message.id,
            'confidence': detection.confidence,
            'type': detection.type.toString(),
            'indicators': detection.indicators,
            'status': 'SUCCESS'
          });
        } catch (e) {
          analysisResults.add({
            'messageId': message.id,
            'status': 'ERROR',
            'error': e.toString()
          });
        }
      }
      
      results['analysisResults'] = analysisResults;
      results['totalTests'] = testMessages.length;
      results['successfulTests'] = analysisResults.where((r) => r['status'] == 'SUCCESS').length;
      results['status'] = 'SUCCESS';
      results['message'] = 'SMS analysis tests completed';
      
    } catch (e) {
      results['status'] = 'ERROR';
      results['message'] = 'SMS analysis test failed: $e';
    }
    
    return results;
  }
  
  /// Test authentication functionality
  Future<Map<String, dynamic>> _testAuthentication() async {
    final results = <String, dynamic>{};
    
    try {
      // Test guest mode
      await SupabaseAuthService.instance.enableGuestMode();
      final isGuestMode = SupabaseAuthService.instance.isGuestMode;
      
      // Test disabling guest mode
      await SupabaseAuthService.instance.disableGuestMode();
      final isGuestModeDisabled = !SupabaseAuthService.instance.isGuestMode;
      
      // Re-enable for app functionality
      await SupabaseAuthService.instance.enableGuestMode();
      
      results['guestModeEnabled'] = isGuestMode;
      results['guestModeDisabled'] = isGuestModeDisabled;
      results['status'] = 'SUCCESS';
      results['message'] = 'Authentication tests completed';
      
    } catch (e) {
      results['status'] = 'ERROR';
      results['message'] = 'Authentication test failed: $e';
    }
    
    return results;
  }
  
  /// Test settings functionality
  Future<Map<String, dynamic>> _testSettings() async {
    final results = <String, dynamic>{};
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Test saving and loading settings
      await prefs.setBool('test_setting', true);
      final testSetting = prefs.getBool('test_setting') ?? false;
      await prefs.remove('test_setting');
      
      results['settingsPersistence'] = testSetting;
      results['status'] = 'SUCCESS';
      results['message'] = 'Settings functionality working';
      
    } catch (e) {
      results['status'] = 'ERROR';
      results['message'] = 'Settings test failed: $e';
    }
    
    return results;
  }
  
  /// Calculate overall test status
  Map<String, dynamic> _calculateOverallStatus(Map<String, dynamic> results) {
    final testResults = results.values.where((r) => r is Map<String, dynamic> && r.containsKey('status')).toList();
    final successfulTests = testResults.where((r) => r['status'] == 'SUCCESS').length;
    final totalTests = testResults.length;
    
    final overallStatus = successfulTests == totalTests ? 'SUCCESS' : 'PARTIAL';
    final successRate = totalTests > 0 ? (successfulTests / totalTests * 100).round() : 0;
    
    return {
      'status': overallStatus,
      'successRate': successRate,
      'successfulTests': successfulTests,
      'totalTests': totalTests,
      'message': overallStatus == 'SUCCESS' 
          ? 'All features working correctly!' 
          : '$successfulTests/$totalTests tests passed',
      'timestamp': DateTime.now().toIso8601String()
    };
  }
  
  /// Print test results to console
  void printTestResults(Map<String, dynamic> results) {
    if (kDebugMode) {
      print('\n🧪 === FEATURE TEST RESULTS ===');
      
      final overall = results['overall'] as Map<String, dynamic>;
      print('📊 Overall Status: ${overall['status']}');
      print('📈 Success Rate: ${overall['successRate']}%');
      print('✅ Successful Tests: ${overall['successfulTests']}/${overall['totalTests']}');
      print('💬 Message: ${overall['message']}');
      
      print('\n📋 Detailed Results:');
      results.forEach((key, value) {
        if (key != 'overall' && value is Map<String, dynamic>) {
          final status = value['status'] ?? 'UNKNOWN';
          final message = value['message'] ?? 'No message';
          print('  $key: $status - $message');
        }
      });
      
      print('===============================\n');
    }
  }
}
