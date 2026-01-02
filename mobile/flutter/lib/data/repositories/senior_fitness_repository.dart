import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/senior_settings.dart';
import '../services/api_client.dart';

/// Senior fitness repository provider
final seniorFitnessRepositoryProvider = Provider<SeniorFitnessRepository>((ref) {
  return SeniorFitnessRepository(ref.watch(apiClientProvider));
});

/// Repository for senior fitness operations
class SeniorFitnessRepository {
  final ApiClient _client;

  SeniorFitnessRepository(this._client);

  // ─────────────────────────────────────────────────────────────────
  // Settings Management
  // ─────────────────────────────────────────────────────────────────

  /// Get senior recovery settings for a user
  Future<SeniorRecoverySettings> getSettings(String userId) async {
    try {
      final response = await _client.get('/senior-fitness/user/$userId/settings');
      return SeniorRecoverySettings.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting senior settings: $e');
      rethrow;
    }
  }

  /// Update senior recovery settings
  Future<SeniorRecoverySettings> updateSettings({
    required String userId,
    required SeniorRecoverySettings settings,
  }) async {
    try {
      final response = await _client.put(
        '/senior-fitness/user/$userId/settings',
        data: settings.toJson(),
      );
      return SeniorRecoverySettings.fromJson(response.data);
    } catch (e) {
      debugPrint('Error updating senior settings: $e');
      rethrow;
    }
  }

  /// Partially update senior recovery settings
  Future<SeniorRecoverySettings> patchSettings({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _client.patch(
        '/senior-fitness/user/$userId/settings',
        data: updates,
      );
      return SeniorRecoverySettings.fromJson(response.data);
    } catch (e) {
      debugPrint('Error patching senior settings: $e');
      rethrow;
    }
  }

