import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../../models/user.dart';

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

// Current app user provider
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return await AuthService.instance.getCurrentAppUser();
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

// Login provider
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref.read(authServiceProvider));
});

// Register provider
final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(ref.read(authServiceProvider));
});

// Google sign in provider
final googleSignInProvider = StateNotifierProvider<GoogleSignInNotifier, GoogleSignInState>((ref) {
  return GoogleSignInNotifier(ref.read(authServiceProvider));
});

// User preferences provider
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences?>((ref) {
  return UserPreferencesNotifier(ref.read(authServiceProvider));
});

// Security settings provider
final securitySettingsProvider = StateNotifierProvider<SecuritySettingsNotifier, SecuritySettings?>((ref) {
  return SecuritySettingsNotifier(ref.read(authServiceProvider));
});

// Login state and notifier
class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  
  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
  
  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthService _authService;
  
  LoginNotifier(this._authService) : super(const LoginState());
  
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
    }
  }
  
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Register state and notifier
class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  
  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
  
  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  final AuthService _authService;
  
  RegisterNotifier(this._authService) : super(const RegisterState());
  
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    
    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
    }
  }
  
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Google sign in state and notifier
class GoogleSignInState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  
  const GoogleSignInState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
  
  GoogleSignInState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return GoogleSignInState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class GoogleSignInNotifier extends StateNotifier<GoogleSignInState> {
  final AuthService _authService;
  
  GoogleSignInNotifier(this._authService) : super(const GoogleSignInState());
  
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _authService.signInWithGoogle();
    
    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
    }
  }
  
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// User preferences notifier
class UserPreferencesNotifier extends StateNotifier<UserPreferences?> {
  final AuthService _authService;
  
  UserPreferencesNotifier(this._authService) : super(null);
  
  Future<void> updatePreferences(UserPreferences preferences) async {
    await _authService.updateUserPreferences(preferences);
    state = preferences;
  }
  
  Future<void> loadPreferences() async {
    final appUser = await _authService.getCurrentAppUser();
    state = appUser?.preferences;
  }
}

// Security settings notifier
class SecuritySettingsNotifier extends StateNotifier<SecuritySettings?> {
  final AuthService _authService;
  
  SecuritySettingsNotifier(this._authService) : super(null);
  
  Future<void> updateSecuritySettings(SecuritySettings settings) async {
    await _authService.updateSecuritySettings(settings);
    state = settings;
  }
  
  Future<void> loadSecuritySettings() async {
    final appUser = await _authService.getCurrentAppUser();
    state = appUser?.securitySettings;
  }
}
