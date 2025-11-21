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
import 'core/services/connectivity_service.dart';
import 'core/services/platform_service.dart';
import 'screens/widgets/connectivity_warning_widget.dart';
import 'supabase_options.dart';
import 'config/api_config.dart'; // API configuration
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL: Check internet connectivity first - app requires online mode
  print('🌐 Checking internet connectivity...');
  final hasInternet = await _checkInternetConnectivity();
  
  if (!hasInternet) {
    print('❌ NO INTERNET CONNECTION DETECTED');
    print('🚫 App requires internet connection to function');
    print('📱 Please connect to the internet and try again');
    
    // Show error screen and exit
    runApp(const NoInternetApp());
    return;
  }
  
  print('✅ Internet connection verified - proceeding with app initialization');
  
  // Initialize Supabase
  try {
    // Validate Supabase configuration before initializing
    if (SupabaseOptions.supabaseUrl.isEmpty || 
        SupabaseOptions.supabaseUrl == 'YOUR_SUPABASE_URL' ||
        SupabaseOptions.supabaseAnonKey.isEmpty ||
        SupabaseOptions.supabaseAnonKey == 'YOUR_SUPABASE_ANON_KEY') {
      throw Exception('Supabase credentials not configured. Please update supabase_options.dart with your actual Supabase project credentials.');
    }
    
    await Supabase.initialize(
      url: SupabaseOptions.supabaseUrl,
      anonKey: SupabaseOptions.supabaseAnonKey,
    );
    print('✅ Supabase initialized successfully');
    print('   URL: ${SupabaseOptions.supabaseUrl}');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
    print('⚠️ Please check your supabase_options.dart configuration.');
    print('📖 See SUPABASE_SETUP_GUIDE.md or SUPABASE_EMAIL_VERIFICATION_SETUP.md for instructions.');
    // Don't continue if Supabase is not configured - app needs it for auth
    rethrow;
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
    // Initialize connectivity service first to ensure we're still online
    await ConnectivityService.instance.initialize();
    
    // Double-check internet connectivity before proceeding
    final isStillOnline = ConnectivityService.instance.isOnline;
    if (!isStillOnline) {
      throw Exception('Internet connection lost during initialization');
    }
    
    print('✅ Internet connection verified - initializing services');
    
    // Initialize database
    await DatabaseService.instance.initialize();
    
    // Initialize ML service (required for phishing detection)
    try {
      // Import API config
      // Note: Import will be added at top of file
      // import 'config/api_config.dart';
      
      // Use correct API URL based on platform, with optional override
      const apiOverride = String.fromEnvironment('API_BASE_URL');
      String apiUrl;
      
      if (apiOverride.isNotEmpty) {
        // Environment variable override (highest priority)
        apiUrl = apiOverride;
        if (kDebugMode) {
          print('🛠 Using API_BASE_URL override: $apiUrl');
        }
      } else {
        // Use ApiConfig for production, or platform-specific for development
        const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
        if (isProduction) {
          // Production mode - use VPS URL
          apiUrl = ApiConfig.productionUrl;
          if (kDebugMode) {
            print('🌐 Production mode - using VPS URL: $apiUrl');
          }
        } else {
          // Development mode - use platform-specific URLs
          if (PlatformService.isAndroid) {
            // Default for Android is emulator host mapping
            apiUrl = 'http://10.0.2.2:5000';
            if (kDebugMode) {
              print('🤖 Android detected - using emulator host mapping: $apiUrl');
              print('   If using a physical device, pass --dart-define API_BASE_URL=http://<your-pc-ip>:5000');
            }
          } else if (PlatformService.isIOS) {
            // For iOS simulator, use localhost
            apiUrl = 'http://localhost:5000';
            if (kDebugMode) {
              print('🍎 iOS detected - using localhost:5000');
            }
          } else if (PlatformService.isMobile) {
            // For physical devices, try common network IPs
            apiUrl = 'http://192.168.254.101:5000'; // Default - update with your computer's IP
            if (kDebugMode) {
              print('📱 Physical device detected - using network IP: $apiUrl');
              print('   ⚠️  If connection fails, update this IP in lib/main.dart');
              print('   💡 Run: python ml_training/get_computer_ip.py to find your IP');
              print('   💡 Or use: flutter run --dart-define=API_BASE_URL=http://<your-ip>:5000');
            }
          } else {
            apiUrl = 'http://localhost:5000';
            if (kDebugMode) {
              print('💻 Desktop/Web detected - using localhost:5000');
            }
          }
        }
      }
      
      await MLService.instance.initialize(
        apiBaseUrl: apiUrl,
      );
      print('✅ ML Service initialized successfully on $apiUrl');
    } catch (e) {
      print('⚠️ ML Service not available: $e');
      print('💡 App requires ML service for phishing detection');
      print('💡 To enable ML detection, run: python ml_training/sms_spam_api_sklearn.py');
      print('💡 Make sure API server is accessible at the configured URL');
    }
    
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

/// Check if internet connectivity is available
Future<bool> _checkInternetConnectivity() async {
  try {
    // Test actual internet access with a reliable endpoint
    final response = await http.get(
      Uri.parse('https://www.google.com'),
      headers: {'Connection': 'close'},
    ).timeout(const Duration(seconds: 10));
    
    return response.statusCode == 200;
  } catch (e) {
    if (kDebugMode) {
      print('Internet connectivity check failed: $e');
    }
    return false;
  }
}

/// App shown when no internet connection is available
class NoInternetApp extends StatelessWidget {
  const NoInternetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhishTi Detector - No Internet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const NoInternetScreen(),
    );
  }
}

/// Screen shown when no internet connection is available
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              const Text(
                'PhishTi Detector requires an internet connection to function properly.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Features that require internet
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Online Features:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem('🔐 User Authentication'),
                    _buildFeatureItem('🤖 AI-Powered Phishing Detection'),
                    _buildFeatureItem('☁️ Cloud Data Synchronization'),
                    _buildFeatureItem('🔄 Real-time Threat Updates'),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Retry button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Check connectivity again
                    final hasInternet = await _checkInternetConnectivity();
                    if (hasInternet) {
                      // Restart the app
                      SystemNavigator.pop();
                    } else {
                      // Show error message
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Still no internet connection. Please check your network settings.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Check Connection Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Help text
              const Text(
                'Please connect to WiFi or mobile data and try again.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