  /// Reset settings to defaults
  Future<SeniorRecoverySettings> resetSettings(String userId) async {
    try {
      final response = await _client.post(
        '/senior-fitness/user/$userId/settings/reset',
      );
      return SeniorRecoverySettings.fromJson(response.data);
    } catch (e) {
      debugPrint('Error resetting senior settings: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Recovery Status
  // ─────────────────────────────────────────────────────────────────

  /// Check recovery status for a user
  Future<RecoveryStatus> checkRecoveryStatus(String userId) async {
    try {
      final response = await _client.get('/senior-fitness/user/$userId/recovery-status');
      return RecoveryStatus.fromJson(response.data);
    } catch (e) {
      debugPrint('Error checking recovery status: $e');
      rethrow;
    }
  }

  /// Get recovery recommendation based on settings and recent workouts
  Future<Map<String, dynamic>> getRecoveryRecommendation(String userId) async {
    try {
      final response = await _client.get('/senior-fitness/user/$userId/recovery-recommendation');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting recovery recommendation: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Workout Logging
  // ─────────────────────────────────────────────────────────────────

  /// Log a completed workout for senior tracking
  Future<SeniorWorkoutLog> logWorkoutCompletion({
    required String userId,
    required String workoutId,
    required String workoutName,
    required String workoutType,
    required int durationMinutes,
    int? perceivedExertion,
    int? energyLevelBefore,
    int? energyLevelAfter,
    bool jointPainReported = false,
    List<String> jointPainAreas = const [],
    int balanceExercisesCompleted = 0,
    int mobilityExercisesCompleted = 0,
    List<String> modificationsUsed = const [],
    bool warmupCompleted = true,
    bool cooldownCompleted = true,
    int? recoveryRating,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        '/senior-fitness/user/$userId/workout-log',
        data: {
          'workout_id': workoutId,
          'workout_name': workoutName,
          'workout_type': workoutType,
          'duration_minutes': durationMinutes,
          if (perceivedExertion != null) 'perceived_exertion': perceivedExertion,
          if (energyLevelBefore != null) 'energy_level_before': energyLevelBefore,
          if (energyLevelAfter != null) 'energy_level_after': energyLevelAfter,
          'joint_pain_reported': jointPainReported,
          'joint_pain_areas': jointPainAreas,
          'balance_exercises_completed': balanceExercisesCompleted,
          'mobility_exercises_completed': mobilityExercisesCompleted,
          'modifications_used': modificationsUsed,
          'warmup_completed': warmupCompleted,
          'cooldown_completed': cooldownCompleted,
          if (recoveryRating != null) 'recovery_rating': recoveryRating,
          if (notes != null) 'notes': notes,
        },
      );
      return SeniorWorkoutLog.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging workout completion: $e');
      rethrow;
    }
  }

  /// Get workout history for senior user
  Future<SeniorWorkoutHistoryResponse> getWorkoutHistory({
    required String userId,
    int limit = 50,
    int? days,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (days != null) queryParams['days'] = days;

      final response = await _client.get(
        '/senior-fitness/user/$userId/workout-history',
        queryParameters: queryParams,
      );
      return SeniorWorkoutHistoryResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting workout history: $e');
      rethrow;
    }
  }

  /// Get a single workout log by ID
  Future<SeniorWorkoutLog> getWorkoutLog(String userId, String logId) async {
    try {
      final response = await _client.get('/senior-fitness/user/$userId/workout-log/$logId');
      return SeniorWorkoutLog.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting workout log: $e');
      rethrow;
    }
  }

  /// Update a workout log
  Future<SeniorWorkoutLog> updateWorkoutLog({
    required String userId,
    required String logId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _client.patch(
        '/senior-fitness/user/$userId/workout-log/$logId',
        data: updates,
      );
      return SeniorWorkoutLog.fromJson(response.data);
    } catch (e) {
      debugPrint('Error updating workout log: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Mobility & Balance Exercises
  // ─────────────────────────────────────────────────────────────────

  /// Get all mobility exercises
  Future<List<SeniorMobilityExercise>> getMobilityExercises({
    String? targetArea,
    bool? isSeated,
    bool? isBalanceExercise,
    String? difficultyLevel,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (targetArea != null) queryParams['target_area'] = targetArea;
      if (isSeated != null) queryParams['is_seated'] = isSeated;
      if (isBalanceExercise != null) queryParams['is_balance_exercise'] = isBalanceExercise;
      if (difficultyLevel != null) queryParams['difficulty_level'] = difficultyLevel;

      final response = await _client.get(
        '/senior-fitness/mobility-exercises',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data.map((json) => SeniorMobilityExercise.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting mobility exercises: $e');
      rethrow;
    }
  }

  /// Get balance exercises specifically
  Future<List<SeniorMobilityExercise>> getBalanceExercises({
    String? difficultyLevel,
    bool? requiresSupport,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (difficultyLevel != null) queryParams['difficulty_level'] = difficultyLevel;
      if (requiresSupport != null) queryParams['requires_support'] = requiresSupport;

      final response = await _client.get(
        '/senior-fitness/balance-exercises',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data.map((json) => SeniorMobilityExercise.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting balance exercises: $e');
      rethrow;
    }
  }

  /// Get a specific mobility exercise by ID
  Future<SeniorMobilityExercise> getMobilityExercise(String exerciseId) async {
    try {
      final response = await _client.get('/senior-fitness/mobility-exercises/$exerciseId');
      return SeniorMobilityExercise.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting mobility exercise: $e');
      rethrow;
    }
  }

  /// Get mobility exercises by target areas
  Future<List<SeniorMobilityExercise>> getMobilityExercisesByAreas(List<String> areas) async {
    try {
      final response = await _client.get(
        '/senior-fitness/mobility-exercises/by-areas',
        queryParameters: {'areas': areas.join(',')},
      );
      final data = response.data as List;
      return data.map((json) => SeniorMobilityExercise.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting mobility exercises by areas: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Low-Impact Alternatives
  // ─────────────────────────────────────────────────────────────────

  /// Get low-impact alternatives for an exercise
  Future<List<LowImpactAlternative>> getLowImpactAlternatives({
    required String exerciseName,
    String? exerciseId,
    bool? preferSeated,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'exercise_name': exerciseName,
      };
      if (exerciseId != null) queryParams['exercise_id'] = exerciseId;
      if (preferSeated != null) queryParams['prefer_seated'] = preferSeated;

      final response = await _client.get(
        '/senior-fitness/low-impact-alternatives',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data.map((json) => LowImpactAlternative.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting low-impact alternatives: $e');
      rethrow;
    }
  }

  /// Get low-impact alternatives for multiple exercises
  Future<Map<String, List<LowImpactAlternative>>> getLowImpactAlternativesForWorkout({
    required List<String> exerciseNames,
    bool? preferSeated,
  }) async {
    try {
      final response = await _client.post(
        '/senior-fitness/low-impact-alternatives/batch',
        data: {
          'exercise_names': exerciseNames,
          if (preferSeated != null) 'prefer_seated': preferSeated,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data.map((key, value) {
        final alternatives = (value as List)
            .map((json) => LowImpactAlternative.fromJson(json))
            .toList();
        return MapEntry(key, alternatives);
      });
    } catch (e) {
      debugPrint('Error getting batch low-impact alternatives: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Workout Modifications
  // ─────────────────────────────────────────────────────────────────

  /// Get modified workout for senior user
  Future<WorkoutModificationResult> modifyWorkoutForSenior({
    required String userId,
    required String workoutId,
  }) async {
    try {
      final response = await _client.post(
        '/senior-fitness/user/$userId/modify-workout/$workoutId',
      );
      return WorkoutModificationResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error modifying workout: $e');
      rethrow;
    }
  }

  /// Preview workout modifications without applying
  Future<WorkoutModificationResult> previewWorkoutModifications({
    required String userId,
    required String workoutId,
  }) async {
    try {
      final response = await _client.get(
        '/senior-fitness/user/$userId/preview-modifications/$workoutId',
      );
      return WorkoutModificationResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error previewing modifications: $e');
      rethrow;
    }
  }

  /// Apply specific modifications to a workout
  Future<WorkoutModificationResult> applyWorkoutModifications({
    required String userId,
    required String workoutId,
    required List<String> modificationTypes,
  }) async {
    try {
      final response = await _client.post(
        '/senior-fitness/user/$userId/apply-modifications/$workoutId',
        data: {
          'modification_types': modificationTypes,
        },
      );
      return WorkoutModificationResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error applying modifications: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Analytics
  // ─────────────────────────────────────────────────────────────────

  /// Get joint pain trends
  Future<Map<String, dynamic>> getJointPainTrends({
    required String userId,
    int days = 30,
  }) async {
    try {
      final response = await _client.get(
        '/senior-fitness/user/$userId/joint-pain-trends',
        queryParameters: {'days': days},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting joint pain trends: $e');
      rethrow;
    }
  }

  /// Get energy level trends
  Future<Map<String, dynamic>> getEnergyTrends({
    required String userId,
    int days = 30,
  }) async {
    try {
      final response = await _client.get(
        '/senior-fitness/user/$userId/energy-trends',
        queryParameters: {'days': days},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting energy trends: $e');
      rethrow;
    }
  }

  /// Get recovery insights
  Future<Map<String, dynamic>> getRecoveryInsights(String userId) async {
    try {
      final response = await _client.get('/senior-fitness/user/$userId/recovery-insights');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting recovery insights: $e');
      rethrow;
    }
  }
}
