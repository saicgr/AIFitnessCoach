import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/muscle_analytics.dart';
import '../services/api_client.dart';

/// Muscle Analytics Repository Provider
final muscleAnalyticsRepositoryProvider = Provider<MuscleAnalyticsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MuscleAnalyticsRepository(apiClient);
});

/// Repository for fetching muscle-level analytics data
class MuscleAnalyticsRepository {
  final ApiClient _apiClient;

  MuscleAnalyticsRepository(this._apiClient);

  /// Get muscle heatmap data for body diagram visualization
  Future<MuscleHeatmapData> getMuscleHeatmap({
    String timeRange = '4_weeks',
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [MuscleAnalytics] Fetching muscle heatmap');

      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/muscle-analytics/heatmap',
        queryParameters: {
          'user_id': userId,
          'time_range': timeRange,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final intensities = (data['muscles'] as List? ?? []).map((m) {
          return MuscleIntensity(
            muscleId: m['muscle_group'] ?? '',
            muscleName: m['muscle_group'],
            intensity: (m['intensity'] as num?)?.toDouble() ?? 0,
            workoutCount: m['workout_count'],
            totalSets: m['sets_count'],
            totalVolumeKg: (m['volume_kg'] as num?)?.toDouble(),
            lastTrained: m['last_trained'],
          );
        }).toList();

        debugPrint('✅ [MuscleAnalytics] Fetched ${intensities.length} muscle intensities');

        return MuscleHeatmapData(
          userId: userId,
          timeRange: timeRange,
          muscleIntensities: intensities,
          maxIntensity: (data['max_volume_kg'] as num?)?.toDouble(),
        );
      }

      throw Exception('Failed to fetch muscle heatmap');
    } catch (e) {
      debugPrint('❌ [MuscleAnalytics] Heatmap error: $e');
      rethrow;
    }
  }

  /// Get training frequency per muscle group
  Future<MuscleTrainingFrequency> getMuscleFrequency() async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [MuscleAnalytics] Fetching muscle frequency');

      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/muscle-analytics/frequency',
        queryParameters: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final frequencies = (data['frequencies'] as List? ?? []).map((f) {
          return MuscleFrequencyData(
            muscleGroup: f['muscle_group'] ?? '',
            timesTrained: f['total_workout_count'] ?? 0,
            timesPerWeek: (f['weekly_frequency'] as num?)?.toDouble() ?? 0,
            totalSets: f['total_workout_count'],
            totalVolumeKg: (f['total_volume_kg'] as num?)?.toDouble(),
            lastTrained: f['last_trained_date'],
            daysSinceTrained: f['days_since_last_training'],
            frequencyStatus: f['recommendation'],
          );
        }).toList();

        debugPrint('✅ [MuscleAnalytics] Fetched ${frequencies.length} frequency records');

