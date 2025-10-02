import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/sms_service.dart';
import 'core/services/ml_service.dart';
import 'core/services/database_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/sms_provider.dart';
import 'core/providers/ml_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize services
  await _initializeServices();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(
    const ProviderScope(
      child: PhishtiDetectorApp(),
    ),
  );
}

Future<void> _initializeServices() async {
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
  
  // Initialize notification service
  await NotificationService.instance.initialize();
  
  // Request permissions
  await _requestPermissions();
}

Future<void> _requestPermissions() async {
  final permissions = [
    Permission.sms,
    Permission.notification,
    Permission.storage,
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
    
    return MaterialApp.router(
      title: 'Phishti Detector',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
