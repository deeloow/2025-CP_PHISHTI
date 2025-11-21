/// API Configuration for PhishTi Detector
/// 
/// This file manages API URLs for different environments.
/// Update the production URL when deploying to VPS.
class ApiConfig {
  // Development URLs
  static const String devLocalhost = 'http://localhost:5000';
  static const String devAndroidEmulator = 'http://10.0.2.2:5000';
  
  // Production URL - UPDATE THIS WITH YOUR VPS DOMAIN/IP
  static const String productionUrl = 'http://72.61.148.38:5000';  // ✅ VPS URL configured
  
  // Alternative: Use IP address if no domain (not recommended for production)
  // static const String productionUrl = '72.61.148.38:5000';
  
  /// Get API URL based on environment
  /// 
  /// Priority:
  /// 1. Environment variable (API_BASE_URL)
  /// 2. Production flag (PRODUCTION)
  /// 3. Platform detection (Android emulator, iOS, etc.)
  static String get apiUrl {
    // Check for environment variable override (highest priority)
    const apiOverride = String.fromEnvironment('API_BASE_URL');
    if (apiOverride.isNotEmpty) {
      return apiOverride;
    }
    
    // Check for production flag
    const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
    if (isProduction) {
      return productionUrl;
    }
    
    // Default: Use platform-specific development URL
    // This will be handled in main.dart based on platform detection
    return devLocalhost;
  }
  
  /// Check if using production API
  static bool get isProduction {
    const apiOverride = String.fromEnvironment('API_BASE_URL');
    if (apiOverride.isNotEmpty) {
      return !apiOverride.contains('localhost') && 
             !apiOverride.contains('10.0.2.2') &&
             !apiOverride.contains('127.0.0.1');
    }
    
    const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
    return isProduction;
  }
  
  /// Get API health check URL
  static String get healthCheckUrl => '$apiUrl/health';
  
  /// Get API predict URL
  static String get predictUrl => '$apiUrl/predict';
  
  /// Get API batch predict URL
  static String get batchPredictUrl => '$apiUrl/batch_predict';
}

