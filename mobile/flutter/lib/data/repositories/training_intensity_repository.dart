import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/training_intensity.dart';
import '../services/api_client.dart';

/// Training intensity repository provider
final trainingIntensityRepositoryProvider =
    Provider<TrainingIntensityRepository>((ref) {
  return TrainingIntensityRepository(ref.watch(apiClientProvider));
});

/// Repository for managing 1RMs and training intensity settings
class TrainingIntensityRepository {
  final ApiClient _apiClient;

  TrainingIntensityRepository(this._apiClient);

  // ---------------------------------------------------------------------------
  // 1RM Management
  // ---------------------------------------------------------------------------

  /// Get all stored 1RMs for a user
  Future<List<UserExercise1RM>> getUserOneRMs(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/training/1rm/$userId',
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => UserExercise1RM.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting user 1RMs: $e');
      return [];
    }
  }

  /// Get 1RM for a specific exercise
  Future<UserExercise1RM?> getOneRM(String userId, String exerciseName) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/training/1rm/$userId/${Uri.encodeComponent(exerciseName)}',
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return UserExercise1RM.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting 1RM: $e');
      return null;
    }
  }

  /// Set 1RM for an exercise
  Future<UserExercise1RM?> setOneRM({
    required String userId,
    required String exerciseName,
    required double oneRepMaxKg,
    String source = 'manual',
    double confidence = 1.0,
    DateTime? lastTestedAt,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/training/1rm',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'one_rep_max_kg': oneRepMaxKg,
          'source': source,
          'confidence': confidence,
          if (lastTestedAt != null)
            'last_tested_at': lastTestedAt.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return UserExercise1RM.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error setting 1RM: $e');
      return null;
    }
  }

  /// Delete 1RM for an exercise
  Future<bool> deleteOneRM(String userId, String exerciseName) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConstants.baseUrl}/training/1rm/$userId/${Uri.encodeComponent(exerciseName)}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting 1RM: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Training Intensity Settings
  // ---------------------------------------------------------------------------

  /// Get user's intensity settings (global + overrides)
  Future<TrainingIntensitySettings> getIntensitySettings(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/training/intensity/$userId',
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return TrainingIntensitySettings.fromJson(response.data as Map<String, dynamic>);
      }
      return const TrainingIntensitySettings();
    } catch (e) {
      debugPrint('Error getting intensity settings: $e');
      return const TrainingIntensitySettings();
    }
  }

  /// Set global training intensity
  Future<IntensityResponse?> setGlobalIntensity({
    required String userId,
    required int intensityPercent,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/training/intensity',
        data: {
          'user_id': userId,
          'intensity_percent': intensityPercent,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return IntensityResponse.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error setting global intensity: $e');
      return null;
    }
  }

  /// Set per-exercise intensity override
  Future<IntensityResponse?> setExerciseIntensityOverride({
    required String userId,
    required String exerciseName,
    required int intensityPercent,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/training/intensity/exercise',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'intensity_percent': intensityPercent,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return IntensityResponse.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error setting exercise intensity: $e');
      return null;
    }
  }

  /// Remove per-exercise intensity override
  Future<bool> removeExerciseIntensityOverride({
    required String userId,
    required String exerciseName,
  }) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConstants.baseUrl}/training/intensity/exercise/$userId/${Uri.encodeComponent(exerciseName)}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error removing exercise intensity: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Working Weight Calculation
  // ---------------------------------------------------------------------------

  /// Calculate working weight for a single exercise
  Future<double?> calculateWorkingWeight({
    required double oneRepMaxKg,
    required int intensityPercent,
    String equipmentType = 'barbell',
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/training/calculate-weight',
        data: {
          'one_rep_max_kg': oneRepMaxKg,
          'intensity_percent': intensityPercent,
          'equipment_type': equipmentType,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return (response.data['working_weight_kg'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      debugPrint('Error calculating working weight: $e');
      return null;
    }
  }

  /// Calculate working weights for all exercises in a workout
  Future<List<WorkingWeightResult>> calculateWorkoutWeights({
    required String userId,
    required List<String> exercises,
    Map<String, String>? equipmentTypes,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/training/workout-weights',
        data: {
          'user_id': userId,
          'exercises': exercises,
          if (equipmentTypes != null) 'equipment_types': equipmentTypes,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) =>
                WorkingWeightResult.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error calculating workout weights: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Auto-Populate
  // ---------------------------------------------------------------------------

  /// Auto-populate 1RMs from workout history
  Future<AutoPopulateResponse?> autoPopulateOneRMs({
    required String userId,
    int daysLookback = 90,
    double minConfidence = 0.7,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/training/auto-populate/$userId?days_lookback=$daysLookback&min_confidence=$minConfidence',
        data: {},
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return AutoPopulateResponse.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error auto-populating 1RMs: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: Calculate working weight locally (no API call)
  // ---------------------------------------------------------------------------

  /// Calculate working weight locally without API call
  static double calculateWorkingWeightLocal({
    required double oneRepMaxKg,
    required int intensityPercent,
    String equipmentType = 'barbell',
  }) {
    const weightIncrements = {
      'barbell': 2.5,
      'dumbbell': 2.0,
      'machine': 5.0,
      'cable': 2.5,
      'kettlebell': 4.0,
      'bodyweight': 0.0,
    };

    final clampedIntensity = intensityPercent.clamp(50, 100);
    final rawWeight = oneRepMaxKg * (clampedIntensity / 100);
    final increment = weightIncrements[equipmentType] ?? 2.5;

    if (increment > 0) {
      return ((rawWeight / increment).round() * increment);
    }
    return rawWeight;
  }
}
