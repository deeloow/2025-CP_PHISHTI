import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart' as app_user;
import '../../models/user.dart' show UserPreferences, SecuritySettings;
// import '../../supabase_options.dart'; // Not needed for now

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final User? user;

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
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );
      
      if (response.user != null) {
        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt == null) {
          // Email confirmation required - user needs to check their email
          return AuthResult.failure('Please check your email and click the confirmation link to complete registration.');
        }
        
        // Create user document in Supabase
        await _createUserDocument(response.user!);
        await disableGuestMode(); // Disable guest mode when user signs up
        
        return AuthResult.success(response.user!);
      } else {
        return AuthResult.failure('Sign up failed');
      }
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
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
  
  Future<void> resendEmailConfirmation(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
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
      
      if (response != null) {
        return app_user.AppUser.fromJson(response);
      }
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
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password';
      case 'Email not confirmed':
        return 'Please verify your email before signing in';
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
