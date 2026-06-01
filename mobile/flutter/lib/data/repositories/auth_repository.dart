import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:home_widget/home_widget.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb show AuthState;
import '../../core/constants/api_constants.dart';
import '../local/database.dart';
import '../local/database_provider.dart';
import '../models/ai_profile_payload.dart';
import '../models/user.dart' as app_user;
import '../providers/consistency_provider.dart';
import '../providers/fasting_provider.dart';
import '../providers/gym_profile_provider.dart';
import '../providers/nutrition_preferences_provider.dart';
import '../providers/referral_provider.dart';
import '../providers/scores_provider.dart';
import '../providers/secondary_tile_providers.dart';
import '../providers/today_workout_provider.dart';
import '../providers/xp_provider.dart';
import '../../screens/onboarding/pre_auth_quiz_data.dart';
import '../repositories/chat_repository.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/measurements_repository.dart';
import '../repositories/workout_repository.dart';
import '../../screens/workout/providers/active_workout_session_provider.dart';
import '../services/widget_service.dart';
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

  // Equality is by (status, user.id, errorMessage). Without this override every
  // `state = AuthState(...)` produces a fresh object reference, so every
  // `ref.watch(authStateProvider)` consumer rebuilds — re-creating notifiers
  // mid-fetch, disposing in-flight requests, and stranding the UI in the
  // initial empty state. Comparing user by `id` only means partial profile
  // hydration (`copyWith(user: …)` with the same id) no longer churns
  // unrelated providers. See plan §2.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthState &&
          other.status == status &&
          other.user?.id == user?.id &&
          other.errorMessage == errorMessage);

  @override
  int get hashCode => Object.hash(status, user?.id, errorMessage);
}

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  final repo = AuthRepository(apiClient, db);

  // Wire the 401 recovery callbacks on ApiClient so the Dio interceptor
  // can route through AuthRepository (instead of calling Supabase
  // directly). Avoids the circular import — auth_repository.dart already
  // imports api_client.dart, so we expose hooks via callback fields on
  // ApiClient and set them here.
  apiClient.onTokenRefresh = () async {
    try {
      final user = await repo.restoreSession();
      // restoreSession() returns null on 404 (orphan auth user) or when
      // no Supabase session exists — both mean refresh effectively failed
      // and the interceptor should fall through to forced sign-out.
      return user != null;
    } catch (e) {
      debugPrint('❌ [Auth] onTokenRefresh hook failed: $e');
      return false;
    }
  };
  apiClient.onForceSignOut = () async {
    try {
      await repo.signOut();
    } catch (e) {
      debugPrint('❌ [Auth] onForceSignOut hook failed: $e');
      // Best-effort fallback so the user is never stranded with a stale
      // session — clear the local auth keys at minimum.
      await apiClient.clearAuth();
    }
  };

  return repo;
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
  final AppDatabase _db;
  final GoogleSignIn _googleSignIn;
  final SupabaseClient _supabase;

  AuthRepository(this._apiClient, this._db)
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

      debugPrint('✅ [Auth] Supabase signup success, syncing user to backend...');

      // Ensure the public.users row exists via /auth/sync. It is idempotent
      // and, on first create, fires the verification email + Discord signup
      // notify. We no longer call /auth/email/signup — it redundantly re-ran
      // the Supabase signup and 409'd "already registered" on every attempt.
      // /auth/sync reads name/quiz from the JWT user_metadata set by signUp.
      final backendResponse = await _apiClient.post(
        '${ApiConstants.users}/auth/sync',
      );

      if (backendResponse.statusCode == 200 || backendResponse.statusCode == 201) {
        final user = app_user.User.fromJson(backendResponse.data as Map<String, dynamic>);
        debugPrint('✅ [Auth] Backend user synced: ${user.id}');

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

  /// Time + log a single sign-out cleanup step. Each [body] is awaited
  /// inside a guard so one failing teardown (e.g. flutter_local_notifications
  /// not yet initialized on first launch) cannot halt the rest of the
  /// orchestration. Emits a structured `🚪 [SignOut] step=X ok=… ms=N`
  /// line in debug builds so we can audit the order from device logs.
  Future<void> _runSignOutStep(String name, Future<void> Function() body) async {
    final sw = Stopwatch()..start();
    var ok = true;
    try {
      await body();
    } catch (e) {
      ok = false;
      debugPrint('❌ [SignOut] step=$name failed: $e');
    } finally {
      sw.stop();
      if (kDebugMode) {
        debugPrint('🚪 [SignOut] step=$name ok=$ok ms=${sw.elapsedMilliseconds}');
      }
    }
  }

  /// Reset every third-party identity that was set during sign-in. MUST run
  /// BEFORE the local data wipe so the LAST event each SDK ships still
  /// carries the correct user_id — that's the audit trail for "user X
  /// signed out at T" on PostHog / Crashlytics / Sentry.
  ///
  /// Every individual call is wrapped in try/catch because some SDKs
  /// (FCM, RevenueCat) raise if the user signs out before the SDK has
  /// finished its first-launch handshake — that's a no-op for our
  /// purposes, not a fatal failure.
  Future<void> _clearThirdPartyIdentities() async {
    await _runSignOutStep('posthog.reset', () async {
      await Posthog().reset();
    });
    await _runSignOutStep('crashlytics.setUserIdentifier', () async {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
    });
    await _runSignOutStep('sentry.scope.clear', () async {
      await Sentry.configureScope((s) => s.setUser(null));
    });
    await _runSignOutStep('fcm.deleteToken', () async {
      // deleteToken can hang on a denied-permission device — bound it so
      // sign-out never blocks longer than a couple of seconds on a flaky
      // APNS handshake.
      await FirebaseMessaging.instance.deleteToken().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              if (kDebugMode) {
                debugPrint('⚠️ [SignOut] FCM deleteToken timed out — continuing');
              }
            },
          );
    });
    await _runSignOutStep('revenuecat.logOut', () async {
      // Purchases.logOut() throws if no user is currently identified
      // (e.g., the SDK was never configured because the user signed up
      // and immediately signed out without hitting the paywall).
      // Swallow that specific failure mode rather than aborting cleanup.
      try {
        await Purchases.logOut();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [SignOut] Purchases.logOut soft-failed: $e');
        }
      }
    });
    await _runSignOutStep('google.signOut', () async {
      await _googleSignIn.signOut();
    });
  }

  /// Tear down every local side-effect that was scheduled for the
  /// outgoing user — local notifications and the iOS / Android home
  /// widget surface. Without this, A's "time to work out!" notification
  /// can fire on B's device, and the home widget will keep showing A's
  /// next workout / streak until B opens the app and triggers a refresh.
  Future<void> _clearLocalSideEffects() async {
    await _runSignOutStep('localNotifications.cancelAll', () async {
      await FlutterLocalNotificationsPlugin().cancelAll();
    });
    await _runSignOutStep('widget.clear', () async {
      // Null every key the WidgetService writes to, then ping the
      // platform widget so the home-screen tile redraws as empty.
      // We deliberately call HomeWidget directly (not WidgetService)
      // because WidgetService.update* methods all REQUIRE non-null
      // data — there's no public "clear" method today.
      const keys = <String>[
        WidgetService.keyWorkout,
        WidgetService.keyStreak,
        WidgetService.keyWater,
        WidgetService.keyFood,
        WidgetService.keyStats,
        WidgetService.keyChallenges,
        WidgetService.keyAchievements,
        WidgetService.keyGoals,
        WidgetService.keyCalendar,
        WidgetService.keyAICoach,
      ];
      for (final k in keys) {
        try {
          await HomeWidget.saveWidgetData<String>(k, null);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [SignOut] HomeWidget.saveWidgetData($k) failed: $e');
          }
        }
      }
      // Two updateWidget calls — one for iOS (name=iOS widget bundle),
      // one for Android (qualifiedAndroidName / androidName). Either may
      // throw on a platform where the widget isn't installed yet; we
      // ignore those.
      try {
        await HomeWidget.updateWidget(
          name: 'FitnessWidget',
          androidName: 'FitnessWidgetReceiver',
          iOSName: 'FitnessWidget',
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [SignOut] HomeWidget.updateWidget failed: $e');
        }
      }
    });
    await _runSignOutStep('chat.closeStreams', () async {
      ChatMessagesNotifier.closeAllStreams();
    });
    await _runSignOutStep('activeWorkout.clear', () async {
      ActiveWorkoutSessionNotifier.clearCache();
    });
  }

  /// Drop every Drift row owned by [outgoingUserId] so the next user
  /// signing in on this device can't read it. The sync queue has no
  /// userId column (it's a single-tenant outbox) so it's wiped wholesale.
  /// Foods/embeddings/media-cache/exercise-library are shared reference
  /// data — NOT user-scoped — and are left intact (re-downloading them
  /// for every account switch would be wasteful and offline-hostile).
  Future<void> _wipeDriftForUser(String? outgoingUserId) async {
    if (outgoingUserId == null || outgoingUserId.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ [SignOut] _wipeDriftForUser called with null/empty id — skipping');
      }
      return;
    }
    await _runSignOutStep('drift.workouts', () async {
      await _db.workoutDao.clearForUser(outgoingUserId);
    });
    await _runSignOutStep('drift.workoutLogs', () async {
      await _db.workoutLogDao.clearForUser(outgoingUserId);
    });
    await _runSignOutStep('drift.userProfile', () async {
      await _db.userProfileDao.clearForUser(outgoingUserId);
    });
    await _runSignOutStep('drift.gymProfiles', () async {
      await _db.gymProfileDao.clearForUser(outgoingUserId);
    });
    await _runSignOutStep('drift.exercise1rm', () async {
      await _db.exercise1rmDao.clearForUser(outgoingUserId);
    });
    await _runSignOutStep('drift.volumeResponses', () async {
      await _db.volumeResponseDao.clearForUser(outgoingUserId);
    });
    await _runSignOutStep('drift.quickPresets', () async {
      await _db.quickPresetDao.deleteAllForUser(outgoingUserId);
    });
    await _runSignOutStep('drift.syncQueue', () async {
      await _db.syncQueueDao.clearForUser(outgoingUserId);
    });
  }

  /// Sign out — transactional.
  ///
  /// Supabase signOut is awaited FIRST. If it fails (network blip,
  /// expired token, server 5xx) we throw immediately WITHOUT touching
  /// any local cache or third-party identity. The user-visible error is
  /// "Couldn't sign out. Check your connection and try again." A
  /// half-state — local data wiped while Supabase still holds a valid
  /// session — would surface on the next cold start as the user
  /// appearing to be signed back in (because restoreSession() finds the
  /// still-live session) with all their data freshly empty.
  ///
  /// Once Supabase signOut succeeds, cleanup runs in a fixed order:
  ///   1. Third-party identities (PostHog / Crashlytics / Sentry / FCM /
  ///      RevenueCat / Google) — so the last event still carries the
  ///      correct user_id.
  ///   2. Local side-effects (notifications, widget, chat streams,
  ///      active-workout state).
  ///   3. Drift rows owned by the outgoing user.
  ///   4. In-memory provider caches (existing).
  ///   5. DataCacheService.clearAll() (existing — runs last so a crash
  ///      mid-cleanup still leaves the disk cache stale-but-scoped, and
  ///      the per-user keys means it can't be served to the next user
  ///      anyway).
  Future<void> signOut() async {
    // Capture the outgoing user id BEFORE we tear down Supabase — once
    // signOut() succeeds, _supabase.auth.currentUser becomes null and we
    // can't scope the Drift wipe.
    final outgoingAuthId = _supabase.auth.currentUser?.id;
    final outgoingBackendId = await _apiClient.getUserId();

    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('❌ [Auth] Supabase signOut failed — aborting local cleanup: $e');
      throw Exception(
        "Couldn't sign out. Check your connection and try again.",
      );
    }

    // From here, everything is best-effort. We deliberately do NOT
    // rethrow individual step failures — once the Supabase session is
    // gone, the user is signed out from the server's point of view and
    // we must finish wiping local state regardless of which SDK errors.
    await _clearThirdPartyIdentities();
    await _clearLocalSideEffects();
    // Wipe Drift rows for whichever id we managed to capture. The
    // backend id (users.id) is what every user-scoped Drift table keys
    // on, so prefer that; fall back to the Supabase auth id only if the
    // user signed out before /by-auth ever resolved.
    await _wipeDriftForUser(outgoingBackendId ?? outgoingAuthId);

    // ----- existing cleanup (unchanged below this line) -----

    await _runSignOutStep('apiClient.clearAuth', () async {
      await _apiClient.clearAuth();
    });

    await _runSignOutStep('providers.clearCache', () async {
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
    });

    await _runSignOutStep('prewarmers.clearAll', () async {
      // Wipe ALL tab prewarmer caches in parallel.
      await Future.wait([
        YouOverviewPrewarmer.clearAll(),
        HomePrewarmer.clearAll(),
        NutritionPrewarmer.clearAll(),
        WorkoutsPrewarmer.clearAll(),
        SocialPrewarmer.clearAll(),
        WorkoutCompletionPrewarmer.clearAll(),
      ]);
    });

    await _runSignOutStep('dataCache.clearAll', () async {
      // Per-user-scoped keys, but call clearAll() to drop legacy
      // global-scoped entries written by older app versions.
      await DataCacheService.instance.clearAll();
    });

    await _runSignOutStep('prefs.clearOnboardingFlags', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      await prefs.remove('paywall_completed');
    });

    await _runSignOutStep('watch.clearCredentials', () async {
      await WearableService.instance.syncUserCredentials(
        userId: '',
        authToken: '',
        refreshToken: '',
      );
    });

    debugPrint('✅ [Auth] Sign-out success (all caches cleared)');
  }

  /// Run the post-Supabase-signOut cleanup pipeline for the case where
  /// the Supabase session was revoked SERVER-SIDE (admin sign-out, JWT
  /// user-deleted, password change from another device). Same sequence
  /// as the user-initiated [signOut] except we don't call
  /// `_supabase.auth.signOut()` again — the session is already gone.
  Future<void> _cleanupAfterRemoteSignOut() async {
    final outgoingBackendId = await _apiClient.getUserId();
    await _clearThirdPartyIdentities();
    await _clearLocalSideEffects();
    await _wipeDriftForUser(outgoingBackendId);
    await _runSignOutStep('apiClient.clearAuth', () async {
      await _apiClient.clearAuth();
    });
    await _runSignOutStep('providers.clearCache', () async {
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
    });
    await _runSignOutStep('prewarmers.clearAll', () async {
      await Future.wait([
        YouOverviewPrewarmer.clearAll(),
        HomePrewarmer.clearAll(),
        NutritionPrewarmer.clearAll(),
        WorkoutsPrewarmer.clearAll(),
        SocialPrewarmer.clearAll(),
        WorkoutCompletionPrewarmer.clearAll(),
      ]);
    });
    await _runSignOutStep('dataCache.clearAll', () async {
      await DataCacheService.instance.clearAll();
    });
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

  /// Load cached user profile for the user currently authenticated with
  /// Supabase. Scoped by Supabase auth_id so a prior install's cache for a
  /// different account can't leak in.
  Future<app_user.User?> _getCachedUser() async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      final cached = await DataCacheService.instance.getCached(
        DataCacheService.userProfileKey,
        userId: authId,
      );
      if (cached != null) {
        return app_user.User.fromJson(cached);
      }
    } catch (e) {
      debugPrint('⚠️ [Auth] Cache parse error: $e');
    }
    return null;
  }

  /// Save user to cache, scoped by the live Supabase auth_id.
  Future<void> _cacheUser(app_user.User user) async {
    try {
      await DataCacheService.instance.cache(
        DataCacheService.userProfileKey,
        user.toJson(),
        userId: _supabase.auth.currentUser?.id,
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
          // Account-deleted path. The backend `users` row is gone but
          // local Drift rows, PostHog identity, FCM token, etc. all
          // still point at the (now-orphaned) authId. Route through the
          // same teardown the manual sign-out uses so the next user on
          // this device starts from a clean slate. Wrapped because we
          // must still return null even if cleanup partially fails —
          // the caller (AuthNotifier._init) will route to the auth
          // screen and the orphan auth row will be re-created on the
          // next sign-in.
          try {
            await _clearThirdPartyIdentities();
            await _clearLocalSideEffects();
            // We never resolved a backend user id here — fall back to
            // the Supabase auth id for the Drift wipe. Drift rows are
            // keyed on users.id, so this is effectively a no-op for
            // rows the deleted user owned (different id space), but
            // running it keeps the orchestration identical to the
            // manual path and surfaces any DAO regressions.
            await _wipeDriftForUser(authId);
            await DataCacheService.instance.clearAll();
          } catch (e) {
            debugPrint('⚠️ [Auth] Account-deleted cleanup partial-failure: $e');
          }
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
        // No session → no auth_id to scope by. Wipe via clearAll's
        // prefix-walk so EVERY user's profile cache on this device gets
        // dropped (logout-equivalent).
        await DataCacheService.instance.clearAll();
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
        // Drop both accounts' caches to be safe — the cached user is the
        // outgoing account, the incoming account has its own slot scoped
        // by liveSession.user.id.
        await DataCacheService.instance.invalidate(
          DataCacheService.userProfileKey,
          userId: liveSession.user.id,
        );
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
    _startSignedOutListener();
  }

  /// SharedPreferences key tracking the last user.id that signed in on this
  /// device. Used to detect account switches: if a different user signs in,
  /// the previous user's pre-auth quiz answers are stale and must be cleared
  /// before being applied to the new account.
  static const _lastAuthUserIdKey = 'lastAuthUserId';

  /// Subscription to Supabase auth events. We separately watch for
  /// `signedOut` so a server-side session revocation (admin sign-out, JWT
  /// user-deleted, password change from another device) triggers the
  /// same teardown as a user-initiated tap on the Sign Out button.
  StreamSubscription<sb.AuthState>? _supabaseAuthSub;

  /// Set to `true` for the duration of a user-initiated [signOut] so the
  /// Supabase listener doesn't double-run the cleanup orchestration
  /// (which is idempotent, but skipping it saves ~200ms of wasted work
  /// and prevents the "signed out" debug log from printing twice).
  bool _userInitiatedSignOutInFlight = false;

  void _startSignedOutListener() {
    try {
      _supabaseAuthSub = Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) async {
          if (data.event != AuthChangeEvent.signedOut) return;
          if (_userInitiatedSignOutInFlight) {
            debugPrint('🚪 [Auth] Ignoring signedOut event — user-initiated path already running');
            return;
          }
          debugPrint('🚪 [Auth] Server-side signedOut detected — running full cleanup');
          try {
            // Reach into the repository's private helpers via the
            // server-revocation path. We can't call `_repository.signOut`
            // here — it would try to call Supabase.signOut again, which
            // already happened (server side). Instead, run the same
            // teardown directly.
            await _repository._cleanupAfterRemoteSignOut();
          } catch (e) {
            debugPrint('⚠️ [Auth] Server-revocation cleanup error: $e');
          }
          if (mounted) {
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
        },
        onError: (Object e) {
          debugPrint('❌ [Auth] signedOut listener error: $e');
        },
      );
    } catch (e) {
      debugPrint('❌ [Auth] Failed to start signedOut listener: $e');
    }
  }

  @override
  void dispose() {
    _supabaseAuthSub?.cancel();
    super.dispose();
  }

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
    // Gate the Supabase signedOut listener — `_repository.signOut()`
    // calls Supabase.signOut() internally, which fires the listener.
    // Without this flag, the listener would re-run the full cleanup
    // we already executed.
    _userInitiatedSignOutInFlight = true;
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
      // Same hazard for the kept-alive secondary tile providers (metric deck,
      // home insights/patterns, etc.): their in-memory keepAlive value survives
      // DataCacheService.clearAll(), so without this user B could inherit user
      // A's deck on a logout→login without an app restart. Invalidate them all.
      for (final p in secondaryTileProviders) {
        _ref.invalidate(p);
      }
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      // Release the gate after a short delay so any signedOut event
      // queued by Supabase's stream is observed-and-ignored, not
      // observed-and-re-cleaned. The stream is synchronous-ish but
      // adds an extra microtask hop on iOS.
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        _userInitiatedSignOutInFlight = false;
      });
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
  /// Optimistic profile update. Applies [updates] to local user state
  /// synchronously so every screen reading `currentUserProvider` rebuilds
  /// on the same frame as the tap. Persistence + the post-write refresh run
  /// in the background. On failure the local state rolls back to the
  /// pre-update user and the error is logged (callers can listen on
  /// `state.errorMessage` for a toast).
  ///
  /// The returned Future completes the instant the background work is
  /// *scheduled*, not when the network finishes, so the caller's
  /// `await updateUserProfile(...)` is non-blocking. Throws synchronously
  /// only if no user is logged in (callers can still try/catch around the
  /// await for that case).
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (state.user == null) {
      throw Exception('No user logged in');
    }
    final previousUser = state.user!;
    final userId = previousUser.id;

    // Apply locally first so the UI reflects the change immediately.
    state =
        state.copyWith(user: _applyOverrides(previousUser, updates));

    unawaited(() async {
      try {
        await _repository._apiClient.put(
          '${ApiConstants.users}/$userId',
          data: updates,
        );
        // Refresh from server, BUT re-apply the fields we just wrote so a
        // lagging /users GET (read-after-write inconsistency) doesn't
        // revert the value the user just picked.
        await refreshUser();
        if (state.user != null) {
          state = state.copyWith(user: _applyOverrides(state.user!, updates));
        }
        debugPrint('✅ [Auth] Updated user profile: $updates');
      } catch (e) {
        debugPrint('❌ [Auth] Update user profile error, rolling back: $e');
        state = state.copyWith(
          user: previousUser,
          errorMessage: 'Failed to update profile: $e',
        );
      }
    }());
  }

  /// Re-apply outgoing `updates` on top of a freshly-fetched user so the
  /// user's just-toggled preference isn't clobbered by stale server data.
  /// Also drives the optimistic-update path in [updateUserProfile] —
  /// every key the UI can edit should be mapped here so the local state
  /// reflects the change synchronously.
  app_user.User _applyOverrides(
    app_user.User u,
    Map<String, dynamic> updates,
  ) {
    var next = u;
    String? asStr(Object? v) => v?.toString();
    double? asDouble(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }
    int? asInt(Object? v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }
    String? asJson(Object? v) {
      if (v == null) return null;
      if (v is String) return v;
      return jsonEncode(v);
    }

    // ── Unit / vacation toggles (original set) ─────────────────────────
    if (updates.containsKey('workout_weight_unit')) {
      next = next.copyWith(workoutWeightUnit: asStr(updates['workout_weight_unit']));
    }
    if (updates.containsKey('weight_unit')) {
      next = next.copyWith(weightUnit: asStr(updates['weight_unit']));
    }
    if (updates.containsKey('measurement_unit')) {
      next = next.copyWith(measurementUnit: asStr(updates['measurement_unit']));
    }
    if (updates.containsKey('in_vacation_mode')) {
      next = next.copyWith(inVacationMode: updates['in_vacation_mode'] as bool?);
    }
    if (updates.containsKey('vacation_start_date')) {
      final raw = asStr(updates['vacation_start_date']);
      next = next.copyWith(vacationStartDate: (raw == null || raw.isEmpty) ? null : raw);
    }
    if (updates.containsKey('vacation_end_date')) {
      final raw = asStr(updates['vacation_end_date']);
      next = next.copyWith(vacationEndDate: (raw == null || raw.isEmpty) ? null : raw);
    }
    // ── Personal info (edit_personal_info_sheet) ───────────────────────
    if (updates.containsKey('name')) {
      next = next.copyWith(name: asStr(updates['name']));
    }
    if (updates.containsKey('username')) {
      next = next.copyWith(username: asStr(updates['username']));
    }
    if (updates.containsKey('photo_url')) {
      next = next.copyWith(photoUrl: asStr(updates['photo_url']));
    }
    if (updates.containsKey('height_cm')) {
      next = next.copyWith(heightCm: asDouble(updates['height_cm']));
    }
    if (updates.containsKey('weight_kg')) {
      next = next.copyWith(weightKg: asDouble(updates['weight_kg']));
    }
    if (updates.containsKey('target_weight_kg')) {
      next = next.copyWith(targetWeightKg: asDouble(updates['target_weight_kg']));
    }
    if (updates.containsKey('date_of_birth')) {
      next = next.copyWith(dateOfBirth: asStr(updates['date_of_birth']));
    }
    if (updates.containsKey('age')) {
      next = next.copyWith(age: asInt(updates['age']));
    }
    if (updates.containsKey('gender')) {
      next = next.copyWith(gender: asStr(updates['gender']));
    }
    // ── Fitness profile (editable_fitness_card + workout_days_sheet) ───
    if (updates.containsKey('fitness_level')) {
      next = next.copyWith(fitnessLevel: asStr(updates['fitness_level']));
    }
    if (updates.containsKey('goals')) {
      // Goals come in as either a plain string or a JSON array — store as JSON.
      next = next.copyWith(goals: asJson(updates['goals']));
    }
    if (updates.containsKey('primary_goal')) {
      next = next.copyWith(primaryGoal: asStr(updates['primary_goal']));
    }
    if (updates.containsKey('active_injuries')) {
      next = next.copyWith(activeInjuries: asJson(updates['active_injuries']));
    }
    if (updates.containsKey('activity_level')) {
      next = next.copyWith(activityLevel: asStr(updates['activity_level']));
    }
    // workout_days + equipment are stored as JSON inside `preferences`.
    // For instant UI we update the `equipment` mirror field too.
    if (updates.containsKey('equipment')) {
      next = next.copyWith(equipment: asJson(updates['equipment']));
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
