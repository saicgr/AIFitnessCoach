import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/api_constants.dart';
import '../models/user.dart';
import '../services/api_client.dart';

/// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Auth state holder
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Auth repository for handling authentication
class AuthRepository {
  final ApiClient _apiClient;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._apiClient)
      : _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: ApiConstants.googleWebClientId,
        );

  /// Sign in with Google
  Future<User> signInWithGoogle() async {
    try {
      debugPrint('🔍 [Auth] Starting Google Sign-In...');

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      debugPrint('✅ [Auth] Google Sign-In success: ${googleUser.email}');

      // Get auth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        throw Exception('Failed to get access token');
      }

      debugPrint('🔍 [Auth] Got access token, authenticating with backend...');

      // Authenticate with backend
      final response = await _apiClient.post(
        ApiConstants.auth,
        data: GoogleAuthRequest(accessToken: accessToken).toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = User.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [Auth] Backend auth success: ${user.id}');

        // Save user ID and token
        await _apiClient.setUserId(user.id);
        await _apiClient.setAuthToken(accessToken);

        return user;
      } else {
        throw Exception('Backend authentication failed');
      }
    } catch (e) {
      debugPrint('❌ [Auth] Sign-in error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _apiClient.clearAuth();
      debugPrint('✅ [Auth] Sign-out success');
    } catch (e) {
      debugPrint('❌ [Auth] Sign-out error: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return _apiClient.isAuthenticated();
  }

  /// Get current user from backend
  Future<User?> getCurrentUser() async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return null;

      final response = await _apiClient.get('${ApiConstants.users}/$userId');
      if (response.statusCode == 200) {
        return User.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Auth] Get current user error: $e');
      return null;
    }
  }

  /// Restore session from stored token
  Future<User?> restoreSession() async {
    try {
      final isAuth = await _apiClient.isAuthenticated();
      if (!isAuth) return null;

      return getCurrentUser();
    } catch (e) {
      debugPrint('❌ [Auth] Restore session error: $e');
      return null;
    }
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  /// Initialize - check for existing session
  Future<void> _init() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.restoreSession();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signInWithGoogle();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update user in state
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = state.copyWith(user: user);
      }
    } catch (e) {
      debugPrint('❌ [Auth] Refresh user error: $e');
    }
  }
}
