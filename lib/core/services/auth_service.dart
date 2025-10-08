import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart' as app_user;
// Import the specific types we need
import '../../models/user.dart' show UserPreferences, SecuritySettings;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  
  AuthService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _updateLastLogin(credential.user!.uid);
        await disableGuestMode(); // Disable guest mode when user signs in
        return AuthResult.success(credential.user!);
      } else {
        return AuthResult.failure('Sign in failed');
      }
    } on FirebaseAuthException catch (e) {
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
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName);
        
        // Create user document in Firestore
        await _createUserDocument(credential.user!);
        await disableGuestMode(); // Disable guest mode when user signs up
        
        return AuthResult.success(credential.user!);
      } else {
        return AuthResult.failure('Sign up failed');
      }
    } on FirebaseAuthException catch (e) {
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
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      print('Attempting Firebase authentication...');
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        print('Google Sign-In successful: ${userCredential.user!.email}');
        // Check if user document exists, create if not
        await _createUserDocumentIfNotExists(userCredential.user!);
        await _updateLastLogin(userCredential.user!.uid);
        await disableGuestMode(); // Disable guest mode when user signs in with Google
        
        return AuthResult.success(userCredential.user!);
      } else {
        return AuthResult.failure('Google sign in failed - no user returned');
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return AuthResult.failure('Firebase authentication failed: ${e.message}');
    } catch (e) {
      print('Google Sign-In Error: $e');
      return AuthResult.failure('Google sign in error: $e');
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      // Don't automatically enable guest mode on sign out
      // Let user choose whether to continue as guest or sign in again
    } catch (e) {
      print('Error signing out: $e');
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }
  
  Future<app_user.AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return app_user.AppUser.fromJson(doc.data()!);
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
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      
      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }
  
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    final user = currentUser;
    if (user == null) return;
    
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'preferences': preferences.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user preferences: $e');
    }
  }
  
  Future<void> updateSecuritySettings(SecuritySettings settings) async {
    final user = currentUser;
    if (user == null) return;
    
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'securitySettings': settings.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating security settings: $e');
    }
  }
  
  Future<void> _createUserDocument(User user) async {
    final appUser = app_user.AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      preferences: UserPreferences(),
      securitySettings: SecuritySettings(),
    );
    
    await _firestore.collection('users').doc(user.uid).set(appUser.toJson());
  }
  
  Future<void> _createUserDocumentIfNotExists(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _createUserDocument(user);
    }
  }
  
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }
  
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  
  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });
  
  factory AuthResult.success(User user) {
    return AuthResult._(
      isSuccess: true,
      user: user,
    );
  }
  
  factory AuthResult.failure(String errorMessage) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
