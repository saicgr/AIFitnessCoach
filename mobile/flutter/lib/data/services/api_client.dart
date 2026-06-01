import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
// dio_http2_adapter intentionally NOT imported — see comment block where the
// adapter is configured below. Reintroduce only after wiring a gzip
// decompressor for HTTP/2 responses, otherwise sign-in breaks.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../../core/providers/locale_provider.dart';
import '../providers/chat_locale_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart' show SentryLevel;
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

/// Wires the current app locale into [ApiClient] so the Accept-Language header
/// stays in sync whenever the user changes their language in Settings.
///
/// Consume this provider once near the app root (e.g. in MaterialApp builder)
/// to activate the side-effect. Separate from [apiClientProvider] so that
/// locale changes don't recreate the entire HTTP client.
final acceptLanguageSyncProvider = Provider<void>((ref) {
  final localeState = ref.watch(localeProvider);
  final client = ref.read(apiClientProvider);
  client.updateAcceptLanguage(localeState.locale?.toLanguageTag());
});

/// Wires the AI Coach chat locale into [ApiClient] so the X-Chat-Locale header
/// stays in sync whenever the user changes their chat language in Settings.
///
/// Consume this provider once near the app root alongside [acceptLanguageSyncProvider].
/// Null chat locale → header omitted → backend falls back to preferred_locale.
final chatLocaleSyncProvider = Provider<void>((ref) {
  final chatLocaleState = ref.watch(chatLocaleProvider);
  final client = ref.read(apiClientProvider);
  client.updateChatLocale(chatLocaleState.locale?.languageCode);
});

/// HTTP API client with auth interceptor
class ApiClient with WidgetsBindingObserver {
  final FlutterSecureStorage _storage;
  late final Dio _dio;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _tokenRefreshTimer;

  /// The BCP-47 language tag to send as `Accept-Language`, e.g. `"en"`, `"fr"`.
  /// `null` = system default (header is omitted; server defaults to `en`).
  String? _currentAcceptLanguage;

  /// Called by [acceptLanguageSyncProvider] whenever the user's locale changes.
  void updateAcceptLanguage(String? languageTag) {
    _currentAcceptLanguage = languageTag;
  }

  /// The ISO 639-1 code to send as `X-Chat-Locale`, e.g. `"te"`, `"hi"`.
  /// `null` = no override (header omitted; server falls back to preferred_locale).
  String? _currentChatLocale;

  /// Called by [chatLocaleSyncProvider] whenever the user's chat locale changes.
  void updateChatLocale(String? languageCode) {
    _currentChatLocale = languageCode;
  }

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  /// Optional hook to refresh the auth session. Returns `true` if a new
  /// access token is now available on the Supabase client. Wired from the
  /// `apiClientProvider` once `AuthRepository` is constructed — see
  /// [authRepositoryProvider] in `auth_repository.dart`.
  ///
  /// Kept as a callback (not a direct AuthRepository reference) to avoid the
  /// circular import: `auth_repository.dart` already imports this file.
  Future<bool> Function()? onTokenRefresh;

  /// Optional hook to force a full sign-out (clears Supabase session,
  /// third-party identities, Drift rows, in-memory caches, disk cache).
  /// Wired from `authRepositoryProvider`.
  Future<void> Function()? onForceSignOut;

