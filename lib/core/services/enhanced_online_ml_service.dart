import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';

/// Enhanced Online ML Service with multiple AI providers and easy setup
class EnhancedOnlineMLService {
  static final EnhancedOnlineMLService _instance = EnhancedOnlineMLService._internal();
  static EnhancedOnlineMLService get instance => _instance;
  
  EnhancedOnlineMLService._internal();
  
  // API Configuration
  static const String _huggingFaceApiUrl = 'https://api-inference.huggingface.co/models';
  static const String _openaiApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _googleCloudApiUrl = 'https://language.googleapis.com/v1/documents:classifyText';
  static const String _azureApiUrl = 'https://your-region.api.cognitive.microsoft.com/text/analytics/v3.1/sentiment';
  static const String _customApiUrl = 'https://your-api-endpoint.com/predict';
  
  // API Keys (stored securely in SharedPreferences)
  String? _huggingFaceApiKey;
  String? _openaiApiKey;
  String? _googleCloudApiKey;
  String? _azureApiKey;
  String? _customApiKey;
  
  bool _isInitialized = false;
  SharedPreferences? _prefs;
  
  // Service preferences
  List<MLProvider> _enabledProviders = [];
  MLProvider _primaryProvider = MLProvider.huggingFace;
  
  /// Initialize the enhanced online ML service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadApiKeys();
    await _loadPreferences();
    _isInitialized = true;
    
