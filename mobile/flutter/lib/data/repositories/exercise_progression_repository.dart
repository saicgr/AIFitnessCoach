import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_progression.dart';
import '../services/api_client.dart';

/// Exercise Progression repository provider
final exerciseProgressionRepositoryProvider =
    Provider<ExerciseProgressionRepository>((ref) {
  return ExerciseProgressionRepository(ref.watch(apiClientProvider));
});

/// Repository for exercise progression operations
///
/// Handles all API calls related to:
/// - Progression chains (exercise variant sequences)
/// - User mastery tracking
/// - Progression suggestions
/// - Rep preferences
class ExerciseProgressionRepository {
  final ApiClient _client;

  ExerciseProgressionRepository(this._client);

  // =========================================================================
  // Progression Chains
  // =========================================================================

  /// Get all available progression chains
  ///
  /// [muscleGroup] - Optional filter by muscle group
  /// [chainType] - Optional filter by chain type (leverage, load, etc.)
  Future<List<ExerciseVariantChain>> getProgressionChains({
    String? muscleGroup,
    ChainType? chainType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (muscleGroup != null) {
        queryParams['muscle_group'] = muscleGroup;
      }
      if (chainType != null) {
        queryParams['chain_type'] = chainType.name;
      }

      final response = await _client.get(
        '/exercise-progressions/chains',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = response.data as List;
      debugPrint('Loaded ${data.length} progression chains');
      return data
          .map((json) => ExerciseVariantChain.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting progression chains: $e');
      rethrow;
    }
  }

  /// Get a specific chain with all its variants
  Future<ExerciseVariantChain> getChainWithVariants(String chainId) async {
    try {
      final response = await _client.get(
        '/exercise-progressions/chains/$chainId',
      );
      return ExerciseVariantChain.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting chain with variants: $e');
      rethrow;
    }
  }

  /// Get chain for a specific base exercise
  Future<ExerciseVariantChain?> getChainForExercise(String exerciseName) async {
    try {
      final response = await _client.get(
        '/exercise-progressions/chains/by-exercise',
        queryParameters: {'exercise_name': exerciseName},
      );
      if (response.data == null) return null;
      return ExerciseVariantChain.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting chain for exercise: $e');
      return null;
    }
  }

  // =========================================================================
  // User Mastery
  // =========================================================================

  /// Get user's mastery data for all exercises they've performed
  Future<List<UserExerciseMastery>> getUserMastery(String userId) async {
    try {
      final response = await _client.get(
        '/exercise-progressions/user/$userId/mastery',
      );

      final data = response.data as List;
      debugPrint('Loaded ${data.length} exercise mastery records');
      return data.map((json) => UserExerciseMastery.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting user mastery: $e');
      rethrow;
    }
  }

  /// Get mastery data for a specific exercise
  Future<UserExerciseMastery?> getExerciseMastery(
    String userId,
    String exerciseName,
  ) async {
    try {
      final response = await _client.get(
        '/exercise-progressions/user/$userId/mastery/$exerciseName',
      );
      if (response.data == null) return null;
      return UserExerciseMastery.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting exercise mastery: $e');
      return null;
    }
  }

  /// Update exercise mastery after a workout
  ///
  /// [userId] - The user ID
  /// [exerciseName] - Name of the exercise performed
  /// [reps] - Reps completed
  /// [weight] - Weight used (kg)
  /// [difficultyFelt] - User's perceived difficulty ('too_easy', 'just_right', 'too_hard')
  Future<UserExerciseMastery> updateExerciseMastery({
    required String userId,
    required String exerciseName,
    required int reps,
    double? weight,
    required String difficultyFelt,
  }) async {
    try {
      debugPrint(
        'Updating mastery for $exerciseName: '
        '$reps reps @ ${weight ?? 0}kg, difficulty: $difficultyFelt',
      );

      final response = await _client.post(
        '/exercise-progressions/user/$userId/mastery/update',
        data: {
          'exercise_name': exerciseName,
          'reps': reps,
          'weight_kg': weight,
          'difficulty_felt': difficultyFelt,
        },
      );

      return UserExerciseMastery.fromJson(response.data);
    } catch (e) {
      debugPrint('Error updating exercise mastery: $e');
      rethrow;
    }
  }

  /// Batch update mastery for multiple exercises (after workout completion)
  Future<List<UserExerciseMastery>> batchUpdateMastery({
    required String userId,
    required List<Map<String, dynamic>> exercisePerformance,
  }) async {
    try {
      debugPrint(
        'Batch updating mastery for ${exercisePerformance.length} exercises',
      );

      final response = await _client.post(
        '/exercise-progressions/user/$userId/mastery/batch-update',
        data: {'exercises': exercisePerformance},
      );

      final data = response.data as List;
      return data.map((json) => UserExerciseMastery.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error batch updating mastery: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Progression Suggestions
  // =========================================================================

  /// Get progression suggestions for the user
  ///
  /// Returns exercises where user is ready to progress to harder variants
  Future<List<ProgressionSuggestion>> getProgressionSuggestions(
    String userId,
  ) async {
    try {
      final response = await _client.get(
        '/exercise-progressions/user/$userId/suggestions',
      );

      final data = response.data as List;
      debugPrint('Got ${data.length} progression suggestions');
      return data
          .map((json) => ProgressionSuggestion.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting progression suggestions: $e');
      rethrow;
    }
  }

  /// Get pending (not accepted/dismissed) progression suggestions
  Future<List<ProgressionSuggestion>> getPendingSuggestions(
    String userId,
  ) async {
    try {
      final response = await _client.get(
        '/exercise-progressions/user/$userId/suggestions',
        queryParameters: {'status': 'pending'},
      );

      final data = response.data as List;
      return data
          .map((json) => ProgressionSuggestion.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending suggestions: $e');
      rethrow;
    }
  }

  /// Accept a progression suggestion
  ///
  /// This tells the system to start using the new exercise variant
  Future<ProgressionSuggestion> acceptProgression({
    required String userId,
    required String suggestionId,
  }) async {
    try {
      debugPrint('Accepting progression suggestion: $suggestionId');

      final response = await _client.post(
        '/exercise-progressions/user/$userId/suggestions/$suggestionId/accept',
      );

      return ProgressionSuggestion.fromJson(response.data);
    } catch (e) {
      debugPrint('Error accepting progression: $e');
      rethrow;
    }
  }

  /// Accept progression by exercise names (alternative method)
  Future<ProgressionSuggestion> acceptProgressionByExercise({
    required String userId,
    required String currentExercise,
    required String newExercise,
  }) async {
    try {
      debugPrint(
        'Accepting progression: $currentExercise -> $newExercise',
      );

      final response = await _client.post(
        '/exercise-progressions/user/$userId/accept-progression',
        data: {
          'current_exercise': currentExercise,
          'new_exercise': newExercise,
        },
      );

      return ProgressionSuggestion.fromJson(response.data);
    } catch (e) {
      debugPrint('Error accepting progression by exercise: $e');
      rethrow;
    }
  }

  /// Dismiss a progression suggestion
  ///
  /// User doesn't want to progress yet
  Future<void> dismissProgression({
    required String userId,
    required String suggestionId,
  }) async {
    try {
      debugPrint('Dismissing progression suggestion: $suggestionId');

      await _client.post(
        '/exercise-progressions/user/$userId/suggestions/$suggestionId/dismiss',
      );
    } catch (e) {
      debugPrint('Error dismissing progression: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Rep Preferences
  // =========================================================================

  /// Get user's rep range preferences
  Future<UserRepPreferences> getRepPreferences(String userId) async {
    try {
      final response = await _client.get(
        '/exercise-progressions/user/$userId/rep-preferences',
      );

      return UserRepPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting rep preferences: $e');
      // Return defaults if not found
      return UserRepPreferences.defaultFor(userId);
    }
  }

  /// Update user's rep range preferences
  Future<UserRepPreferences> updateRepPreferences({
    required String userId,
    required UserRepPreferences preferences,
  }) async {
    try {
      debugPrint(
        'Updating rep preferences: '
        'focus=${preferences.trainingFocus.name}, '
        'range=${preferences.preferredMinReps}-${preferences.preferredMaxReps}',
      );

      final response = await _client.put(
        '/exercise-progressions/user/$userId/rep-preferences',
        data: preferences.toJson(),
      );

      return UserRepPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('Error updating rep preferences: $e');
      rethrow;
    }
  }

  /// Update specific rep preference fields
  Future<UserRepPreferences> patchRepPreferences({
    required String userId,
    TrainingFocus? trainingFocus,
    int? preferredMinReps,
    int? preferredMaxReps,
    bool? avoidHighReps,
    ProgressionStyle? progressionStyle,
    bool? autoSuggestProgressions,
    int? maxSetsPerExercise,
    int? minSetsPerExercise,
    bool? enforceRepCeiling,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (trainingFocus != null) {
        data['training_focus'] = trainingFocus.name;
      }
      if (preferredMinReps != null) {
        data['preferred_min_reps'] = preferredMinReps;
      }
      if (preferredMaxReps != null) {
        data['preferred_max_reps'] = preferredMaxReps;
      }
      if (avoidHighReps != null) {
        data['avoid_high_reps'] = avoidHighReps;
      }
      if (progressionStyle != null) {
        data['progression_style'] = progressionStyle.name;
      }
      if (autoSuggestProgressions != null) {
        data['auto_suggest_progressions'] = autoSuggestProgressions;
      }
      if (maxSetsPerExercise != null) {
        data['max_sets_per_exercise'] = maxSetsPerExercise;
      }
      if (minSetsPerExercise != null) {
        data['min_sets_per_exercise'] = minSetsPerExercise;
      }
      if (enforceRepCeiling != null) {
        data['enforce_rep_ceiling'] = enforceRepCeiling;
      }

      final response = await _client.patch(
        '/exercise-progressions/user/$userId/rep-preferences',
        data: data,
      );

      return UserRepPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('Error patching rep preferences: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Utility Methods
  // =========================================================================

  /// Get exercises ready for progression (convenience method)
  Future<List<UserExerciseMastery>> getExercisesReadyForProgression(
    String userId,
  ) async {
    try {
      final response = await _client.get(
        '/exercise-progressions/user/$userId/ready-for-progression',
      );

      final data = response.data as List;
      return data.map((json) => UserExerciseMastery.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting exercises ready for progression: $e');
      rethrow;
    }
  }

  /// Get all muscle groups that have progression chains
  Future<List<String>> getMuscleGroupsWithChains() async {
    try {
      final response = await _client.get(
        '/exercise-progressions/muscle-groups',
      );

      final data = response.data as List;
      return data.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Error getting muscle groups: $e');
      rethrow;
    }
  }

  /// Generate new progression suggestions based on recent workout
  Future<List<ProgressionSuggestion>> generateSuggestions({
    required String userId,
    required String workoutLogId,
  }) async {
    try {
      debugPrint('Generating progression suggestions for workout: $workoutLogId');

      final response = await _client.post(
        '/exercise-progressions/user/$userId/generate-suggestions',
        data: {'workout_log_id': workoutLogId},
      );

      final data = response.data as List;
      return data
          .map((json) => ProgressionSuggestion.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error generating suggestions: $e');
      rethrow;
    }
  }
}
