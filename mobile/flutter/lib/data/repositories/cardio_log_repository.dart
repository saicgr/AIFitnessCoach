import 'package:flutter/foundation.dart';

import '../models/cardio_log.dart';
import '../services/api_client.dart';

/// Repository for the `cardio_logs` backend endpoints (see
/// `backend/api/v1/cardio_logs.py`). This sits alongside
/// `WorkoutHistoryRepository` — strength imports use that one, cardio
/// uses this.
///
/// NOTE: This repository intentionally does not swallow errors. Callers
/// (providers) decide how to surface failures (toast, retry, etc.) — per
/// `feedback_no_silent_fallbacks.md`.
class CardioLogRepository {
  final ApiClient _apiClient;

  CardioLogRepository(this._apiClient);

  /// List cardio sessions for a user, with optional activity-type and date filters.
  Future<List<CardioLog>> getUserCardioLogs({
    required String userId,
    String? activityType,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    debugPrint('🏃 [CardioLogs] fetch user=$userId type=$activityType');

    final qp = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (activityType != null) 'activity_type': activityType,
      if (from != null) 'from': _formatDate(from),
      if (to != null) 'to': _formatDate(to),
    };

    final response = await _apiClient.get(
      '/cardio-logs/user/$userId',
      queryParameters: qp,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load cardio history (${response.statusCode})');
    }

    final rawList = response.data as List<dynamic>;
    return rawList
        .map((row) => CardioLog.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// Aggregated summary — totals, weekly counts, per-activity PRs.
  Future<CardioSummary> getSummary(String userId) async {
    debugPrint('🏃 [CardioLogs] fetch summary user=$userId');

    final response = await _apiClient.get('/cardio-logs/user/$userId/summary');
    if (response.statusCode != 200) {
      throw Exception('Failed to load cardio summary (${response.statusCode})');
    }
    return CardioSummary.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// Single manual insert. Uses the same idempotent `source_row_hash`
  /// dedup as imports — re-submitting the same session → 0 duplicates.
  Future<Map<String, dynamic>> createCardioLog({
    required String userId,
    required DateTime performedAt,
    required String activityType,
    required int durationSeconds,
    double? distanceM,
    double? elevationGainM,
    int? avgHeartRate,
    int? maxHeartRate,
    int? calories,
    double? rpe,
    String? notes,
    String sourceApp = 'manual',
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'performed_at': performedAt.toUtc().toIso8601String(),
      'activity_type': activityType,
      'duration_seconds': durationSeconds,
      'source_app': sourceApp,
      if (distanceM != null) 'distance_m': distanceM,
      if (elevationGainM != null) 'elevation_gain_m': elevationGainM,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
      if (calories != null) 'calories': calories,
      if (rpe != null) 'rpe': rpe,
      if (notes != null) 'notes': notes,
    };

    final response = await _apiClient.post('/cardio-logs', data: payload);
    if (response.statusCode != 200) {
      throw Exception('Failed to log cardio session (${response.statusCode})');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Delete a single entry.
  Future<void> deleteCardioLog({
    required String userId,
    required String entryId,
  }) async {
    final response = await _apiClient.delete(
      '/cardio-logs/user/$userId/entry/$entryId',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete cardio entry (${response.statusCode})');
    }
  }

  static String _formatDate(DateTime d) {
    // ISO-8601 date (YYYY-MM-DD) — matches the `from`/`to` query param format
    // that the FastAPI endpoint's pydantic `date` type expects.
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
