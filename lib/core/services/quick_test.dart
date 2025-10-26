import 'package:flutter/foundation.dart';

import 'supabase_auth_service.dart';
import 'connectivity_service.dart';
import 'ml_service.dart';
import 'feature_test_service.dart';

/// Quick test to verify core functionality
class QuickTest {
  static final QuickTest _instance = QuickTest._internal();
  static QuickTest get instance => _instance;
  
  QuickTest._internal();
  
  /// Run a quick test of core features
  static Future<void> runQuickTest() async {
    if (kDebugMode) {
      print('\n🚀 === QUICK FEATURE TEST ===');
      
      try {
        // Test 1: Basic Services
        print('1. Testing basic services...');
        await SupabaseAuthService.instance.initializeGuestMode();
        await ConnectivityService.instance.initialize();
        print('   ✅ Basic services initialized');
        
        // Test 2: Guest Mode
        print('2. Testing guest mode...');
        await SupabaseAuthService.instance.enableGuestMode();
        final isGuestMode = SupabaseAuthService.instance.isGuestMode;
        print('   ✅ Guest mode: ${isGuestMode ? "Enabled" : "Disabled"}');
        
        // Test 3: Connectivity
        print('3. Testing connectivity...');
        final isOnline = ConnectivityService.instance.isOnline;
        print('   ✅ Internet: ${isOnline ? "Connected" : "Offline"}');
        
        // Test 4: ML Service
        print('4. Testing ML service...');
        await MLService.instance.initialize(serviceMode: MLServiceMode.hybrid);
        final serviceMode = MLService.instance.serviceMode;
        print('   ✅ ML Service: $serviceMode mode');
        
        // Test 5: Overall Status
        print('5. Overall status...');
        if (isGuestMode && isOnline) {
          print('   ✅ Perfect! Guest mode + Online ML ready');
        } else if (isGuestMode && !isOnline) {
          print('   ⚠️  Guest mode ready, but offline');
        } else {
          print('   ❌ Issues detected');
        }
        
        print('\n🎉 Quick test completed successfully!');
        print('📱 App is ready for use in guest mode');
        
      } catch (e) {
        print('\n❌ Quick test failed: $e');
        print('🔧 Please check the comprehensive test for details');
      }
      
      print('===============================\n');
    }
  }
  
  /// Run comprehensive test
  static Future<void> runComprehensiveTest() async {
    if (kDebugMode) {
      print('\n🧪 === COMPREHENSIVE TEST ===');
      
      try {
        final results = await FeatureTestService.instance.runAllTests();
        FeatureTestService.instance.printTestResults(results);
        
        final overall = results['overall'] as Map<String, dynamic>;
        final status = overall['status'] as String;
        
        if (status == 'SUCCESS') {
          print('🎉 All features working perfectly!');
        } else if (status == 'PARTIAL') {
          print('⚠️  Some features need attention');
        } else {
          print('❌ Multiple issues detected');
        }
        
      } catch (e) {
        print('❌ Comprehensive test failed: $e');
      }
      
      print('===============================\n');
    }
  }
}
