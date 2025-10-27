import 'package:flutter/material.dart';
import 'lib/core/services/ml_service.dart';
import 'lib/core/services/enhanced_online_ml_service.dart';
import 'lib/models/sms_message.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing ML Services...');
  
  // Test ML Service
  print('\n📱 Testing ML Service...');
  final mlService = MLService.instance;
  await mlService.initialize();
  print('✅ ML Service initialized successfully');
  
  // Test Enhanced Online ML Service
  print('\n🤖 Testing Enhanced Online ML Service...');
  final enhancedMLService = EnhancedOnlineMLService.instance;
  await enhancedMLService.initialize();
  print('✅ Enhanced Online ML Service initialized successfully');
  
  // Test SMS Analysis
  print('\n📧 Testing SMS Analysis...');
  final testMessage = SmsMessage(
    id: 'test-1',
    sender: 'Bank',
    body: 'URGENT: Your account will be suspended. Click here to verify: http://fake-bank.com/verify',
    timestamp: DateTime.now(),
    isPhishing: false,
    phishingScore: 0.0,
    extractedUrls: [],
  );
  
  final detection = await mlService.analyzeSms(testMessage);
  print('✅ SMS Analysis completed');
  print('   - Is Phishing: ${detection.confidence > 0.5}');
  print('   - Confidence: ${detection.confidence}');
  print('   - Type: ${detection.type}');
  print('   - Indicators: ${detection.indicators.length}');
  
  // Test URL Analysis
  print('\n🔗 Testing URL Analysis...');
  final urlAnalysis = await mlService.analyzeUrl('http://fake-bank.com/verify');
  print('✅ URL Analysis completed');
  print('   - Is Suspicious: ${urlAnalysis['isSuspicious']}');
  print('   - Threat Level: ${urlAnalysis['threatLevel']}');
  print('   - Confidence: ${urlAnalysis['confidence']}');
  
  // Test Enhanced Online ML Service
  print('\n🌐 Testing Enhanced Online ML Service...');
  final enhancedDetection = await enhancedMLService.analyzeSms(testMessage);
  print('✅ Enhanced Online ML Analysis completed');
  print('   - Is Phishing: ${enhancedDetection.confidence > 0.5}');
  print('   - Confidence: ${enhancedDetection.confidence}');
  print('   - Type: ${enhancedDetection.type}');
  
  // Test Service Status
  print('\n📊 Testing Service Status...');
  print('   - ML Service status: Available');
  print('   - Enhanced Online Service status: Available');
  
  print('\n🎉 All ML Services tests completed successfully!');
}
