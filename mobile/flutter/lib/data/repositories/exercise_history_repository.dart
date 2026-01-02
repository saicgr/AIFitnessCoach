import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/exercise_history.dart';
import '../services/api_client.dart';

/// Exercise History Repository Provider
final exerciseHistoryRepositoryProvider = Provider<ExerciseHistoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExerciseHistoryRepository(apiClient);
});

/// Repository for fetching per-exercise workout history
class ExerciseHistoryRepository {
  final ApiClient _apiClient;

  ExerciseHistoryRepository(this._apiClient);

  /// Get paginated workout history for a specific exercise
  Future<ExerciseHistoryData> getExerciseHistory({
    required String exerciseName,
    String timeRange = '12_weeks',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ExerciseHistory] Fetching history for: $exerciseName');

      final encodedName = Uri.encodeComponent(exerciseName);
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/exercise-history/$encodedName',
        queryParameters: {
          'user_id': userId,
          'time_range': timeRange,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Map API response to our model
        final sessions = (data['records'] as List? ?? []).map((r) {
          return ExerciseWorkoutSession(
            workoutId: r['id']?.toString() ?? '',
            workoutDate: r['workout_date'] ?? '',
            workoutName: r['workout_name'],
            sets: r['sets_completed'] ?? 0,
            reps: r['total_reps'] ?? 0,
            weightKg: (r['max_weight_kg'] as num?)?.toDouble() ?? 0,
            totalVolumeKg: (r['total_volume_kg'] as num?)?.toDouble() ?? 0,
            estimated1rmKg: (r['estimated_1rm_kg'] as num?)?.toDouble(),
            isPr: r['is_pr'] == true,
            notes: r['notes'],
          );
        }).toList();

        final summary = data['summary'] as Map<String, dynamic>?;

        debugPrint('✅ [ExerciseHistory] Fetched ${sessions.length} sessions');

        return ExerciseHistoryData(
          userId: userId,
          exerciseName: exerciseName,
          timeRange: timeRange,
          totalSessions: data['total_records'] ?? sessions.length,
          sessions: sessions,
          summary: summary != null ? ExerciseProgressionSummary(
            totalSessions: summary['times_performed'] ?? 0,
            totalVolumeKg: (summary['total_volume_kg'] as num?)?.toDouble(),
            avgVolumePerSessionKg: (summary['avg_weight_kg'] as num?)?.toDouble(),
            firstSessionDate: summary['first_performed_at'],
            lastSessionDate: summary['last_performed_at'],
            currentWeightKg: (summary['max_weight_kg'] as num?)?.toDouble(),
            current1rmKg: (summary['estimated_1rm_kg'] as num?)?.toDouble(),
          ) : null,
        );
      }

      throw Exception('Failed to fetch exercise history');
    } catch (e) {
      debugPrint('❌ [ExerciseHistory] Error: $e');
      rethrow;
    }
  }

  /// Get chart data for exercise progression visualization
  Future<List<ExerciseChartDataPoint>> getExerciseChartData({
    required String exerciseName,
    String timeRange = '12_weeks',
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ExerciseHistory] Fetching chart data for: $exerciseName');

      final encodedName = Uri.encodeComponent(exerciseName);
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/exercise-history/$encodedName/chart',
        queryParameters: {
          'user_id': userId,
          'time_range': timeRange,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final points = (data['data_points'] as List? ?? []).map((p) {
          return ExerciseChartDataPoint(
            date: p['date'] ?? '',
            value: (p['max_weight_kg'] as num?)?.toDouble() ?? 0,
            label: '${(p['max_weight_kg'] as num?)?.toStringAsFixed(1) ?? 0} kg',
            isPr: p['is_pr'] == true,
          );
        }).toList();

        debugPrint('✅ [ExerciseHistory] Fetched ${points.length} chart data points');
        return points;
      }

      throw Exception('Failed to fetch chart data');
    } catch (e) {
      debugPrint('❌ [ExerciseHistory] Chart data error: $e');
      rethrow;
    }
  }

  /// Get personal records for a specific exercise
  Future<List<ExercisePersonalRecord>> getExercisePRs({
    required String exerciseName,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ExerciseHistory] Fetching PRs for: $exerciseName');

      final encodedName = Uri.encodeComponent(exerciseName);
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/exercise-history/$encodedName/prs',
        queryParameters: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final records = (data['records'] as List? ?? []).map((r) {
          return ExercisePersonalRecord(
            id: r['type'] ?? '',
            exerciseName: exerciseName,
            prType: r['type'] ?? '',
            prValue: (r['value'] as num?)?.toDouble() ?? 0,
            achievedDate: r['achieved_at'] ?? '',
            reps: r['reps'],
            weightKg: (r['weight_kg'] as num?)?.toDouble(),
          );
        }).toList();

        debugPrint('✅ [ExerciseHistory] Fetched ${records.length} PRs');
        return records;
      }

      throw Exception('Failed to fetch PRs');
    } catch (e) {
      debugPrint('❌ [ExerciseHistory] PRs error: $e');
      rethrow;
    }
  }

  /// Get most performed exercises
  Future<List<MostPerformedExercise>> getMostPerformedExercises({
    int limit = 20,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ExerciseHistory] Fetching most performed exercises');

      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/exercise-history/most-performed',
        queryParameters: {
          'user_id': userId,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final exercises = (data['exercises'] as List? ?? []).map((e) {
          return MostPerformedExercise(
            exerciseName: e['exercise_name'] ?? '',
            muscleGroup: e['muscle_group'],
            timesPerformed: e['times_performed'] ?? 0,
            totalVolumeKg: (e['total_volume_kg'] as num?)?.toDouble(),
            maxWeightKg: (e['max_weight_kg'] as num?)?.toDouble(),
            lastPerformed: e['last_performed_at'],
          );
        }).toList();

        debugPrint('✅ [ExerciseHistory] Fetched ${exercises.length} exercises');
        return exercises;
      }

      throw Exception('Failed to fetch most performed exercises');
    } catch (e) {
      debugPrint('❌ [ExerciseHistory] Most performed error: $e');
      rethrow;
    }
  }

  /// Log exercise history view for analytics
  Future<void> logView({
    required String exerciseName,
    int? sessionDurationSeconds,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _apiClient.post(
        '${ApiConstants.baseUrl}/exercise-history/log-view',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'session_duration_seconds': sessionDurationSeconds,
        },
      );

      debugPrint('✅ [ExerciseHistory] Logged view for: $exerciseName');
    } catch (e) {
      debugPrint('⚠️ [ExerciseHistory] Failed to log view: $e');
    }
  }
}
