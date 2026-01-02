import 'dart:async' as async;
import 'dart:io';

import 'package:dio/dio.dart';

/// Base exception class for app-specific errors
abstract class AppException implements Exception {
  final String message;
  final String? details;

  const AppException(this.message, [this.details]);

  @override
  String toString() => message;

  /// User-friendly message for display in UI
  String get userMessage => message;
}

/// Exception for network connectivity issues (no internet, DNS failure, etc.)
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Check your internet connection',
    super.details,
  ]);

  @override
  String get userMessage => 'Check your internet connection';
}

/// Exception for request timeout
class AppTimeoutException extends AppException {
  const AppTimeoutException([
    super.message = 'Request timed out. Please try again',
    super.details,
  ]);

  @override
  String get userMessage => 'Request timed out. Please try again';
}

/// Exception for API/server errors (4xx, 5xx responses)
class ApiException extends AppException {
  final int? statusCode;

  const ApiException({
    String message = 'Server error occurred',
    this.statusCode,
    String? details,
  }) : super(message, details);

  @override
  String get userMessage {
    if (statusCode != null) {
      if (statusCode! >= 500) {
        return 'Server is temporarily unavailable (Error $statusCode)';
      } else if (statusCode == 401) {
        return 'Session expired. Please sign in again';
      } else if (statusCode == 403) {
        return 'Access denied';
      } else if (statusCode == 404) {
        return 'Content not found';
      } else if (statusCode! >= 400) {
        return 'Request failed (Error $statusCode)';
      }
    }
    return message;
  }
}

/// Exception for JSON parsing/data format issues
class ParseException extends AppException {
  const ParseException([
    super.message = 'Unable to load data. Please try again',
    super.details,
  ]);

  @override
  String get userMessage => 'Unable to load data. Please try again';
}

/// Exception for authentication errors
class AuthException extends AppException {
  const AuthException([
    super.message = 'Authentication required',
    super.details,
  ]);

  @override
  String get userMessage => 'Please sign in to continue';
}

/// Utility class to convert various exceptions to app-specific exceptions
class ExceptionHandler {
  /// Converts any exception to an appropriate AppException
  static AppException handle(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is SocketException) {
      return NetworkException(
        'Check your internet connection',
        error.message,
      );
    }

    if (error is async.TimeoutException) {
      return const AppTimeoutException();
    }

    if (error is FormatException) {
      return ParseException(
        'Unable to load data. Please try again',
        error.message,
      );
    }

    if (error is TypeError) {
      return ParseException(
        'Unable to load data. Please try again',
        error.toString(),
      );
    }

    // Generic fallback
    return ApiException(
      message: 'Something went wrong. Please try again',
      details: error.toString(),
    );
  }

  /// Handle Dio-specific exceptions
  static AppException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppTimeoutException();

      case DioExceptionType.connectionError:
        // Check if it's a socket exception (no internet)
        if (error.error is SocketException) {
          return const NetworkException();
        }
        return NetworkException(
          'Unable to connect to server',
          error.message,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String? serverMessage;

        // Try to extract error message from response
        if (responseData is Map) {
          serverMessage = responseData['message'] as String? ??
              responseData['error'] as String? ??
              responseData['detail'] as String?;
        }

        return ApiException(
          message: serverMessage ?? 'Server error occurred',
          statusCode: statusCode,
          details: error.message,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled',
        );

      case DioExceptionType.badCertificate:
        return const NetworkException(
          'Security certificate error',
        );

      case DioExceptionType.unknown:
      default:
        // Check for socket exception in the error chain
        if (error.error is SocketException) {
          return const NetworkException();
        }
        return ApiException(
          message: 'Something went wrong. Please try again',
          details: error.message,
        );
    }
  }

  /// Get a user-friendly error message from any exception
  static String getUserMessage(Object error) {
    final appException = handle(error);
    return appException.userMessage;
  }
}

// Legacy alias - keeping for backwards compatibility
typedef TimeoutException = AppTimeoutException;
