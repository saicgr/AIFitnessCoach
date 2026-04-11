import 'package:flutter/foundation.dart';

/// Centralized date/time utilities for timezone-safe API communication.
///
/// The backend runs on UTC (Render). All timestamps sent to the API must be
/// in UTC so the backend stores them correctly. All "date" query parameters
/// must use the user's LOCAL date so "today" means the user's today, not
/// the server's UTC today.
///
/// Usage:
///   import '../../utils/tz.dart';
///
///   // For timestamps (logged_at, completed_at, adjusted_at, etc.):
///   'logged_at': Tz.timestamp(),
///
///   // For date query params ("what day's data?"):
///   queryParameters: {'date': Tz.localDate()},
class Tz {
  Tz._();

  /// UTC ISO-8601 timestamp for API fields like logged_at, completed_at, etc.
  /// Always sends UTC so the backend interprets it unambiguously.
  static String timestamp([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    final utc = now.toUtc().toIso8601String();
    if (kDebugMode && now.day != now.toUtc().day) {
      debugPrint('🕐 [Tz] timestamp: local=${now.toIso8601String()} utc=$utc (days differ!)');
    }
    return utc;
  }

  /// User's local date as YYYY-MM-DD string for date query parameters.
  /// Ensures "today" means the user's local today, not server UTC today.
  static String localDate([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    final local = now.toIso8601String().substring(0, 10);
    final utcDate = now.toUtc().toIso8601String().substring(0, 10);
    if (kDebugMode && local != utcDate) {
      debugPrint('🕐 [Tz] localDate=$local utcDate=$utcDate tz=${now.timeZoneName} (differ!)');
    }
    return local;
  }
}
