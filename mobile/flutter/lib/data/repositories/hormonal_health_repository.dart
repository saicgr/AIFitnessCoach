import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hormonal_health.dart';
import '../services/api_client.dart';
import '../../core/constants/api_constants.dart';

/// `yyyy-MM-dd` — the date-only contract the backend `/periods` and
/// `/prediction` endpoints expect (matches Python `date.isoformat()`).
String _isoDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

/// Repository for hormonal health API interactions
class HormonalHealthRepository {
  final ApiClient _apiClient;

  HormonalHealthRepository(this._apiClient);

  // ============================================================================
  // HORMONAL PROFILE
  // ============================================================================

  /// Get user's hormonal profile
  Future<HormonalProfile?> getProfile(String userId) async {
    try {
      final response = await _apiClient.get('/hormonal-health/profile/$userId');
      if (response.data == null) return null;
      return HormonalProfile.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching hormonal profile: $e');
      return null;
    }
  }

  /// Update or create hormonal profile
  Future<HormonalProfile?> upsertProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _apiClient.put(
        '/hormonal-health/profile/$userId',
        data: profileData,
      );
      return HormonalProfile.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error upserting hormonal profile: $e');
      rethrow;
    }
  }

  /// Delete hormonal profile
  Future<void> deleteProfile(String userId) async {
    try {
      await _apiClient.delete('/hormonal-health/profile/$userId');
    } catch (e) {
      debugPrint('Error deleting hormonal profile: $e');
      rethrow;
    }
  }

  // ============================================================================
  // HORMONE LOGS
  // ============================================================================

  /// Create a hormone log entry
  Future<HormoneLog?> createLog(String userId, Map<String, dynamic> logData) async {
    try {
      final response = await _apiClient.post(
        '/hormonal-health/logs/$userId',
        data: logData,
      );
      return HormoneLog.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error creating hormone log: $e');
      rethrow;
    }
  }

  /// Get hormone logs with optional date range
  Future<List<HormoneLog>> getLogs(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      queryParams['limit'] = limit;

      final response = await _apiClient.get(
        '/hormonal-health/logs/$userId',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => HormoneLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching hormone logs: $e');
      return [];
    }
  }

  /// Get today's hormone log
  Future<HormoneLog?> getTodayLog(String userId) async {
    try {
      final response = await _apiClient.get('/hormonal-health/logs/$userId/today');
      if (response.data == null) return null;
      return HormoneLog.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching today\'s hormone log: $e');
      return null;
    }
  }

  // ============================================================================
  // CYCLE PHASE
  // ============================================================================

  /// Get current cycle phase info
  Future<CyclePhaseInfo?> getCyclePhase(String userId) async {
    try {
      final response = await _apiClient.get('/hormonal-health/cycle-phase/$userId');
      if (response.data == null) return null;
      return CyclePhaseInfo.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching cycle phase: $e');
      return null;
    }
  }

  /// Log period start
  Future<void> logPeriodStart(String userId, {DateTime? periodDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (periodDate != null) {
        queryParams['period_date'] = periodDate.toIso8601String().split('T')[0];
      }

      await _apiClient.post(
        '/hormonal-health/cycle-phase/$userId/log-period',
        queryParameters: queryParams,
      );
    } catch (e) {
      debugPrint('Error logging period start: $e');
      rethrow;
    }
  }

  // ============================================================================
  // HORMONE-SUPPORTIVE FOODS
  // ============================================================================

  /// Get hormone-supportive foods
  Future<List<HormoneSupportiveFood>> getFoods({
    HormoneGoal? goal,
    CyclePhase? cyclePhase,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (goal != null) {
        queryParams['goal'] = goal.toString().split('.').last;
      }
      if (cyclePhase != null) {
        queryParams['cycle_phase'] = cyclePhase.toString().split('.').last;
      }

      final response = await _apiClient.get(
        '/hormonal-health/foods',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => HormoneSupportiveFood.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching hormone-supportive foods: $e');
      return [];
    }
  }

  /// Get personalized food recommendations
  Future<Map<String, dynamic>?> getFoodRecommendations(String userId) async {
    try {
      final response = await _apiClient.get(
        '/hormonal-health/foods/recommendations/$userId',
      );
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching food recommendations: $e');
      return null;
    }
  }

  // ============================================================================
  // COMPREHENSIVE INSIGHTS
  // ============================================================================

  /// Get comprehensive hormonal health insights
  Future<Map<String, dynamic>?> getInsights(String userId) async {
    try {
      final response = await _apiClient.get('/hormonal-health/insights/$userId');
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching hormonal insights: $e');
      return null;
    }
  }

  // ============================================================================
  // CYCLE PREDICTION + PERIOD HISTORY (Phase B)
  // ----------------------------------------------------------------------------
  // These talk to the Phase-A endpoints in `backend/api/v1/hormonal_health.py`.
  // Errors are RETHROWN (no silent fallback per `feedback_no_silent_fallbacks`)
  // so the cycle UI / providers can surface them — the provider layer keeps a
  // cached value + the on-device `CyclePredictor` for instant offline render.
  // ============================================================================

  /// `GET /hormonal-health/prediction/{user_id}` — the full deterministic
  /// cycle prediction: current phase, next-period forecast + confidence
  /// window, ovulation (estimated or BBT-confirmed), fertile window, stats.
  Future<CyclePrediction> getPrediction(String userId) async {
    final response =
        await _apiClient.get(ApiConstants.cyclePrediction(userId));
    final data = response.data;
    if (data is! Map) {
      throw const FormatException(
          'getPrediction: expected a CyclePrediction object');
    }
    return CyclePrediction.fromJson(Map<String, dynamic>.from(data));
  }

  /// `GET /hormonal-health/periods/{user_id}` — the user's logged periods,
  /// newest first. `limit` is clamped server-side to 1..120.
  Future<List<CyclePeriod>> listPeriods(String userId, {int limit = 24}) async {
    final response = await _apiClient.get(
      ApiConstants.cyclePeriods(userId),
      queryParameters: {'limit': limit},
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .map((e) => CyclePeriod.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// `POST /hormonal-health/periods/{user_id}` — log a period (Day 1 of
  /// bleeding + optional end date). Upserts on `start_date` server-side, so
  /// re-logging the same day edits rather than duplicates. Any write
  /// recomputes the prediction on the next `getPrediction` call.
  Future<CyclePeriod> createPeriod(
    String userId, {
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.cyclePeriods(userId),
      data: {
        'start_date': _isoDate(startDate),
        if (endDate != null) 'end_date': _isoDate(endDate),
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('createPeriod: expected a CyclePeriod');
    }
    return CyclePeriod.fromJson(Map<String, dynamic>.from(data));
  }

  /// `PATCH /hormonal-health/periods/{user_id}/{period_id}` — edit a logged
  /// period (e.g. set its end date when the period finishes). At least one
  /// of [startDate] / [endDate] must be provided.
  Future<CyclePeriod> updatePeriod(
    String userId,
    String periodId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final body = <String, dynamic>{};
    if (startDate != null) body['start_date'] = _isoDate(startDate);
    if (endDate != null) body['end_date'] = _isoDate(endDate);
    if (body.isEmpty) {
      throw ArgumentError(
          'updatePeriod: provide at least one of startDate / endDate');
    }
    final response = await _apiClient.patch(
      ApiConstants.cyclePeriod(userId, periodId),
      data: body,
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('updatePeriod: expected a CyclePeriod');
    }
    return CyclePeriod.fromJson(Map<String, dynamic>.from(data));
  }

  /// `DELETE /hormonal-health/periods/{user_id}/{period_id}` — delete a
  /// logged period; predictions recompute from what remains.
  Future<void> deletePeriod(String userId, String periodId) async {
    await _apiClient.delete(ApiConstants.cyclePeriod(userId, periodId));
  }

  // ============================================================================
  // CYCLE AI INSIGHT + RAW DAY LOGS (Phases C / D / F)
  // ----------------------------------------------------------------------------
  // The Cycle screen needs (a) the proactive server-generated insight and
  // (b) the *raw* `hormone_logs` rows including the cycle-specific columns
  // (`basal_body_temperature`, `cervical_mucus`, `period_flow`,
  // `lh_test_result`, `sexual_activity`) which the typed `HormoneLog` model
  // does not yet surface. Both return permissive shapes so a missing column
  // never crashes the cycle UI.
  // ============================================================================

  /// `GET /hormonal-health/ai-insight/{user_id}` — a proactive, server-cached
  /// cycle insight for the current phase/data. Returns null on any failure so
  /// the AI insight card can simply hide rather than blocking the screen.
  Future<Map<String, dynamic>?> getAiInsight(String userId) async {
    try {
      final response =
          await _apiClient.get(ApiConstants.cycleAiInsight(userId));
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (e) {
      debugPrint('⚠️ [Cycle] getAiInsight failed: $e');
      return null;
    }
  }

  /// Raw `hormone_logs` rows over a date range — used by the Calendar and
  /// Insights tabs which need the cycle-specific columns the typed model
  /// drops. Returns an empty list on failure (the tabs render their own
  /// empty state).
  Future<List<Map<String, dynamic>>> getRawLogs(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 180,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      final response = await _apiClient.get(
        '/hormonal-health/logs/$userId',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('⚠️ [Cycle] getRawLogs failed: $e');
      return const [];
    }
  }
}

/// Provider for HormonalHealthRepository
final hormonalHealthRepositoryProvider = Provider<HormonalHealthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HormonalHealthRepository(apiClient);
});
