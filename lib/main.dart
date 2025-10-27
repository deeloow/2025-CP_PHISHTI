import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/responsive_helper.dart';
import 'core/optimizations/performance_optimizer.dart';
import 'core/optimizations/device_optimizer.dart';
import 'core/optimizations/performance_monitor.dart';
import 'core/optimizations/huawei_optimizer.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/ml_service.dart';
import 'core/services/database_service.dart';
import 'core/services/supabase_auth_service.dart';
import 'core/services/quick_test.dart';
import 'core/services/biometric_service.dart';
import 'core/services/sms_integration_service.dart';
import 'core/services/sms_share_service.dart';
import 'screens/widgets/connectivity_warning_widget.dart';
import 'supabase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseOptions.supabaseUrl,
      anonKey: SupabaseOptions.supabaseAnonKey,
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('⚠️ Supabase not configured yet. Please update supabase_options.dart with your credentials.');
    print('📖 See SUPABASE_SETUP_GUIDE.md for instructions.');
  }
  
  // Initialize services
  await _initializeServices();
  
  // Initialize guest mode
  await SupabaseAuthService.instance.initializeGuestMode();
  
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
    
    // Initialize ML service with Rust DistilBERT as primary model
    // This ensures ML-based phishing detection instead of rule-based
    await MLService.instance.initialize(
      modelType: ModelType.rust_distilbert,
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
    
    // Initialize SMS share service
    await SmsShareService.instance.initialize();
    
    // Request permissions (skip on web)
    if (!kIsWeb) {
      await _requestPermissions();
    }
    
    print('All services initialized successfully - ready for both authenticated and guest mode');
    
    // Run quick test in debug mode
    if (kDebugMode) {
      try {
        await QuickTest.runQuickTest();
      } catch (e) {
        print('Quick test failed: $e');
      }
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
              return Column(
                children: [
                  const AnimatedConnectivityWarning(),
                  Expanded(child: child!),
                ],
              );
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
                  child: Column(
                    children: [
                      const AnimatedConnectivityWarning(),
                      Expanded(child: child!),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
