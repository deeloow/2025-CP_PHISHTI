import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fallback authentication service for when Firebase is not configured
class FallbackAuthService {
  static final FallbackAuthService _instance = FallbackAuthService._internal();
  static FallbackAuthService get instance => _instance;
  
  FallbackAuthService._internal();
  
  static const String _userKey = 'fallback_user';
  static const String _isLoggedInKey = 'is_logged_in';
  
  /// Check if user is logged in using fallback method
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
  
  /// Get current user email
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }
  
  /// Sign in with email and password (fallback method)
  Future<FallbackAuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Simple validation
      if (email.isEmpty || password.isEmpty) {
        return FallbackAuthResult.failure('Email and password are required');
      }
      
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return FallbackAuthResult.failure('Please enter a valid email address');
      }
      
      if (password.length < 6) {
        return FallbackAuthResult.failure('Password must be at least 6 characters');
      }
      
      // Simulate authentication delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Store user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, email);
      await prefs.setBool(_isLoggedInKey, true);
      
      return FallbackAuthResult.success(email);
    } catch (e) {
      return FallbackAuthResult.failure('Sign in failed: $e');
    }
  }
  
  /// Sign up with email and password (fallback method)
  Future<FallbackAuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Simple validation
      if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
        return FallbackAuthResult.failure('All fields are required');
      }
      
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return FallbackAuthResult.failure('Please enter a valid email address');
      }
      
      if (password.length < 6) {
        return FallbackAuthResult.failure('Password must be at least 6 characters');
      }
      
      // Simulate authentication delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Store user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, email);
      await prefs.setBool(_isLoggedInKey, true);
      
      return FallbackAuthResult.success(email);
    } catch (e) {
      return FallbackAuthResult.failure('Sign up failed: $e');
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
  
  /// Reset password (simulation)
  Future<FallbackAuthResult> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        return FallbackAuthResult.failure('Email is required');
      }
      
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return FallbackAuthResult.failure('Please enter a valid email address');
      }
      
      // Simulate password reset delay
      await Future.delayed(const Duration(seconds: 1));
      
      return FallbackAuthResult.success(email);
    } catch (e) {
      return FallbackAuthResult.failure('Password reset failed: $e');
    }
  }
}

class FallbackAuthResult {
  final bool isSuccess;
  final String? userEmail;
  final String? errorMessage;
  
  FallbackAuthResult._({
    required this.isSuccess,
    this.userEmail,
    this.errorMessage,
  });
  
  factory FallbackAuthResult.success(String email) {
    return FallbackAuthResult._(
      isSuccess: true,
      userEmail: email,
    );
  }
  
  factory FallbackAuthResult.failure(String errorMessage) {
    return FallbackAuthResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// Show Firebase configuration warning dialog
void showFirebaseConfigWarning(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('Firebase Not Configured'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Google Sign-In requires Firebase configuration. You can:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text('1. Configure Firebase (see GOOGLE_SIGNIN_SETUP.md)'),
          Text('2. Use Email/Password authentication instead'),
          SizedBox(height: 12),
          Text(
            'For now, please use Email/Password authentication.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
