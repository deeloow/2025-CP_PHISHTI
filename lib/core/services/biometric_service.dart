import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  static BiometricService get instance => _instance;
  
  BiometricService._internal();
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricEnabled = false;
  bool _isInitialized = false;
  
  bool get isBiometricEnabled => _isBiometricEnabled;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _isInitialized = true;
    } catch (e) {
      print('Error initializing biometric service: $e');
    }
  }
  
  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }
  
  /// Get available biometric types on the device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }
  
  /// Check if biometric authentication is enabled in app settings
  Future<bool> isBiometricEnabledInSettings() async {
    await initialize();
    return _isBiometricEnabled;
  }
  
  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      // Check if biometric is available
      if (!await isBiometricAvailable()) {
        throw Exception('Biometric authentication is not available on this device');
      }
      
      // Test biometric authentication
      final isAuthenticated = await authenticate(
        reason: 'Enable biometric authentication for PhishTi Detector',
        useErrorDialogs: true,
      );
      
      if (isAuthenticated) {
        // Save setting
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        _isBiometricEnabled = true;
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error enabling biometric: $e');
      return false;
    }
  }
  
  /// Disable biometric authentication
  Future<bool> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      _isBiometricEnabled = false;
      return true;
    } catch (e) {
      print('Error disabling biometric: $e');
      return false;
    }
  }
  
  /// Authenticate using biometric
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      if (!await isBiometricAvailable()) {
        throw Exception('Biometric authentication is not available');
      }
      
      final result = await _localAuth.authenticate(
        localizedReason: reason,
      );
      
      return result;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }
  
  /// Authenticate for app access (login/session)
  Future<bool> authenticateForAccess() async {
    if (!_isBiometricEnabled) return false;
    
    return await authenticate(
      reason: 'Authenticate to access PhishTi Detector',
      useErrorDialogs: true,
    );
  }
  
  /// Authenticate for sensitive operations
  Future<bool> authenticateForSensitiveOperation(String operation) async {
    if (!_isBiometricEnabled) return false;
    
    return await authenticate(
      reason: 'Authenticate to $operation',
      useErrorDialogs: true,
    );
  }
  
  /// Get biometric type display name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }
  
  /// Get all available biometric types as display names
  Future<List<String>> getAvailableBiometricNames() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.map((type) => getBiometricTypeName(type)).toList();
  }
  
  /// Check if device has fingerprint sensor
  Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }
  
  /// Check if device has face recognition
  Future<bool> hasFaceRecognition() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }
  
  /// Get user-friendly error message
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'notAvailable':
        return 'Biometric authentication is not available on this device';
      case 'notEnrolled':
        return 'No biometric data is enrolled. Please set up fingerprint or face unlock in device settings';
      case 'lockedOut':
        return 'Biometric authentication is locked. Please use your device PIN/pattern/password';
      case 'permanentlyLockedOut':
        return 'Biometric authentication is permanently locked. Please use your device PIN/pattern/password';
      case 'userCancel':
        return 'Authentication was cancelled';
      case 'authenticationFailed':
        return 'Authentication failed. Please try again';
      case 'systemCancel':
        return 'Authentication was cancelled by the system';
      default:
        return 'Biometric authentication failed. Please try again';
    }
  }
  
  /// Show biometric setup dialog
  Future<bool> showBiometricSetupDialog(BuildContext context) async {
    try {
      // Check availability
      if (!await isBiometricAvailable()) {
        _showErrorDialog(
          context,
          'Biometric Not Available',
          'Biometric authentication is not available on this device. Please ensure your device supports fingerprint or face recognition.',
        );
        return false;
      }
      
      // Get available biometrics
      final availableBiometrics = await getAvailableBiometricNames();
      final biometricText = availableBiometrics.join(' and ');
      
      // Show setup dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.fingerprint,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Enable Biometric Authentication'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your device supports $biometricText authentication.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Benefits of enabling biometric authentication:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Quick and secure app access'),
              const Text('• No need to remember passwords'),
              const Text('• Enhanced security for sensitive operations'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Your biometric data never leaves your device and is not stored by our app.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      
      if (result == true) {
        // Test biometric authentication
        final isAuthenticated = await authenticate(
          reason: 'Set up biometric authentication for PhishTi Detector',
          useErrorDialogs: true,
        );
        
        if (isAuthenticated) {
          // Enable biometric
          await enableBiometric();
          _showSuccessDialog(
            context,
            'Biometric Authentication Enabled',
            'You can now use $biometricText to quickly access your app.',
          );
          return true;
        } else {
          _showErrorDialog(
            context,
            'Setup Failed',
            'Failed to set up biometric authentication. Please try again.',
          );
          return false;
        }
      }
      
      return false;
    } catch (e) {
      _showErrorDialog(
        context,
        'Setup Error',
        'An error occurred while setting up biometric authentication: $e',
      );
      return false;
    }
  }
  
  /// Show biometric authentication dialog
  Future<bool> showBiometricAuthDialog(
    BuildContext context, {
    required String title,
    required String reason,
  }) async {
    try {
      if (!_isBiometricEnabled) {
        return false;
      }
      
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.fingerprint,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(reason),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Please authenticate...'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (result == true) {
        return await authenticateForAccess();
      }
      
      return false;
    } catch (e) {
      print('Error showing biometric auth dialog: $e');
      return false;
    }
  }
  
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
