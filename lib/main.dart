import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/responsive_helper.dart';
import 'core/optimizations/performance_optimizer.dart';
import 'core/optimizations/device_optimizer.dart';
import 'core/optimizations/performance_monitor.dart';
import 'core/optimizations/huawei_optimizer.dart';
import 'core/optimizations/frame_rate_optimizer.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/ml_service.dart';
import 'core/services/database_service_interface.dart';
import 'core/services/database_service.dart';
import 'core/services/firebase_test_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/php_auth_service.dart';
import 'core/services/biometric_service.dart';
import 'core/services/sms_integration_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (temporarily disabled until you configure Firebase)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
  // Test Firebase connection (disabled until Firebase is configured)
  // await FirebaseTestService.runAllTests();
  } catch (e) {
    print('⚠️ Firebase not configured yet. Please follow the Firebase setup guide.');
    print('📖 See FIREBASE_SETUP_GUIDE.md for instructions.');
  }
  
  // Initialize services
  await _initializeServices();
  
  // Initialize guest mode
  await AuthService.instance.initializeGuestMode();
  
  // Initialize PHP auth service
  await PhpAuthService.instance.initialize();
  
  // Initialize device-specific optimizations (skip on web)
  if (!kIsWeb) {
    await DeviceOptimizer.initialize();
    
    // Apply Huawei-specific optimizations
    HuaweiOptimizer.initialize();
    
    // Apply frame rate optimizations (disabled for better performance)
    // FrameRateOptimizer.initialize();
    
    // Apply performance optimizations
    PerformanceOptimizer.optimizeForLowEndDevices();
    MemoryManager.scheduleMemoryCleanup();
  }
  
  // Set system UI overlay style (skip on web)
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
  
  runApp(
    const ProviderScope(
      child: PhishtiDetectorApp(),
    ),
  );
}

Future<void> _initializeServices() async {
  try {
    // Initialize database
    await DatabaseService.instance.initialize();
    
    // Initialize ML service in hybrid mode (online + offline)
    await MLService.instance.initialize(
      serviceMode: MLServiceMode.hybrid,
      // Add your API keys here (store securely in production)
      // huggingFaceApiKey: 'your_hugging_face_api_key',
      // googleCloudApiKey: 'your_google_cloud_api_key',
      // customApiKey: 'your_custom_api_key',
    );
    
    // Initialize notification service (skip on web)
    if (!kIsWeb) {
      await NotificationService.instance.initialize();
    }
    
    // Initialize biometric service (skip on web)
    if (!kIsWeb) {
      await BiometricService.instance.initialize();
    }
    
    // Initialize SMS integration service
    await SmsIntegrationService.instance.initialize();
    
    // Request permissions (skip on web)
    if (!kIsWeb) {
      await _requestPermissions();
    }
  } catch (e) {
    print('Error initializing services: $e');
    // Continue with app initialization even if some services fail
  }
}

Future<void> _requestPermissions() async {
  final permissions = [
    Permission.sms,
    Permission.phone,
    Permission.notification,
    Permission.storage,
    Permission.camera,
    Permission.contacts,
  ];
  
  for (final permission in permissions) {
    await permission.request();
  }
}

class PhishtiDetectorApp extends ConsumerWidget {
  const PhishtiDetectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // Initialize responsive helper
        ResponsiveHelper.init(context);
        
        return MaterialApp.router(
          title: 'PhishTi Detector',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: router,
          builder: (context, child) {
            // Platform-specific optimizations (skip on web)
            if (kIsWeb) {
              return child!;
            }
            
            // Android-specific optimizations
            return HuaweiOptimizer.buildHuaweiOptimizedWidget(
              PerformanceMonitor.buildPerformanceOptimizedWidget(
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
                    ),
                  ),
                  child: child!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