  /// In-flight refresh coalescing — when several requests 401 in parallel,
  /// only the first one actually calls `onTokenRefresh`; the others await
  /// the same `Future<bool>` and then retry against the freshly-rotated
  /// token. Cleared (set to `null`) once the refresh completes regardless
  /// of outcome.
  Future<bool>? _refreshInFlight;

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
              // Hard timeout: a hung refresh must NOT block the request path
              // forever (see ApiConstants.tokenRefreshTimeout). On timeout we
              // fall through to the stale token and let the 401 interceptor
              // drive recovery (refresh-with-cap → force sign-out).
              final refreshed = await Supabase.instance.client.auth
                  .refreshSession()
                  .timeout(ApiConstants.tokenRefreshTimeout);
              if (refreshed.session != null) {
                debugPrint('✅ [API] Inline token refresh succeeded');
                return refreshed.session!.accessToken;
              }
            } on TimeoutException {
              debugPrint('❌ [API] Inline token refresh timed out after '
                  '${ApiConstants.tokenRefreshTimeout.inSeconds}s — using stale token, 401 path will recover');
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

  /// Single refresh attempt — prefers the wired [onTokenRefresh] hook
  /// (which routes through `AuthRepository.restoreSession()` so the
  /// `public.users` row, Sentry user tag, and cached profile all stay in
  /// sync) and falls back to a raw Supabase `refreshSession()` call when
  /// no hook is wired yet (e.g. earliest startup).
  ///
  /// Always returns a non-null bool; throws only on truly unexpected
  /// errors. Storage write + proactive-refresh re-arm happen in the
  /// onAuthStateChange listener so we don't duplicate them here.
  Future<bool> _refreshOnce() async {
    // Both refresh paths are capped (ApiConstants.tokenRefreshTimeout). A hung
    // refresh would otherwise never resolve, and since the 401 interceptor
    // coalesces every authenticated request onto this single future, one hang
    // wedges the whole app. A TimeoutException here is caught by the caller's
    // `catch (refreshError)` → refreshFailedFatally → force sign-out.
    final hook = onTokenRefresh;
    if (hook != null) {
      return await hook().timeout(ApiConstants.tokenRefreshTimeout);
    }
    final refreshed = await Supabase.instance.client.auth
        .refreshSession()
        .timeout(ApiConstants.tokenRefreshTimeout);
    final session = refreshed.session;
    if (session == null) return false;
    await _storage.write(key: _tokenKey, value: session.accessToken);
    _scheduleProactiveRefresh();
    return true;
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
          // gzip only — `dio_http2_adapter` does NOT auto-decompress responses,
          // and Dio's body parser only handles gzip via the IOHttpClientAdapter
          // (`autoUncompress = true`). Adding `br` here previously caused the
          // server to brotli-encode responses, which the client then tried to
          // JSON-parse byte-for-byte → "FormatException Unexpected character
          // (at offset 0)" → sign-in error pill. Stick with gzip + the default
          // IOHttpClientAdapter until we have a decompressor for HTTP/2.
          'Accept-Encoding': 'gzip',
        },
      ),
    );

    // Reverted from `dio_http2_adapter` back to the default IOHttpClientAdapter.
    // The HTTP/2 adapter would multiplex 12+ parallel prewarmer requests onto
    // one TCP connection (faster), but it does NOT auto-decompress gzipped
    // response bodies. With `Accept-Encoding: gzip` set, the server compresses
    // responses, the HTTP/2 adapter delivers raw 0x1f-prefixed bytes, and Dio's
    // JSON decoder throws FormatException at offset 0 → sign-in fails.
    //
    // We accept the loss of HTTP/2 multiplexing (~200-400ms slower cold-start
    // prewarmer fan-out on cellular) in exchange for sign-in actually working.
    // Re-enable HTTP/2 only after wiring an explicit gzip decompressor or
    // switching to a HTTP/2 adapter that handles Content-Encoding (cronet_http
    // is a candidate — it auto-handles compression server-side).
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 30);
      // 32, not 6. We reverted from the HTTP/2 adapter (which multiplexed all
      // parallel requests onto ONE connection) back to HTTP/1.1, where every
      // in-flight request needs its own connection. Home + Nutrition fan out
      // 12+ requests on mount, several of them slow LLM calls (coach insight,
      // breakfast/training insight, nutrition AI feedback) that hold a
      // connection for many seconds up to aiReceiveTimeout (2 min). With a cap
      // of 6, those slow calls saturated the pool and the fast
      // /nutrition/summary/daily request could never acquire a socket — it died
      // with DioException[connectionTimeout] at 25s ("nutrition not loading"),
      // while a one-off direct call always connected. 64 comfortably exceeds the
      // realistic concurrent burst (~12-20) so fast data requests never queue
      // behind slow AI ones. (dart:io's default is unlimited; 6 was an arbitrary
      // throttle.)
      client.maxConnectionsPerHost = 64;
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

    // /exercise-images/ 404 swallow: AI-generated workouts occasionally
    // contain hallucinated exercise names (e.g. "Major Groups Muscle Body")
    // that aren't in the library, so the lookup 404s. That's an expected
    // miss, not a bug — return an empty 200 response with `url=null` so
    // callers fall back to the placeholder without throwing DioException
    // (which otherwise floods Sentry with FITWIZ-FLUTTER-8W noise).
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final path = error.requestOptions.path;
          if (error.response?.statusCode == 404 &&
              path.startsWith('/exercise-images/') &&
              !path.startsWith('/exercise-images/batch')) {
            return handler.resolve(
              Response(
                requestOptions: error.requestOptions,
                statusCode: 200,
                data: const {'url': null, 'reason': 'not_in_library'},
              ),
            );
          }
          // /activity/sync 403 swallow: backend rejects sync when the user
          // hasn't opted into health-data processing. ActivityService already
          // gates retries; we just need to keep this out of Sentry.
          if (error.response?.statusCode == 403 &&
              (path.startsWith('/activity/sync') ||
                  path.startsWith('/activity/sync-batch'))) {
            return handler.resolve(
              Response(
                requestOptions: error.requestOptions,
                statusCode: 200,
                data: const {'skipped': true, 'reason': 'no_health_consent'},
              ),
            );
          }
          handler.next(error);
        },
      ),
    );

    // Transient-failure retry interceptor. Retries only failures that are
    // SAFE to repeat, up to 2 times, with exponential backoff + jitter:
    //   • connectionTimeout — the TCP connect never completed, so the request
    //     never reached the server. Safe to retry for any HTTP method.
    //   • HTTP 503 — server overloaded / restarting. Retried for idempotent
    //     methods (GET) ONLY, so a write is never double-submitted.
    // receive-timeouts and 4xx / other-5xx are NOT retried — those are real
    // errors, and a receive-timeout may mean a write already landed.
    // Jitter prevents a fleet of clients from resynchronising into a retry
    // storm against a briefly-degraded backend.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final opts = error.requestOptions;
          final attempt = (opts.extra['_transientRetry'] as int?) ?? 0;
          final isConnectTimeout =
              error.type == DioExceptionType.connectionTimeout;
          final isOverloaded = error.response?.statusCode == 503;
          final isIdempotent = opts.method.toUpperCase() == 'GET';
          final retryable =
              isConnectTimeout || (isOverloaded && isIdempotent);
          if (retryable && attempt < 2) {
            opts.extra['_transientRetry'] = attempt + 1;
            // Exponential backoff (~0.5s, ~1s) + up to 400ms random jitter.
            final baseMs = 500 * (1 << attempt);
            final delay = Duration(milliseconds: baseMs + Random().nextInt(400));
            debugPrint(
                '🔄 [API] Transient failure (${error.type}/${error.response?.statusCode}), '
                'retry ${attempt + 1}/2 in ${delay.inMilliseconds}ms...');
            await Future.delayed(delay);
            try {
              final retryResponse = await _dio.fetch(opts);
              return handler.resolve(retryResponse);
            } catch (retryError) {
              debugPrint('❌ [API] Transient retry failed: $retryError');
              // fall through to reporting the original error
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
          // Short-circuit: once we've detected JWT_USER_DELETED, the auth
          // user is gone server-side and every subsequent request will 401.
          // Reject in-flight requests locally to avoid the duplicate 401
          // storm + noisy DioException stack traces in the console.
          if (_userDeletedSignOutInFlight) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'JWT_USER_DELETED — request cancelled',
              ),
            );
          }
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
              // Replace the noisy 401 bad-response with a benign cancel —
              // callers' catch handlers will see a cancellation instead of
              // re-logging a full DioException stack for every duplicate.
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  type: DioExceptionType.cancel,
                  error: 'JWT_USER_DELETED — duplicate 401 suppressed',
                ),
              );
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
            // Loop-prevention tag: once a request has been retried after a
            // successful refresh, a second 401 means the new JWT is ALSO
            // invalid → fall straight through to forced sign-out instead
            // of attempting to refresh again. Backwards-compatible with the
            // older `_retryCount` integer.
            final alreadyRetried =
                error.requestOptions.extra['authRetried'] == true;
            final retryCount =
                error.requestOptions.extra['_retryCount'] as int? ?? 0;
            bool refreshFailedFatally = false;
            if (!alreadyRetried && retryCount < 2) {
              try {
                debugPrint(
                    '🔄 [API] 401 received (attempt ${retryCount + 1}/2), refreshing token...');

                // Coalesce parallel 401s onto a single in-flight refresh.
                // Otherwise N concurrent failed requests would each call
                // refreshSession() and burn rate-limit + race the storage
                // write that the listener performs.
                //
                // The latch is cleared via `whenComplete` so it ALWAYS resets
                // when the underlying refresh settles — success, failure, or
                // the tokenRefreshTimeout firing. Clearing it only after the
                // `await` (the old code) meant a hung refresh never reset the
                // latch, so every subsequent 401 coalesced onto a dead future
                // and the whole app wedged. `_refreshOnce()` is now time-capped,
                // and the latch can no longer get stuck regardless.
                final refreshFuture = _refreshInFlight ??=
                    _refreshOnce().whenComplete(() => _refreshInFlight = null);
                final ok = await refreshFuture;

                if (ok) {
                  final newToken = await _getCurrentAccessToken();
                  if (newToken != null) {
                    debugPrint(
                        '✅ [API] Token refreshed, retrying request (attempt ${retryCount + 1})...');
                    error.requestOptions.headers['Authorization'] =
                        'Bearer $newToken';
                    error.requestOptions.headers['X-Auth-Retry'] = '1';
                    error.requestOptions.extra['authRetried'] = true;
                    error.requestOptions.extra['_retryCount'] = retryCount + 1;
                    final retryResponse =
                        await _dio.fetch(error.requestOptions);
                    return handler.resolve(retryResponse);
                  }
                }
                // Refresh hook reported failure without throwing — treat as
                // a dead session.
                refreshFailedFatally = true;
              } catch (refreshError) {
                // `_refreshInFlight` is cleared by the future's whenComplete —
                // no manual reset here (avoids nulling a newer in-flight latch).
                debugPrint(
                    '❌ [API] Retry ${retryCount + 1} refresh failed: $refreshError');
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

            // Either (a) refresh threw / returned false, (b) the retried
            // request still 401'd, or (c) we burned through 2 retries.
            // All three mean the session is dead — force a full sign-out
            // (clears third-party identities, Drift rows, in-memory caches
            // via AuthRepository.signOut() if wired) and resolve this
            // request with a synthetic 401 so the caller bails instead of
            // hanging on a Future that never completes.
            if (refreshFailedFatally || alreadyRetried || retryCount >= 2) {
              debugPrint(
                  '🚪 [API] Session unrecoverable, signing out to reset auth state');
              try {
                SentryService.addBreadcrumb(
                  category: 'auth.401',
                  level: SentryLevel.error,
                  message: 'Forced sign-out — refresh failed',
                  data: {
                    'path': error.requestOptions.path,
                    'method': error.requestOptions.method,
                    'retryCount': retryCount,
                    'alreadyRetried': alreadyRetried,
                  },
                );
              } catch (_) {
                // Sentry disabled or not initialised — never block sign-out.
              }
              try {
                if (onForceSignOut != null) {
                  await onForceSignOut!();
                } else {
                  // Fallback path used before AuthRepository wires the hook
                  // (e.g. very early startup). The onAuthStateChange listener
                  // will still clear stored tokens.
                  await Supabase.instance.client.auth.signOut();
                }
              } catch (signOutError) {
                debugPrint('❌ [API] Force sign-out failed: $signOutError');
                // Still clear local auth as last resort
                await clearAuth();
              }
              // Replace the bad-response with a synthetic, terminal 401 so
              // the caller's catch-handler runs exactly once instead of
              // re-triggering this branch.
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  type: DioExceptionType.badResponse,
                  error: 'Session expired — signed out',
                ),
              );
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

    // Accept-Language interceptor — attaches the user's chosen locale so the
    // backend can return locale-aware content (AI replies, exercise names, etc).
    // Null locale = header omitted → backend defaults to 'en'.
    // Updated reactively via [updateAcceptLanguage] whenever the user changes
    // their language in Settings (driven by [acceptLanguageSyncProvider]).
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final lang = _currentAcceptLanguage;
          if (lang != null && lang.isNotEmpty) {
            options.headers['Accept-Language'] = lang;
          }
          return handler.next(options);
        },
      ),
    );

    // X-Chat-Locale interceptor — tells the backend which language the AI Coach
    // should reply in (independent of the UI locale). Null = header omitted →
    // backend falls back to preferred_locale. Updated reactively via
    // [updateChatLocale] whenever the user changes AI Chat Language in Settings
    // (driven by [chatLocaleSyncProvider]).
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final chatLang = _currentChatLocale;
          if (chatLang != null && chatLang.isNotEmpty) {
            options.headers['X-Chat-Locale'] = chatLang;
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
      Supabase.instance.client.auth
          .refreshSession()
          .timeout(ApiConstants.tokenRefreshTimeout)
          .then((_) {
        debugPrint('✅ [Auth] Immediate proactive refresh succeeded');
        // The onAuthStateChange listener will re-schedule
      }).catchError((e) {
        // Includes TimeoutException — a hung background refresh must not pin
        // a never-completing future. The 401 interceptor remains the backstop.
        debugPrint('❌ [Auth] Immediate proactive refresh failed: $e');
      });
      return;
    }

    debugPrint('🔄 [Auth] Proactive refresh scheduled in ${delay.inMinutes}m ${delay.inSeconds % 60}s');
    _tokenRefreshTimer = Timer(delay, () async {
      try {
        await Supabase.instance.client.auth
            .refreshSession()
            .timeout(ApiConstants.tokenRefreshTimeout);
        debugPrint('✅ [Auth] Proactively refreshed token before expiry');
        // The onAuthStateChange listener will call _scheduleProactiveRefresh again
      } catch (e) {
        // Includes TimeoutException — fall through to the 30s retry below.
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
        await Supabase.instance.client.auth
            .refreshSession()
            .timeout(ApiConstants.tokenRefreshTimeout);
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

  /// Normalise a 307/308 redirect `Location` into a clean absolute-path
  /// reference (leading `/`, NO `/api/v1` prefix) so the retried request
  /// resolves to exactly one `/api/v1` once Dio prepends `baseUrl`.
  ///
  /// Three forms of `Location` all have to be handled or the retry
  /// double-prefixes (`/api/v1/api/v1/...` → 404 — seen in prod on the
  /// hormonal-health/trends call):
  ///   1. absolute URL  `https://host/api/v1/x/`  → reduce to `/x/`
  ///   2. path with version `/api/v1/x/`          → strip to `/x/`
  ///   3. RELATIVE ref `api/v1/x/` (no leading /) → Dio resolves it
  ///      against `baseUrl`'s directory, yielding `/api/v1/api/v1/x/`.
  /// The fix: drop scheme+host, force a leading slash, then collapse
  /// every leading `apiVersion` segment (baseUrl already carries one).
  static String _resolveRedirectPath(String redirectUrl) {
    var p = redirectUrl;
    if (p.startsWith('http://') || p.startsWith('https://')) {
      final u = Uri.parse(p);
      p = u.path + (u.hasQuery ? '?${u.query}' : '');
    }
    if (!p.startsWith('/')) p = '/$p';
    final prefix = ApiConstants.apiVersion; // '/api/v1'
    while (p.startsWith('$prefix/')) {
      p = p.substring(prefix.length);
    }
    return p;
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

  /// In-memory cache + coalescing latch for the user id.
  ///
  /// getUserId() sits on MANY hot paths (every metric tile, the nutrition hero
  /// card, the chat-history + timeline + nutrition notifiers, the auth
  /// interceptor). FlutterSecureStorage serializes all reads through a single
  /// platform channel, so a burst of concurrent getUserId() calls (e.g. the
  /// home deck's tiles + cards all mounting at once) contend and can stall —
  /// which wedges every authed load simultaneously (skeletons that never
  /// resolve, "couldn't load" errors). The id is immutable for a session, so:
  ///   * we read storage AT MOST ONCE and serve every later caller from memory;
  ///   * concurrent first-callers share ONE in-flight read (no stampede);
  ///   * the read is timeout-capped so a wedged keychain can never hang callers.
  String? _cachedUserId;
  Future<String?>? _userIdReadInFlight;

  /// Save user ID
  Future<void> setUserId(String userId) async {
    _cachedUserId = userId;
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get stored user ID (memory-cached, coalesced, timeout-capped).
  Future<String?> getUserId() async {
    final cached = _cachedUserId;
    if (cached != null) return cached;
    final inFlight = _userIdReadInFlight;
    if (inFlight != null) return inFlight;
    final future = _readUserIdFromStorage();
    _userIdReadInFlight = future;
    try {
      return await future;
    } finally {
      _userIdReadInFlight = null;
    }
  }

  Future<String?> _readUserIdFromStorage() async {
    try {
      final id = await _storage
          .read(key: _userIdKey)
          .timeout(const Duration(seconds: 5));
      if (id != null) _cachedUserId = id;
      return id;
    } catch (_) {
      // Wedged / timed-out keychain read → null; the 401 path recovers auth if
      // the id was genuinely lost. Never hang the caller.
      return null;
    }
  }

  /// Get stored auth token
  Future<String?> getAuthToken() async {
    return _storage.read(key: _tokenKey);
  }

  /// Clear auth data
  Future<void> clearAuth() async {
    _cachedUserId = null;
    _userIdReadInFlight = null;
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

  /// Swap a workout to a lighter / moderate / bodyweight variant.
  ///
  /// POSTs to `/workouts/{workoutId}/swap-variant` with
  /// `{ "target_intensity": <kind> }` and returns the parsed JSON body
  /// `{ workout_id, source_workout_id, target_intensity, name,
  ///    duration_minutes, exercise_count, cached }`.
  ///
  /// Surfaces backend errors directly (no silent fallback). Callers
  /// should catch `DioException` and render an error coach turn so the
  /// user knows the swap didn't happen — never pretend success.
  Future<Map<String, dynamic>> swapWorkoutVariant(
    String workoutId,
    String targetIntensity,
  ) async {
    final res = await _dio.post<dynamic>(
      '/workouts/$workoutId/swap-variant',
      data: <String, dynamic>{
        'target_intensity': targetIntensity,
      },
    );
    final body = res.data;
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    throw StateError(
      'swapWorkoutVariant: unexpected response shape ${body.runtimeType}',
    );
  }

  /// Execute an injury recovery check-in chip action (WS-B).
  ///
  /// [action] is one of `injury_resolved` / `injury_extend` / `start_rehab`.
  /// One of [bodyPart] / [injuryId] identifies the injury (the check-in chip
  /// carries both). Returns the server payload — `message` (a confirmation
  /// line) and, for `start_rehab`, `workout_id` to route to the rehab session.
  Future<Map<String, dynamic>> injuryAction({
    required String action,
    String? bodyPart,
    String? injuryId,
  }) async {
    final res = await _dio.post<dynamic>(
      '/coach/injury-action',
      data: <String, dynamic>{
        'action': action,
        if (bodyPart != null && bodyPart.isNotEmpty) 'body_part': bodyPart,
        if (injuryId != null && injuryId.isNotEmpty) 'injury_id': injuryId,
      },
    );
    final body = res.data;
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    throw StateError(
      'injuryAction: unexpected response shape ${body.runtimeType}',
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
