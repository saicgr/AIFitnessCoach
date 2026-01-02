import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hormonal_health.dart';
import '../services/api_client.dart';

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
      print('Error fetching hormonal profile: $e');
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
      print('Error upserting hormonal profile: $e');
      rethrow;
    }
  }

  /// Delete hormonal profile
  Future<void> deleteProfile(String userId) async {
    try {
      await _apiClient.delete('/hormonal-health/profile/$userId');
    } catch (e) {
      print('Error deleting hormonal profile: $e');
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
      print('Error creating hormone log: $e');
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
      print('Error fetching hormone logs: $e');
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
      print('Error fetching today\'s hormone log: $e');
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
      print('Error fetching cycle phase: $e');
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
      print('Error logging period start: $e');
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
      print('Error fetching hormone-supportive foods: $e');
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
      print('Error fetching food recommendations: $e');
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
      print('Error fetching hormonal insights: $e');
      return null;
    }
  }
}

/// Provider for HormonalHealthRepository
final hormonalHealthRepositoryProvider = Provider<HormonalHealthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HormonalHealthRepository(apiClient);
});
