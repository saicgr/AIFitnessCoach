import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../../core/constants/api_constants.dart';

/// Secure storage for auth tokens
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

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

  /// How many minutes before expiry to proactively refresh the token.
  static const _refreshBufferMinutes = 5;

  /// Get the current valid access token from the live Supabase session.
  /// Falls back to the stored token if Supabase session is not available
  /// (e.g., during initial startup before Supabase is fully initialized).
  Future<String?> _getCurrentAccessToken() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
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
        },
      ),
    );

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
            options.path = redirectUrl;
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
            options.path = redirectUrl;
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
            final retryCount = error.requestOptions.extra['_retryCount'] as int? ?? 0;
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
              }
            }

            // All refresh attempts exhausted -- force sign-out to avoid broken state
            if (retryCount >= 2) {
              debugPrint('🚪 [API] All refresh attempts failed, signing out to reset auth state');
              try {
                await Supabase.instance.client.auth.signOut();
                // The onAuthStateChange listener will handle clearing stored tokens
              } catch (signOutError) {
                debugPrint('❌ [API] Force sign-out failed: $signOutError');
                // Still clear local auth as last resort
                await clearAuth();
              }
            } else {
              // Only clear auth if we didn't even get to retry
              debugPrint('🚪 [API] Clearing auth after failed refresh');
              await clearAuth();
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Timezone interceptor — attaches X-User-Timezone header to every request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final tz = prefs.getString('user_timezone');
            if (tz != null && tz.isNotEmpty) {
              options.headers['X-User-Timezone'] = tz;
            } else {
              // Fallback: use device timezone name
              options.headers['X-User-Timezone'] = DateTime.now().timeZoneName;
            }
          } catch (e) {
            debugPrint('⚠️ [API] Could not attach timezone header: $e');
          }
          return handler.next(options);
        },
      ),
    );

    // Logging (debug only)
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
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
          await _storage.write(key: _tokenKey, value: session.accessToken);
          // Re-schedule proactive refresh whenever we get a new token
          _scheduleProactiveRefresh();
        } else if (event == AuthChangeEvent.signedOut) {
          debugPrint('🚪 [API] Auth state: signed out, clearing stored token');
          _tokenRefreshTimer?.cancel();
          _tokenRefreshTimer = null;
          await clearAuth();
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
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
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
