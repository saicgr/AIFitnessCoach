import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
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
  return ApiClient(storage);
});

/// HTTP API client with auth interceptor
class ApiClient {
  final FlutterSecureStorage _storage;
  late final Dio _dio;

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

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

    // Auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Try to refresh Supabase session before clearing auth
            try {
              final session = Supabase.instance.client.auth.currentSession;
              if (session != null) {
                debugPrint('🔄 [API] 401 received, attempting token refresh...');
                final refreshed = await Supabase.instance.client.auth.refreshSession();
                if (refreshed.session != null) {
                  // Save new token
                  await _storage.write(key: _tokenKey, value: refreshed.session!.accessToken);
                  debugPrint('✅ [API] Token refreshed, retrying request...');

                  // Retry the original request with new token
                  error.requestOptions.headers['Authorization'] = 'Bearer ${refreshed.session!.accessToken}';
                  final retryResponse = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (refreshError) {
              debugPrint('❌ [API] Token refresh failed: $refreshError');
            }

            // Only clear auth if refresh failed
            debugPrint('🚪 [API] Clearing auth after failed refresh');
            await clearAuth();
          }
          return handler.next(error);
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

  /// Get the Dio instance
  Dio get dio => _dio;

  /// Get the base URL
  String get baseUrl => ApiConstants.apiBaseUrl;

  /// Get auth headers for manual requests (e.g., streaming)
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _storage.read(key: _tokenKey);
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
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
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
