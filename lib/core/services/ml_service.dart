import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';
import 'online_ml_service.dart';
import 'enhanced_online_ml_service.dart';
import 'connectivity_service.dart';
import 'rust_ml_service.dart';

// Model types enum
enum ModelType { lstm, bert, distilbert, rust_distilbert, ensemble }

// ML service modes
enum MLServiceMode { offline, online, hybrid }

class MLService {
  static final MLService _instance = MLService._internal();
  static MLService get instance => _instance;
  
  MLService._internal();
  
  // Interpreter? _smsModel;
  // Interpreter? _urlModel;
  // Interpreter? _bertModel;
  // Interpreter? _lstmModel;
  
  // Placeholder model references (since TensorFlow Lite is disabled)
  dynamic _smsModel;
  dynamic _urlModel;
  dynamic _bertModel;
  dynamic _lstmModel;
  bool _isInitialized = false;
  ModelType _currentModelType = ModelType.lstm;
  MLServiceMode _serviceMode = MLServiceMode.hybrid;
  
  // Online service instances
  final OnlineMLService _onlineService = OnlineMLService.instance;
  final EnhancedOnlineMLService _enhancedOnlineService = EnhancedOnlineMLService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final RustMLService _rustMLService = RustMLService.instance;
  
  // Model configuration
  static const String _bertModelPath = 'assets/models/bert_phishing_classifier.tflite';
  static const String _lstmModelPath = 'assets/models/lstm_phishing_classifier.tflite';
  static const int _maxSequenceLength = 128;
  
  
  // Preprocessing
  final Map<String, int> _wordToIndex = {};
  final bool _vocabLoaded = false;
  
  Future<void> initialize({
    ModelType modelType = ModelType.rust_distilbert,
    MLServiceMode serviceMode = MLServiceMode.hybrid,
    String? huggingFaceApiKey,
    String? googleCloudApiKey,
    String? customApiKey,
  }) async {
    if (_isInitialized) return;
    
    _currentModelType = modelType;
    _serviceMode = serviceMode;
    
    try {
      // Initialize connectivity service first
      await _connectivityService.initialize();
      
      // PRIORITY 1: Try to initialize Rust DistilBERT model first (best performance)
      if (modelType == ModelType.rust_distilbert) {
        try {
          await _rustMLService.initialize();
          if (_rustMLService.isInitialized) {
            print('✅ Rust DistilBERT model initialized successfully - ML-based detection enabled');
            _isInitialized = true;
            return; // Success - exit early
          } else {
            print('⚠️ Rust DistilBERT initialized but not ready - continuing with other services');
          }
        } catch (e) {
          print('❌ Rust DistilBERT initialization failed: $e');
          print('🔄 Falling back to online ML services...');
        }
      }
      
      // PRIORITY 2: Try online ML services if Rust DistilBERT fails
      final isOnline = _connectivityService.isOnline;
      
      if (isOnline) {
        // If online, try to initialize online services
        if (_serviceMode == MLServiceMode.online || _serviceMode == MLServiceMode.hybrid) {
          try {
            // Initialize enhanced online service (preferred)
            await _enhancedOnlineService.initialize();
            print('✅ Enhanced online ML service initialized successfully - ML-based detection enabled');
            _isInitialized = true;
            return; // Success - exit early
          } catch (e) {
            print('❌ Enhanced online service initialization failed: $e');
          }
          
          try {
            // Initialize legacy online service as fallback
            await _onlineService.initialize(
              huggingFaceApiKey: huggingFaceApiKey,
              googleCloudApiKey: googleCloudApiKey,
              customApiKey: customApiKey,
            );
            print('✅ Legacy online ML service initialized successfully - ML-based detection enabled');
            _isInitialized = true;
            return; // Success - exit early
          } catch (e) {
            print('❌ Legacy online service initialization failed: $e');
          }
        }
      }
      
      // PRIORITY 3: Initialize offline models as fallback
      if (_serviceMode == MLServiceMode.offline || _serviceMode == MLServiceMode.hybrid) {
        await _initializeOfflineModels(modelType);
      }
      
      _isInitialized = true;
      print('ML Service initialized in ${_serviceMode.toString()} mode (Online: $isOnline)');
    } catch (e) {
      print('Error initializing ML service: $e');
      // Fallback to rule-based detection if models fail
      _isInitialized = true;
    }
  }
  
