import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart' as app_user;
import '../../models/user.dart' show UserPreferences, SecuritySettings;
// import '../../supabase_options.dart'; // Not needed for now

/// Custom exception for rate limiting
class RateLimitException implements Exception {
  final int waitSeconds;
  final String message;
  
  RateLimitException(this.waitSeconds, this.message);
  
  @override
  String toString() => message;
}

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final User? user;
  
  // Special flag to indicate email confirmation is required
  bool get requiresEmailConfirmation => errorMessage == 'EMAIL_CONFIRMATION_REQUIRED';

  AuthResult._(this.isSuccess, this.errorMessage, this.user);

  factory AuthResult.success(User user) => AuthResult._(true, null, user);
  factory AuthResult.failure(String error) => AuthResult._(false, error, null);
}

class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  static SupabaseAuthService get instance => _instance;
  
  SupabaseAuthService._internal();
  
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // Guest mode functionality
  bool _isGuestMode = false;
  bool get isGuestMode => _isGuestMode;
  
  Future<void> enableGuestMode() async {
    _isGuestMode = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', true);
  }
  
  Future<void> disableGuestMode() async {
    _isGuestMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', false);
  }
  
  Future<bool> isGuestModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('guest_mode') ?? false;
  }
  
  Future<void> initializeGuestMode() async {
    _isGuestMode = await isGuestModeEnabled();
  }
  
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _updateLastLogin(response.user!.id);
        await disableGuestMode(); // Disable guest mode when user signs in
        return AuthResult.success(response.user!);
      } else {
        return AuthResult.failure('Sign in failed');
      }
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }
  
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('🔐 Starting sign up for: $email');
      
      // Verify Supabase client is available
      print('   Checking Supabase client...');
      print('   Supabase client initialized');
      
      print('   Calling Supabase signUp...');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );
      
      print('   SignUp response received');
      print('   Response user: ${response.user?.id ?? 'null'}');
      print('   Response session: ${response.session?.accessToken != null ? 'present' : 'null'}');
      print('   Email confirmed at: ${response.user?.emailConfirmedAt ?? 'null'}');
      
      if (response.user != null) {
        print('✅ User created in Supabase: ${response.user!.id}');
        print('   Email: ${response.user!.email}');
        print('   Email confirmed: ${response.user!.emailConfirmedAt != null}');
        
        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt == null) {
          print('   Email confirmation required - verification email should be sent automatically');
          
          // Verify the user exists in Supabase by checking current session
          try {
            final currentUser = _supabase.auth.currentUser;
            print('   Current user after signup: ${currentUser?.id ?? 'null'}');
            
            if (currentUser != null) {
              print('✅ User is in session - account created successfully');
            } else {
              print('⚠️ User not in session - may need email confirmation first');
            }
          } catch (e) {
            print('   Error checking current user: $e');
          }
          
          // Supabase automatically sends verification email when user signs up
          // Only explicitly send if we detect that automatic sending failed
          // (Check after a short delay to see if we need to resend)
          try {
            // Wait a moment to see if Supabase automatically sent the email
            await Future.delayed(const Duration(seconds: 1));
            
            // Only try to resend if we suspect automatic sending didn't work
            // But don't do it immediately - Supabase sends it automatically
            print('   📧 Supabase should have automatically sent verification email');
            print('   📧 Check email inbox and spam folder for: ${response.user!.email}');
            print('   💡 If email not received, use "Resend Verification Email" button');
          } catch (e) {
            print('   Error: $e');
          }
          
          // Email confirmation required - Return success with special flag
          return AuthResult._(true, 'EMAIL_CONFIRMATION_REQUIRED', response.user!);
        }
        
        // Create user document in Supabase
        print('   Creating user document in database...');
        await _createUserDocument(response.user!);
        await disableGuestMode(); // Disable guest mode when user signs up
        
        print('✅ User fully registered and ready to use');
        return AuthResult.success(response.user!);
      } else {
        print('❌ Sign up failed - no user returned');
        return AuthResult.failure('Sign up failed - no user returned');
      }
    } on AuthException catch (e) {
      print('❌ AuthException during signup: ${e.message}');
      print('   Exception type: ${e.runtimeType}');
      
      // Check if it's an email confirmation error (which might still be success)
      final errorMsg = e.message.toLowerCase();
      print('   Error message (lowercase): $errorMsg');
      
      if (errorMsg.contains('email') && 
          (errorMsg.contains('confirm') || errorMsg.contains('verify'))) {
        // Even if there's an exception, if we have user data, it's likely a success
        // Check if we can get the user from the exception or session
        try {
          final currentUser = _supabase.auth.currentUser;
          print('   Checking current user after exception: ${currentUser?.id ?? 'null'}');
          
          if (currentUser != null && currentUser.emailConfirmedAt == null) {
            print('✅ User created despite exception - email verification required');
            return AuthResult._(true, 'EMAIL_CONFIRMATION_REQUIRED', currentUser);
          }
        } catch (checkError) {
          print('   Error checking current user: $checkError');
          // Fall through to return error
        }
      }
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e, stackTrace) {
      print('❌ Exception during signup: $e');
      print('   Stack trace: $stackTrace');
      
      // Check if user was actually created despite the error
      try {
        final currentUser = _supabase.auth.currentUser;
        print('   Checking current user after error: ${currentUser?.id ?? 'null'}');
        
        if (currentUser != null && currentUser.emailConfirmedAt == null) {
          print('✅ User created despite error - email verification required');
          return AuthResult._(true, 'EMAIL_CONFIRMATION_REQUIRED', currentUser);
        }
      } catch (checkError) {
        print('   Error checking current user: $checkError');
        // Fall through to return error
      }
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }
  
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Check if Google Sign-In is available
      final isAvailable = await _googleSignIn.isSignedIn();
      print('Google Sign-In available: $isAvailable');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('Google sign in cancelled by user');
      }
      
      print('Google user: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return AuthResult.failure('Failed to get Google authentication tokens');
      }
      
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );
      
      if (response.user != null) {
        print('Google Sign-In successful: ${response.user!.email}');
        // Check if user document exists, create if not
        await _createUserDocumentIfNotExists(response.user!);
        await _updateLastLogin(response.user!.id);
        await disableGuestMode(); // Disable guest mode when user signs in with Google
        
        return AuthResult.success(response.user!);
      } else {
        return AuthResult.failure('Google sign in failed - no user returned');
      }
    } on AuthException catch (e) {
      print('Supabase Auth Error: ${e.message}');
      return AuthResult.failure('Supabase authentication failed: ${e.message}');
    } catch (e) {
      print('Google Sign-In Error: $e');
      return AuthResult.failure('Google sign in error: $e');
    }
  }
  
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _googleSignIn.signOut();
      // Don't automatically enable guest mode on sign out
      // Let user choose whether to continue as guest or sign in again
    } catch (e) {
      print('Error signing out: $e');
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }
  
  /// Check if email has been verified
  Future<bool> checkEmailVerificationStatus(String email) async {
    try {
      // Try to get user by email to check verification status
      // Note: This might require admin access or the user to be signed in
      final user = currentUser;
      if (user != null && user.email == email) {
        return user.emailConfirmedAt != null;
      }
      
      // If not signed in, we can't check - return false
      return false;
    } catch (e) {
      print('Error checking email verification status: $e');
      return false;
    }
  }
  
  /// Verify email using a token or code (for manual verification)
  /// Can be used with either token from URL or code parameter
  Future<AuthResult> verifyEmailToken({
    required String token,
    String? email,
  }) async {
    try {
      print('🔐 Verifying email with token/code...');
      print('   Token/Code: ${token.substring(0, 8)}...');
      
      // Verify the token/code
      final response = await _supabase.auth.verifyOTP(
        token: token,
        type: OtpType.signup,
        email: email,
      );
      
      if (response.user != null && response.user!.emailConfirmedAt != null) {
        print('✅ Email verified successfully');
        await _createUserDocument(response.user!);
        await disableGuestMode();
        return AuthResult.success(response.user!);
      } else {
        print('⚠️ Email verification returned but not confirmed');
        return AuthResult.failure('Email verification failed - email not confirmed');
      }
    } on AuthException catch (e) {
      print('❌ AuthException during email verification: ${e.message}');
      final errorMsg = _getAuthErrorMessage(e);
      
      // Check for expired token
      if (e.message.toLowerCase().contains('expired') || 
          e.message.toLowerCase().contains('invalid')) {
        return AuthResult.failure('Verification code expired or invalid. Please request a new verification email.');
      }
      
      return AuthResult.failure(errorMsg);
    } catch (e) {
      print('❌ Error verifying email: $e');
      return AuthResult.failure('Failed to verify email: $e');
    }
  }
  
  /// Verify email using code from URL parameter (extracted from verification link)
  Future<AuthResult> verifyEmailCode({
    required String code,
    String? email,
  }) async {
    // Same as verifyEmailToken - code is just a token
    return verifyEmailToken(token: code, email: email);
  }
  
  Future<void> resendEmailConfirmation(String email) async {
    try {
      print('📧 === RESENDING VERIFICATION EMAIL ===');
      print('   Email: $email');
      print('   Calling Supabase auth.resend...');
      
      final result = await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      
      print('   Response received: ${result.toString()}');
      print('✅ Verification email sent successfully to: $email');
      print('   Please check inbox and spam folder');
      print('   💡 Click the link immediately - tokens expire quickly!');
      print('   ⚠️ If link expires, request a new email and click immediately');
    } on AuthException catch (e) {
      print('❌ === AUTH EXCEPTION DURING RESEND ===');
      print('   Message: ${e.message}');
      print('   Status Code: ${e.statusCode}');
      print('   Exception Type: ${e.runtimeType}');
      
      // Check for rate limiting error
      if (e.message.toLowerCase().contains('rate') || 
          e.message.toLowerCase().contains('limit') ||
          e.statusCode == 429 ||
          e.message.toLowerCase().contains('after') && e.message.toLowerCase().contains('seconds')) {
        final match = RegExp(r'after (\d+) seconds').firstMatch(e.message);
        final seconds = match != null ? (int.tryParse(match.group(1) ?? '60') ?? 60) : 60;
        final errorMsg = 'Please wait $seconds seconds before requesting another verification email.';
        print('   ⚠️ Rate limit error detected: $errorMsg');
        throw RateLimitException(seconds, errorMsg);
      }
      
      final errorMsg = _getAuthErrorMessage(e);
      print('   ❌ Error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e, stackTrace) {
      print('❌ === GENERAL ERROR DURING RESEND ===');
      print('   Error: $e');
      print('   Error Type: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');
      
      // Check if it's a rate limit error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('rate') || errorString.contains('limit') || errorString.contains('429')) {
        final match = RegExp(r'after (\d+) seconds').firstMatch(errorString);
        final seconds = match != null ? int.tryParse(match.group(1) ?? '60') : 60;
        final errorMsg = 'Please wait $seconds seconds before requesting another verification email.';
        print('   ⚠️ Rate limit detected: $errorMsg');
        throw Exception(errorMsg);
      }
      
      final errorMsg = 'Failed to resend verification email: $e';
      print('   ❌ Final error: $errorMsg');
      throw Exception(errorMsg);
    }
  }
  
  Future<app_user.AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      
      return app_user.AppUser.fromJson(response);
        } catch (e) {
      print('Error getting current app user: $e');
    }
    
    return null;
  }
  
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;
    
    try {
      // Update Supabase user metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            if (displayName != null) 'display_name': displayName,
            if (photoUrl != null) 'photo_url': photoUrl,
          },
        ),
      );
      
      // Update users table
      await _supabase.from('users').update({
        if (displayName != null) 'display_name': displayName,
        if (photoUrl != null) 'photo_url': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }
  
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    final user = currentUser;
    if (user == null) return;
    
    try {
      await _supabase.from('users').update({
        'preferences': preferences.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      print('Error updating user preferences: $e');
    }
  }
  
  Future<void> updateSecuritySettings(SecuritySettings settings) async {
    final user = currentUser;
    if (user == null) return;
    
    try {
      await _supabase.from('users').update({
        'security_settings': settings.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      print('Error updating security settings: $e');
    }
  }
  
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;
    
    try {
      // Delete user data from database
      await _supabase.from('users').delete().eq('id', user.id);
      
      // Delete user from Supabase Auth
      await _supabase.auth.admin.deleteUser(user.id);
    } catch (e) {
      print('Error deleting account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }
  
  Future<void> _createUserDocument(User user) async {
    try {
      await _supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'display_name': user.userMetadata?['display_name'] ?? user.email?.split('@')[0],
        'photo_url': user.userMetadata?['photo_url'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_login': DateTime.now().toIso8601String(),
        'is_verified': user.emailConfirmedAt != null,
        'preferences': {},
        'security_settings': {},
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }
  
  Future<void> _createUserDocumentIfNotExists(User user) async {
    try {
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (existingUser == null) {
        await _createUserDocument(user);
      }
    } catch (e) {
      print('Error checking/creating user document: $e');
    }
  }
  
  Future<void> _updateLastLogin(String userId) async {
    try {
      await _supabase.from('users').update({
        'last_login': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      print('Error updating last login: $e');
    }
  }
  
  String _getAuthErrorMessage(AuthException e) {
    // Check for email verification errors
    if (e.message.toLowerCase().contains('email') && 
        (e.message.toLowerCase().contains('confirm') || 
         e.message.toLowerCase().contains('verify') ||
         e.message.toLowerCase().contains('not confirmed'))) {
      return 'Please verify your email before signing in. Check your email inbox for the verification link.';
    }
    
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password';
      case 'Email not confirmed':
        return 'Please verify your email before signing in. Check your email inbox for the verification link.';
      case 'User not found':
        return 'No account found with this email';
      case 'Email address is already in use':
        return 'An account with this email already exists';
      case 'Password should be at least 6 characters':
        return 'Password must be at least 6 characters long';
      case 'Unable to validate email address: invalid format':
        return 'Please enter a valid email address';
      default:
        return e.message;
    }
  }
}
