import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';
import 'online_ml_service.dart';
import 'connectivity_service.dart';

// Model types enum
enum ModelType { lstm, bert, distilbert, ensemble }

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
  
  // Online service instance
  final OnlineMLService _onlineService = OnlineMLService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  
  // Model configuration
  static const String _smsModelPath = 'assets/models/sms_classifier.tflite';
  static const String _urlModelPath = 'assets/models/url_classifier.tflite';
  static const String _bertModelPath = 'assets/models/bert_phishing_classifier.tflite';
  static const String _lstmModelPath = 'assets/models/lstm_phishing_classifier.tflite';
  static const int _maxSequenceLength = 128;
  static const int _vocabSize = 10000;
  
  
  // Preprocessing
  final Map<String, int> _wordToIndex = {};
  final Map<int, String> _indexToWord = {};
  bool _vocabLoaded = false;
  
  Future<void> initialize({
    ModelType modelType = ModelType.lstm,
    MLServiceMode serviceMode = MLServiceMode.hybrid,
    String? huggingFaceApiKey,
    String? googleCloudApiKey,
    String? customApiKey,
  }) async {
    if (_isInitialized) return;
    
    _currentModelType = modelType;
    _serviceMode = serviceMode;
    
    try {
      // Initialize connectivity service
      await _connectivityService.initialize();
      
      // Initialize online service if needed
      if (_serviceMode == MLServiceMode.online || _serviceMode == MLServiceMode.hybrid) {
        await _onlineService.initialize(
          huggingFaceApiKey: huggingFaceApiKey,
          googleCloudApiKey: googleCloudApiKey,
          customApiKey: customApiKey,
        );
      }
      
      // Initialize offline models if needed
      if (_serviceMode == MLServiceMode.offline || _serviceMode == MLServiceMode.hybrid) {
        await _initializeOfflineModels(modelType);
      }
      
      _isInitialized = true;
      print('ML Service initialized in ${_serviceMode.toString()} mode');
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
        case ModelType.lstm:
          _lstmModel ??= await _loadModel(_lstmModelPath);
          break;
        case ModelType.ensemble:
          _bertModel ??= await _loadModel(_bertModelPath);
          _lstmModel ??= await _loadModel(_lstmModelPath);
          break;
        default:
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
  
  Future<void> _loadVocabulary() async {
    try {
      final vocabData = await rootBundle.loadString('assets/models/vocab.json');
      final vocabMap = json.decode(vocabData) as Map<String, dynamic>;
      
      for (final entry in vocabMap.entries) {
        final word = entry.key;
        final index = entry.value as int;
        _wordToIndex[word] = index;
        _indexToWord[index] = word;
      }
      
      _vocabLoaded = true;
    } catch (e) {
      print('Error loading vocabulary: $e');
      _vocabLoaded = false;
    }
  }
  
  Future<PhishingDetection> analyzeSms(SmsMessage message) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Extract URLs from message first
      final urls = extractUrls(message.body);
      final messageWithUrls = message.copyWith(extractedUrls: urls);
      
      // Determine which analysis method to use based on service mode and connectivity
      switch (_serviceMode) {
        case MLServiceMode.online:
          return await _analyzeOnlineOnly(messageWithUrls);
        case MLServiceMode.offline:
          return await _analyzeOfflineOnly(messageWithUrls);
        case MLServiceMode.hybrid:
          return await _analyzeHybrid(messageWithUrls);
      }
    } catch (e) {
      print('Error analyzing SMS: $e');
      return await _analyzeWithRules(message);
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
      return await _onlineService.analyzeSms(message);
    } catch (e) {
      print('Online analysis failed: $e');
      return await _analyzeWithRules(message);
    }
  }
  
  /// Analyze using offline models only
  Future<PhishingDetection> _analyzeOfflineOnly(SmsMessage message) async {
    try {
      // For mobile testing, use rule-based detection only
      return await _analyzeWithRules(message);
    } catch (e) {
      print('Offline analysis failed: $e');
      return await _analyzeWithRules(message);
    }
  }
  
  /// Analyze using hybrid approach (online preferred, offline fallback)
  Future<PhishingDetection> _analyzeHybrid(SmsMessage message) async {
    // If online, try online analysis first
    if (_connectivityService.isOnline) {
      try {
        final onlineResult = await _onlineService.analyzeSms(message);
        
        // If online analysis gives high confidence result, use it
        if (onlineResult.confidence > 0.8) {
          return onlineResult;
        }
        
        // For mobile testing, skip ML combination
        // Use online result or fallback to rules
        
        return onlineResult;
      } catch (e) {
        print('Online analysis failed in hybrid mode: $e');
        // Fall through to offline analysis
      }
    }
    
    // Fallback to offline analysis
    return await _analyzeOfflineOnly(message);
  }
  
  /// Combine online and offline analysis results
  PhishingDetection _combineResults(
    PhishingDetection onlineResult,
    PhishingDetection offlineResult,
    SmsMessage message,
  ) {
    // Weighted average of confidences (online gets higher weight)
    final combinedConfidence = (onlineResult.confidence * 0.7) + (offlineResult.confidence * 0.3);
    
    // Combine indicators
    final combinedIndicators = <String>{
      ...onlineResult.indicators,
      ...offlineResult.indicators,
    }.toList();
    
    // Use higher confidence type
    final combinedType = onlineResult.confidence > offlineResult.confidence 
        ? onlineResult.type 
        : offlineResult.type;
    
    return PhishingDetection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messageId: message.id,
      confidence: combinedConfidence,
      type: combinedType,
      indicators: combinedIndicators,
      reason: 'Hybrid analysis (online + offline)',
      detectedAt: DateTime.now(),
    );
  }
  
  Future<PhishingDetection?> _analyzeWithML(SmsMessage message) async {
    try {
      switch (_currentModelType) {
        case ModelType.bert:
          return await _analyzeWithBERT(message);
        case ModelType.lstm:
          return await _analyzeWithLSTM(message);
        case ModelType.ensemble:
          return await _analyzeWithEnsemble(message);
        default:
          return await _analyzeWithLSTM(message);
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
          indicators: _extractIndicators(message.body),
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
          indicators: _extractIndicators(message.body),
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
            indicators: [...lstmResult.indicators, ...bertResult.indicators].toSet().toList(),
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
  
  Future<PhishingDetection> _analyzeWithRules(SmsMessage message) async {
    final indicators = <String>[];
    double confidence = 0.0;
    PhishingType type = PhishingType.content;
    String reason = 'Rule-based analysis';
    
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
    
    // Check for suspicious URLs with enhanced analysis
    final urls = extractUrls(message.body);
    for (final url in urls) {
      final urlAnalysis = await analyzeUrl(url);
      if (urlAnalysis['isSuspicious']) {
        indicators.add('Suspicious URL: $url (${urlAnalysis['threatLevel']})');
        indicators.addAll(urlAnalysis['indicators'].cast<String>());
        confidence += urlAnalysis['confidence'] * 0.5; // Weight URL analysis
        type = PhishingType.url;
      }
    }
    
    // Check sender patterns
    if (_isSuspiciousSender(message.sender)) {
      indicators.add('Suspicious sender pattern');
      confidence += 0.2;
      type = PhishingType.sender;
    }
    
    // Check for common phishing patterns
    if (_hasPhishingPatterns(message.body)) {
      indicators.add('Common phishing patterns detected');
      confidence += 0.3;
    }
    
    if (confidence > 0.5) {
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
    
    return PhishingDetection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messageId: message.id,
      confidence: confidence,
      type: type,
      indicators: indicators,
      reason: 'No threats detected',
      detectedAt: DateTime.now(),
    );
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
  
  // Extract URLs from text
  List<String> _extractUrls(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    return urlRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }
  
  List<String> _extractIndicators(String text) {
    final indicators = <String>[];
    
    // Check for urgent language
    if (_containsUrgentLanguage(text)) {
      indicators.add('Urgent language');
    }
    
    // Check for suspicious keywords
    indicators.addAll(_getSuspiciousKeywords(text));
    
    // Check for suspicious URLs
    final urls = _extractUrls(text);
    for (final url in urls) {
      if (_isSuspiciousUrl(url)) {
        indicators.add('Suspicious URL');
      }
    }
    
    return indicators;
  }
  
  bool _containsUrgentLanguage(String text) {
    final urgentWords = [
      'urgent', 'immediately', 'act now', 'limited time',
      'expires', 'verify', 'confirm', 'suspended',
      'blocked', 'security', 'fraud', 'unauthorized'
    ];
    
    final lowerText = text.toLowerCase();
    return urgentWords.any((word) => lowerText.contains(word));
  }
  
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

  bool _isSuspiciousUrl(String url) {
    // Legacy method - now uses the enhanced analysis
    return _isUrlShortener(url) || _isSuspiciousDomain(url) || _hasPhishingKeywordsInUrl(url);
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
      'account', 'suspended', 'limited', 'urgent', 'click'
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
  
  bool _isSuspiciousSender(String sender) {
    // Check for suspicious sender patterns
    final suspiciousPatterns = [
      RegExp(r'^\d{4,}$'), // Only numbers
      RegExp(r'^[A-Z]{2,}$'), // Only uppercase letters
      RegExp(r'.*@.*\..*'), // Email-like patterns in SMS
    ];
    
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(sender));
  }
  
  bool _hasPhishingPatterns(String text) {
    final patterns = [
      RegExp(r'click\s+here', caseSensitive: false),
      RegExp(r'verify\s+your\s+account', caseSensitive: false),
      RegExp(r'update\s+your\s+information', caseSensitive: false),
      RegExp(r'your\s+account\s+has\s+been', caseSensitive: false),
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(text));
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
      'hasOnlineApiKeys': _onlineService.getServiceStatus()['hasHuggingFaceKey'] ||
                         _onlineService.getServiceStatus()['hasGoogleCloudKey'] ||
                         _onlineService.getServiceStatus()['hasCustomApiKey'],
    };
  }
}