  Future<void> _initializeOfflineModels(ModelType modelType) async {
    try {
      // For mobile testing, skip ML model loading and use rule-based detection
      print('Using rule-based detection for mobile testing');
      // Load vocabulary
      // await _loadVocabulary();
    } catch (e) {
      print('Error loading offline models: $e');
    }
  }
  
  // Placeholder method for loading models (TensorFlow Lite disabled)
  Future<dynamic> _loadModel(String modelPath) async {
    print('Loading model from: $modelPath (placeholder implementation)');
    // Return null since TensorFlow Lite is disabled
    return null;
  }
  
  Future<void> switchModel(ModelType modelType) async {
    if (modelType == _currentModelType) return;
    
    _currentModelType = modelType;
    
    try {
      switch (modelType) {
        case ModelType.bert:
          _bertModel ??= await _loadModel(_bertModelPath);
          break;
        case ModelType.distilbert:
          _bertModel ??= await _loadModel(_bertModelPath);
          break;
        case ModelType.rust_distilbert:
          // Rust model is initialized separately
          break;
        case ModelType.lstm:
          _lstmModel ??= await _loadModel(_lstmModelPath);
          break;
        case ModelType.ensemble:
          _bertModel ??= await _loadModel(_bertModelPath);
          _lstmModel ??= await _loadModel(_lstmModelPath);
          break;
      }
    } catch (e) {
      print('Error switching model: $e');
    }
  }
  
  // Future<Interpreter> _loadModel(String modelPath) async {
  //   try {
  //     return await Interpreter.fromAsset(modelPath);
  //   } catch (e) {
  //     print('Error loading model $modelPath: $e');
  //     // Return a dummy interpreter for fallback
  //     return await Interpreter.fromAsset('assets/models/dummy_model.tflite');
  //   }
  // }
  
  
  Future<PhishingDetection> analyzeSms(SmsMessage message) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Extract URLs from message first
      final urls = extractUrls(message.body);
      final messageWithUrls = message.copyWith(extractedUrls: urls);
      
      // PRIORITY 1: Try Rust DistilBERT first (best ML performance)
      if (_currentModelType == ModelType.rust_distilbert && _rustMLService.isInitialized) {
        try {
          final result = await _rustMLService.analyzeSms(messageWithUrls);
          if (kDebugMode) {
            print('🤖 Rust DistilBERT analysis completed - ML-based detection (confidence: ${result.confidence})');
          }
          return result;
        } catch (e) {
          if (kDebugMode) {
            print('❌ Rust DistilBERT analysis failed: $e');
            print('🔄 Falling back to other ML services...');
          }
        }
      }
      
      // PRIORITY 2: Try online ML services if available
      if (_connectivityService.isOnline) {
        try {
          // Try enhanced online service first
          final result = await _enhancedOnlineService.analyzeSms(messageWithUrls);
          if (kDebugMode) {
            print('🌐 Enhanced online ML analysis completed - ML-based detection');
          }
          return result;
        } catch (e) {
          if (kDebugMode) {
            print('❌ Enhanced online service failed: $e');
          }
        }
        
        try {
          // Try legacy online service as fallback
          final result = await _onlineService.analyzeSms(messageWithUrls);
          if (kDebugMode) {
            print('🌐 Legacy online ML analysis completed - ML-based detection');
          }
          return result;
        } catch (e) {
          if (kDebugMode) {
            print('❌ Legacy online service failed: $e');
          }
        }
      }
      
      // PRIORITY 3: Try to reinitialize Rust DistilBERT if it failed
      if (_currentModelType == ModelType.rust_distilbert && !_rustMLService.isInitialized) {
        try {
          await _rustMLService.initialize();
          if (_rustMLService.isInitialized) {
            final result = await _rustMLService.analyzeSms(messageWithUrls);
            if (kDebugMode) {
              print('🤖 Rust DistilBERT reinitialized and analysis completed - ML-based detection');
            }
            return result;
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Rust DistilBERT reinitialization failed: $e');
          }
        }
      }
      
