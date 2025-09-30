import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../models/sms_message.dart';
import '../../models/phishing_detection.dart';

class MLService {
  static final MLService _instance = MLService._internal();
  static MLService get instance => _instance;
  
  MLService._internal();
  
  Interpreter? _smsModel;
  Interpreter? _urlModel;
  bool _isInitialized = false;
  
  // Model configuration
  static const String _smsModelPath = 'assets/models/sms_classifier.tflite';
  static const String _urlModelPath = 'assets/models/url_classifier.tflite';
  static const int _maxSequenceLength = 128;
  static const int _vocabSize = 10000;
  
  // Preprocessing
  final Map<String, int> _wordToIndex = {};
  final Map<int, String> _indexToWord = {};
  bool _vocabLoaded = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load SMS classification model
      _smsModel = await _loadModel(_smsModelPath);
      
      // Load URL classification model
      _urlModel = await _loadModel(_urlModelPath);
      
      // Load vocabulary
      await _loadVocabulary();
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing ML service: $e');
      // Fallback to rule-based detection if models fail
      _isInitialized = true;
    }
  }
  
  Future<Interpreter> _loadModel(String modelPath) async {
    try {
      return await Interpreter.fromAsset(modelPath);
    } catch (e) {
      print('Error loading model $modelPath: $e');
      // Return a dummy interpreter for fallback
      return await Interpreter.fromAsset('assets/models/dummy_model.tflite');
    }
  }
  
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
      // Try ML-based detection first
      if (_smsModel != null && _vocabLoaded) {
        final mlResult = await _analyzeWithML(message);
        if (mlResult != null) {
          return mlResult;
        }
      }
      
      // Fallback to rule-based detection
      return _analyzeWithRules(message);
    } catch (e) {
      print('Error analyzing SMS: $e');
      return _analyzeWithRules(message);
    }
  }
  
  Future<PhishingDetection?> _analyzeWithML(SmsMessage message) async {
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
      _smsModel!.run(input, output);
      
      final confidence = output[0][1]; // Probability of being phishing
      final isPhishing = confidence > 0.7;
      
      if (isPhishing) {
        return PhishingDetection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          messageId: message.id,
          confidence: confidence,
          type: PhishingType.content,
          indicators: _extractIndicators(message.body),
          reason: 'ML model detected suspicious content',
          detectedAt: DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      print('Error in ML analysis: $e');
      return null;
    }
  }
  
  PhishingDetection _analyzeWithRules(SmsMessage message) {
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
  
  List<int> _textToSequence(String text) {
    final words = text.split(' ');
    final sequence = <int>[];
    
    for (final word in words) {
      final index = _wordToIndex[word] ?? _wordToIndex['<UNK>'] ?? 0;
      sequence.add(index);
    }
    
    return sequence;
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
  
  List<String> _extractUrls(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    return urlRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }
  
  bool _isSuspiciousUrl(String url) {
    // Check for suspicious domains
    final suspiciousDomains = [
      'bit.ly', 'tinyurl.com', 'goo.gl', 't.co',
      'shortened-url', 'suspicious-domain'
    ];
    
    final lowerUrl = url.toLowerCase();
    return suspiciousDomains.any((domain) => lowerUrl.contains(domain));
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
    _isInitialized = false;
  }
}
