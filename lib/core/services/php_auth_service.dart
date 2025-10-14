import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PhpAuthService {
  static final PhpAuthService _instance = PhpAuthService._internal();
  static PhpAuthService get instance => _instance;
  
  PhpAuthService._internal();
  
  // Change this to your PHP backend URL
  static const String _baseUrl = 'http://localhost:8081';
  
  String? _token;
  Map<String, dynamic>? _currentUser;
  
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = jsonDecode(userJson);
    }
  }
  
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'displayName': displayName,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return AuthResult.success(
          message: data['message'] ?? 'Registration successful',
          email: data['email'],
          emailSent: data['emailSent'] ?? false,
        );
      } else {
        return AuthResult.failure(data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }
  
  Future<AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        _token = data['token'];
        _currentUser = data['user'];
        
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('current_user', jsonEncode(_currentUser));
        
        return AuthResult.success(
          message: data['message'] ?? 'Email verified successfully',
          user: _currentUser,
          token: _token,
        );
      } else {
        return AuthResult.failure(data['error'] ?? 'Verification failed');
      }
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }
  
  Future<AuthResult> resendVerificationCode({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/resend.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return AuthResult.success(
          message: data['message'] ?? 'Verification code sent',
          emailSent: data['emailSent'] ?? false,
        );
      } else {
        return AuthResult.failure(data['error'] ?? 'Failed to resend code');
      }
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }
  
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        _token = data['token'];
        _currentUser = data['user'];
        
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('current_user', jsonEncode(_currentUser));
        
        return AuthResult.success(
          message: 'Login successful',
          user: _currentUser,
          token: _token,
        );
      } else {
        return AuthResult.failure(data['error'] ?? 'Login failed');
      }
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }
  
  Future<AuthResult> getCurrentUser() async {
    if (_token == null) {
      return AuthResult.failure('Not authenticated');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/me.php'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        _currentUser = data['user'];
        
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', jsonEncode(_currentUser));
        
        return AuthResult.success(
          message: 'User data retrieved',
          user: _currentUser,
        );
      } else {
        return AuthResult.failure(data['error'] ?? 'Failed to get user data');
      }
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }
  
  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/logout.php'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
        );
      } catch (e) {
        print('Error during logout: $e');
      }
    }
    
    _token = null;
    _currentUser = null;
    
    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
  }
}

class AuthResult {
  final bool isSuccess;
  final String? message;
  final String? errorMessage;
  final Map<String, dynamic>? user;
  final String? token;
  final String? email;
  final bool? emailSent;
  
  AuthResult._({
    required this.isSuccess,
    this.message,
    this.errorMessage,
    this.user,
    this.token,
    this.email,
    this.emailSent,
  });
  
  factory AuthResult.success({
    String? message,
    Map<String, dynamic>? user,
    String? token,
    String? email,
    bool? emailSent,
  }) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      user: user,
      token: token,
      email: email,
      emailSent: emailSent,
    );
  }
  
  factory AuthResult.failure(String errorMessage) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