      // PRIORITY 4: All ML services failed - return neutral result
      if (kDebugMode) {
        print('⚠️ All ML services failed - returning neutral result');
      }
      return PhishingDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        messageId: message.id,
        confidence: 0.0,
        type: PhishingType.content,
        indicators: ['ML services unavailable'],
        reason: 'All ML-based detection services failed',
        detectedAt: DateTime.now(),
      );
      
    } catch (e) {
      print('❌ Error analyzing SMS: $e');
      return PhishingDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        messageId: message.id,
        confidence: 0.0,
        type: PhishingType.content,
        indicators: ['Analysis error'],
        reason: 'ML analysis failed: $e',
        detectedAt: DateTime.now(),
      );
    }
  }
  
  /// Analyze using online services only
  Future<PhishingDetection> _analyzeOnlineOnly(SmsMessage message) async {
    if (!_connectivityService.isOnline) {
      return PhishingDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        messageId: message.id,
        confidence: 0.0,
        type: PhishingType.content,
        indicators: ['No internet connection'],
        reason: 'Online mode requires internet connection',
        detectedAt: DateTime.now(),
      );
    }
    
    try {
      // Try enhanced online service first
      return await _enhancedOnlineService.analyzeSms(message);
    } catch (e) {
      print('Enhanced online analysis failed: $e');
      try {
        // Fallback to legacy online service
        return await _onlineService.analyzeSms(message);
      } catch (e2) {
        print('Legacy online analysis failed: $e2');
        return PhishingDetection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          messageId: message.id,
          confidence: 0.0,
          type: PhishingType.content,
          indicators: ['All online ML services failed'],
          reason: 'Online ML analysis failed',
          detectedAt: DateTime.now(),
        );
      }
    }
  }
  
  /// Analyze using offline models only
  Future<PhishingDetection> _analyzeOfflineOnly(SmsMessage message) async {
    try {
      // Use Rust DistilBERT if available and selected
      if (_currentModelType == ModelType.rust_distilbert && _rustMLService.isInitialized) {
        return await _rustMLService.analyzeSms(message);
      }
      
      // Try other ML models
      final mlResult = await _analyzeWithML(message);
      if (mlResult != null) {
        return mlResult;
      }
      
      // If no ML models available, return neutral result
      return PhishingDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        messageId: message.id,
        confidence: 0.0,
        type: PhishingType.content,
        indicators: ['No offline ML models available'],
        reason: 'Offline ML analysis failed',
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      print('Offline analysis failed: $e');
      return PhishingDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        messageId: message.id,
        confidence: 0.0,
        type: PhishingType.content,
        indicators: ['Offline analysis error'],
        reason: 'Offline ML analysis failed: $e',
        detectedAt: DateTime.now(),
      );
    }
  }
  
  /// Analyze using hybrid approach (online preferred, offline fallback)
  Future<PhishingDetection> _analyzeHybrid(SmsMessage message) async {
    // If online, prioritize online services for better accuracy
    if (_connectivityService.isOnline) {
      print('Online detected - using online ML services for analysis');
      
      try {
        // Try enhanced online service first (best accuracy)
        final onlineResult = await _enhancedOnlineService.analyzeSms(message);
        
        // Use online result if confidence is reasonable (lower threshold for online services)
        if (onlineResult.confidence > 0.6) {
          print('Enhanced online analysis successful (confidence: ${onlineResult.confidence})');
          return onlineResult;
        }
        
        // If confidence is low, still use online result but log it
        print('Enhanced online analysis completed with low confidence: ${onlineResult.confidence}');
        return onlineResult;
      } catch (e) {
        print('Enhanced online analysis failed in hybrid mode: $e');
        try {
          // Fallback to legacy online service
          final legacyResult = await _onlineService.analyzeSms(message);
          if (legacyResult.confidence > 0.6) {
            print('Legacy online analysis successful (confidence: ${legacyResult.confidence})');
            return legacyResult;
          }
          print('Legacy online analysis completed with low confidence: ${legacyResult.confidence}');
          return legacyResult;
        } catch (e2) {
          print('Legacy online analysis failed in hybrid mode: $e2');
          // Fall through to offline analysis
        }
      }
    } else {
      print('Offline detected - using offline analysis');
    }
    
    // Fallback to offline analysis
    return await _analyzeOfflineOnly(message);
  }
  
  
  Future<PhishingDetection?> _analyzeWithML(SmsMessage message) async {
    try {
      switch (_currentModelType) {
        case ModelType.bert:
          return await _analyzeWithBERT(message);
        case ModelType.distilbert:
          return await _analyzeWithBERT(message);
        case ModelType.rust_distilbert:
          return await _rustMLService.analyzeSms(message);
        case ModelType.lstm:
          return await _analyzeWithLSTM(message);
        case ModelType.ensemble:
          return await _analyzeWithEnsemble(message);
      }
    } catch (e) {
      print('Error in ML analysis: $e');
      return null;
    }
  }
  
  Future<PhishingDetection?> _analyzeWithLSTM(SmsMessage message) async {
    if (_lstmModel == null) return null;
    
    try {
      // Preprocess text
      final preprocessedText = _preprocessText(message.body);
      final inputSequence = _textToSequence(preprocessedText);
      
      // Prepare input tensor
      final input = List.filled(1, List.filled(_maxSequenceLength, 0));
      for (int i = 0; i < inputSequence.length && i < _maxSequenceLength; i++) {
        input[0][i] = inputSequence[i];
      }
      
      // Run inference
      final output = List.filled(1, List.filled(2, 0.0));
      _lstmModel!.run(input, output);
      
      final confidence = output[0][1]; // Probability of being phishing
      final isPhishing = confidence > 0.7;
      
      if (isPhishing) {
        return PhishingDetection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          messageId: message.id,
          confidence: confidence,
          type: PhishingType.content,
          indicators: ['LSTM model detected suspicious content'],
          reason: 'LSTM model detected suspicious content',
          detectedAt: DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      print('Error in LSTM analysis: $e');
      return null;
    }
  }
  
  Future<PhishingDetection?> _analyzeWithBERT(SmsMessage message) async {
    if (_bertModel == null) return null;
    
    try {
      // BERT requires different preprocessing
      final preprocessedText = _preprocessTextForBERT(message.body);
      final tokenIds = _tokenizeForBERT(preprocessedText);
      
      // Prepare input tensors for BERT (input_ids, attention_mask, token_type_ids)
      final inputIds = List.filled(1, List.filled(_maxSequenceLength, 0));
      final attentionMask = List.filled(1, List.filled(_maxSequenceLength, 0));
      
      for (int i = 0; i < tokenIds.length && i < _maxSequenceLength; i++) {
        inputIds[0][i] = tokenIds[i];
        attentionMask[0][i] = 1;
      }
      
      // Run inference
      final output = List.filled(1, List.filled(2, 0.0));
      _bertModel!.run([inputIds, attentionMask], output);
      
      final confidence = output[0][1]; // Probability of being phishing
      final isPhishing = confidence > 0.8; // Higher threshold for BERT
      
      if (isPhishing) {
        return PhishingDetection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          messageId: message.id,
          confidence: confidence,
          type: PhishingType.content,
          indicators: ['LSTM model detected suspicious content'],
          reason: 'BERT model detected suspicious content',
          detectedAt: DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      print('Error in BERT analysis: $e');
      return null;
    }
  }
  
  Future<PhishingDetection?> _analyzeWithEnsemble(SmsMessage message) async {
    try {
      final lstmResult = await _analyzeWithLSTM(message);
      final bertResult = await _analyzeWithBERT(message);
      
      // Ensemble logic: combine predictions
      if (lstmResult != null && bertResult != null) {
        final combinedConfidence = (lstmResult.confidence + bertResult.confidence) / 2;
        final isPhishing = combinedConfidence > 0.75;
        
        if (isPhishing) {
          return PhishingDetection(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            messageId: message.id,
            confidence: combinedConfidence,
            type: PhishingType.content,
            indicators: <String>{...lstmResult.indicators, ...bertResult.indicators}.toList(),
            reason: 'Ensemble model (LSTM + BERT) detected suspicious content',
            detectedAt: DateTime.now(),
          );
        }
      } else if (lstmResult != null) {
        return lstmResult;
      } else if (bertResult != null) {
        return bertResult;
      }
      
      return null;
    } catch (e) {
      print('Error in ensemble analysis: $e');
      return null;
    }
  }
  
  
  String _preprocessText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  
  String _preprocessTextForBERT(String text) {
    // BERT preprocessing: keep punctuation, add special tokens
    return '[CLS] ${text.toLowerCase()} [SEP]';
  }
  
  List<int> _tokenizeForBERT(String text) {
    // Simplified BERT tokenization
    // In production, use proper BERT tokenizer
    final words = text.split(' ');
    final tokens = <int>[];
    
    for (final word in words) {
      if (word == '[CLS]') {
        tokens.add(101); // [CLS] token ID
      } else if (word == '[SEP]') {
        tokens.add(102); // [SEP] token ID
      } else {
        final index = _wordToIndex[word] ?? _wordToIndex['[UNK]'] ?? 100;
        tokens.add(index);
      }
    }
    
    return tokens;
  }
  
  List<int> _textToSequence(String text) {
    final words = text.split(' ');
    final sequence = <int>[];
    
    for (final word in words) {
      final index = _wordToIndex[word] ?? _wordToIndex['<UNK>'] ?? 0;
      sequence.add(index);
    }
    
    return sequence;
  }
  
  
  
  
  List<String> extractUrls(String text) {
    // Enhanced URL extraction with support for various formats
    final urlRegexes = [
      RegExp(r'https?://[^\s]+'),
      RegExp(r'www\.[^\s]+'),
      RegExp(r'[a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*'),
      RegExp(r'bit\.ly/[^\s]+'),
      RegExp(r'tinyurl\.com/[^\s]+'),
      RegExp(r'goo\.gl/[^\s]+'),
      RegExp(r't\.co/[^\s]+'),
    ];
    
    final urls = <String>{};
    for (final regex in urlRegexes) {
      urls.addAll(regex.allMatches(text).map((match) => match.group(0)!));
    }
    
    return urls.toList();
  }

  /// Enhanced URL analysis with multiple threat indicators
  Future<Map<String, dynamic>> analyzeUrl(String url) async {
    final analysis = {
      'url': url,
      'isSuspicious': false,
      'threatLevel': 'safe',
      'indicators': <String>[],
      'confidence': 0.0,
    };
    
    double suspicionScore = 0.0;
    final indicators = <String>[];
    
    // Check for URL shorteners
    if (_isUrlShortener(url)) {
      indicators.add('URL shortener detected');
      suspicionScore += 0.4;
    }
    
    // Check for suspicious domains
    if (_isSuspiciousDomain(url)) {
      indicators.add('Suspicious domain pattern');
      suspicionScore += 0.5;
    }
    
    // Check for phishing keywords in URL
    if (_hasPhishingKeywordsInUrl(url)) {
      indicators.add('Phishing keywords in URL');
      suspicionScore += 0.6;
    }
    
    // Check for homograph attacks
    if (_hasHomographAttack(url)) {
      indicators.add('Potential homograph attack');
      suspicionScore += 0.7;
    }
    
    // Check for suspicious TLD
    if (_hasSuspiciousTLD(url)) {
      indicators.add('Suspicious top-level domain');
      suspicionScore += 0.3;
    }
    
    // Check for excessive subdomains
    if (_hasExcessiveSubdomains(url)) {
      indicators.add('Excessive subdomains');
      suspicionScore += 0.3;
    }
    
    // Check for IP address instead of domain
    if (_isIpAddress(url)) {
      indicators.add('IP address instead of domain');
      suspicionScore += 0.5;
    }
    
    analysis['indicators'] = indicators;
    analysis['confidence'] = suspicionScore;
    analysis['isSuspicious'] = suspicionScore > 0.5;
    
    if (suspicionScore > 0.8) {
      analysis['threatLevel'] = 'high';
    } else if (suspicionScore > 0.5) {
      analysis['threatLevel'] = 'medium';
    } else if (suspicionScore > 0.2) {
      analysis['threatLevel'] = 'low';
    }
    
    return analysis;
  }

  
  bool _isUrlShortener(String url) {
    final shorteners = [
      'bit.ly', 'tinyurl.com', 'goo.gl', 't.co', 'short.link',
      'ow.ly', 'buff.ly', 'adf.ly', 'tiny.cc', 'is.gd',
      'v.gd', 'tr.im', 'url.ie', 'miniurl.com', 'x.co'
    ];
    
    final lowerUrl = url.toLowerCase();
    return shorteners.any((shortener) => lowerUrl.contains(shortener));
  }
  
  bool _isSuspiciousDomain(String url) {
    final suspiciousPatterns = [
      RegExp(r'[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'), // IP addresses
      RegExp(r'[a-z0-9]{20,}'), // Very long random strings
      RegExp(r'.*-.*-.*-.*'), // Multiple hyphens
      RegExp(r'.*\d{4,}.*'), // Long number sequences
    ];
    
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(url.toLowerCase()));
  }
  
  bool _hasPhishingKeywordsInUrl(String url) {
    final phishingKeywords = [
      'paypal', 'amazon', 'apple', 'microsoft', 'google', 'facebook',
      'bank', 'secure', 'verify', 'update', 'confirm', 'login',
      'account', 'suspended', 'limited', 'urgent', 'click',
      'fake', 'scam', 'phishing', 'malicious', 'steal', 'hack',
      'lottery', 'prize', 'claim', 'free', 'offer', 'win'
    ];
    
    final lowerUrl = url.toLowerCase();
    return phishingKeywords.any((keyword) => lowerUrl.contains(keyword));
  }
  
  bool _hasHomographAttack(String url) {
    // Check for common homograph characters
    final homographs = ['а', 'е', 'о', 'р', 'с', 'х', 'у']; // Cyrillic lookalikes
    return homographs.any((char) => url.contains(char));
  }
  
  bool _hasSuspiciousTLD(String url) {
    final suspiciousTlds = ['.tk', '.ml', '.ga', '.cf', '.top', '.click', '.download'];
    final lowerUrl = url.toLowerCase();
    return suspiciousTlds.any((tld) => lowerUrl.endsWith(tld));
  }
  
  bool _hasExcessiveSubdomains(String url) {
    final domainPart = url.replaceAll(RegExp(r'https?://'), '').split('/')[0];
    final subdomains = domainPart.split('.');
    return subdomains.length > 4; // More than 3 subdomains is suspicious
  }
  
  bool _isIpAddress(String url) {
    final ipPattern = RegExp(r'[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}');
    return ipPattern.hasMatch(url);
  }
  
  
  Future<String> generateSignature(SmsMessage message) async {
    final content = '${message.sender}:${message.body}';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  Future<void> dispose() async {
    await _smsModel?.close();
    await _urlModel?.close();
    await _bertModel?.close();
    await _lstmModel?.close();
    _isInitialized = false;
  }
  
  // Getters
  ModelType get currentModelType => _currentModelType;
  MLServiceMode get serviceMode => _serviceMode;
  bool get isOnline => _connectivityService.isOnline;
  
  /// Switch service mode (online/offline/hybrid)
  Future<void> switchServiceMode(MLServiceMode mode) async {
    if (_serviceMode == mode) return;
    
    _serviceMode = mode;
    
    // Initialize required services based on new mode
    if (mode == MLServiceMode.online || mode == MLServiceMode.hybrid) {
      // Ensure online service is initialized
      if (!_onlineService.getServiceStatus()['isInitialized']) {
        await _onlineService.initialize();
      }
    }
    
    if (mode == MLServiceMode.offline || mode == MLServiceMode.hybrid) {
      // Ensure offline models are loaded
      if (_smsModel == null) {
        await _initializeOfflineModels(_currentModelType);
      }
    }
    
    print('Switched to ${mode.toString()} mode');
  }
  
  /// Force connectivity check
  Future<bool> checkConnectivity() async {
    return await _connectivityService.checkConnectivity();
  }
  
  /// Get comprehensive service stats
  Map<String, dynamic> getModelStats() {
    final connectivityInfo = _connectivityService.isOnline 
        ? 'Online' 
        : 'Offline';
    
    return {
      'serviceMode': _serviceMode.toString(),
      'currentModel': _currentModelType.toString(),
      'isInitialized': _isInitialized,
      'connectivity': connectivityInfo,
      'vocabLoaded': _vocabLoaded,
      'vocabSize': _wordToIndex.length,
      'offlineModelsLoaded': {
        'sms': _smsModel != null,
        'url': _urlModel != null,
        'bert': _bertModel != null,
        'lstm': _lstmModel != null,
      },
      'onlineServiceStatus': _onlineService.getServiceStatus(),
    };
  }
  
  /// Get service capabilities
  Map<String, bool> getServiceCapabilities() {
    return {
      'canWorkOffline': _serviceMode == MLServiceMode.offline || 
                       _serviceMode == MLServiceMode.hybrid,
      'canWorkOnline': _serviceMode == MLServiceMode.online || 
                      _serviceMode == MLServiceMode.hybrid,
      'hasInternetConnection': _connectivityService.isOnline,
      'hasOfflineModels': _smsModel != null || _lstmModel != null || _bertModel != null,
      'hasRustDistilBERT': _rustMLService.isInitialized,
      'hasOnlineApiKeys': _onlineService.getServiceStatus()['hasHuggingFaceKey'] ||
                         _onlineService.getServiceStatus()['hasGoogleCloudKey'] ||
                         _onlineService.getServiceStatus()['hasCustomApiKey'],
    };
  }
  
  /// Force ML-based detection (avoid rule-based fallback)
  Future<PhishingDetection> analyzeSmsMLOnly(SmsMessage message) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Extract URLs from message first
      final urls = extractUrls(message.body);
      final messageWithUrls = message.copyWith(extractedUrls: urls);
      
      // Try Rust DistilBERT first
      if (_rustMLService.isInitialized) {
        try {
          final result = await _rustMLService.analyzeSms(messageWithUrls);
          if (kDebugMode) {
            print('🤖 ML-only: Rust DistilBERT analysis completed (confidence: ${result.confidence})');
          }
          return result;
        } catch (e) {
          if (kDebugMode) {
            print('❌ ML-only: Rust DistilBERT failed: $e');
          }
        }
      }
      
      // Try online ML services
      if (_connectivityService.isOnline) {
        try {
          final result = await _enhancedOnlineService.analyzeSms(messageWithUrls);
          if (kDebugMode) {
            print('🌐 ML-only: Enhanced online analysis completed (confidence: ${result.confidence})');
          }
          return result;
        } catch (e) {
          if (kDebugMode) {
            print('❌ ML-only: Enhanced online failed: $e');
          }
        }
        
        try {
          final result = await _onlineService.analyzeSms(messageWithUrls);
          if (kDebugMode) {
            print('🌐 ML-only: Legacy online analysis completed (confidence: ${result.confidence})');
          }
          return result;
        } catch (e) {
          if (kDebugMode) {
            print('❌ ML-only: Legacy online failed: $e');
          }
        }
      }
      
      // If all ML services fail, return a low-confidence result instead of rule-based
      return PhishingDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        messageId: message.id,
        confidence: 0.0,
        type: PhishingType.content,
        indicators: ['ML services unavailable'],
        reason: 'All ML-based detection services failed',
        detectedAt: DateTime.now(),
      );
      
    } catch (e) {
      print('❌ Error in ML-only analysis: $e');
      return PhishingDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        messageId: message.id,
        confidence: 0.0,
        type: PhishingType.content,
        indicators: ['Analysis error'],
        reason: 'ML analysis failed: $e',
        detectedAt: DateTime.now(),
      );
    }
  }
}
