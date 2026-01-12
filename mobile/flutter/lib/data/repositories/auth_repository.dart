import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../models/user.dart' as app_user;
import '../services/api_client.dart';
import '../services/wearable_service.dart';

/// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Auth state holder
class AuthState {
  final AuthStatus status;
  final app_user.User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    app_user.User? user,
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
  final SupabaseClient _supabase;

  AuthRepository(this._apiClient)
      : _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: ApiConstants.googleWebClientId,
        ),
        _supabase = Supabase.instance.client;

  /// Sign in with Google via Supabase
  Future<app_user.User> signInWithGoogle() async {
    try {
      debugPrint('🔍 [Auth] Starting Google Sign-In...');

      // Sign out first to ensure account picker is shown (not auto-selecting previous account)
      // This is important for new users who want to choose which Google account to use
      await _googleSignIn.signOut();

      // Trigger Google Sign-In flow - will now show account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      debugPrint('✅ [Auth] Google Sign-In success: ${googleUser.email}');

      // Get auth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      debugPrint('🔍 [Auth] Got ID token, authenticating with Supabase...');

      // Exchange Google ID token for Supabase session
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      if (response.session == null) {
        throw Exception('Failed to get Supabase session');
      }

      final supabaseAccessToken = response.session!.accessToken;
      debugPrint('✅ [Auth] Supabase auth success, authenticating with backend...');

      // Authenticate with backend using Supabase access token
      final backendResponse = await _apiClient.post(
        ApiConstants.auth,
        data: app_user.GoogleAuthRequest(accessToken: supabaseAccessToken).toJson(),
      );

      if (backendResponse.statusCode == 200 || backendResponse.statusCode == 201) {
        final user = app_user.User.fromJson(backendResponse.data as Map<String, dynamic>);
        debugPrint('✅ [Auth] Backend auth success: ${user.id}');

        // Save user ID and token
        await _apiClient.setUserId(user.id);
        await _apiClient.setAuthToken(supabaseAccessToken);

        // Sync credentials to watch (Android only, non-blocking)
        if (Platform.isAndroid) {
          _syncCredentialsToWatch(
            userId: user.id,
            authToken: supabaseAccessToken,
            refreshToken: response.session?.refreshToken,
          );
        }

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
      await _supabase.auth.signOut();
      await _apiClient.clearAuth();

      // Clear local onboarding flags so next user gets fresh experience
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');

      debugPrint('✅ [Auth] Sign-out success');
    } catch (e) {
      debugPrint('❌ [Auth] Sign-out error: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    // Check both Supabase session and stored token
    final supabaseSession = _supabase.auth.currentSession;
    final hasStoredToken = await _apiClient.isAuthenticated();
    return supabaseSession != null || hasStoredToken;
  }

  /// Sync credentials to watch (fire-and-forget, non-blocking)
  void _syncCredentialsToWatch({
    required String userId,
    required String authToken,
    String? refreshToken,
  }) {
    // Fire and forget - don't block login flow
    WearableService.instance.syncUserCredentials(
      userId: userId,
      authToken: authToken,
      refreshToken: refreshToken,
    ).then((success) {
      if (success) {
        debugPrint('✅ [Auth] Credentials synced to watch');
      } else {
        debugPrint('⚠️ [Auth] Watch credential sync skipped (not connected)');
      }
    }).catchError((e) {
      debugPrint('⚠️ [Auth] Watch credential sync failed: $e');
    });
  }

  /// Get current user from backend
  Future<app_user.User?> getCurrentUser() async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return null;

      final response = await _apiClient.get('${ApiConstants.users}/$userId');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('🔍 [Auth] User data from API: onboarding_completed=${data['onboarding_completed']}, coach_selected=${data['coach_selected']}, paywall_completed=${data['paywall_completed']}');
        return app_user.User.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Auth] Get current user error: $e');
      return null;
    }
  }

  /// Restore session from Supabase or stored token
  Future<app_user.User?> restoreSession() async {
    try {
      // First check Supabase session
      final session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('🔍 [Auth] Found Supabase session, refreshing...');

        // Update stored token
        await _apiClient.setAuthToken(session.accessToken);

        // Get user from backend
        final user = await getCurrentUser();

        // Sync credentials to watch on session restore (Android only)
        if (user != null && Platform.isAndroid) {
          _syncCredentialsToWatch(
            userId: user.id,
            authToken: session.accessToken,
            refreshToken: session.refreshToken,
          );
        }

        return user;
      }

      // Fall back to stored token
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
  void updateUser(app_user.User user) {
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

  /// Mark onboarding as complete
  Future<void> markOnboardingComplete() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(onboardingCompleted: true);
      state = state.copyWith(user: updatedUser);
      debugPrint('✅ [Auth] Marked onboarding as complete');
    }
  }

  /// Mark coach as selected
  Future<void> markCoachSelected() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(coachSelected: true);
      state = state.copyWith(user: updatedUser);
      debugPrint('✅ [Auth] Marked coach as selected');
    }
  }

  /// Mark paywall as completed
  Future<void> markPaywallComplete() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(paywallCompleted: true);
      state = state.copyWith(user: updatedUser);
      debugPrint('✅ [Auth] Marked paywall as completed');
    }
  }

  /// Reset coach selection (for start over)
  Future<void> markCoachNotSelected() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(coachSelected: false);
      state = state.copyWith(user: updatedUser);
      debugPrint('✅ [Auth] Reset coach selection');
    }
  }

  /// Reset onboarding (for start over)
  Future<void> markOnboardingIncomplete() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(onboardingCompleted: false);
      state = state.copyWith(user: updatedUser);
      debugPrint('✅ [Auth] Reset onboarding status');
    }
  }

  /// Reset paywall (for start over)
  Future<void> markPaywallIncomplete() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(paywallCompleted: false);
      state = state.copyWith(user: updatedUser);
      debugPrint('✅ [Auth] Reset paywall status');
    }
  }
}
