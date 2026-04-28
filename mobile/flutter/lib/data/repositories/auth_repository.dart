import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../models/ai_profile_payload.dart';
import '../models/user.dart' as app_user;
import '../providers/consistency_provider.dart';
import '../providers/fasting_provider.dart';
import '../providers/gym_profile_provider.dart';
import '../providers/nutrition_preferences_provider.dart';
import '../providers/referral_provider.dart';
import '../providers/scores_provider.dart';
import '../providers/today_workout_provider.dart';
import '../providers/xp_provider.dart';
import '../../screens/onboarding/pre_auth_quiz_data.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/measurements_repository.dart';
import '../repositories/workout_repository.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';
import '../services/device_info_service.dart';
import '../services/pending_referral_service.dart';
import '../services/wearable_service.dart';
import 'package:fitwiz/core/constants/branding.dart';

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
  return AuthNotifier(repository, ref);
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
          debugPrint('🎉 [Auth] New user signed up! ${Branding.appName} Support auto-added as friend');
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
      MeasurementsNotifier.clearCache();

      // Clear local onboarding flags so next user gets fresh experience
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      await prefs.remove('paywall_completed');

      // SECURITY: Clear watch credentials on logout
      try {
        await WearableService.instance.syncUserCredentials(
          userId: '',
          authToken: '',
          refreshToken: '',
        );
        debugPrint('✅ [Auth] Watch credentials cleared');
      } catch (_) {
        // Non-critical — watch may not be connected
      }

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

        int? lookupStatus;
        try {
          final response = await _apiClient.get('${ApiConstants.users}/by-auth/$authId');
          lookupStatus = response.statusCode;

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
          }
        } catch (e) {
          // Dio throws on non-2xx by default — extract the status code.
          final match = RegExp(r'status code of (\d+)').firstMatch(e.toString());
          if (match != null) lookupStatus = int.tryParse(match.group(1) ?? '');
          debugPrint('❌ [Auth] by-auth lookup failed (status=$lookupStatus): $e');
        }

        // 404 means the Supabase Auth account exists but the backend `users`
        // row was deleted (or never created — orphan auth user). Clear the
        // stale session so we don't hit the same 404 on every cold start.
        if (lookupStatus == 404) {
          debugPrint('⚠️ [Auth] No backend user for auth_id=$authId — clearing stale Supabase session');
          try {
            await _supabase.auth.signOut();
          } catch (_) {}
          await _apiClient.clearAuth();
          return null;
        }

        // Any other error (500, network) — leave session alone, caller retries
        return null;
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

      // Step 1.6: Eagerly set the auth token from the live Supabase session.
      // Without this, API calls made immediately after the cached user is shown
      // use whatever stale token is in secure storage, causing 401 errors.
      // restoreSession() sets the token too, but it's async and may not complete
      // before the first screen renders and makes API requests.
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _apiClient.setAuthToken(session.accessToken);
        debugPrint('⚡ [Auth] Eagerly set auth token from live Supabase session');
      }
    }

    // Step 2: Create future for fresh data (runs in background)
    final freshFuture = restoreSession();

    return (cached: cachedUser, fresh: freshFuture);
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(const AuthState()) {
    _init();
  }

  /// SharedPreferences key tracking the last user.id that signed in on this
  /// device. Used to detect account switches: if a different user signs in,
  /// the previous user's pre-auth quiz answers are stale and must be cleared
  /// before being applied to the new account.
  static const _lastAuthUserIdKey = 'lastAuthUserId';

  /// Clear pre-auth quiz state. Only called on sign-out — quiz answers must
  /// persist through the entire onboarding flow (personal-info, coach-selection,
  /// paywall) because those screens read from preAuthQuizProvider and the
  /// backend POST happens later in coach_selection_screen._submitUserPreferencesAndFlags.
  /// Clearing on isNewUser sign-in caused users to be bounced back to /pre-auth-quiz
  /// because the router checks quizData.isComplete before personal-info.
  Future<void> _clearPreAuthQuiz() async {
    try {
      await _ref.read(preAuthQuizProvider.notifier).clear();
    } catch (e) {
      debugPrint('⚠️ [Auth] Failed to clear pre-auth quiz state: $e');
    }
  }

  /// Post-sign-in housekeeping for pre-auth quiz state. Runs synchronously
  /// before [state] flips to authenticated so the router's onboarding-step
  /// check sees the correct quiz state.
  ///
  /// Three jobs:
  /// 1. Detect account switch (different user.id than last sign-in on this
  ///    device) and clear the previous user's stale quiz answers before they
  ///    bleed into the new account.
  /// 2. For users still in onboarding with local quiz data: POST it to
  ///    backend immediately so it survives uninstall/reinstall. (Previously
  ///    only happened later in coach_selection — users who reinstalled mid-flow
  ///    lost their answers.)
  /// 3. For users still in onboarding with EMPTY local quiz: hydrate from
  ///    backend's saved preferences (re-install / cross-device case).
  ///
  /// All errors are caught and logged — never fail sign-in over quiz sync.
  Future<void> _syncQuizAfterSignIn(app_user.User user) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final previousUserId = sp.getString(_lastAuthUserIdKey);

      if (previousUserId != null && previousUserId != user.id) {
        debugPrint('🔄 [Auth] Account switch detected ($previousUserId → ${user.id}), clearing stale quiz');
        await _clearPreAuthQuiz();
      }
      await sp.setString(_lastAuthUserIdKey, user.id);

      // User has finished onboarding — quiz state no longer relevant.
      if (user.isPaywallComplete) return;

      final notifier = _ref.read(preAuthQuizProvider.notifier);
      final quizData = await notifier.ensureLoaded();

      if (quizData.isComplete) {
        // Local has quiz answers — back them up to the server now so they
        // survive an uninstall/reinstall mid-onboarding. coach_selection's
        // POST will re-submit later (idempotent), so this is best-effort.
        await _backupQuizToBackend(user.id, quizData);
      } else {
        // Local quiz is empty but user is mid-onboarding. Try to recover
        // their previously-saved answers from the backend.
        await notifier.hydrateFromUserPreferences(user.toJson());
        debugPrint('💧 [Auth] Hydrated pre-auth quiz from backend preferences for ${user.id}');
      }
    } catch (e) {
      debugPrint('⚠️ [Auth] _syncQuizAfterSignIn failed (non-fatal): $e');
    }
  }

  /// Best-effort POST of local pre-auth quiz answers to the backend.
  /// Non-blocking failure — coach_selection_screen retries the same POST after
  /// the user picks a coach. This early POST exists purely for resilience to
  /// uninstall/reinstall during onboarding.
  Future<void> _backupQuizToBackend(String userId, PreAuthQuizData quizData) async {
    try {
      final payload = AIProfilePayloadBuilder.buildPayload(quizData);
      // Personal info fields not in AI payload but accepted by /preferences endpoint
      if (quizData.gender != null) payload['gender'] = quizData.gender;
      if (quizData.age != null) payload['age'] = quizData.age;
      if (quizData.heightCm != null) payload['height_cm'] = quizData.heightCm;
      if (quizData.weightKg != null) payload['weight_kg'] = quizData.weightKg;
      if (quizData.workoutDays != null) payload['workout_days'] = quizData.workoutDays;
      if (quizData.activityLevel != null) payload['activity_level'] = quizData.activityLevel;

      await _repository._apiClient.post(
        '${ApiConstants.users}/$userId/preferences',
        data: payload,
      );
      debugPrint('✅ [Auth] Pre-auth quiz backed up to backend for $userId');
    } catch (e) {
      debugPrint('⚠️ [Auth] Quiz backup POST failed (will retry at coach selection): $e');
    }
  }

  /// Apply any referral code captured pre-auth (deep link, onboarding
  /// paste, manual entry from a friend). Called after every successful
  /// sign-in / sign-up. Silent on failure — the user can still redeem
  /// manually from Settings → Invite Friends → Enter a code.
  Future<void> _flushPendingReferral() async {
    try {
      final code = await PendingReferralService.read();
      if (code == null || code.isEmpty) return;
      debugPrint('🔍 [Auth] Flushing pending referral code: $code');
      final result = await _ref
          .read(referralApplyProvider.notifier)
          .apply(code);
      if (result.success) {
        await PendingReferralService.clear();
        debugPrint('✅ [Auth] Applied pending referral: $code');
      } else {
        debugPrint('⚠️ [Auth] Referral apply failed: ${result.message}');
        // Leave pending so user can retry from Settings; only clear on
        // explicit success or on sign-out.
      }
    } catch (e) {
      debugPrint('⚠️ [Auth] Failed to flush pending referral: $e');
    }
  }

  /// Fire-and-forget device info update after successful auth.
  ///
  /// Two responsibilities:
  ///   1. Refresh the user's device columns (model, OS, screen size) — the
  ///      legacy 7-day-cached path.
  ///   2. Register the device fingerprint for security alerting. The
  ///      backend emails the user the first time it sees a new fingerprint
  ///      under their account (new-phone, stolen-token, OkHttp client, etc).
  ///
  /// [isFreshSignin] is true when called from a successful login flow and
  /// false on cache-restore / app warm-launch — the security endpoint uses
  /// this hint when deciding alert behavior.
  void _updateDeviceInfo(String userId, {bool isFreshSignin = false}) {
    final service = DeviceInfoService(_repository._apiClient);
    service.updateIfNeeded(userId: userId).catchError((e) {
      debugPrint('⚠️ [Auth] Device info update failed: $e');
    });
    service.trackSignInDevice(isFirstSignin: isFreshSignin).catchError((e) {
      debugPrint('⚠️ [Auth] track-device failed: $e');
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
      // Quiz sync (account-switch detection, backup, hydrate) runs BEFORE
      // state flips to authenticated so the router sees correct quiz state
      // on its next redirect. See _syncQuizAfterSignIn for the 3 jobs.
      await _syncQuizAfterSignIn(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _updateDeviceInfo(user.id);
      // Fire-and-forget referral flush — never block auth UX on this.
      unawaited(_flushPendingReferral());
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
      await _syncQuizAfterSignIn(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _updateDeviceInfo(user.id, isFreshSignin: true);
      unawaited(_flushPendingReferral());
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
      await _syncQuizAfterSignIn(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _updateDeviceInfo(user.id, isFreshSignin: true);
      unawaited(_flushPendingReferral());
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
      await _clearPreAuthQuiz();
      // Clear the last-auth-user fingerprint so the next sign-in is treated
      // as a fresh session (no false-positive account-switch detection).
      try {
        final sp = await SharedPreferences.getInstance();
        await sp.remove(_lastAuthUserIdKey);
      } catch (_) {}
      await PendingReferralService.clear();
      // Reset live XP state — the provider persists (not autoDispose), so
      // stale userXp/lastLevelUp would survive logout and cause false
      // level-up animations on re-login.
      _ref.read(xpProvider.notifier).resetState();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update user in state and persist to cache
  void updateUser(app_user.User user) {
    state = state.copyWith(user: user);
    _repository._cacheUser(user);
  }

  /// Refresh user data from server
  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        // Force new AuthState to ensure StateNotifier notifies listeners
        // even if Equatable comparison has edge cases
        state = AuthState(status: AuthStatus.authenticated, user: user);
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
      // Don't cache here — full user with preferences will be cached by refreshUser()
      debugPrint('✅ [Auth] Marked onboarding as complete (in-memory)');
    }
  }

  /// Mark coach as selected
  Future<void> markCoachSelected() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(coachSelected: true);
      state = state.copyWith(user: updatedUser);
      // Don't cache here — full user with preferences will be cached by refreshUser()
      debugPrint('✅ [Auth] Marked coach as selected (in-memory)');
    }
  }

  /// Mark paywall as completed
  Future<void> markPaywallComplete() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(paywallCompleted: true);
      state = state.copyWith(user: updatedUser);
      // Don't cache here — full user with preferences will be cached by refreshUser()
      debugPrint('✅ [Auth] Marked paywall as completed (in-memory)');
    }
  }

  /// Optimistically flip the in-memory workout weight unit ('kg' or 'lbs')
  /// without awaiting a server round-trip. Use when a UI affordance needs
  /// the unit-flip to be reflected across consumers of
  /// `workoutWeightUnitProvider` instantly (e.g. the active-workout screen's
  /// displayWeight converter). The caller is responsible for calling
  /// `updateUserProfile` in the background to persist.
  void setWorkoutWeightUnitOptimistic(String unit) {
    final u = state.user;
    if (u == null) return;
    final next = u.copyWith(workoutWeightUnit: unit);
    state = state.copyWith(user: next);
  }

  /// Update user profile fields
  /// [updates] - Map of field names to new values (e.g., {'weight_unit': 'lbs'})
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (state.user == null) {
      throw Exception('No user logged in');
    }

    try {
      final userId = state.user!.id;
      await _repository._apiClient.put(
        '${ApiConstants.users}/$userId',
        data: updates,
      );

      // Refresh user data from server, BUT re-apply the fields we just
      // wrote so a lagging /users GET (read-after-write inconsistency on
      // the backend) doesn't revert the value the user just picked.
      await refreshUser();
      if (state.user != null) {
        state = state.copyWith(user: _applyOverrides(state.user!, updates));
      }
      debugPrint('✅ [Auth] Updated user profile: $updates');
    } catch (e) {
      debugPrint('❌ [Auth] Update user profile error: $e');
      rethrow;
    }
  }

  /// Re-apply outgoing `updates` on top of a freshly-fetched user so the
  /// user's just-toggled preference isn't clobbered by stale server data.
  /// Only handles keys the UI toggles inline; extend as new toggles need it.
  app_user.User _applyOverrides(
    app_user.User u,
    Map<String, dynamic> updates,
  ) {
    var next = u;
    if (updates.containsKey('workout_weight_unit')) {
      next = next.copyWith(
          workoutWeightUnit: updates['workout_weight_unit'] as String?);
    }
    if (updates.containsKey('weight_unit')) {
      next = next.copyWith(weightUnit: updates['weight_unit'] as String?);
    }
    if (updates.containsKey('measurement_unit')) {
      next = next.copyWith(
          measurementUnit: updates['measurement_unit'] as String?);
    }
    if (updates.containsKey('in_vacation_mode')) {
      next = next.copyWith(
          inVacationMode: updates['in_vacation_mode'] as bool?);
    }
    if (updates.containsKey('vacation_start_date')) {
      final raw = updates['vacation_start_date'] as String?;
      next = next.copyWith(
          vacationStartDate: (raw == null || raw.isEmpty) ? null : raw);
    }
    if (updates.containsKey('vacation_end_date')) {
      final raw = updates['vacation_end_date'] as String?;
      next = next.copyWith(
          vacationEndDate: (raw == null || raw.isEmpty) ? null : raw);
    }
    return next;
  }

  /// Reset coach selection (for start over)
  Future<void> markCoachNotSelected() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(coachSelected: false);
      state = state.copyWith(user: updatedUser);
      // Don't cache here — full user with preferences will be cached by refreshUser()
      debugPrint('✅ [Auth] Reset coach selection (in-memory)');
    }
  }

  /// Reset onboarding (for start over)
  Future<void> markOnboardingIncomplete() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(onboardingCompleted: false);
      state = state.copyWith(user: updatedUser);
      // Don't cache here — full user with preferences will be cached by refreshUser()
      debugPrint('✅ [Auth] Reset onboarding status (in-memory)');
    }
  }

  /// Reset paywall (for start over)
  Future<void> markPaywallIncomplete() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(paywallCompleted: false);
      state = state.copyWith(user: updatedUser);
      // Don't cache here — full user with preferences will be cached by refreshUser()
      debugPrint('✅ [Auth] Reset paywall status (in-memory)');
    }
  }
}
