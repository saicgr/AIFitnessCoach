part of 'exercise_preferences_repository.dart';

/// Methods extracted from ExercisePreferencesRepository for staple exercises
extension ExercisePreferencesRepositoryStaplesExt on ExercisePreferencesRepository {

  /// Add an exercise to staples
  Future<StapleExercise> addStapleExercise(
    String userId,
    String exerciseName, {
    String? libraryId,
    String? muscleGroup,
    String? reason,
    String? gymProfileId,
    String section = 'main',
    Map<String, double>? cardioParams,
    int? userSets,
    String? userReps,
    int? userRestSeconds,
    double? userWeightLbs,
    List<int>? targetDays,
    String? userTempo,
    String? userNotes,
    String? userBandColor,
    String? userRangeOfMotion,
  }) async {
    debugPrint('🔒 [ExercisePrefs] Adding staple: $exerciseName for user: $userId');

    try {
      final data = <String, dynamic>{
        'user_id': userId,
        'exercise_name': exerciseName,
        if (libraryId != null) 'library_id': libraryId,
        if (muscleGroup != null) 'muscle_group': muscleGroup,
        if (reason != null) 'reason': reason,
        if (gymProfileId != null) 'gym_profile_id': gymProfileId,
        'section': section,
        if (userSets != null) 'user_sets': userSets,
        if (userReps != null) 'user_reps': userReps,
        if (userRestSeconds != null) 'user_rest_seconds': userRestSeconds,
        if (userWeightLbs != null) 'user_weight_lbs': userWeightLbs,
        if (targetDays != null) 'target_days': targetDays,
        if (userTempo != null) 'user_tempo': userTempo,
        if (userNotes != null) 'user_notes': userNotes,
        if (userBandColor != null) 'user_band_color': userBandColor,
        if (userRangeOfMotion != null) 'user_range_of_motion': userRangeOfMotion,
      };

      if (cardioParams != null) {
        if (cardioParams.containsKey('duration_seconds')) {
          data['user_duration_seconds'] = cardioParams['duration_seconds']!.toInt();
        }
        if (cardioParams.containsKey('speed_mph')) {
          data['user_speed_mph'] = cardioParams['speed_mph'];
        }
        if (cardioParams.containsKey('incline_percent')) {
          data['user_incline_percent'] = cardioParams['incline_percent'];
        }
        if (cardioParams.containsKey('rpm')) {
          data['user_rpm'] = cardioParams['rpm']!.toInt();
        }
        if (cardioParams.containsKey('resistance_level')) {
          data['user_resistance_level'] = cardioParams['resistance_level']!.toInt();
        }
        if (cardioParams.containsKey('stroke_rate_spm')) {
          data['user_stroke_rate_spm'] = cardioParams['stroke_rate_spm']!.toInt();
        }
        if (cardioParams.containsKey('distance_miles')) {
          data['user_distance_miles'] = cardioParams['distance_miles'];
        }
        if (cardioParams.containsKey('rpe')) {
          data['user_rpe'] = cardioParams['rpe']!.toInt();
        }
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.apiBaseUrl}/exercise-preferences/staples',
        data: data,
      );

      if (response.data != null) {
        final staple = StapleExercise.fromJson(response.data!);
        debugPrint('✅ [ExercisePrefs] Added staple: ${staple.exerciseName}');
        return staple;
      }

      throw Exception('Failed to add staple exercise');
    } catch (e, stackTrace) {
      debugPrint('❌ [ExercisePrefs] Error adding staple: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

}
