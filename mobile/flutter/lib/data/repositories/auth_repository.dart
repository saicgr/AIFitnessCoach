import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
import '../services/home_prewarmer.dart';
import '../services/nutrition_prewarmer.dart';
import '../services/social_prewarmer.dart';
import '../services/workout_completion_prewarmer.dart';
import '../services/workouts_prewarmer.dart';
import '../services/you_overview_prewarmer.dart';
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

  /// Sign in with Apple via Supabase. iOS / iPadOS only — guard at call site
  /// with `Platform.isIOS`. Apple sends fullName + email ONLY on the very
  /// first authorization for a given (Apple ID, app) pair; on every later
  /// sign-in those fields come back null. The Supabase user record is
  /// populated from the identity token's verified email claim, so we don't
  /// rely on the optional fullName.
  Future<app_user.User> signInWithApple() async {
    try {
      debugPrint('🍎 [Auth] Starting Apple Sign-In...');

      // Nonce: send sha256(rawNonce) to Apple, send rawNonce to Supabase.
      // Supabase verifies the identity token's `nonce` claim equals
      // sha256(rawNonce) — prevents replay attacks.
      final rawNonce = _generateAppleNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Apple Sign-In failed: missing identity token');
      }

      debugPrint('✅ [Auth] Apple credential received, exchanging with Supabase...');

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (response.session == null) {
        throw Exception('Failed to get Supabase session');
      }

      final supabaseAccessToken = response.session!.accessToken;
      debugPrint('✅ [Auth] Supabase auth success, authenticating with backend...');

      // Backend's /auth/google endpoint accepts any Supabase access token
      // regardless of upstream IdP. We additionally forward Apple-only
      // payload bits the backend needs for compliance:
      //   - apple_authorization_code: backend exchanges for refresh_token
      //     used at App Store-required /auth/revoke on account deletion.
      //   - apple_given_name / apple_family_name: Apple emits these ONLY on
      //     the first sign-in for a given (Apple ID, app) pair. If we don't
      //     forward them now, users.name lands empty and we can never
      //     recover the real name.
      final backendBody = <String, dynamic>{
        'access_token': supabaseAccessToken,
        if (credential.authorizationCode.isNotEmpty)
          'apple_authorization_code': credential.authorizationCode,
        if ((credential.givenName ?? '').isNotEmpty)
          'apple_given_name': credential.givenName,
        if ((credential.familyName ?? '').isNotEmpty)
          'apple_family_name': credential.familyName,
      };
      final backendResponse = await _apiClient.post(
        ApiConstants.auth,
        data: backendBody,
      );

      if (backendResponse.statusCode == 200 || backendResponse.statusCode == 201) {
        final user = app_user.User.fromJson(backendResponse.data as Map<String, dynamic>);
        debugPrint('✅ [Auth] Backend auth success: ${user.id}');

        if (user.isFirstLogin && user.hasSupportFriend) {
          debugPrint('🎉 [Auth] New user signed up via Apple! ${Branding.appName} Support auto-added as friend');
        }

        await _apiClient.setUserId(user.id);
        await _apiClient.setAuthToken(supabaseAccessToken);

        return user;
      } else {
        throw Exception('Backend authentication failed');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      // User canceled Apple sheet, or Apple denied. Treat the same as Google
      // cancel — surface a clean message rather than a stack trace.
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('Apple Sign-In was cancelled');
      }
      debugPrint('❌ [Auth] Apple authorization error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [Auth] Apple sign-in error: $e');
      rethrow;
    }
  }

  /// Cryptographically secure nonce for Sign in with Apple.
  String _generateAppleNonce([int length = 32]) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
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

  /// Sign up with email and password.
  ///
  /// `quizMetadata` carries pre-auth quiz answers (first_name, goal, days,
  /// weight) that get embedded into Supabase Auth user_metadata so the
  /// post-onboarding welcome email + Supabase auth templates can personalize
  /// without round-tripping back to the backend. Without this, Supabase's
  /// `user_metadata.full_name` was empty → welcome email said "Hey there".
  Future<app_user.User> signUpWithEmail(
    String email,
    String password, {
    String? name,
    Map<String, dynamic>? quizMetadata,
  }) async {
    try {
      debugPrint('🔍 [Auth] Starting Email Sign-Up for $email...');

      final firstName = (name ?? '').trim().split(RegExp(r'\s+')).first;
      final metadata = <String, dynamic>{
        'full_name': name ?? '',
        if (firstName.isNotEmpty) 'first_name': firstName,
        ...?quizMetadata,
      };

      // Sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
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

  /// Fully revoke the Google session for this device. Used only from the
  /// account-deletion path — a regular sign-out only calls signOut() so the
  /// account picker is shown on next login. disconnect() additionally
  /// revokes our app's grant on Google's side, which is the right behavior
  /// when the user is permanently destroying their account.
  Future<void> disconnectGoogle() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint('✅ [Auth] Google session disconnected');
    } catch (e) {
      // disconnect() throws if the user wasn't signed in via Google — safe
      // to ignore; we just want to ensure the grant is gone if it existed.
      debugPrint('⚠️ [Auth] Google disconnect skipped: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    // Cache wipes run in `finally` so a partial Supabase signOut failure
    // (network blip, expired token) cannot leave the previous user's
    // cached profile sitting in SharedPreferences. Without this, a flaky
    // sign-out followed by a fresh sign-in would surface the OLD user
    // on /home until the background restoreSession() completes.
    Object? signOutError;
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      await _apiClient.clearAuth();
    } catch (e) {
      // Capture but don't rethrow yet — we still need to clear local
      // caches so the next user doesn't see stale data. Surface the
      // error after cleanup (matches the pre-fix behavior).
      signOutError = e;
      debugPrint('❌ [Auth] Sign-out (Supabase/Google) error: $e — continuing with local cleanup');
    }

    try {
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

      // Wipe ALL tab prewarmer caches (in-memory + on-disk where applicable)
      // so the next user signing in on this device doesn't briefly see the
      // prior account's streaks / workouts / food / social state before the
      // network refresh lands. Run in parallel — none of them block each
      // other and clearAll on each is idempotent.
      await Future.wait([
        YouOverviewPrewarmer.clearAll(),
        HomePrewarmer.clearAll(),
        NutritionPrewarmer.clearAll(),
        WorkoutsPrewarmer.clearAll(),
        SocialPrewarmer.clearAll(),
        WorkoutCompletionPrewarmer.clearAll(),
      ]);

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
      debugPrint('❌ [Auth] Sign-out cleanup error: $e');
      // If we already had a Supabase/Google error, prefer that one.
      signOutError ??= e;
    }

    if (signOutError != null) {
      // ignore: only_throw_errors
      throw signOutError;
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
          // 404 here is an EXPECTED state (auth row exists but public.users
          // was deleted — orphan auth user). Whitelist it through
          // validateStatus so Dio doesn't throw, which keeps the Sentry
          // HTTP integration from reporting it as a production error.
          final response = await _apiClient.get(
            '${ApiConstants.users}/by-auth/$authId',
            options: Options(
              validateStatus: (s) => s != null && (s < 400 || s == 404),
            ),
          );
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
    // Step 0: Validate cache against the live Supabase session BEFORE
    // surfacing the cached user. Without this guard, a prior account's
    // user (sitting in SharedPreferences from a previous install or a
    // partially-completed sign-out) gets shown instantly on app open and
    // the router routes the user to /home with someone else's name. The
    // user then sees "names and everything before signing up" — see plan
    // ~/.claude/plans/i-am-still-not-quizzical-comet.md for the symptom.
    //
    // Rule: cache is only trustworthy if there's an active Supabase
    // session right now. If the session is gone (signed out, expired,
    // never-existed-on-this-device), the cached user is stale. Drop it
    // and fall through to the no-cache branch.
    final liveSession = _supabase.auth.currentSession;
    if (liveSession == null) {
      if (await _getCachedUser() != null) {
        debugPrint('🧹 [Auth] Cache rejected: no live Supabase session — clearing stale user cache');
        await DataCacheService.instance.invalidate(DataCacheService.userProfileKey);
      }
      return (cached: null, fresh: restoreSession());
    }

    // Step 1: Try to load cached user instantly
    final cachedUser = await _getCachedUser();
    if (cachedUser != null) {
      // Account-switch guard: the User model does NOT carry the Supabase
      // auth_id, but it does carry email. If the live session's email
      // doesn't match the cached user, we're looking at a different
      // account on the same device — drop the cache and force a fresh
      // by-auth lookup before painting any UI.
      final sessionEmail = liveSession.user.email?.toLowerCase().trim();
      final cachedEmail = cachedUser.email?.toLowerCase().trim();
      if (sessionEmail != null && cachedEmail != null && sessionEmail != cachedEmail) {
        debugPrint('🧹 [Auth] Cache rejected: account switch detected ($cachedEmail → $sessionEmail)');
        await DataCacheService.instance.invalidate(DataCacheService.userProfileKey);
        return (cached: null, fresh: restoreSession());
      }
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

  /// Fire all 5 tab prewarmers in parallel, fire-and-forget. Call this BEFORE
  /// flipping `state = AuthState(authenticated)` so the prewarmer fetches start
  /// running concurrently with the router's redirect → home-screen-mount cycle
  /// (which costs ~16ms of frame time before initState fires). The Supabase
  /// session is already populated by the time `_repository.signInXxx()`
  /// returns, so `apiClient.getUserId()` inside each warm() succeeds.
  ///
  /// Each prewarmer has its own dedup + staleness check, so calling this from
  /// multiple sites (sign-in + _init cache-restore) is safe.
  void _firePrewarmers() {
    unawaited(YouOverviewPrewarmer.warm(_ref));
    unawaited(HomePrewarmer.warm(_ref));
    unawaited(NutritionPrewarmer.warm(_ref));
    unawaited(WorkoutsPrewarmer.warm(_ref));
    unawaited(SocialPrewarmer.warm(_ref));
  }

  /// Initialize with cache-first pattern for instant auth
  Future<void> _init() async {
    try {
      // Step 1: Try to load cached user instantly (no loading state)
      final result = await _repository.restoreSessionWithCache();

      if (result.cached != null) {
        // Show cached user immediately - no loading spinner!
        debugPrint('⚡ [Auth] Authenticated from cache instantly');
        // Fire prewarmers BEFORE the state flip so their fetches overlap with
        // the router redirect → home mount frame (~16ms head start).
        _firePrewarmers();
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
          _firePrewarmers();
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
      // Fire all 5 tab prewarmers BEFORE the state flip so their fetches
      // overlap with the router redirect + home mount frame.
      _firePrewarmers();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      // Persist the freshly-signed-in user to cache so the next cold start
      // hits the cache-first happy path with THIS user — not whatever
      // previous account left a row in SharedPreferences.
      await _repository._cacheUser(user);
      _updateDeviceInfo(user.id);
      // Fire-and-forget referral flush — never block auth UX on this.
      unawaited(_flushPendingReferral());
    } catch (e) {
      // User dismissing the Google account picker is not an error — don't
      // render a red error pill on a deliberate cancellation. Same for
      // Apple. Reset to unauthenticated so the sign-in screen looks clean.
      if (_isUserCancellation(e)) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _humanizeAuthException(e),
      );
    }
  }

  /// Sign in with Apple (iOS / iPadOS only)
  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signInWithApple();
      await _syncQuizAfterSignIn(user);
      _firePrewarmers();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _repository._cacheUser(user);
      _updateDeviceInfo(user.id);
      unawaited(_flushPendingReferral());
    } catch (e) {
      if (_isUserCancellation(e)) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _humanizeAuthException(e),
      );
    }
  }

  /// True for the well-known "user dismissed the OS sheet" exceptions —
  /// Google's account picker or Apple's auth sheet. These are deliberate
  /// user actions, not failures, so they shouldn't surface as error UI.
  bool _isUserCancellation(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('cancelled') ||
        s.contains('canceled') ||
        s.contains('user_cancelled') ||
        s.contains('sign_in_canceled') ||
        s.contains('sign-in was cancelled');
  }

  /// Translate raw network/SDK exceptions into copy a user can act on.
  /// Without this, the sign-in screen renders strings like
  /// `Exception: DioException [connection error]: ...` verbatim.
  String _humanizeAuthException(Object e) {
    final raw = e.toString().replaceAll('Exception: ', '').trim();
    final l = raw.toLowerCase();
    if (l.contains('socketexception') ||
        l.contains('connection') ||
        l.contains('network') ||
        l.contains('failed host lookup') ||
        l.contains('timed out') ||
        l.contains('timeout')) {
      return "Can't reach the server. Check your connection and try again.";
    }
    if (l.contains('429') || l.contains('rate limit') || l.contains('too many')) {
      return 'Too many attempts. Wait a minute and try again.';
    }
    if (l.contains('500') || l.contains('502') || l.contains('503') || l.contains('504')) {
      return "Our servers had a hiccup. Please try again in a moment.";
    }
    if (l.contains('id token') || l.contains('idtoken')) {
      return "Couldn't verify your account with Google. Try again.";
    }
    return raw;
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signInWithEmail(email, password);
      await _syncQuizAfterSignIn(user);
      _firePrewarmers();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _repository._cacheUser(user);
      _updateDeviceInfo(user.id, isFreshSignin: true);
      unawaited(_flushPendingReferral());
    } catch (e) {
      // Email-screen has its own _humanizeAuthError that runs on
      // state.errorMessage, so we keep the original string here for
      // signal preservation (it inspects "invalid login credentials"
      // etc.). Only swap network-class noise into something readable.
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _isNetworkException(e) ? _humanizeAuthException(e) : e.toString(),
      );
    }
  }

  bool _isNetworkException(Object e) {
    final l = e.toString().toLowerCase();
    return l.contains('socketexception') ||
        l.contains('failed host lookup') ||
        l.contains('connection error') ||
        l.contains('connection refused') ||
        l.contains('connection closed') ||
        l.contains('connection timed out') ||
        l.contains('timed out');
  }

  /// Sign up with email and password.
  ///
  /// `quizMetadata` is forwarded into Supabase Auth user_metadata so
  /// transactional emails (welcome, magic link, reset) can personalize
  /// without depending on the backend round-trip having completed.
  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? name,
    Map<String, dynamic>? quizMetadata,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signUpWithEmail(
        email,
        password,
        name: name,
        quizMetadata: quizMetadata,
      );
      await _syncQuizAfterSignIn(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _repository._cacheUser(user);
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
