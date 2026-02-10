import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../models/user.dart' as app_user;
import '../providers/consistency_provider.dart';
import '../providers/fasting_provider.dart';
import '../providers/gym_profile_provider.dart';
import '../providers/nutrition_preferences_provider.dart';
import '../providers/scores_provider.dart';
import '../providers/today_workout_provider.dart';
import '../providers/xp_provider.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/workout_repository.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';
import '../services/device_info_service.dart';
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

        // Log if new user with support friend
        if (user.isFirstLogin && user.hasSupportFriend) {
          debugPrint('🎉 [Auth] New user signed up! FitWiz Support auto-added as friend');
        }

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

  /// Sign in with email and password
  Future<app_user.User> signInWithEmail(String email, String password) async {
    try {
      debugPrint('🔍 [Auth] Starting Email Sign-In for $email...');

      // Sign in with Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception('Invalid email or password');
      }

      final supabaseAccessToken = response.session!.accessToken;
      debugPrint('✅ [Auth] Supabase email auth success, authenticating with backend...');

      // Authenticate with backend
      final backendResponse = await _apiClient.post(
        '${ApiConstants.users}/auth/email',
        data: {'email': email, 'password': password},
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
      debugPrint('❌ [Auth] Email sign-in error: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<app_user.User> signUpWithEmail(String email, String password, {String? name}) async {
    try {
      debugPrint('🔍 [Auth] Starting Email Sign-Up for $email...');

      // Sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name ?? ''},
      );

      if (response.user == null) {
        throw Exception('Failed to create account. Email may already be in use.');
      }

      final supabaseAccessToken = response.session?.accessToken;
      if (supabaseAccessToken == null) {
        // User may need to verify email first
        throw Exception('Please check your email to verify your account.');
      }

      debugPrint('✅ [Auth] Supabase signup success, creating user in backend...');

      // Create user in backend
      final backendResponse = await _apiClient.post(
        '${ApiConstants.users}/auth/email/signup',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      if (backendResponse.statusCode == 200 || backendResponse.statusCode == 201) {
        final user = app_user.User.fromJson(backendResponse.data as Map<String, dynamic>);
        debugPrint('✅ [Auth] Backend user created: ${user.id}');

        // Save user ID and token
        await _apiClient.setUserId(user.id);
        await _apiClient.setAuthToken(supabaseAccessToken);

        return user;
      } else {
        throw Exception('Backend user creation failed');
      }
    } catch (e) {
      debugPrint('❌ [Auth] Email sign-up error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      debugPrint('🔍 [Auth] Sending password reset email to $email...');

      // Use backend endpoint which handles Supabase
      await _apiClient.post(
        '${ApiConstants.users}/auth/forgot-password',
        data: {'email': email},
      );

      debugPrint('✅ [Auth] Password reset email sent');
    } catch (e) {
      debugPrint('❌ [Auth] Password reset error: $e');
      // Don't rethrow - always show success for security
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      await _apiClient.clearAuth();

      // Clear all cached data for next user
      await DataCacheService.instance.clearAll();
      // Clear ALL in-memory caches
      TodayWorkoutNotifier.clearCache();
      XPNotifier.clearCache();
      GymProfilesNotifier.clearCache();
      WorkoutsNotifier.clearCache();
      ScoresNotifier.clearCache();
      ConsistencyNotifier.clearCache();
      NutritionPreferencesNotifier.clearCache();
      HydrationNotifier.clearCache();
      FastingNotifier.clearCache();

      // Clear local onboarding flags so next user gets fresh experience
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');

      debugPrint('✅ [Auth] Sign-out success (all caches cleared)');
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
        final user = app_user.User.fromJson(data);

        // Cache user for faster app startup
        await _cacheUser(user);

        return user;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Auth] Get current user error: $e');
      return null;
    }
  }

  /// Load cached user profile
  Future<app_user.User?> _getCachedUser() async {
    try {
      final cached = await DataCacheService.instance.getCached(
        DataCacheService.userProfileKey,
      );
      if (cached != null) {
        return app_user.User.fromJson(cached);
      }
    } catch (e) {
      debugPrint('⚠️ [Auth] Cache parse error: $e');
    }
    return null;
  }

  /// Save user to cache
  Future<void> _cacheUser(app_user.User user) async {
    try {
      await DataCacheService.instance.cache(
        DataCacheService.userProfileKey,
        user.toJson(),
      );
    } catch (e) {
      debugPrint('⚠️ [Auth] Cache save error: $e');
    }
  }

  /// Restore session from Supabase or stored token with cache-first pattern
  ///
  /// Returns (cachedUser, freshUser) where cachedUser is immediately available
  /// and freshUser is fetched in the background
  Future<app_user.User?> restoreSession() async {
    try {
      // First check Supabase session
      final session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('🔍 [Auth] Found Supabase session, refreshing...');

        // Update stored auth token
        await _apiClient.setAuthToken(session.accessToken);

        // IMPORTANT: Look up user by Supabase Auth ID to get the correct users.id
        // session.user.id is the Supabase Auth UUID, NOT the users table UUID
        final authId = session.user.id;
        debugPrint('🔍 [Auth] Looking up user by auth_id: $authId');

        final response = await _apiClient.get('${ApiConstants.users}/by-auth/$authId');

        if (response.statusCode == 200) {
          final user = app_user.User.fromJson(response.data as Map<String, dynamic>);

          // NOW set the correct user ID (from users table, not auth)
          await _apiClient.setUserId(user.id);
          debugPrint('✅ [Auth] Set correct user ID: ${user.id} (auth_id was: $authId)');

          // Cache user for faster app startup
          await _cacheUser(user);

          // Sync credentials to watch on session restore (Android only)
          if (Platform.isAndroid) {
            _syncCredentialsToWatch(
              userId: user.id,
              authToken: session.accessToken,
              refreshToken: session.refreshToken,
            );
          }

          return user;
        } else {
          debugPrint('❌ [Auth] Failed to look up user by auth_id: ${response.statusCode}');
          return null;
        }
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

  /// Restore session with cache-first pattern for instant auth
  ///
  /// Returns cached user immediately if available, then fetches fresh in background
  Future<({app_user.User? cached, Future<app_user.User?> fresh})> restoreSessionWithCache() async {
    // Step 1: Try to load cached user instantly
    final cachedUser = await _getCachedUser();
    if (cachedUser != null) {
      debugPrint('⚡ [Auth] Loaded user from cache instantly: ${cachedUser.name}');

      // Step 1.5: Set user ID in secure storage from cached user
      // This ensures getUserId() works even before restoreSession() completes
      // Fixes race condition where home screen requests user ID before session restore finishes
      await _apiClient.setUserId(cachedUser.id);
      debugPrint('⚡ [Auth] Set user ID from cache: ${cachedUser.id}');
    }

    // Step 2: Create future for fresh data (runs in background)
    final freshFuture = restoreSession();

    return (cached: cachedUser, fresh: freshFuture);
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  /// Fire-and-forget device info update after successful auth
  void _updateDeviceInfo(String userId) {
    final service = DeviceInfoService(_repository._apiClient);
    service.updateIfNeeded(userId: userId).catchError((e) {
      debugPrint('⚠️ [Auth] Device info update failed: $e');
    });
  }

  /// Initialize with cache-first pattern for instant auth
  Future<void> _init() async {
    try {
      // Step 1: Try to load cached user instantly (no loading state)
      final result = await _repository.restoreSessionWithCache();

      if (result.cached != null) {
        // Show cached user immediately - no loading spinner!
        debugPrint('⚡ [Auth] Authenticated from cache instantly');
        state = AuthState(status: AuthStatus.authenticated, user: result.cached);
        _updateDeviceInfo(result.cached!.id);

        // Step 2: Fetch fresh data in background and update silently
        result.fresh.then((freshUser) {
          if (freshUser != null && mounted) {
            debugPrint('🔄 [Auth] Updated with fresh user data');
            state = AuthState(status: AuthStatus.authenticated, user: freshUser);
          }
        }).catchError((e) {
          debugPrint('⚠️ [Auth] Background refresh failed: $e');
          // Keep cached user, don't show error
        });
      } else {
        // No cache - show loading and wait for API
        state = state.copyWith(status: AuthStatus.loading);
        final user = await result.fresh;
        if (user != null) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
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
      _updateDeviceInfo(user.id);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signInWithEmail(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _updateDeviceInfo(user.id);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password, {String? name}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signUpWithEmail(email, password, name: name);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _updateDeviceInfo(user.id);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordReset(email);
    } catch (e) {
      // Silently handle - always show success for security
      debugPrint('❌ [Auth] Password reset error: $e');
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
      // Update cache to persist across app restarts
      await _repository._cacheUser(updatedUser);
      debugPrint('✅ [Auth] Marked onboarding as complete (cached)');
    }
  }

  /// Mark coach as selected
  Future<void> markCoachSelected() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(coachSelected: true);
      state = state.copyWith(user: updatedUser);
      // Update cache to persist across app restarts
      await _repository._cacheUser(updatedUser);
      debugPrint('✅ [Auth] Marked coach as selected (cached)');
    }
  }

  /// Mark paywall as completed
  Future<void> markPaywallComplete() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(paywallCompleted: true);
      state = state.copyWith(user: updatedUser);
      // Update cache to persist across app restarts
      await _repository._cacheUser(updatedUser);
      debugPrint('✅ [Auth] Marked paywall as completed (cached)');
    }
  }

  /// Update user profile fields
  /// [updates] - Map of field names to new values (e.g., {'weight_unit': 'lbs'})
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (state.user == null) {
      throw Exception('No user logged in');
    }

    try {
      final userId = state.user!.id;
      await _repository._apiClient.patch(
        '${ApiConstants.users}/$userId',
        data: updates,
      );

      // Refresh user data from server to get updated values
      await refreshUser();
      debugPrint('✅ [Auth] Updated user profile: $updates');
    } catch (e) {
      debugPrint('❌ [Auth] Update user profile error: $e');
      rethrow;
    }
  }

  /// Reset coach selection (for start over)
  Future<void> markCoachNotSelected() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(coachSelected: false);
      state = state.copyWith(user: updatedUser);
      // Update cache to persist across app restarts
      await _repository._cacheUser(updatedUser);
      debugPrint('✅ [Auth] Reset coach selection (cached)');
    }
  }

  /// Reset onboarding (for start over)
  Future<void> markOnboardingIncomplete() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(onboardingCompleted: false);
      state = state.copyWith(user: updatedUser);
      // Update cache to persist across app restarts
      await _repository._cacheUser(updatedUser);
      debugPrint('✅ [Auth] Reset onboarding status (cached)');
    }
  }

  /// Reset paywall (for start over)
  Future<void> markPaywallIncomplete() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(paywallCompleted: false);
      state = state.copyWith(user: updatedUser);
      // Update cache to persist across app restarts
      await _repository._cacheUser(updatedUser);
      debugPrint('✅ [Auth] Reset paywall status (cached)');
    }
  }
}
