import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';

/// Online ML Service for cloud-based SMS phishing detection
class OnlineMLService {
  static final OnlineMLService _instance = OnlineMLService._internal();
  static OnlineMLService get instance => _instance;
  
  OnlineMLService._internal();
  
  // API Configuration
  static const String _huggingFaceApiUrl = 'https://api-inference.huggingface.co/models';
  static const String _googleCloudApiUrl = 'https://language.googleapis.com/v1/documents:classifyText';
  static const String _customApiUrl = 'https://your-api-endpoint.com/predict';
  
  // API Keys (should be stored securely)
  String? _huggingFaceApiKey;
  String? _googleCloudApiKey;
  String? _customApiKey;
  
  bool _isInitialized = false;
  
  /// Initialize the online ML service with API keys
  Future<void> initialize({
    String? huggingFaceApiKey,
    String? googleCloudApiKey,
    String? customApiKey,
  }) async {
    _huggingFaceApiKey = huggingFaceApiKey;
    _googleCloudApiKey = googleCloudApiKey;
    _customApiKey = customApiKey;
    _isInitialized = true;
    
    if (kDebugMode) {
      print('Online ML Service initialized');
    }
  }
  
  /// Analyze SMS message using online ML services
  Future<PhishingDetection> analyzeSms(SmsMessage message) async {
    if (!_isInitialized) {
      throw Exception('Online ML Service not initialized');
    }
    
    try {
      // Try multiple online services in order of preference
      PhishingDetection? detection;
      
      // 1. Try Hugging Face API (free tier available)
      if (_huggingFaceApiKey != null) {
        detection = await _analyzeWithHuggingFace(message);
        if (detection != null) return detection;
      }
      
      // 2. Try Google Cloud Natural Language API
      if (_googleCloudApiKey != null) {
        detection = await _analyzeWithGoogleCloud(message);
        if (detection != null) return detection;
      }
      
      // 3. Try custom API
      if (_customApiKey != null) {
        detection = await _analyzeWithCustomAPI(message);
        if (detection != null) return detection;
      }
      
      // 4. Fallback to rule-based analysis
      return _analyzeWithRules(message);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error in online ML analysis: $e');
      }
      // Fallback to rule-based analysis
      return _analyzeWithRules(message);
    }
  }
  
  /// Analyze using Hugging Face Inference API
  Future<PhishingDetection?> _analyzeWithHuggingFace(SmsMessage message) async {
    try {
      // Use a pre-trained text classification model
      const modelId = 'unitary/toxic-bert';
      final url = '$_huggingFaceApiUrl/$modelId';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_huggingFaceApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': message.body,
          'options': {
            'wait_for_model': true,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result is List && result.isNotEmpty) {
          final predictions = result[0] as List;
          
          // Find phishing/spam probability
          double phishingScore = 0.0;
          for (final prediction in predictions) {
            final label = prediction['label'].toString().toLowerCase();
            if (label.contains('toxic') || label.contains('spam')) {
              phishingScore = prediction['score'] as double;
              break;
            }
          }
          
          if (phishingScore > 0.7) {
            return PhishingDetection(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              messageId: message.id,
              confidence: phishingScore,
              type: PhishingType.content,
              indicators: _extractIndicators(message.body),
              reason: 'Hugging Face API detected suspicious content',
              detectedAt: DateTime.now(),
            );
          }
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Hugging Face API error: $e');
      }
      return null;
    }
  }
  
  /// Analyze using Google Cloud Natural Language API
  Future<PhishingDetection?> _analyzeWithGoogleCloud(SmsMessage message) async {
    try {
      final url = '$_googleCloudApiUrl?key=$_googleCloudApiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'document': {
            'type': 'PLAIN_TEXT',
            'content': message.body,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final categories = result['categories'] as List?;
        
        if (categories != null) {
          for (final category in categories) {
            final name = category['name'].toString().toLowerCase();
            final confidence = category['confidence'] as double;
            
            // Check for spam/phishing categories
            if ((name.contains('spam') || 
                 name.contains('phishing') || 
                 name.contains('fraud')) && 
                confidence > 0.7) {
              return PhishingDetection(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                messageId: message.id,
                confidence: confidence,
                type: PhishingType.content,
                indicators: _extractIndicators(message.body),
                reason: 'Google Cloud API detected suspicious content',
                detectedAt: DateTime.now(),
              );
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Google Cloud API error: $e');
      }
      return null;
    }
  }
  
  /// Analyze using custom API
  Future<PhishingDetection?> _analyzeWithCustomAPI(SmsMessage message) async {
    try {
      final response = await http.post(
        Uri.parse(_customApiUrl),
        headers: {
          'Authorization': 'Bearer $_customApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': message.body,
          'sender': message.sender,
          'timestamp': message.timestamp.toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final isPhishing = result['is_phishing'] as bool;
        final confidence = result['confidence'] as double;
        final indicators = List<String>.from(result['indicators'] ?? []);
        
        if (isPhishing && confidence > 0.7) {
          return PhishingDetection(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            messageId: message.id,
            confidence: confidence,
            type: PhishingType.content,
            indicators: indicators,
            reason: 'Custom API detected suspicious content',
            detectedAt: DateTime.now(),
          );
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Custom API error: $e');
      }
      return null;
    }
  }
  
  /// Fallback rule-based analysis (same as offline version)
  PhishingDetection _analyzeWithRules(SmsMessage message) {
    final indicators = <String>[];
    double confidence = 0.0;
    PhishingType type = PhishingType.content;
    String reason = 'Rule-based analysis (offline fallback)';
    
    // Check for urgent language
    if (_containsUrgentLanguage(message.body)) {
      indicators.add('Urgent language detected');
      confidence += 0.3;
      type = PhishingType.urgent;
    }
    
    // Check for suspicious keywords
    final suspiciousKeywords = _getSuspiciousKeywords(message.body);
    if (suspiciousKeywords.isNotEmpty) {
      indicators.addAll(suspiciousKeywords);
      confidence += suspiciousKeywords.length * 0.1;
      type = PhishingType.suspiciousKeywords;
    }
    
    // Check for suspicious URLs
    final urls = _extractUrls(message.body);
    for (final url in urls) {
      if (_isSuspiciousUrl(url)) {
        indicators.add('Suspicious URL: $url');
        confidence += 0.4;
        type = PhishingType.url;
      }
    }
    
    // Check sender patterns
    if (_isSuspiciousSender(message.sender)) {
      indicators.add('Suspicious sender pattern');
      confidence += 0.2;
      type = PhishingType.sender;
    }
    
    return PhishingDetection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messageId: message.id,
      confidence: confidence,
      type: type,
      indicators: indicators,
      reason: reason,
      detectedAt: DateTime.now(),
    );
  }
  
  /// Extract indicators from message text
  List<String> _extractIndicators(String text) {
    final indicators = <String>[];
    
    if (_containsUrgentLanguage(text)) {
      indicators.add('Urgent language');
    }
    
    indicators.addAll(_getSuspiciousKeywords(text));
    
    final urls = _extractUrls(text);
    for (final url in urls) {
      if (_isSuspiciousUrl(url)) {
        indicators.add('Suspicious URL');
      }
    }
    
    return indicators;
  }
  
  /// Check for urgent language patterns
  bool _containsUrgentLanguage(String text) {
    final urgentWords = [
      'urgent', 'immediately', 'act now', 'limited time',
      'expires', 'verify', 'confirm', 'suspended',
      'blocked', 'security', 'fraud', 'unauthorized'
    ];
    
    final lowerText = text.toLowerCase();
    return urgentWords.any((word) => lowerText.contains(word));
  }
  
  /// Get suspicious keywords from text
  List<String> _getSuspiciousKeywords(String text) {
    final suspiciousKeywords = [
      'password', 'pin', 'ssn', 'social security',
      'credit card', 'bank account', 'wire transfer',
      'gift card', 'bitcoin', 'cryptocurrency',
      'click here', 'verify account', 'update info'
    ];
    
    final lowerText = text.toLowerCase();
    return suspiciousKeywords.where((keyword) => lowerText.contains(keyword)).toList();
  }
  
  /// Extract URLs from text
  List<String> _extractUrls(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    return urlRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }
  
  /// Check if URL is suspicious
  bool _isSuspiciousUrl(String url) {
    final suspiciousDomains = [
      'bit.ly', 'tinyurl.com', 'goo.gl', 't.co',
      'shortened-url', 'suspicious-domain'
    ];
    
    final lowerUrl = url.toLowerCase();
    return suspiciousDomains.any((domain) => lowerUrl.contains(domain));
  }
  
  /// Check if sender is suspicious
  bool _isSuspiciousSender(String sender) {
    final suspiciousPatterns = [
      RegExp(r'^\d{4,}$'), // Only numbers
      RegExp(r'^[A-Z]{2,}$'), // Only uppercase letters
      RegExp(r'.*@.*\..*'), // Email-like patterns in SMS
    ];
    
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(sender));
  }
  
  /// Check internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasHuggingFaceKey': _huggingFaceApiKey != null,
      'hasGoogleCloudKey': _googleCloudApiKey != null,
      'hasCustomApiKey': _customApiKey != null,
      'serviceType': 'online',
    };
  }
}
