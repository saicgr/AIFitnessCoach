import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../../core/constants/api_constants.dart';
import '../../core/services/sentry_service.dart';

/// Secure storage for auth tokens.
///
/// Returns a [FlutterSecureStorage] subclass that automatically falls
/// back to `SharedPreferences` on `errSecMissingEntitlement` (-34018).
/// Without this, every sign-in crashes on iOS simulator builds run via
/// `--no-codesign` (Live Activity workaround on iOS 26 sim) and on
/// certain TestFlight provisioning configs, because the keychain
/// entitlement is only embedded at signing time.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return _ResilientSecureStorage();
});

/// Drop-in replacement for [FlutterSecureStorage] that catches Keychain
/// entitlement errors (-34018) and persists to `SharedPreferences`
/// instead. Same `read` / `write` / `delete` API — callers don't need
/// to know which backend is active.
///
/// Trade-off when SharedPreferences is used: token is sandbox-isolated
/// (other apps can't read it) but not hardware-encrypted. For a 1-hour
/// Supabase access token this is acceptable — Supabase's own SDK
/// documents `SharedPreferencesLocalStorage` as the supported fallback.
class _ResilientSecureStorage extends FlutterSecureStorage {
  _ResilientSecureStorage()
      : super(
          aOptions: const AndroidOptions(encryptedSharedPreferences: true),
          iOptions: const IOSOptions(
              accessibility: KeychainAccessibility.first_unlock),
        );

