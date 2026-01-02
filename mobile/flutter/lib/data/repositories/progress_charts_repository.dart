import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress_charts.dart';
import '../services/api_client.dart';

/// Progress charts repository provider
final progressChartsRepositoryProvider =
    Provider<ProgressChartsRepository>((ref) {
  return ProgressChartsRepository(ref.watch(apiClientProvider));
});

/// Repository for progress charts API calls
class ProgressChartsRepository {
  final ApiClient _client;

  ProgressChartsRepository(this._client);

  // ============================================
  // Strength Progression
  // ============================================

  /// Get weekly strength progression per muscle group
  Future<StrengthProgressionData> getStrengthOverTime({
    required String userId,
    ProgressTimeRange timeRange = ProgressTimeRange.twelveWeeks,
    String? muscleGroup,
  }) async {
    try {
      debugPrint(
          '🔍 [ProgressCharts] Getting strength progression for $userId, range: ${timeRange.value}');

      final queryParams = <String, dynamic>{
        'user_id': userId,
        'time_range': timeRange.value,
      };

      if (muscleGroup != null && muscleGroup.isNotEmpty) {
        queryParams['muscle_group'] = muscleGroup;
      }

      final response = await _client.get(
        '/progress/strength-over-time',
        queryParameters: queryParams,
      );

      debugPrint('✅ [ProgressCharts] Got strength progression data');
      return StrengthProgressionData.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [ProgressCharts] Error getting strength progression: $e');
      rethrow;
    }
  }

  // ============================================
  // Volume Progression
  // ============================================

  /// Get weekly total volume progression
  Future<VolumeProgressionData> getVolumeOverTime({
    required String userId,
    ProgressTimeRange timeRange = ProgressTimeRange.twelveWeeks,
  }) async {
    try {
      debugPrint(
          '🔍 [ProgressCharts] Getting volume progression for $userId, range: ${timeRange.value}');

      final response = await _client.get(
        '/progress/volume-over-time',
        queryParameters: {
          'user_id': userId,
          'time_range': timeRange.value,
        },
      );

      debugPrint('✅ [ProgressCharts] Got volume progression data');
      return VolumeProgressionData.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [ProgressCharts] Error getting volume progression: $e');
      rethrow;
    }
  }

  // ============================================
  // Exercise Progression
  // ============================================

  /// Get strength progression for a specific exercise
  Future<ExerciseProgressionData> getExerciseProgression({
    required String userId,
    required String exerciseName,
    ProgressTimeRange timeRange = ProgressTimeRange.twelveWeeks,
  }) async {
    try {
      debugPrint(
          '🔍 [ProgressCharts] Getting exercise progression for $exerciseName');

      final response = await _client.get(
        '/progress/exercise/${Uri.encodeComponent(exerciseName)}',
        queryParameters: {
          'user_id': userId,
          'time_range': timeRange.value,
        },
      );

      debugPrint('✅ [ProgressCharts] Got exercise progression data');
      return ExerciseProgressionData.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [ProgressCharts] Error getting exercise progression: $e');
      rethrow;
    }
  }

  // ============================================
  // Progress Summary
  // ============================================

  /// Get overall progress summary statistics
  Future<ProgressSummary> getProgressSummary({
    required String userId,
  }) async {
    try {
      debugPrint('🔍 [ProgressCharts] Getting progress summary for $userId');

      final response = await _client.get(
        '/progress/summary',
        queryParameters: {'user_id': userId},
      );

      debugPrint('✅ [ProgressCharts] Got progress summary');
      return ProgressSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [ProgressCharts] Error getting progress summary: $e');
      rethrow;
    }
  }

  // ============================================
  // Available Muscle Groups
  // ============================================

  /// Get list of muscle groups the user has trained
  Future<AvailableMuscleGroups> getAvailableMuscleGroups({
    required String userId,
  }) async {
    try {
      debugPrint(
          '🔍 [ProgressCharts] Getting available muscle groups for $userId');

      final response = await _client.get(
        '/progress/muscle-groups/$userId',
      );

      debugPrint('✅ [ProgressCharts] Got available muscle groups');
      return AvailableMuscleGroups.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [ProgressCharts] Error getting muscle groups: $e');
      rethrow;
    }
  }

  // ============================================
  // Analytics Logging
  // ============================================

  /// Log when user views a progress chart
  Future<void> logChartView({
    required String userId,
    required ChartType chartType,
    required ProgressTimeRange timeRange,
    String? muscleGroup,
    int? sessionDurationSeconds,
  }) async {
    try {
      debugPrint(
          '🔍 [ProgressCharts] Logging chart view: ${chartType.value}');

      await _client.post(
        '/progress/log-view',
        data: {
          'user_id': userId,
          'chart_type': chartType.value,
          'time_range': timeRange.value,
          if (muscleGroup != null) 'muscle_group': muscleGroup,
          if (sessionDurationSeconds != null)
            'session_duration_seconds': sessionDurationSeconds,
        },
      );

      debugPrint('✅ [ProgressCharts] Chart view logged');
    } catch (e) {
      // Don't fail on logging errors
      debugPrint('⚠️ [ProgressCharts] Failed to log chart view: $e');
    }
  }
}
