import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Service to manage internet connectivity and online/offline states
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;
  
  ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  bool _isOnline = false;
  bool _isInitialized = false;
  
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  /// Stream of connectivity changes
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  /// Current online status
  bool get isOnline => _isOnline;
  
  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        await _checkConnectivity();
      },
    );
    
    _isInitialized = true;
    
    if (kDebugMode) {
      print('Connectivity Service initialized - Online: $_isOnline');
    }
  }
  
  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    
    if (connectivityResult == ConnectivityResult.none) {
      _updateConnectionStatus(false);
      return;
    }
    
    // Even if connected to WiFi/mobile, check if internet is actually accessible
    final hasInternet = await _hasInternetAccess();
    _updateConnectionStatus(hasInternet);
  }
  
  /// Test actual internet access
  Future<bool> _hasInternetAccess() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Internet access check failed: $e');
      }
      return false;
    }
  }
  
  /// Update connection status and notify listeners
  void _updateConnectionStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectivityController.add(_isOnline);
      
      if (kDebugMode) {
        print('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
      }
    }
  }
  
  /// Force connectivity check
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isOnline;
  }
  
  /// Test connection to specific API endpoint
  Future<bool> testApiConnection(String apiUrl) async {
    if (!_isOnline) return false;
    
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 15));
      
      return response.statusCode == 200 || response.statusCode == 401; // 401 means API is accessible but needs auth
    } catch (e) {
      if (kDebugMode) {
        print('API connection test failed for $apiUrl: $e');
      }
      return false;
    }
  }
  
  /// Get connection quality (rough estimate)
  Future<ConnectionQuality> getConnectionQuality() async {
    if (!_isOnline) return ConnectionQuality.none;
    
    try {
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 10));
      
      stopwatch.stop();
      
      if (response.statusCode != 200) return ConnectionQuality.poor;
      
      final responseTime = stopwatch.elapsedMilliseconds;
      
      if (responseTime < 1000) return ConnectionQuality.excellent;
      if (responseTime < 3000) return ConnectionQuality.good;
      if (responseTime < 5000) return ConnectionQuality.fair;
      return ConnectionQuality.poor;
      
    } catch (e) {
      return ConnectionQuality.poor;
    }
  }
  
  /// Get connectivity information
  Future<Map<String, dynamic>> getConnectivityInfo() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final quality = await getConnectionQuality();
    
    return {
      'isOnline': _isOnline,
      'connectionType': connectivityResult.toString(),
      'quality': quality.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    _isInitialized = false;
  }
}

/// Connection quality levels
enum ConnectionQuality {
  none,
  poor,
  fair,
  good,
  excellent,
}