    if (kDebugMode) {
      print('Enhanced Online ML Service initialized');
      print('Enabled providers: ${_enabledProviders.map((p) => p.name).join(', ')}');
    }
  }
  
  /// Load API keys from secure storage
  Future<void> _loadApiKeys() async {
    _huggingFaceApiKey = _prefs?.getString('hf_api_key');
    _openaiApiKey = _prefs?.getString('openai_api_key');
    _googleCloudApiKey = _prefs?.getString('gcp_api_key');
    _azureApiKey = _prefs?.getString('azure_api_key');
    _customApiKey = _prefs?.getString('custom_api_key');
  }
  
  /// Load service preferences
  Future<void> _loadPreferences() async {
    final enabledProvidersJson = _prefs?.getStringList('enabled_providers') ?? [];
    _enabledProviders = enabledProvidersJson
        .map((p) => MLProvider.values.firstWhere((provider) => provider.name == p))
        .toList();
    
    final primaryProviderName = _prefs?.getString('primary_provider');
    if (primaryProviderName != null) {
      _primaryProvider = MLProvider.values.firstWhere(
        (provider) => provider.name == primaryProviderName,
        orElse: () => MLProvider.huggingFace,
      );
    }
  }
  
  /// Save API key securely
  Future<void> setApiKey(MLProvider provider, String apiKey) async {
    switch (provider) {
      case MLProvider.huggingFace:
        _huggingFaceApiKey = apiKey;
        await _prefs?.setString('hf_api_key', apiKey);
        break;
      case MLProvider.openai:
        _openaiApiKey = apiKey;
        await _prefs?.setString('openai_api_key', apiKey);
        break;
      case MLProvider.googleCloud:
        _googleCloudApiKey = apiKey;
        await _prefs?.setString('gcp_api_key', apiKey);
        break;
      case MLProvider.azure:
        _azureApiKey = apiKey;
        await _prefs?.setString('azure_api_key', apiKey);
        break;
      case MLProvider.custom:
        _customApiKey = apiKey;
        await _prefs?.setString('custom_api_key', apiKey);
        break;
    }
    
    if (!_enabledProviders.contains(provider)) {
      _enabledProviders.add(provider);
      await _savePreferences();
    }
  }
  
  /// Remove API key
  Future<void> removeApiKey(MLProvider provider) async {
    switch (provider) {
      case MLProvider.huggingFace:
        _huggingFaceApiKey = null;
        await _prefs?.remove('hf_api_key');
        break;
      case MLProvider.openai:
        _openaiApiKey = null;
        await _prefs?.remove('openai_api_key');
        break;
      case MLProvider.googleCloud:
        _googleCloudApiKey = null;
        await _prefs?.remove('gcp_api_key');
        break;
      case MLProvider.azure:
        _azureApiKey = null;
        await _prefs?.remove('azure_api_key');
        break;
      case MLProvider.custom:
        _customApiKey = null;
        await _prefs?.remove('custom_api_key');
        break;
    }
    
    _enabledProviders.remove(provider);
    await _savePreferences();
  }
  
  /// Save service preferences
  Future<void> _savePreferences() async {
    await _prefs?.setStringList(
      'enabled_providers',
      _enabledProviders.map((p) => p.name).toList(),
    );
    await _prefs?.setString('primary_provider', _primaryProvider.name);
  }
  
  /// Set primary provider
  Future<void> setPrimaryProvider(MLProvider provider) async {
    if (_enabledProviders.contains(provider)) {
      _primaryProvider = provider;
      await _savePreferences();
    }
  }
  
  /// Analyze SMS message using online ML services
  Future<PhishingDetection> analyzeSms(SmsMessage message) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_enabledProviders.isEmpty) {
      return _analyzeWithRules(message);
    }
    
    try {
      // Try providers in order of preference
      final providersToTry = [_primaryProvider, ..._enabledProviders.where((p) => p != _primaryProvider)];
      
      for (final provider in providersToTry) {
        try {
          final detection = await _analyzeWithProvider(provider, message);
          if (detection != null && detection.confidence > 0.7) {
            return detection;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error with ${provider.name}: $e');
          }
          continue;
        }
      }
      
      // If no provider gives high confidence, use rule-based analysis
      return _analyzeWithRules(message);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error in online ML analysis: $e');
      }
      return _analyzeWithRules(message);
    }
  }
  
  /// Analyze with specific provider
  Future<PhishingDetection?> _analyzeWithProvider(MLProvider provider, SmsMessage message) async {
    switch (provider) {
      case MLProvider.huggingFace:
        return await _analyzeWithHuggingFace(message);
      case MLProvider.openai:
        return await _analyzeWithOpenAI(message);
      case MLProvider.googleCloud:
        return await _analyzeWithGoogleCloud(message);
      case MLProvider.azure:
        return await _analyzeWithAzure(message);
      case MLProvider.custom:
        return await _analyzeWithCustomAPI(message);
    }
  }
  
  /// Analyze using Hugging Face Inference API
  Future<PhishingDetection?> _analyzeWithHuggingFace(SmsMessage message) async {
    if (_huggingFaceApiKey == null) return null;
    
    try {
      // Use a pre-trained spam/phishing detection model
      const modelId = 'microsoft/DialoGPT-medium'; // Can be changed to a spam detection model
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
            'use_cache': false,
          }
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return _parseHuggingFaceResponse(result, message);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Hugging Face API error: $e');
      }
      return null;
    }
  }
  
  /// Analyze using OpenAI GPT API
  Future<PhishingDetection?> _analyzeWithOpenAI(SmsMessage message) async {
    if (_openaiApiKey == null) return null;
    
    try {
      final response = await http.post(
        Uri.parse(_openaiApiUrl),
        headers: {
          'Authorization': 'Bearer $_openaiApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a cybersecurity expert. Analyze the following SMS message for phishing indicators. Respond with a JSON object containing: {"is_phishing": boolean, "confidence": number (0-1), "indicators": [array of strings], "reason": "explanation"}.'
            },
            {
              'role': 'user',
              'content': 'SMS from "${message.sender}": "${message.body}"'
            }
          ],
          'max_tokens': 200,
          'temperature': 0.1,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return _parseOpenAIResponse(result, message);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI API error: $e');
      }
      return null;
    }
  }
  
  /// Analyze using Google Cloud Natural Language API
  Future<PhishingDetection?> _analyzeWithGoogleCloud(SmsMessage message) async {
    if (_googleCloudApiKey == null) return null;
    
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
          },
          'features': {
            'extractEntities': true,
            'extractDocumentSentiment': true,
            'classifyText': true,
          }
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return _parseGoogleCloudResponse(result, message);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Google Cloud API error: $e');
      }
      return null;
    }
  }
  
  /// Analyze using Azure Cognitive Services
  Future<PhishingDetection?> _analyzeWithAzure(SmsMessage message) async {
    if (_azureApiKey == null) return null;
    
    try {
      final response = await http.post(
        Uri.parse(_azureApiUrl),
        headers: {
          'Ocp-Apim-Subscription-Key': _azureApiKey!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'documents': [
            {
              'id': message.id,
              'text': message.body,
              'language': 'en'
            }
          ]
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return _parseAzureResponse(result, message);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Azure API error: $e');
      }
      return null;
    }
  }
  
  /// Analyze using custom API
  Future<PhishingDetection?> _analyzeWithCustomAPI(SmsMessage message) async {
    if (_customApiKey == null) return null;
    
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
          'message_id': message.id,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return _parseCustomAPIResponse(result, message);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Custom API error: $e');
      }
      return null;
    }
  }
  
  /// Parse Hugging Face API response
  PhishingDetection? _parseHuggingFaceResponse(dynamic result, SmsMessage message) {
    if (result is List && result.isNotEmpty) {
      final predictions = result[0] as List;
      
      double phishingScore = 0.0;
      for (final prediction in predictions) {
        final label = prediction['label'].toString().toLowerCase();
        if (label.contains('toxic') || label.contains('spam') || label.contains('phishing')) {
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
          reason: 'Hugging Face AI detected suspicious content',
          detectedAt: DateTime.now(),
        );
      }
    }
    return null;
  }
  
  /// Parse OpenAI API response
  PhishingDetection? _parseOpenAIResponse(dynamic result, SmsMessage message) {
    try {
      final content = result['choices'][0]['message']['content'] as String;
      final analysis = jsonDecode(content);
      
      if (analysis['is_phishing'] == true && analysis['confidence'] > 0.7) {
        return PhishingDetection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          messageId: message.id,
          confidence: analysis['confidence'] as double,
          type: PhishingType.content,
          indicators: List<String>.from(analysis['indicators'] ?? []),
          reason: analysis['reason'] ?? 'OpenAI detected suspicious content',
          detectedAt: DateTime.now(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing OpenAI response: $e');
      }
    }
    return null;
  }
  
  /// Parse Google Cloud API response
  PhishingDetection? _parseGoogleCloudResponse(dynamic result, SmsMessage message) {
    final categories = result['categories'] as List?;
    
    if (categories != null) {
      for (final category in categories) {
        final name = category['name'].toString().toLowerCase();
        final confidence = category['confidence'] as double;
        
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
            reason: 'Google Cloud AI detected suspicious content',
            detectedAt: DateTime.now(),
          );
        }
      }
    }
    return null;
  }
  
  /// Parse Azure API response
  PhishingDetection? _parseAzureResponse(dynamic result, SmsMessage message) {
    final documents = result['documents'] as List?;
    
    if (documents != null && documents.isNotEmpty) {
      final doc = documents[0];
      final sentiment = doc['sentiment'] as String;
      final confidence = doc['confidenceScores'][sentiment] as double;
      
      // Negative sentiment with high confidence might indicate phishing
      if (sentiment == 'negative' && confidence > 0.8) {
        return PhishingDetection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          messageId: message.id,
          confidence: confidence,
          type: PhishingType.content,
          indicators: _extractIndicators(message.body),
          reason: 'Azure AI detected suspicious sentiment',
          detectedAt: DateTime.now(),
        );
      }
    }
    return null;
  }
  
  /// Parse Custom API response
  PhishingDetection? _parseCustomAPIResponse(dynamic result, SmsMessage message) {
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
        reason: result['reason'] ?? 'Custom AI detected suspicious content',
        detectedAt: DateTime.now(),
      );
    }
    return null;
  }
  
  /// Fallback rule-based analysis
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
      'click here', 'verify account', 'update info',
      'congratulations', 'won', 'prize', 'claim',
      'free', 'offer', 'limited time', 'expires',
      'suspended', 'blocked', 'compromised', 'fraud',
      'urgent', 'immediately', 'act now', 'verify',
      'confirm', 'update', 'restore', 'secure'
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
      'shortened-url', 'suspicious-domain', 'fake',
      'scam', 'phishing', 'malicious'
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
  
  /// Test API connection
  Future<bool> testApiConnection(MLProvider provider) async {
    try {
      final testMessage = SmsMessage(
        id: 'test',
        sender: 'Test',
        body: 'This is a test message for API connection',
        timestamp: DateTime.now(),
        isPhishing: false,
        phishingScore: 0.0,
        extractedUrls: [],
      );
      
      final result = await _analyzeWithProvider(provider, testMessage);
      return result != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'isInitialized': _isInitialized,
      'enabledProviders': _enabledProviders.map((p) => p.name).toList(),
      'primaryProvider': _primaryProvider.name,
      'hasApiKeys': {
        'huggingFace': _huggingFaceApiKey != null,
        'openai': _openaiApiKey != null,
        'googleCloud': _googleCloudApiKey != null,
        'azure': _azureApiKey != null,
        'custom': _customApiKey != null,
      },
      'serviceType': 'enhanced_online',
    };
  }
  
  /// Get available providers
  List<MLProvider> getAvailableProviders() {
    return MLProvider.values;
  }
  
  /// Get enabled providers
  List<MLProvider> getEnabledProviders() {
    return List.from(_enabledProviders);
  }
  
  /// Get primary provider
  MLProvider getPrimaryProvider() {
    return _primaryProvider;
  }
}

/// ML Provider enumeration
enum MLProvider {
  huggingFace('Hugging Face', 'Free tier available, good for basic analysis'),
  openai('OpenAI GPT', 'Advanced AI analysis, requires paid API key'),
  googleCloud('Google Cloud', 'Enterprise-grade analysis, requires billing account'),
  azure('Azure Cognitive', 'Microsoft AI services, requires Azure subscription'),
  custom('Custom API', 'Your own AI endpoint');
  
  const MLProvider(this.name, this.description);
  
  final String name;
  final String description;
}
