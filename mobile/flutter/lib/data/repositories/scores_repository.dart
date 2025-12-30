import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scores.dart';
import '../services/api_client.dart';

/// Scores repository provider
final scoresRepositoryProvider = Provider<ScoresRepository>((ref) {
  return ScoresRepository(ref.watch(apiClientProvider));
});

/// Scores repository for all score-related API calls
class ScoresRepository {
  final ApiClient _client;

  ScoresRepository(this._client);

  // ============================================
  // Readiness Endpoints
  // ============================================

  /// Submit daily readiness check-in
  Future<ReadinessScore> submitReadinessCheckIn({
    required String userId,
    required int sleepQuality,
    required int fatigueLevel,
    required int stressLevel,
    required int muscleSoreness,
    int? mood,
    int? energyLevel,
    String? scoreDate,
  }) async {
    try {
      debugPrint('🎯 [Scores] Submitting readiness check-in for $userId');
      final response = await _client.post(
        '/scores/readiness',
        data: {
          'user_id': userId,
          'sleep_quality': sleepQuality,
          'fatigue_level': fatigueLevel,
          'stress_level': stressLevel,
          'muscle_soreness': muscleSoreness,
          if (mood != null) 'mood': mood,
          if (energyLevel != null) 'energy_level': energyLevel,
          if (scoreDate != null) 'score_date': scoreDate,
        },
      );
      debugPrint('✅ [Scores] Readiness check-in submitted successfully');
      return ReadinessScore.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error submitting readiness check-in: $e');
      rethrow;
    }
  }

  /// Get readiness for a specific date
  Future<ReadinessScore?> getReadinessForDate({
    required String userId,
    required String date,
  }) async {
    try {
      debugPrint('🔍 [Scores] Getting readiness for $userId on $date');
      final response = await _client.get(
        '/scores/readiness/$date',
        queryParameters: {'user_id': userId},
      );
      if (response.data == null) {
        debugPrint('ℹ️ [Scores] No readiness data for $date');
        return null;
      }
      debugPrint('✅ [Scores] Got readiness for $date');
      return ReadinessScore.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting readiness: $e');
      rethrow;
    }
  }

  /// Get readiness history
  Future<ReadinessHistory> getReadinessHistory({
    required String userId,
    int days = 30,
  }) async {
    try {
      debugPrint('🔍 [Scores] Getting readiness history for $userId ($days days)');
      final response = await _client.get(
        '/scores/readiness/history',
        queryParameters: {
          'user_id': userId,
          'days': days,
        },
      );
      debugPrint('✅ [Scores] Got readiness history');
      return ReadinessHistory.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting readiness history: $e');
      rethrow;
    }
  }

  // ============================================
  // Strength Score Endpoints
  // ============================================

  /// Get all muscle group strength scores
  Future<AllStrengthScores> getAllStrengthScores({
    required String userId,
  }) async {
    try {
      debugPrint('🏋️ [Scores] Getting all strength scores for $userId');
      final response = await _client.get(
        '/scores/strength',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Scores] Got all strength scores');
      return AllStrengthScores.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting strength scores: $e');
      rethrow;
    }
  }

  /// Get detailed strength info for a specific muscle group
  Future<StrengthDetail> getStrengthDetail({
    required String userId,
    required String muscleGroup,
  }) async {
    try {
      debugPrint('🏋️ [Scores] Getting strength detail for $muscleGroup');
      final response = await _client.get(
        '/scores/strength/$muscleGroup',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Scores] Got strength detail for $muscleGroup');
      return StrengthDetail.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting strength detail: $e');
      rethrow;
    }
  }

  /// Trigger strength score recalculation
  Future<Map<String, dynamic>> calculateStrengthScores({
    required String userId,
  }) async {
    try {
      debugPrint('🏋️ [Scores] Triggering strength score calculation for $userId');
      final response = await _client.post(
        '/scores/strength/calculate',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Scores] Strength scores calculated');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error calculating strength scores: $e');
      rethrow;
    }
  }

  // ============================================
  // Personal Records Endpoints
  // ============================================

  /// Get personal records and statistics
  Future<PRStats> getPersonalRecords({
    required String userId,
    int limit = 10,
    int periodDays = 30,
  }) async {
    try {
      debugPrint('🏆 [Scores] Getting personal records for $userId');
      final response = await _client.get(
        '/scores/personal-records',
        queryParameters: {
          'user_id': userId,
          'limit': limit,
          'period_days': periodDays,
        },
      );
      debugPrint('✅ [Scores] Got personal records');
      return PRStats.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting personal records: $e');
      rethrow;
    }
  }

  /// Get PR history for a specific exercise
  Future<Map<String, dynamic>> getExercisePRHistory({
    required String userId,
    required String exercise,
  }) async {
    try {
      debugPrint('🏆 [Scores] Getting PR history for $exercise');
      final response = await _client.get(
        '/scores/personal-records/$exercise',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Scores] Got PR history for $exercise');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting PR history: $e');
      rethrow;
    }
  }

  // ============================================
  // Overview Endpoint
  // ============================================

  /// Get combined dashboard data
  Future<ScoresOverview> getScoresOverview({
    required String userId,
  }) async {
    try {
      debugPrint('📊 [Scores] Getting scores overview for $userId');
      final response = await _client.get(
        '/scores/overview',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Scores] Got scores overview');
      return ScoresOverview.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting scores overview: $e');
      rethrow;
    }
  }
}