        return MuscleTrainingFrequency(
          userId: userId,
          timeRange: '30_days',
          frequencies: frequencies,
          totalWorkouts: data['undertrained_count'] ?? 0 + (data['overtrained_count'] ?? 0),
          avgWorkoutsPerWeek: (data['avg_weekly_workouts'] as num?)?.toDouble(),
        );
      }

      throw Exception('Failed to fetch muscle frequency');
    } catch (e) {
      debugPrint('❌ [MuscleAnalytics] Frequency error: $e');
      rethrow;
    }
  }

  /// Get muscle balance analysis (push/pull, upper/lower ratios)
  Future<MuscleBalanceData> getMuscleBalance() async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [MuscleAnalytics] Fetching muscle balance');

      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/muscle-analytics/balance',
        queryParameters: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final ratios = data['ratios'] as List? ?? [];
        double? pushPullRatio;
        double? pushVolume;
        double? pullVolume;
        double? upperLowerRatio;
        double? upperVolume;
        double? lowerVolume;

        for (final r in ratios) {
          final category = r['category'] as String?;
          if (category == 'push_pull') {
            pushPullRatio = (r['ratio'] as num?)?.toDouble();
            pushVolume = (r['side1_volume_kg'] as num?)?.toDouble();
            pullVolume = (r['side2_volume_kg'] as num?)?.toDouble();
          } else if (category == 'upper_lower') {
            upperLowerRatio = (r['ratio'] as num?)?.toDouble();
            upperVolume = (r['side1_volume_kg'] as num?)?.toDouble();
            lowerVolume = (r['side2_volume_kg'] as num?)?.toDouble();
          }
        }

        final imbalances = (ratios).where((r) {
          final status = r['status'] as String?;
          return status == 'imbalanced' || status == 'severe_imbalance';
        }).map((r) {
          return MuscleImbalance(
            musclePair: r['category'] ?? '',
            ratio: (r['ratio'] as num?)?.toDouble() ?? 0,
            dominantSide: r['side1'],
            severity: r['status'],
            recommendation: r['recommendation'],
          );
        }).toList();

        debugPrint('✅ [MuscleAnalytics] Fetched balance data');

        return MuscleBalanceData(
          userId: userId,
          timeRange: '30_days',
          pushPullRatio: pushPullRatio,
          pushVolumeKg: pushVolume,
          pullVolumeKg: pullVolume,
          upperLowerRatio: upperLowerRatio,
          upperVolumeKg: upperVolume,
          lowerVolumeKg: lowerVolume,
          balanceScore: data['imbalance_count'] == 0 ? 100 : (data['imbalance_count'] == 1 ? 75 : 50),
          recommendations: (data['recommendations'] as List?)?.cast<String>(),
          imbalances: imbalances,
        );
      }

      throw Exception('Failed to fetch muscle balance');
    } catch (e) {
      debugPrint('❌ [MuscleAnalytics] Balance error: $e');
      rethrow;
    }
  }

  /// Get exercises that target a specific muscle group
  Future<MuscleExerciseData> getExercisesForMuscle({
    required String muscleGroup,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [MuscleAnalytics] Fetching exercises for: $muscleGroup');

      final encodedMuscle = Uri.encodeComponent(muscleGroup);
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/muscle-analytics/muscle/$encodedMuscle/exercises',
        queryParameters: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final exercises = (data['exercises'] as List? ?? []).map((e) {
          return MuscleExerciseStats(
            exerciseName: e['exercise_name'] ?? '',
            timesPerformed: e['times_performed'] ?? 0,
            totalVolumeKg: (e['total_volume_kg'] as num?)?.toDouble(),
            maxWeightKg: (e['max_weight_kg'] as num?)?.toDouble(),
            volumePercentage: (e['contribution'] as num?)?.toDouble(),
            lastPerformed: e['last_performed'],
          );
        }).toList();

        debugPrint('✅ [MuscleAnalytics] Fetched ${exercises.length} exercises');

        return MuscleExerciseData(
          muscleGroup: muscleGroup,
          timeRange: 'all_time',
          exercises: exercises,
          totalExercises: data['total_exercises'],
          totalVolumeKg: (data['total_volume_kg'] as num?)?.toDouble(),
        );
      }

      throw Exception('Failed to fetch exercises for muscle');
    } catch (e) {
      debugPrint('❌ [MuscleAnalytics] Muscle exercises error: $e');
      rethrow;
    }
  }

  /// Get historical training data for a specific muscle group
  Future<MuscleHistoryData> getMuscleHistory({
    required String muscleGroup,
    String timeRange = '12_weeks',
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [MuscleAnalytics] Fetching history for: $muscleGroup');

      final encodedMuscle = Uri.encodeComponent(muscleGroup);
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/muscle-analytics/muscle/$encodedMuscle/history',
        queryParameters: {
          'user_id': userId,
          'time_range': timeRange,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final history = (data['data_points'] as List? ?? []).map((h) {
          return MuscleWorkoutEntry(
            workoutId: h['week_start'] ?? '',
            workoutDate: h['week_start'] ?? '',
            exercisesCount: h['exercise_count'] ?? 0,
            totalSets: h['sets_count'],
            totalVolumeKg: (h['volume_kg'] as num?)?.toDouble(),
            maxWeightKg: (h['max_weight_kg'] as num?)?.toDouble(),
          );
        }).toList();

        debugPrint('✅ [MuscleAnalytics] Fetched ${history.length} history entries');

        return MuscleHistoryData(
          userId: userId,
          muscleGroup: muscleGroup,
          timeRange: timeRange,
          history: history,
          summary: MuscleHistorySummary(
            totalWorkouts: history.length,
            totalVolumeKg: (data['avg_weekly_volume'] as num?)?.toDouble(),
            volumeTrend: data['volume_trend'],
            volumeChangePercent: (data['volume_change'] as num?)?.toDouble(),
          ),
        );
      }

      throw Exception('Failed to fetch muscle history');
    } catch (e) {
      debugPrint('❌ [MuscleAnalytics] History error: $e');
      rethrow;
    }
  }

  /// Log muscle analytics view for engagement tracking
  Future<void> logView({
    required String viewType,
    String? muscleGroup,
    int? sessionDurationSeconds,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _apiClient.post(
        '${ApiConstants.baseUrl}/muscle-analytics/log-view',
        data: {
          'user_id': userId,
          'view_type': viewType,
          'muscle_group': muscleGroup,
          'session_duration_seconds': sessionDurationSeconds,
        },
      );

      debugPrint('✅ [MuscleAnalytics] Logged view: $viewType');
    } catch (e) {
      debugPrint('⚠️ [MuscleAnalytics] Failed to log view: $e');
    }
  }
}
