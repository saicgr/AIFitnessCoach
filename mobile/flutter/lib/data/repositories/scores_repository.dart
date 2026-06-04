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

  /// Get all muscle group strength scores.
  ///
  /// [gymProfileId] is OPTIONAL: when set, the score is computed from sets
  /// logged at that gym only (so the score stops bouncing when the user
  /// switches gyms); when omitted, the combined cross-gym score is returned
  /// exactly as before.
  Future<AllStrengthScores> getAllStrengthScores({
    required String userId,
    String? gymProfileId,
  }) async {
    try {
      debugPrint('🏋️ [Scores] Getting all strength scores for $userId'
          '${gymProfileId != null ? ' (gym=$gymProfileId)' : ''}');
      final response = await _client.get(
        '/scores/strength',
        queryParameters: {
          'user_id': userId,
          if (gymProfileId != null) 'gym_profile_id': gymProfileId,
        },
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

  /// Get personal records and statistics.
  ///
  /// [gymProfileId] is OPTIONAL: when set, the PR list is scoped to records set
  /// at that gym (machine/cable PRs no longer get crushed by an incomparable
  /// record at another gym); combined otherwise.
  Future<PRStats> getPersonalRecords({
    required String userId,
    int limit = 10,
    int periodDays = 30,
    String? gymProfileId,
  }) async {
    try {
      debugPrint('🏆 [Scores] Getting personal records for $userId'
          '${gymProfileId != null ? ' (gym=$gymProfileId)' : ''}');
      final response = await _client.get(
        '/scores/personal-records',
        queryParameters: {
          'user_id': userId,
          'limit': limit,
          'period_days': periodDays,
          if (gymProfileId != null) 'gym_profile_id': gymProfileId,
        },
      );
      debugPrint('✅ [Scores] Got personal records');
      return PRStats.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting personal records: $e');
      rethrow;
    }
  }

  /// Per-PR gym attribution, keyed by lowercased exercise name.
  ///
  /// The shared `PersonalRecordScore` model (owned elsewhere) drops the gym
  /// columns, so the Personal Records screen reads the raw `/scores/personal-
  /// records` JSON here to recover `{gym_profile_id, gym_name, gym_color}` per
  /// exercise. Returns an empty map on any error so the screen degrades to no
  /// gym labels rather than failing.
  Future<Map<String, Map<String, String?>>> getPersonalRecordGymTags({
    required String userId,
    int limit = 50,
    int periodDays = 365,
    String? gymProfileId,
  }) async {
    try {
      final response = await _client.get(
        '/scores/personal-records',
        queryParameters: {
          'user_id': userId,
          'limit': limit,
          'period_days': periodDays,
          if (gymProfileId != null) 'gym_profile_id': gymProfileId,
        },
      );
      final data = response.data;
      if (data is! Map) return const {};
      final recent = data['recent_prs'];
      final result = <String, Map<String, String?>>{};
      if (recent is List) {
        for (final r in recent) {
          if (r is! Map) continue;
          final name = r['exercise_name']?.toString();
          if (name == null) continue;
          final gymId = r['gym_profile_id']?.toString();
          if (gymId == null || gymId.isEmpty) continue;
          // Keep the first (most-recent) gym tag per exercise.
          result.putIfAbsent(
            name.toLowerCase(),
            () => {
              'gym_profile_id': gymId,
              'gym_name': r['gym_name']?.toString(),
              'gym_color': r['gym_color']?.toString(),
            },
          );
        }
      }
      return result;
    } catch (e) {
      debugPrint('⚠️ [Scores] PR gym-tags fetch failed: $e');
      return const {};
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
  // DOTS / Wilks Score
  // ============================================

  /// Get DOTS and Wilks scores for the user
  Future<DotsScore> getDotsScore({required String userId}) async {
    try {
      debugPrint('🏋️ [Scores] Getting DOTS score for $userId');
      final response = await _client.get(
        '/scores/dots',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Scores] Got DOTS score');
      return DotsScore.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting DOTS score: $e');
      rethrow;
    }
  }

  // ============================================
  // Nutrition Score Endpoints
  // ============================================

  /// Get current nutrition score for the user
  Future<NutritionScoreData> getNutritionScore({
    required String userId,
  }) async {
    try {
      debugPrint('🥗 [Scores] Getting nutrition score for $userId');
      final response = await _client.get(
        '/scores/nutrition',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Scores] Got nutrition score');
      return NutritionScoreData.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting nutrition score: $e');
      rethrow;
    }
  }

  /// Calculate/recalculate nutrition score
  Future<NutritionScoreData> calculateNutritionScore({
    required String userId,
    int? weekNumber,
    int? year,
  }) async {
    try {
      debugPrint('🥗 [Scores] Calculating nutrition score for $userId');
      final response = await _client.post(
        '/scores/nutrition/calculate',
        data: {
          'user_id': userId,
          if (weekNumber != null) 'week_number': weekNumber,
          if (year != null) 'year': year,
        },
      );
      debugPrint('✅ [Scores] Nutrition score calculated');
      return NutritionScoreData.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error calculating nutrition score: $e');
      rethrow;
    }
  }

  // ============================================
  // Fitness Score Endpoints
  // ============================================

  /// Get overall fitness score with breakdown
  Future<FitnessScoreBreakdown> getFitnessScore({
    required String userId,
  }) async {
    try {
      debugPrint('💪 [Scores] Getting fitness score for $userId');
      final response = await _client.get(
        '/scores/fitness',
        queryParameters: {'user_id': userId},
      );
      debugPrint('✅ [Scores] Got fitness score');
      return FitnessScoreBreakdown.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error getting fitness score: $e');
      rethrow;
    }
  }

  /// Calculate/recalculate overall fitness score
  Future<FitnessScoreBreakdown> calculateFitnessScore({
    required String userId,
  }) async {
    try {
      debugPrint('💪 [Scores] Calculating fitness score for $userId');
      final response = await _client.post(
        '/scores/fitness/calculate',
        data: {
          'user_id': userId,
        },
      );
      debugPrint('✅ [Scores] Fitness score calculated');
      return FitnessScoreBreakdown.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Scores] Error calculating fitness score: $e');
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
