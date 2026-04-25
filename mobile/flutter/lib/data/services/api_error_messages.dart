import 'package:dio/dio.dart';

/// Human-friendly error message + retry advice for API failures.
///
/// Goal: when an API call fails, distinguish:
///   - Device offline                  → "You're offline. Check your connection."
///   - Backend slow / unreachable      → "We're having trouble reaching our servers."
///   - Backend returned 5xx            → "Our servers are having trouble."
///   - Backend returned 4xx non-auth   → use the server's detail message
///   - Auth failure (401/403)         → "Please sign in again."
///   - Other / unknown                 → "Something went wrong. Please try again."
///
/// Each message is short, blame-free, and points at a specific cause so the
/// user can decide whether retrying or waiting is the right move. We keep
/// these scoped to the error TYPE rather than the endpoint — every screen's
/// retry button calls back through the same helper.
class ApiErrorMessages {
  ApiErrorMessages._();

  /// Map a DioException to a human-friendly message. Returns one of the
  /// constants below — all under 80 chars so it fits in a SnackBar without
  /// truncation on a 360px-wide phone.
  static String forDio(Object error) {
    if (error is! DioException) {
      // Generic exception — could be parsing, state, etc. Don't leak internals.
      return genericFailure;
    }

    switch (error.type) {
      case DioExceptionType.connectionError:
        // Common cases: device airplane mode, captive portal, DNS failure.
        return offline;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // Backend reachable but slow. Distinct from a hard offline so the
        // user knows retrying might work in a few seconds.
        return backendSlow;
      case DioExceptionType.cancel:
        return cancelled;
      case DioExceptionType.badCertificate:
        return certificateError;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == null) return genericFailure;
        if (status == 401 || status == 403) return authRequired;
        if (status == 404) return notFound;
        if (status == 429) return rateLimited;
        if (status >= 500) return backendError;

        // 4xx other than auth/notFound/rateLimited — pull the server's
        // detail field if present, otherwise generic.
        final data = error.response?.data;
        if (data is Map && data['detail'] is String) {
          final detail = (data['detail'] as String).trim();
          if (detail.isNotEmpty && detail.length < 200) return detail;
        }
        return genericFailure;
      case DioExceptionType.unknown:
        return genericFailure;
    }
  }

  /// Whether retrying *might* succeed for this error type. UI uses this to
  /// decide between showing a Retry button vs only a Dismiss.
  static bool isRetryable(Object error) {
    if (error is! DioException) return true;
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        // 5xx and 429 are worth retrying; 4xx generally is not.
        return status >= 500 || status == 429;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  // -- Message constants -----------------------------------------------------

  static const String offline =
      "You're offline. Check your connection and try again.";
  static const String backendSlow =
      "We're having trouble reaching our servers. Please try again.";
  static const String backendError =
      "Our servers are having trouble. Please try again in a moment.";
  static const String authRequired =
      'Please sign in again to continue.';
  static const String notFound =
      "We couldn't find what you're looking for.";
  static const String rateLimited =
      "You're going a little fast — give us a moment.";
  static const String certificateError =
      "Couldn't verify a secure connection.";
  static const String cancelled = 'Cancelled.';
  static const String genericFailure =
      'Something went wrong. Please try again.';
}