  bool _shouldFallback(Object e) {
    final msg = e.toString();
    return msg.contains('-34018') ||
        msg.contains('errSecMissingEntitlement') ||
        msg.contains('required entitlement');
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    try {
      await super.write(
        key: key,
        value: value,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } catch (e) {
      if (!_shouldFallback(e)) rethrow;
      debugPrint(
          '⚠️ [SecureStorage] Keychain write failed (-34018), using SharedPreferences for "$key"');
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove('secure.$key');
      } else {
        await prefs.setString('secure.$key', value);
      }
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    try {
      final fromKeychain = await super.read(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
      // Migration aid: if Keychain has nothing but SharedPreferences does
      // (because an earlier write fell back), surface the SharedPreferences
      // copy so reads stay consistent.
      if (fromKeychain != null) return fromKeychain;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('secure.$key');
    } catch (e) {
      if (!_shouldFallback(e)) rethrow;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('secure.$key');
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    try {
      await super.delete(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } catch (e) {
      if (!_shouldFallback(e)) rethrow;
    }
    // Always sweep SharedPreferences too, in case a fallback write landed there.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('secure.$key');
  }
}

/// API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final client = ApiClient(storage);
  // Start listening for Supabase auth state changes to keep token in sync
  client.startAuthListener();
  ref.onDispose(() => client.dispose());
  return client;
});

/// HTTP API client with auth interceptor
class ApiClient with WidgetsBindingObserver {
  final FlutterSecureStorage _storage;
  late final Dio _dio;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _tokenRefreshTimer;

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  /// Set true once we've detected a JWT_USER_DELETED 401 in this session and
  /// kicked off the forced sign-out. Prevents the 401 storm: every subsequent
  /// in-flight request that returns the same 401 short-circuits instead of
  /// re-triggering signOut() / route navigation. Reset on next signedIn event.
  bool _userDeletedSignOutInFlight = false;

  /// Detect the backend's stable "JWT user is gone, sign out now" signal.
  /// Backend emits both an `X-Auth-Error: JWT_USER_DELETED` header and the
  /// same string in the response body's `detail` field. We also accept the
  /// raw Supabase substring "User from sub claim in JWT does not exist" as
  /// a fallback so this works against backend revisions that haven't picked
  /// up the new error code yet (the symptom is identical).
  bool _isJwtUserDeleted(Response? response) {
    if (response == null) return false;
    final headerVal = response.headers.value('x-auth-error');
    if (headerVal != null && headerVal.contains('JWT_USER_DELETED')) {
      return true;
    }
    final body = response.data;
    String? detail;
    if (body is Map) {
      final d = body['detail'];
      if (d is String) detail = d;
    } else if (body is String) {
      detail = body;
    }
    if (detail == null) return false;
    final lower = detail.toLowerCase();
    return lower.contains('jwt_user_deleted') ||
        lower.contains('user from sub claim in jwt does not exist') ||
        lower.contains('user_not_found');
  }

  // In-memory timezone cache — avoids hitting SharedPreferences on every request
  static String? _cachedTimezone;
  static DateTime? _cachedTimezoneTime;

  /// Returns IANA timezone string, cached in memory for 30 minutes.
  static Future<String> _getCachedTimezone() async {
    final now = DateTime.now();
    if (_cachedTimezone != null &&
        _cachedTimezone!.isNotEmpty &&
        _cachedTimezoneTime != null &&
        now.difference(_cachedTimezoneTime!) < const Duration(minutes: 30)) {
      return _cachedTimezone!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final tz = prefs.getString('user_timezone');
      if (tz != null && tz.isNotEmpty && tz.contains('/')) {
        _cachedTimezone = tz;
        _cachedTimezoneTime = now;
        return tz;
      }
      // Fallback: detect from device
      final deviceTzInfo = await FlutterTimezone.getLocalTimezone();
      final deviceTz = deviceTzInfo.identifier;
      if (deviceTz.isNotEmpty) {
        _cachedTimezone = deviceTz;
        _cachedTimezoneTime = now;
        await prefs.setString('user_timezone', deviceTz);
        return deviceTz;
      }
    } catch (_) {}
    return DateTime.now().timeZoneName;
  }

  /// How many minutes before expiry to proactively refresh the token.
  static const _refreshBufferMinutes = 5;

  /// Get the current valid access token from the live Supabase session.
  /// If the token is expired or near expiry, refreshes it inline before returning.
  /// Falls back to the stored token if Supabase session is not available
  /// (e.g., during initial startup before Supabase is fully initialized).
  Future<String?> _getCurrentAccessToken() async {
    try {
      var session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // Check if token is expired or about to expire (within 30s buffer)
        final expiresAt = session.expiresAt;
        if (expiresAt != null) {
          final expiresAtDate = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
          if (DateTime.now().isAfter(expiresAtDate.subtract(const Duration(seconds: 30)))) {
            debugPrint('⚠️ [API] Token expired/expiring, refreshing inline before request...');
            try {
              final refreshed = await Supabase.instance.client.auth.refreshSession();
              if (refreshed.session != null) {
                debugPrint('✅ [API] Inline token refresh succeeded');
                return refreshed.session!.accessToken;
              }
            } catch (e) {
              debugPrint('❌ [API] Inline token refresh failed: $e');
              // Return the expired token — the 401 interceptor will retry
            }
          }
        }
        return session.accessToken;
      }
    } catch (e) {
      debugPrint('⚠️ [API] Could not read Supabase session: $e');
    }
    // Fall back to stored token (may be stale, but better than nothing)
    return _storage.read(key: _tokenKey);
  }

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        followRedirects: true,
        maxRedirects: 5,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip',
        },
      ),
    );

    // Configure HttpClient for connection keep-alive and reuse
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 30);
      client.maxConnectionsPerHost = 6;
      client.autoUncompress = true;
      return client;
    };

    // Certificate pinning: disabled for Render's rotating certificates. TLS is enforced by network_security_config.xml.

    // 307/308 redirect interceptor for POST/PUT/DELETE
    // Dio 5.x only follows redirects for GET/HEAD, so we manually handle
    // 307/308 redirects (e.g. FastAPI trailing-slash redirects).
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if ((response.statusCode == 307 || response.statusCode == 308) &&
              response.headers['location'] != null) {
            final redirectUrl = response.headers['location']!.first;
            final options = response.requestOptions;
            options.path = _resolveRedirectPath(redirectUrl);
            _dio.fetch(options).then(
              (r) => handler.resolve(r),
              onError: (e) => handler.reject(e as DioException),
            );
            return;
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (error.response != null &&
              (error.response!.statusCode == 307 ||
                  error.response!.statusCode == 308) &&
              error.response!.headers['location'] != null) {
            final redirectUrl =
                error.response!.headers['location']!.first;
            final options = error.requestOptions;
            options.path = _resolveRedirectPath(redirectUrl);
            _dio.fetch(options).then(
              (r) => handler.resolve(r),
              onError: (e) => handler.reject(e as DioException),
            );
            return;
          }
          handler.next(error);
        },
      ),
    );

    // Connect-timeout retry interceptor — only retries TCP connect failures
    // (cold iOS/Android network init, carrier handoff, Wi-Fi↔cellular switch).
    // Never retries receive-timeouts or 4xx/5xx — those are real errors.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.type == DioExceptionType.connectionTimeout) {
            final retried = error.requestOptions.extra['_connectRetried'] == true;
            if (!retried) {
              error.requestOptions.extra['_connectRetried'] = true;
              debugPrint('🔄 [API] Connect timeout, retrying once after 1s...');
              await Future.delayed(const Duration(seconds: 1));
              try {
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              } catch (retryError) {
                debugPrint('❌ [API] Connect retry failed: $retryError');
                // fall through to reporting the original error
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Auth interceptor — always uses the CURRENT Supabase session token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getCurrentAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // FIRST: detect the unrecoverable "JWT's user was hard-deleted"
            // case. refreshSession() can't fix this — the refresh token will
            // happily mint a new JWT for a sub claim that no longer exists,
            // and every subsequent call 401s again, producing the production
            // 401 storm. Short-circuit straight to sign-out so the auth
            // listener routes the user back to /sign-in.
            if (_isJwtUserDeleted(error.response)) {
              if (!_userDeletedSignOutInFlight) {
                _userDeletedSignOutInFlight = true;
                debugPrint(
                    '🚪 [API] JWT_USER_DELETED detected — auth user gone server-side, forcing sign-out');
                // Fire-and-forget: we still want to reject this request below
                // so the caller's UI gets an error frame instead of hanging
                // on a Future that never completes. The signOut triggers the
                // onAuthStateChange listener which clears tokens and the
                // app.dart route guard sends the user to /sign-in.
                unawaited(() async {
                  try {
                    await Supabase.instance.client.auth.signOut();
                  } catch (e) {
                    debugPrint('❌ [API] Forced sign-out after JWT_USER_DELETED failed: $e');
                    await clearAuth();
                  }
                }());
              } else {
                debugPrint(
                    '🚪 [API] JWT_USER_DELETED already handled — dropping duplicate 401 from ${error.requestOptions.path}');
              }
              return handler.next(error);
            }

            // A 401 on an auth endpoint means bad credentials, not expired token —
            // don't try to refresh/retry or we'll nuke the user's existing session.
            final path = error.requestOptions.path;
            final method = error.requestOptions.method.toUpperCase();
            // DELETE /users/{id}/reset re-authenticates with the user's
            // password and returns 401 on wrong password. Treating that as
            // "expired session" makes us refresh + sign out, leaving the user
            // with no JWT for the retry → "Authorization header required".
            final isFullReset = method == 'DELETE' && path.contains('/users/') && path.endsWith('/reset');
            if (path.contains('/users/auth/') || path.contains('/auth/email') || path.contains('/auth/signup') || path.contains('/auth/password') || isFullReset) {
              return handler.next(error);
            }
            final retryCount = error.requestOptions.extra['_retryCount'] as int? ?? 0;
            bool refreshFailedFatally = false;
            if (retryCount < 2) {
              try {
                debugPrint('🔄 [API] 401 received (attempt ${retryCount + 1}/2), refreshing token...');
                final refreshed = await Supabase.instance.client.auth.refreshSession();
                final newToken = refreshed.session?.accessToken ?? await _getCurrentAccessToken();
                if (newToken != null) {
                  // Save new token to storage for consistency
                  if (refreshed.session != null) {
                    await _storage.write(key: _tokenKey, value: refreshed.session!.accessToken);
                    // Re-schedule proactive refresh after successful token refresh
                    _scheduleProactiveRefresh();
                  }
                  debugPrint('✅ [API] Token refreshed, retrying request (attempt ${retryCount + 1})...');
                  error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                  error.requestOptions.extra['_retryCount'] = retryCount + 1;
                  final retryResponse = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (refreshError) {
                debugPrint('❌ [API] Retry ${retryCount + 1} refresh failed: $refreshError');
                // Dead session — e.g. Supabase returns "Session from session_id
                // claim in JWT does not exist" (403) when the session was
                // terminated server-side (admin action, user signed out on
                // another device, project auth reset, etc.). refreshSession()
                // itself fails in that case, so no amount of retries will
                // recover. Force a full sign-out so the auth state listener
                // routes the user back to /intro instead of leaving the app
                // firing stale 401s forever.
                refreshFailedFatally = true;
              }
            }

            // Either (a) refresh threw fatally, or (b) we burned through 2
            // retries and the server still says 401. Both mean the session
            // is dead — force sign-out so the auth listener clears state and
            // re-routes to /intro.
            if (refreshFailedFatally || retryCount >= 2) {
              debugPrint('🚪 [API] Session unrecoverable, signing out to reset auth state');
              try {
                await Supabase.instance.client.auth.signOut();
                // The onAuthStateChange listener will handle clearing stored tokens
              } catch (signOutError) {
                debugPrint('❌ [API] Force sign-out failed: $signOutError');
                // Still clear local auth as last resort
                await clearAuth();
              }
            } else {
              // Only clear auth if we didn't even get to retry (no token at
              // all in storage). Shouldn't normally land here; keep as a
              // defensive fallback.
              debugPrint('🚪 [API] Clearing auth after failed refresh');
              await clearAuth();
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Timezone interceptor — attaches X-User-Timezone header to every request.
    // Uses in-memory cache to avoid hitting SharedPreferences on every call.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final tz = await _getCachedTimezone();
            if (tz.isNotEmpty) {
              options.headers['X-User-Timezone'] = tz;
            }
          } catch (e) {
            debugPrint('⚠️ [API] Could not attach timezone header: $e');
          }
          return handler.next(options);
        },
      ),
    );

    // Logging (debug only) — uses Dio's built-in interceptor, no extra package
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    // Sentry breadcrumbs + traces for every outbound HTTP call (no-op when
    // Sentry is disabled). Must be last so it wraps the other interceptors.
    SentryService.attachToDio(_dio);
  }

  /// Start listening to Supabase auth state changes.
  /// Keeps the stored token in sync whenever Supabase auto-refreshes the JWT.
  /// Also schedules proactive token refresh and registers lifecycle observer.
  void startAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        final session = data.session;

        if (session != null &&
            (event == AuthChangeEvent.tokenRefreshed ||
             event == AuthChangeEvent.signedIn)) {
          debugPrint('🔄 [API] Auth state changed ($event), updating stored token');
          // New session means we're past any prior JWT_USER_DELETED storm —
          // re-arm the flag so a future server-side deletion is handled.
          _userDeletedSignOutInFlight = false;
          await _storage.write(key: _tokenKey, value: session.accessToken);
          // Re-schedule proactive refresh whenever we get a new token
          _scheduleProactiveRefresh();
          // Attach the auth user id to Sentry events for this session.
          unawaited(SentryService.setUser(
            id: session.user.id,
            email: session.user.email,
          ));
          // Backfill `public.users` row for sessions that came in via paths
          // other than the explicit signUp/signIn methods — most importantly
          // the email-confirmation deep-link flow, where Supabase mints a
          // valid JWT but no backend create-user call ever ran. Without
          // this, every subsequent request 401s and the user is invisible
          // in `SELECT email FROM users`. Idempotent + non-blocking.
          if (event == AuthChangeEvent.signedIn) {
            unawaited(_ensurePublicUserRow(session.accessToken));
          }
        } else if (event == AuthChangeEvent.signedOut) {
          debugPrint('🚪 [API] Auth state: signed out, clearing stored token');
          _tokenRefreshTimer?.cancel();
          _tokenRefreshTimer = null;
          await clearAuth();
          unawaited(SentryService.clearUser());
        }
      },
      onError: (error) {
        debugPrint('❌ [API] Auth state listener error: $error');
      },
    );
    debugPrint('✅ [API] Auth state listener started');

    // Schedule proactive refresh for the current session (if any)
    _scheduleProactiveRefresh();

    // Register lifecycle observer so we can check token on app resume
    WidgetsBinding.instance.addObserver(this);
  }

  /// Idempotent backend backfill — POST /users/auth/sync.
  ///
  /// Every Supabase signedIn event triggers this so the `public.users` row
  /// is guaranteed to exist before any other API call runs. Critical for the
  /// email-confirmation deep-link path, where Supabase auto-restores a
  /// session without going through `signInWithEmail` (the only existing
  /// path that creates the public.users row).
  ///
  /// Uses a raw Dio call with the fresh token directly to avoid relying on
  /// the storage-write→read race in the same listener tick.
  Future<void> _ensurePublicUserRow(String accessToken) async {
    try {
      await _dio.post(
        '${ApiConstants.users}/auth/sync',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      debugPrint('✅ [API] auth/sync ensured public.users row');
    } catch (e) {
      // Non-fatal: next protected call will surface the underlying error if
      // the row is genuinely missing. We log and move on so transient
      // failures don't block app startup.
      debugPrint('⚠️ [API] auth/sync failed (non-fatal): $e');
    }
  }

  /// Schedule a timer to proactively refresh the Supabase token
  /// [_refreshBufferMinutes] minutes before it expires.
  void _scheduleProactiveRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final expiresAt = session.expiresAt; // Unix timestamp in seconds
    if (expiresAt == null) return;

    final expiresAtDate = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    final refreshAt = expiresAtDate.subtract(Duration(minutes: _refreshBufferMinutes));
    final delay = refreshAt.difference(DateTime.now());

    if (delay.isNegative) {
      // Already past the proactive refresh window -- refresh immediately
      debugPrint('⚠️ [Auth] Token expires soon or already expired, refreshing now...');
      Supabase.instance.client.auth.refreshSession().then((_) {
        debugPrint('✅ [Auth] Immediate proactive refresh succeeded');
        // The onAuthStateChange listener will re-schedule
      }).catchError((e) {
        debugPrint('❌ [Auth] Immediate proactive refresh failed: $e');
      });
      return;
    }

    debugPrint('🔄 [Auth] Proactive refresh scheduled in ${delay.inMinutes}m ${delay.inSeconds % 60}s');
    _tokenRefreshTimer = Timer(delay, () async {
      try {
        await Supabase.instance.client.auth.refreshSession();
        debugPrint('✅ [Auth] Proactively refreshed token before expiry');
        // The onAuthStateChange listener will call _scheduleProactiveRefresh again
      } catch (e) {
        debugPrint('❌ [Auth] Proactive token refresh failed: $e');
        // Try again in 30 seconds in case of transient network issue
        _tokenRefreshTimer = Timer(const Duration(seconds: 30), () {
          _scheduleProactiveRefresh();
        });
      }
    });
  }

  /// Called by the system when the app lifecycle state changes.
  /// Verifies and refreshes the auth token when the app resumes from background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyAndRefreshTokenOnResume();
    }
  }

  /// When the app comes back from the background, check if the token is close
  /// to expiring (or already expired) and refresh it proactively.
  Future<void> _verifyAndRefreshTokenOnResume() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;

      final expiresAt = session.expiresAt;
      if (expiresAt == null) return;

      final expiresAtDate = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      final bufferThreshold = expiresAtDate.subtract(Duration(minutes: _refreshBufferMinutes));

      if (DateTime.now().isAfter(bufferThreshold)) {
        debugPrint('🔄 [Auth] App resumed, token near/past expiry -- refreshing...');
        await Supabase.instance.client.auth.refreshSession();
        debugPrint('✅ [Auth] Token refreshed on app resume');
      } else {
        debugPrint('✅ [Auth] App resumed, token still valid');
      }

      // Re-schedule proactive refresh (timer may have fired/been cancelled while in background)
      _scheduleProactiveRefresh();
    } catch (e) {
      debugPrint('❌ [Auth] Token refresh on resume failed: $e');
    }
  }

  /// Dispose resources (auth listener, proactive refresh timer, lifecycle observer)
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Get the Dio instance
  Dio get dio => _dio;

  /// Get the base URL
  String get baseUrl => ApiConstants.apiBaseUrl;

  /// Resolve a redirect Location header against `apiBaseUrl` so a 307/308
  /// retry doesn't end up double-prefixed (`/api/v1/api/v1/...`).
  ///
  /// Dio concatenates `baseUrl` + `options.path` literally, so when a
  /// FastAPI redirect Location like `/api/v1/workouts/.../share-link/`
  /// is fed back as `options.path`, the next request hits
  /// `/api/v1/api/v1/...` and 404s. Strip the shared `apiVersion` prefix
  /// when present; absolute URLs (http*) are passed through unchanged.
  static String _resolveRedirectPath(String redirectUrl) {
    if (redirectUrl.startsWith('http://') || redirectUrl.startsWith('https://')) {
      return redirectUrl;
    }
    final prefix = ApiConstants.apiVersion;
    if (redirectUrl.startsWith('$prefix/')) {
      return redirectUrl.substring(prefix.length);
    }
    return redirectUrl;
  }

  /// Get auth headers for manual requests (e.g., streaming).
  /// Always uses the CURRENT Supabase session token to avoid stale tokens.
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _getCurrentAccessToken();
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  /// Save auth token
  Future<void> setAuthToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Save user ID
  Future<void> setUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  /// Get stored auth token
  Future<String?> getAuthToken() async {
    return _storage.read(key: _tokenKey);
  }

  /// Clear auth data
  Future<void> clearAuth() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ─────────────────────────────────────────────────────────────────
  // HTTP Methods
  // ─────────────────────────────────────────────────────────────────

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    void Function(int, int)? onSendProgress,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      onSendProgress: onSendProgress,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Upload file using multipart form data
  Future<Response<dynamic>> uploadFile(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
    Options? options,
  }) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
      if (extraFields != null) ...extraFields,
    });

    return _dio.post(
      path,
      data: formData,
      options: options ?? Options(
        contentType: 'multipart/form-data',
      ),
    );
  }
}
