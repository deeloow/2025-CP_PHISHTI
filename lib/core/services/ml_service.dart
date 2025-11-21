import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';

/// ML Service Mode
enum MLServiceMode {
  online,
  offline,
  hybrid,
}

/// Model Type for ML Service
enum ModelType {
  lstm,
  bert,
  distilbert,
  sklearn,
}

/// ML Service for SMS Phishing Detection
/// Uses Hugging Face model via API server
class MLService {
  static final MLService _instance = MLService._internal();
  static MLService get instance => _instance;
  
  MLService._internal();
  
  bool _isInitialized = false;
  String _apiBaseUrl = 'http://localhost:5000';
  MLServiceMode _serviceMode = MLServiceMode.online;
  ModelType _currentModelType = ModelType.sklearn;
  
  /// Get current service mode
  MLServiceMode get serviceMode => _serviceMode;
  
  /// Get current online status (always true for this service)
  bool get isOnline => _isInitialized;
  
  /// Get current model type
  ModelType get currentModelType => _currentModelType;
  
  /// Initialize the ML service
  Future<void> initialize({
    String? apiBaseUrl,
    MLServiceMode? serviceMode,
    ModelType? modelType,
  }) async {
    if (serviceMode != null) {
      _serviceMode = serviceMode;
    }
    if (modelType != null) {
      _currentModelType = modelType;
    }
    if (_isInitialized && apiBaseUrl == null) {
      // Already initialized with current URL, skip
      return;
    }
    
    // Reset initialization state if changing URL
    if (apiBaseUrl != null && apiBaseUrl != _apiBaseUrl) {
      _isInitialized = false;
      _apiBaseUrl = apiBaseUrl;
    }
    
    if (kDebugMode) {
      print('🔄 Attempting to connect to ML API at: $_apiBaseUrl');
          }
          
          try {
      // Check if API server is available
      // Increased timeout for slow connections
      if (kDebugMode) {
        print('📡 Testing connection to: $_apiBaseUrl/health');
      }
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/health'),
      ).timeout(const Duration(seconds: 15)); // Increased to 15 seconds
      
      if (kDebugMode) {
        print('📡 Response status: ${response.statusCode}');
        print('📡 Response body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['model_loaded'] == true) {
      _isInitialized = true;
        if (kDebugMode) {
            print('✅ ML Service initialized successfully at $_apiBaseUrl');
            print('✅ Model loaded: ${data['model_loaded']}');
          }
          return;
        } else {
          throw Exception('API server responded but model not loaded. Response: ${response.body}');
        }
      } else {
        throw Exception('API server returned status ${response.statusCode}. Body: ${response.body}');
      }
    } on SocketException catch (e) {
      _isInitialized = false;
        if (kDebugMode) {
        print('❌ Network error connecting to $_apiBaseUrl');
        print('   SocketException: ${e.message}');
        print('   This usually means:');
        print('   1. API server is not running');
        print('   2. Firewall is blocking the connection');
        print('   3. Wrong IP address/port');
        print('   4. Network unreachable');
      }
      rethrow;
    } on TimeoutException {
      _isInitialized = false;
          if (kDebugMode) {
        print('❌ Connection timeout to $_apiBaseUrl');
        print('   TimeoutException: Connection took too long (>15 seconds)');
        print('   Possible causes:');
        print('   1. Server is slow to respond');
        print('   2. Network congestion');
        print('   3. Firewall blocking silently');
      }
      rethrow;
        } catch (e) {
      _isInitialized = false;
          if (kDebugMode) {
        print('❌ ML Service initialization failed at $_apiBaseUrl');
        print('   Error type: ${e.runtimeType}');
        print('   Error message: $e');
        print('💡 Troubleshooting:');
        print('   1. Verify API server is running: python ml_training/sms_spam_api_sklearn.py');
        print('   2. Test from computer: curl http://192.168.254.111:5000/health');
        print('   3. Check Windows Firewall allows port 5000');
        print('   4. For Android emulator, try network IP: http://192.168.254.111:5000');
      }
      rethrow;
    }
  }
  
  /// Analyze SMS message for phishing
  Future<PhishingDetection> analyzeSms(SmsMessage message) async {
    // Try to initialize if not already initialized
    if (!_isInitialized) {
      try {
      await initialize();
        } catch (e) {
          if (kDebugMode) {
          print('⚠️ ML Service initialization failed: $e');
          print('💡 Attempting to reconnect to API server...');
        }
        
        // Try alternative URLs automatically
        final alternativeUrls = <String>[];
        
        if (_apiBaseUrl.contains('10.0.2.2')) {
          // If 10.0.2.2 failed (Android emulator), try other options
          alternativeUrls.addAll([
            _apiBaseUrl.replaceAll('10.0.2.2', 'localhost'),
            _apiBaseUrl.replaceAll('10.0.2.2', '192.168.254.101'), // Common network IP
            _apiBaseUrl.replaceAll('10.0.2.2', '192.168.1.100'),   // Common router IP range
            _apiBaseUrl.replaceAll('10.0.2.2', '192.168.0.100'),  // Common router IP range
          ]);
        } else if (_apiBaseUrl.contains('localhost')) {
          // If localhost failed, try network IPs
          alternativeUrls.addAll([
            _apiBaseUrl.replaceAll('localhost', '10.0.2.2'),        // Android emulator
            _apiBaseUrl.replaceAll('localhost', '192.168.254.101'), // Common network IP
            _apiBaseUrl.replaceAll('localhost', '192.168.1.100'),   // Common router IP range
            _apiBaseUrl.replaceAll('localhost', '192.168.0.100'),  // Common router IP range
          ]);
        } else {
          // If a specific IP failed, try other common IPs and localhost
          alternativeUrls.addAll([
            'http://localhost:5000',
            'http://10.0.2.2:5000',                              // Android emulator
            'http://192.168.254.101:5000',                       // Common network IP
            'http://192.168.1.100:5000',                         // Common router IP range
            'http://192.168.0.100:5000',                         // Common router IP range
          ]);
        }
        
        // Try each alternative URL
        for (final altUrl in alternativeUrls) {
          if (kDebugMode) {
            print('🔄 Trying alternative URL: $altUrl');
          }
          try {
            await initialize(apiBaseUrl: altUrl);
            if (_isInitialized) {
              if (kDebugMode) {
                print('✅ Connected via alternative URL: $altUrl');
              }
              break; // Success, stop trying
            }
          } catch (e2) {
            if (kDebugMode) {
              print('❌ $altUrl also failed: $e2');
            }
          }
        }
      }
    }
    
    // If still not initialized, throw error
    if (!_isInitialized) {
      throw Exception('ML Service not available.\n\nCurrent URL: $_apiBaseUrl\n\nPlease:\n1. Make sure API server is running: python ml_training/sms_spam_api_sklearn.py\n2. For Android emulator, server should be accessible via 10.0.2.2:5000');
    }
    
    try {
      final requestBody = json.encode({'message': message.body});
      
      if (kDebugMode) {
        print('📤 Sending prediction request to: $_apiBaseUrl/predict');
        print('📤 Request body: ${message.body.substring(0, message.body.length.clamp(0, 50))}...');
      }
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (kDebugMode) {
          print('✅ ML prediction: is_phishing=${data['is_phishing']}, confidence=${data['confidence']}');
        }
        
      final double phishingConfidence = (data['phishing_confidence'] as num?)?.toDouble() ?? (data['confidence'] as num).toDouble();
      return PhishingDetection(
          id: const Uuid().v4(),
        messageId: message.id,
          confidence: phishingConfidence,
          type: data['is_phishing'] == true 
              ? PhishingType.content 
              : PhishingType.content,
          reason: data['reason'] ?? 'ML model prediction',
          indicators: List<String>.from(data['indicators'] ?? []),
        detectedAt: DateTime.now(),
      );
      } else {
        // Try to parse error response
        String errorMsg = 'Prediction failed';
        try {
          final errorData = json.decode(response.body);
          errorMsg = errorData['error'] ?? errorMsg;
          if (kDebugMode) {
            print('❌ API Error Response: ${response.statusCode}');
            print('   Error: $errorMsg');
            if (errorData.containsKey('received_fields')) {
              print('   Received fields: ${errorData['received_fields']}');
            }
          }
        } catch (jsonError) {
          // Response body is not JSON
          errorMsg = 'API returned status ${response.statusCode}: ${response.body.substring(0, 100)}';
          if (kDebugMode) {
            print('❌ API Error Response (non-JSON): ${response.statusCode}');
            print('   Body: ${response.body.substring(0, 200)}');
          }
        }
        throw Exception(errorMsg);
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ Network error: $e');
        print('💡 Cannot reach API server at $_apiBaseUrl');
        print('💡 Make sure API server is running: python ml_training/sms_spam_api_sklearn.py');
        print('💡 For Android emulator, ensure server is accessible via: http://192.168.254.111:5000 or http://10.0.2.2:5000');
      }
      rethrow;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('❌ Timeout error: $e');
        print('💡 API server did not respond in time');
        print('💡 Check if server is running and accessible');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error analyzing SMS with ML: $e');
        print('💡 Make sure API server is running: python ml_training/sms_spam_api_sklearn.py');
      }
      rethrow;
    }
  }
  
  /// Analyze multiple messages in batch
  Future<List<PhishingDetection>> analyzeBatch(List<SmsMessage> messages) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final messageTexts = messages.map((m) => m.body).toList();
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/batch_predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'messages': messageTexts}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.asMap().entries.map((entry) {
          final idx = entry.key;
          final result = entry.value as Map<String, dynamic>;
          final double phishingConfidence = (result['phishing_confidence'] as num?)?.toDouble() ?? (result['confidence'] as num).toDouble();
          return PhishingDetection(
            id: const Uuid().v4(),
            messageId: messages[idx].id,
            confidence: phishingConfidence,
            type: result['is_phishing'] == true 
                ? PhishingType.content 
                : PhishingType.content,
            reason: 'ML model batch prediction',
            indicators: result['is_phishing'] == true 
                ? ['Phishing detected by ML model']
                : ['Legitimate message'],
          detectedAt: DateTime.now(),
        );
        }).toList();
      } else {
        throw Exception('Batch prediction failed');
          }
        } catch (e) {
          if (kDebugMode) {
        print('Error in batch analysis: $e');
      }
      rethrow;
    }
  }
  
  /// Analyze URL for phishing (placeholder - uses SMS analysis)
  Future<Map<String, dynamic>> analyzeUrl(String url) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Treat URL as a message for analysis
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': url}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'url': url,
          'isSuspicious': data['is_phishing'] == true,
          'confidence': (data['confidence'] as num).toDouble(),
          'threatLevel': data['is_phishing'] == true ? 'high' : 'low',
          'indicators': List<String>.from(data['indicators'] ?? []),
          'reason': data['reason'] ?? 'ML model analysis',
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'URL analysis failed');
      }
        } catch (e) {
          if (kDebugMode) {
        print('Error analyzing URL: $e');
      }
      // Return default safe result on error
      return {
        'url': url,
        'isSuspicious': false,
        'confidence': 0.0,
        'threatLevel': 'unknown',
        'indicators': [],
        'reason': 'Analysis unavailable - ML service not accessible',
      };
    }
  }
  
  /// Extract URLs from text (utility function)
  List<String> extractUrls(String text) {
    final urlRegex = RegExp(
      r'https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*',
      caseSensitive: false,
    );
    return urlRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Get API base URL
  String get apiBaseUrl => _apiBaseUrl;
  
  /// Get model statistics
  Map<String, dynamic> getModelStats() {
    return {
      'isInitialized': _isInitialized,
      'currentModel': _currentModelType.toString(),
      'serviceMode': _serviceMode.toString(),
      'apiBaseUrl': _apiBaseUrl,
      'vocabLoaded': _isInitialized,
      'modelsLoaded': _isInitialized,
    };
  }
  
  /// Switch to a different model type
  Future<void> switchModel(ModelType modelType) async {
    _currentModelType = modelType;
    // If service was initialized, we may need to reinitialize
    // For now, just update the model type
    if (kDebugMode) {
      print('🔄 Switched to model type: $modelType');
    }
  }
  
  /// Generate signature for a message
  Future<String> generateSignature(SmsMessage message) async {
    final content = '${message.sender}|${message.body}|${message.timestamp.toIso8601String()}';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    _isInitialized = false;
    if (kDebugMode) {
      print('🧹 ML Service disposed');
    }
  }
}

