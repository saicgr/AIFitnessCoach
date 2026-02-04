import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood.dart';
import 'api_client.dart';

/// Service for logging user context events for analytics and AI personalization.
///
/// Tracks events like:
/// - Mood check-ins
/// - Workout starts/completions
/// - Score views
/// - Feature interactions
class ContextLoggingService {
  final ApiClient _apiClient;

  ContextLoggingService(this._apiClient);

  // ============================================
  // Mood Events
  // ============================================

  /// Log when user selects a mood
  Future<void> logMoodSelection({
    required Mood mood,
    String? source,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'mood_checkin',
        eventData: {
          'mood': mood.value,
          'source': source ?? 'mood_picker_card',
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged mood selection: ${mood.value}');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log mood selection: $e');
    }
  }

  /// Log when mood workout is generated
  Future<void> logMoodWorkoutGenerated({
    required Mood mood,
    required String workoutId,
    int? durationMinutes,
    int? generationTimeMs,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'mood_workout_generated',
        eventData: {
          'mood': mood.value,
          'workout_id': workoutId,
          'duration_minutes': durationMinutes,
          'generation_time_ms': generationTimeMs,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged mood workout generation');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log mood workout generation: $e');
    }
  }

  // ============================================
  // Workout Events
  // ============================================

  /// Log when user starts a workout
  Future<void> logWorkoutStart({
    required String workoutId,
    required String source, // 'scheduled', 'mood', 'quick_start', 'regenerated'
    String? workoutType,
    Mood? mood,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'workout_start',
        eventData: {
          'workout_id': workoutId,
          'source': source,
          'workout_type': workoutType,
          if (mood != null) 'mood': mood.value,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged workout start: $workoutId');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log workout start: $e');
    }
  }

  /// Log when user completes a workout
  Future<void> logWorkoutComplete({
    required String workoutId,
    required int durationSeconds,
    int? exercisesCompleted,
    int? totalExercises,
    int? setsCompleted,
    double? totalVolumeKg,
    String? source,
    Mood? mood,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'workout_complete',
        eventData: {
          'workout_id': workoutId,
          'duration_seconds': durationSeconds,
          'exercises_completed': exercisesCompleted,
          'total_exercises': totalExercises,
          'sets_completed': setsCompleted,
          'total_volume_kg': totalVolumeKg,
          'source': source,
          if (mood != null) 'mood': mood.value,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged workout complete: $workoutId');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log workout complete: $e');
    }
  }

  /// Log when user exits/quits a workout early
  Future<void> logWorkoutExit({
    required String workoutId,
    required String exitReason,
    int? timeSpentSeconds,
    double? progressPercentage,
    int? exercisesCompleted,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'workout_exit',
        eventData: {
          'workout_id': workoutId,
          'exit_reason': exitReason,
          'time_spent_seconds': timeSpentSeconds,
          'progress_percentage': progressPercentage,
          'exercises_completed': exercisesCompleted,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged workout exit: $workoutId');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log workout exit: $e');
    }
  }

  // ============================================
  // Score Events
  // ============================================

  /// Log when user views the scoring screen
  Future<void> logScoreView({
    required String screen, // 'home_card', 'scoring_screen', 'strength_detail', etc.
    int? durationMs,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'score_view',
        eventData: {
          'screen': screen,
          'duration_ms': durationMs,
          ...?additionalData,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged score view: $screen');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log score view: $e');
    }
  }

  // ============================================
  // Nutrition Events
  // ============================================

  /// Log when user logs food
  Future<void> logNutritionEntry({
    required String mealType, // 'breakfast', 'lunch', 'dinner', 'snack'
    String? foodName,
    int? calories,
    double? protein,
    String? source, // 'manual', 'barcode', 'ai', 'search'
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'nutrition_log',
        eventData: {
          'meal_type': mealType,
          'food_name': foodName,
          'calories': calories,
          'protein': protein,
          'source': source,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged nutrition entry: $mealType');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log nutrition entry: $e');
    }
  }

  // ============================================
  // Feature Interaction Events
  // ============================================

  /// Log generic feature interaction
  Future<void> logFeatureInteraction({
    required String feature,
    required String action,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'feature_interaction',
        eventData: {
          'feature': feature,
          'action': action,
          ...?data,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged feature interaction: $feature.$action');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log feature interaction: $e');
    }
  }

  // ============================================
  // Milestone & ROI Events
  // ============================================

  /// Log when user views milestones screen
  Future<void> logMilestonesViewed({
    int? achievedCount,
    int? totalPoints,
    int? upcomingCount,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'milestones_viewed',
        eventData: {
          'achieved_count': achievedCount,
          'total_points': totalPoints,
          'upcoming_count': upcomingCount,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged milestones viewed');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log milestones viewed: $e');
    }
  }

  /// Log when a milestone is achieved
  Future<void> logMilestoneAchieved({
    required String milestoneId,
    required String milestoneName,
    required String tier,
    required int points,
    String? category,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'milestone_achieved',
        eventData: {
          'milestone_id': milestoneId,
          'milestone_name': milestoneName,
          'tier': tier,
          'points': points,
          'category': category,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged milestone achieved: $milestoneName');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log milestone achieved: $e');
    }
  }

  /// Log when user celebrates a milestone (sees celebration dialog)
  Future<void> logMilestoneCelebrated({
    required String milestoneId,
    required String milestoneName,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'milestone_celebrated',
        eventData: {
          'milestone_id': milestoneId,
          'milestone_name': milestoneName,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged milestone celebrated: $milestoneName');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log milestone celebrated: $e');
    }
  }

  /// Log when user shares a milestone
  Future<void> logMilestoneShared({
    required String milestoneId,
    required String milestoneName,
    required String platform, // 'twitter', 'instagram', 'copy', 'share'
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'milestone_shared',
        eventData: {
          'milestone_id': milestoneId,
          'milestone_name': milestoneName,
          'platform': platform,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged milestone shared: $milestoneName on $platform');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log milestone shared: $e');
    }
  }

  /// Log when user views ROI metrics
  Future<void> logROIViewed({
    int? totalWorkouts,
    double? totalHours,
    int? prsCount,
    double? strengthIncrease,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'roi_viewed',
        eventData: {
          'total_workouts': totalWorkouts,
          'total_hours': totalHours,
          'prs_count': prsCount,
          'strength_increase': strengthIncrease,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged ROI viewed');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log ROI viewed: $e');
    }
  }

  // ============================================
  // Library Events - For AI preference learning
  // ============================================

  /// Log when user views an exercise detail in the library
  Future<void> logExerciseViewed({
    required String exerciseId,
    required String exerciseName,
    required String source, // 'library_browse', 'search_result', 'carousel', 'workout_detail'
    String? muscleGroup,
    String? difficulty,
    List<String>? equipment,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _apiClient.post(
        '/library/log/exercise-view',
        data: {
          'exercise_id': exerciseId,
          'exercise_name': exerciseName,
          'source': source,
          'muscle_group': muscleGroup,
          'difficulty': difficulty,
          'equipment': equipment,
        },
      );
      debugPrint('✅ [ContextLog] Logged exercise view: $exerciseName');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log exercise view: $e');
    }
  }

  /// Log when user views a program detail in the library
  Future<void> logProgramViewed({
    required String programId,
    required String programName,
    String? category,
    String? difficulty,
    int? durationWeeks,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _apiClient.post(
        '/library/log/program-view',
        data: {
          'program_id': programId,
          'program_name': programName,
          'category': category,
          'difficulty': difficulty,
          'duration_weeks': durationWeeks,
        },
      );
      debugPrint('✅ [ContextLog] Logged program view: $programName');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log program view: $e');
    }
  }

  /// Log when user searches in the library
  Future<void> logLibrarySearch({
    required String searchQuery,
    String searchType = 'exercises', // 'exercises' or 'programs'
    Map<String, dynamic>? filtersUsed,
    int resultCount = 0,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _apiClient.post(
        '/library/log/search',
        data: {
          'search_query': searchQuery,
          'search_type': searchType,
          'filters_used': filtersUsed,
          'result_count': resultCount,
        },
      );
      debugPrint('✅ [ContextLog] Logged library search: $searchQuery');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log library search: $e');
    }
  }

  /// Log when user applies a filter in the library
  Future<void> logExerciseFilterUsed({
    required String filterType, // 'muscle_group', 'equipment', 'difficulty', 'body_part'
    required List<String> filterValues,
    int resultCount = 0,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _apiClient.post(
        '/library/log/filter',
        data: {
          'filter_type': filterType,
          'filter_values': filterValues,
          'result_count': resultCount,
        },
      );
      debugPrint('✅ [ContextLog] Logged filter usage: $filterType=$filterValues');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log filter usage: $e');
    }
  }

  // ============================================
  // Superset Events
  // ============================================

  /// Log when user creates a superset pair
  Future<void> logSupersetCreated({
    required String workoutId,
    required String exercise1Name,
    required String exercise2Name,
    String supersetType = 'custom', // 'antagonist', 'compound', 'pre_exhaust', 'custom'
    String? source, // 'exercise_menu', 'superset_sheet', 'ai_suggestion'
  }) async {
    try {
      await _logEvent(
        eventType: 'superset_created',
        eventData: {
          'workout_id': workoutId,
          'exercise_1': exercise1Name,
          'exercise_2': exercise2Name,
          'superset_type': supersetType,
          'source': source ?? 'unknown',
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged superset created: $exercise1Name + $exercise2Name');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log superset created: $e');
    }
  }

  /// Log when user completes a superset (both exercises done back-to-back)
  Future<void> logSupersetCompleted({
    required String workoutId,
    required String exercise1Name,
    required String exercise2Name,
    int? totalTimeSeconds,
    int setsCompleted = 1,
    bool wasModified = false, // If user added rest between
  }) async {
    try {
      await _logEvent(
        eventType: 'superset_completed',
        eventData: {
          'workout_id': workoutId,
          'exercise_1': exercise1Name,
          'exercise_2': exercise2Name,
          'total_time_seconds': totalTimeSeconds,
          'sets_completed': setsCompleted,
          'was_modified': wasModified,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged superset completed: $exercise1Name + $exercise2Name');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log superset completed: $e');
    }
  }

  /// Log when user removes/breaks a superset
  Future<void> logSupersetRemoved({
    required String workoutId,
    required String exercise1Name,
    required String exercise2Name,
    String? reason, // 'too_hard', 'prefer_separate', 'equipment_issue', etc.
  }) async {
    try {
      await _logEvent(
        eventType: 'superset_removed',
        eventData: {
          'workout_id': workoutId,
          'exercise_1': exercise1Name,
          'exercise_2': exercise2Name,
          'reason': reason,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged superset removed: $exercise1Name + $exercise2Name');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log superset removed: $e');
    }
  }

  /// Log when user updates superset preferences
  Future<void> logSupersetPreferencesChanged({
    required bool supersetsEnabled,
    required bool preferAntagonist,
    required bool allowCompound,
    required int maxSupersets,
    required int restBetween,
    required int restAfter,
  }) async {
    try {
      await _logEvent(
        eventType: 'superset_preferences_changed',
        eventData: {
          'supersets_enabled': supersetsEnabled,
          'prefer_antagonist': preferAntagonist,
          'allow_compound': allowCompound,
          'max_supersets': maxSupersets,
          'rest_between_seconds': restBetween,
          'rest_after_seconds': restAfter,
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged superset preferences changed');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log superset preferences: $e');
    }
  }

  /// Log when user adds a favorite superset pair
  Future<void> logFavoriteSupersetAdded({
    required String exercise1Name,
    required String exercise2Name,
    String? notes,
  }) async {
    try {
      await _logEvent(
        eventType: 'favorite_superset_added',
        eventData: {
          'exercise_1': exercise1Name,
          'exercise_2': exercise2Name,
          'has_notes': notes != null && notes.isNotEmpty,
        },
      );
      debugPrint('✅ [ContextLog] Logged favorite superset added');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log favorite superset: $e');
    }
  }

  /// Log when user accepts an AI superset suggestion
  Future<void> logSupersetSuggestionAccepted({
    required String exercise1Name,
    required String exercise2Name,
    required String suggestionReason,
    double? confidence,
  }) async {
    try {
      await _logEvent(
        eventType: 'superset_suggestion_accepted',
        eventData: {
          'exercise_1': exercise1Name,
          'exercise_2': exercise2Name,
          'suggestion_reason': suggestionReason,
          'confidence': confidence,
        },
      );
      debugPrint('✅ [ContextLog] Logged superset suggestion accepted');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log suggestion acceptance: $e');
    }
  }



  // ============================================
  // Injury Tracking Events
  // ============================================

  /// Log when user reports a new injury
  Future<void> logInjuryReported({
    required String bodyPart,
    required String injuryType,
    required String severity,
    String? description,
    List<String>? exercisesToAvoid,
    int? expectedRecoveryDays,
  }) async {
    try {
      await _logEvent(
        eventType: 'injury_reported',
        eventData: {
          'body_part': bodyPart,
          'injury_type': injuryType,
          'severity': severity,
          'description': description,
          'exercises_to_avoid': exercisesToAvoid ?? [],
          'expected_recovery_days': expectedRecoveryDays,
          'reported_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged injury reported');
    } catch (e) {
      debugPrint('Failed to log injury reported');
    }
  }

  /// Log when user marks an injury as healed
  Future<void> logInjuryHealed({
    required String bodyPart,
    required String injuryType,
    required int recoveryDays,
    List<String>? exercisesResumed,
  }) async {
    try {
      await _logEvent(
        eventType: 'injury_healed',
        eventData: {
          'body_part': bodyPart,
          'injury_type': injuryType,
          'recovery_days': recoveryDays,
          'exercises_resumed': exercisesResumed ?? [],
          'healed_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged injury healed');
    } catch (e) {
      debugPrint('Failed to log injury healed');
    }
  }

  /// Log when user checks in on injury status
  Future<void> logInjuryCheckIn({
    required String bodyPart,
    required int painLevel,
    required String mobilityLevel,
    required String improvementSinceLast,
    String? notes,
  }) async {
    try {
      await _logEvent(
        eventType: 'injury_check_in',
        eventData: {
          'body_part': bodyPart,
          'pain_level': painLevel,
          'mobility_level': mobilityLevel,
          'improvement_since_last': improvementSinceLast,
          'notes': notes,
          'checked_in_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged injury check-in');
    } catch (e) {
      debugPrint('Failed to log injury check-in');
    }
  }

  // ============================================
  // Strain Prevention Events
  // ============================================

  /// Log strain data after a workout session
  Future<void> logStrainRecorded({
    required List<String> muscleGroups,
    required double volumeToday,
    required double volumeWeekly,
    required String intensityLevel,
    double? fatigueScore,
  }) async {
    try {
      await _logEvent(
        eventType: 'strain_recorded',
        eventData: {
          'muscle_groups': muscleGroups,
          'volume_today': volumeToday,
          'volume_weekly': volumeWeekly,
          'intensity_level': intensityLevel,
          'fatigue_score': fatigueScore,
          'recorded_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged strain recorded');
    } catch (e) {
      debugPrint('Failed to log strain recorded');
    }
  }

  /// Log when a strain alert is created
  Future<void> logStrainAlertCreated({
    required String alertType,
    required String riskLevel,
    required List<String> affectedMuscles,
    required String recommendation,
    double? volumeThresholdExceeded,
    int? daysWithoutRest,
  }) async {
    try {
      await _logEvent(
        eventType: 'strain_alert_created',
        eventData: {
          'alert_type': alertType,
          'risk_level': riskLevel,
          'affected_muscles': affectedMuscles,
          'recommendation': recommendation,
          'volume_threshold_exceeded': volumeThresholdExceeded,
          'days_without_rest': daysWithoutRest,
          'alert_created_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged strain alert created');
    } catch (e) {
      debugPrint('Failed to log strain alert created');
    }
  }

  /// Log when user acknowledges a strain alert
  Future<void> logStrainAlertAcknowledged({
    required String alertType,
    required String riskLevel,
    required String actionTaken,
    String? notes,
  }) async {
    try {
      await _logEvent(
        eventType: 'strain_alert_acknowledged',
        eventData: {
          'alert_type': alertType,
          'risk_level': riskLevel,
          'action_taken': actionTaken,
          'notes': notes,
          'acknowledged_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged strain alert acknowledged');
    } catch (e) {
      debugPrint('Failed to log strain alert acknowledged');
    }
  }

  // ============================================
  // Senior Fitness Events
  // ============================================

  /// Log when senior fitness settings are updated
  Future<void> logSeniorSettingsUpdated({
    required int age,
    required double recoveryMultiplier,
    required int preferredRestDays,
    required bool jointFriendlyMode,
    required bool balanceExercisesEnabled,
    required bool mobilityFocus,
    Map<String, dynamic>? previousSettings,
  }) async {
    try {
      await _logEvent(
        eventType: 'senior_settings_updated',
        eventData: {
          'age': age,
          'recovery_multiplier': recoveryMultiplier,
          'preferred_rest_days': preferredRestDays,
          'joint_friendly_mode': jointFriendlyMode,
          'balance_exercises_enabled': balanceExercisesEnabled,
          'mobility_focus': mobilityFocus,
          'previous_settings': previousSettings,
          'updated_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged senior settings updated');
    } catch (e) {
      debugPrint('Failed to log senior settings updated');
    }
  }

  /// Log a senior user recovery check before workout
  Future<void> logSeniorRecoveryCheck({
    required int daysSinceLastWorkout,
    required String recoveryStatus,
    required int energyLevel,
    required int sorenessLevel,
    required String recommendedIntensity,
  }) async {
    try {
      await _logEvent(
        eventType: 'senior_recovery_check',
        eventData: {
          'days_since_last_workout': daysSinceLastWorkout,
          'recovery_status': recoveryStatus,
          'energy_level': energyLevel,
          'soreness_level': sorenessLevel,
          'recommended_intensity': recommendedIntensity,
          'checked_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged senior recovery check');
    } catch (e) {
      debugPrint('Failed to log senior recovery check');
    }
  }

  // ============================================
  // Fasting Impact Analysis Events
  // ============================================

  /// Log when user logs weight with fasting context
  Future<void> logWeightWithFastingContext({
    required double weightKg,
    required bool isFastingDay,
    String? fastingProtocol,
    int? fastingDurationMinutes,
    bool? completedGoal,
    String? notes,
  }) async {
    try {
      await _logEvent(
        eventType: 'weight_logged_with_fasting',
        eventData: {
          'weight_kg': weightKg,
          'is_fasting_day': isFastingDay,
          'fasting_protocol': fastingProtocol,
          'fasting_duration_minutes': fastingDurationMinutes,
          'completed_goal': completedGoal,
          'notes': notes,
          'logged_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged weight with fasting context: $weightKg kg');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log weight with fasting: $e');
    }
  }

  /// Log when fasting impact analysis is viewed
  Future<void> logFastingImpactViewed({
    required String period, // 'week', 'month', '3months', 'all'
    double? correlationScore,
    String? insightType,
    int? fastingDaysAnalyzed,
    int? nonFastingDaysAnalyzed,
  }) async {
    try {
      await _logEvent(
        eventType: 'fasting_impact_viewed',
        eventData: {
          'period': period,
          'correlation_score': correlationScore,
          'insight_type': insightType,
          'fasting_days_analyzed': fastingDaysAnalyzed,
          'non_fasting_days_analyzed': nonFastingDaysAnalyzed,
          'viewed_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged fasting impact viewed');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log fasting impact viewed: $e');
    }
  }

  /// Log when fasting calendar is viewed
  Future<void> logFastingCalendarViewed({
    required int month,
    required int year,
    int? fastingDaysInMonth,
    int? weightLogsInMonth,
  }) async {
    try {
      await _logEvent(
        eventType: 'fasting_calendar_viewed',
        eventData: {
          'month': month,
          'year': year,
          'fasting_days_in_month': fastingDaysInMonth,
          'weight_logs_in_month': weightLogsInMonth,
          'viewed_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged fasting calendar viewed');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log fasting calendar viewed: $e');
    }
  }

  /// Log when user receives a fasting insight
  Future<void> logFastingInsightReceived({
    required String insightType, // 'positive', 'neutral', 'negative', 'needs_more_data'
    required String insightTitle,
    String? recommendation,
    double? correlationScore,
    bool wasAIGenerated = true,
  }) async {
    try {
      await _logEvent(
        eventType: 'fasting_insight_received',
        eventData: {
          'insight_type': insightType,
          'insight_title': insightTitle,
          'recommendation': recommendation,
          'correlation_score': correlationScore,
          'was_ai_generated': wasAIGenerated,
          'received_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged fasting insight received: $insightType');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log fasting insight: $e');
    }
  }

  /// Log when user takes action based on fasting insight
  Future<void> logFastingInsightAction({
    required String insightType,
    required String actionTaken, // 'applied', 'dismissed', 'shared', 'learn_more'
    String? insightId,
  }) async {
    try {
      await _logEvent(
        eventType: 'fasting_insight_action',
        eventData: {
          'insight_type': insightType,
          'action_taken': actionTaken,
          'insight_id': insightId,
          'action_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged fasting insight action: $actionTaken');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log fasting insight action: $e');
    }
  }

  /// Log fasting goal impact correlation data
  Future<void> logFastingGoalCorrelation({
    required double correlationScore,
    required int totalFastingDays,
    required int totalNonFastingDays,
    double? weightChangeOnFasting,
    double? weightChangeOnNonFasting,
    double? workoutPerformanceFasting,
    double? workoutPerformanceNonFasting,
    int? goalsAchievedFasting,
    int? goalsAchievedNonFasting,
  }) async {
    try {
      await _logEvent(
        eventType: 'fasting_goal_correlation',
        eventData: {
          'correlation_score': correlationScore,
          'total_fasting_days': totalFastingDays,
          'total_non_fasting_days': totalNonFastingDays,
          'weight_change_on_fasting': weightChangeOnFasting,
          'weight_change_on_non_fasting': weightChangeOnNonFasting,
          'workout_performance_fasting': workoutPerformanceFasting,
          'workout_performance_non_fasting': workoutPerformanceNonFasting,
          'goals_achieved_fasting': goalsAchievedFasting,
          'goals_achieved_non_fasting': goalsAchievedNonFasting,
          'analyzed_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged fasting goal correlation');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log fasting goal correlation: $e');
    }
  }

  // ============================================
  // Progression Pace Events
  // ============================================

  /// Log when progression pace preference is changed
  Future<void> logProgressionPaceChanged({
    required String oldPace,
    required String newPace,
    String? reason,
    String triggeredBy = 'user',
  }) async {
    try {
      await _logEvent(
        eventType: 'progression_pace_changed',
        eventData: {
          'old_pace': oldPace,
          'new_pace': newPace,
          'reason': reason,
          'triggered_by': triggeredBy,
          'changed_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged progression pace changed');
    } catch (e) {
      debugPrint('Failed to log progression pace changed');
    }
  }

  /// Log when a workout is modified for safety reasons
  Future<void> logWorkoutModifiedForSafety({
    required String workoutId,
    required String modificationReason,
    List<String>? exercisesRemoved,
    Map<String, String>? exercisesSubstituted,
    bool intensityReduced = false,
    bool volumeReduced = false,
    double? reductionPercentage,
  }) async {
    try {
      await _logEvent(
        eventType: 'workout_modified_for_safety',
        eventData: {
          'workout_id': workoutId,
          'modification_reason': modificationReason,
          'exercises_removed': exercisesRemoved ?? [],
          'exercises_substituted': exercisesSubstituted ?? {},
          'intensity_reduced': intensityReduced,
          'volume_reduced': volumeReduced,
          'reduction_percentage': reductionPercentage,
          'modified_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged workout modified for safety');
    } catch (e) {
      debugPrint('Failed to log workout modified for safety');
    }
  }

  // ============================================
  // Exercise History & Muscle Analytics Events
  // ============================================

  /// Log when user views exercise history for a specific exercise
  Future<void> logExerciseHistoryView({
    required String exerciseName,
    String timeRange = 'month', // 'week', 'month', '3months', '6months', 'year', 'all'
    int? totalSessions,
    int? totalSets,
    double? maxWeight,
    String? progressionTrend, // 'improving', 'stable', 'declining'
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'exercise_history_viewed',
        eventData: {
          'exercise_name': exerciseName,
          'time_range': timeRange,
          'total_sessions': totalSessions,
          'total_sets': totalSets,
          'max_weight': maxWeight,
          'progression_trend': progressionTrend,
          'viewed_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged exercise history view: $exerciseName ($timeRange)');
    } catch (e) {
      debugPrint('Failed to log exercise history view: $e');
    }
  }

  /// Log when user views muscle analytics (heatmap, distribution, balance)
  Future<void> logMuscleAnalyticsView({
    required String viewType, // 'heatmap', 'distribution', 'balance', 'weekly_volume', 'recovery'
    String? muscleGroup,
    String timeRange = 'week', // 'week', 'month', '3months'
    List<String>? topMusclesTrained,
    List<String>? neglectedMuscles,
    double? balanceScore,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'muscle_analytics_viewed',
        eventData: {
          'view_type': viewType,
          'muscle_group': muscleGroup,
          'time_range': timeRange,
          'top_muscles_trained': topMusclesTrained ?? [],
          'neglected_muscles': neglectedMuscles ?? [],
          'balance_score': balanceScore,
          'viewed_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged muscle analytics view: $viewType (muscle=$muscleGroup)');
    } catch (e) {
      debugPrint('Failed to log muscle analytics view: $e');
    }
  }

  /// Log when user interacts with the muscle heatmap (taps on a muscle)
  Future<void> logMuscleInteraction({
    required String muscle,
    String interactionType = 'tap', // 'tap', 'long_press', 'drill_down'
    double? muscleVolumePercentage,
    String? lastTrainedDate,
    int? setsThisWeek,
    List<String>? exercisesForMuscle,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _logEvent(
        eventType: 'muscle_heatmap_interaction',
        eventData: {
          'muscle_clicked': muscle,
          'interaction_type': interactionType,
          'muscle_volume_percentage': muscleVolumePercentage,
          'last_trained_date': lastTrainedDate,
          'sets_this_week': setsThisWeek,
          'exercises_for_muscle': exercisesForMuscle ?? [],
          'interacted_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged muscle heatmap interaction: $muscle ($interactionType)');
    } catch (e) {
      debugPrint('Failed to log muscle heatmap interaction: $e');
    }
  }

  // ============================================
  // Diabetes Tracking Events
  // ============================================

  /// Log when user creates or updates their diabetes profile
  Future<void> logDiabetesProfileSetup({
    required String diabetesType, // 'type1', 'type2', 'prediabetes', 'gestational'
    String? diagnosisDate,
    double targetGlucoseMin = 70.0,
    double targetGlucoseMax = 180.0,
    double? a1cGoal,
    bool usesInsulin = false,
    bool usesCgm = false,
  }) async {
    try {
      await _logEvent(
        eventType: 'diabetes_profile_created',
        eventData: {
          'diabetes_type': diabetesType,
          'diagnosis_date': diagnosisDate,
          'target_glucose_min': targetGlucoseMin,
          'target_glucose_max': targetGlucoseMax,
          'a1c_goal': a1cGoal,
          'uses_insulin': usesInsulin,
          'uses_cgm': usesCgm,
          'created_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged diabetes profile setup');
    } catch (e) {
      debugPrint('Failed to log diabetes profile setup');
    }
  }

  /// Log when user records a blood glucose reading
  Future<void> logGlucoseLogged({
    required double value, // mg/dL
    required String status, // 'low', 'normal', 'high', 'very_high'
    String? mealContext, // 'fasting', 'pre_meal', 'post_meal', 'bedtime'
    String source = 'manual', // 'manual', 'cgm', 'health_connect'
    String? notes,
  }) async {
    try {
      await _logEvent(
        eventType: 'glucose_reading_logged',
        eventData: {
          'value': value,
          'status': status,
          'meal_context': mealContext,
          'source': source,
          'notes': notes,
          'logged_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged glucose reading');
    } catch (e) {
      debugPrint('Failed to log glucose reading');
    }
  }

  /// Log when user records an insulin dose
  Future<void> logInsulinLogged({
    required double units,
    required String insulinType, // 'rapid', 'short', 'intermediate', 'long', 'mixed'
    String? doseContext, // 'meal', 'correction', 'basal', 'exercise'
    double? glucoseAtDose,
    String? notes,
  }) async {
    try {
      await _logEvent(
        eventType: 'insulin_dose_logged',
        eventData: {
          'units': units,
          'insulin_type': insulinType,
          'dose_context': doseContext,
          'glucose_at_dose': glucoseAtDose,
          'notes': notes,
          'logged_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged insulin dose');
    } catch (e) {
      debugPrint('Failed to log insulin dose');
    }
  }

  /// Log when user records an A1C result
  Future<void> logA1CLogged({
    required double value, // A1C percentage (e.g., 6.5 for 6.5%)
    String? testDate,
    double? goal,
    double? previousA1c,
    bool isLabResult = true,
  }) async {
    try {
      double? change;
      if (previousA1c != null) {
        change = (value - previousA1c).roundToDouble();
      }
      final goalMet = goal != null && value <= goal;

      await _logEvent(
        eventType: 'a1c_logged',
        eventData: {
          'value': value,
          'test_date': testDate,
          'goal': goal,
          'previous_a1c': previousA1c,
          'change_from_previous': change,
          'goal_met': goalMet,
          'is_lab_result': isLabResult,
          'logged_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged A1C');
    } catch (e) {
      debugPrint('Failed to log A1C');
    }
  }

  /// Log when a glucose alert is triggered
  Future<void> logDiabetesAlertTriggered({
    required String alertType, // 'low', 'very_low', 'high', 'very_high', 'rapid_drop', 'rapid_rise'
    required double value, // Current glucose value
    required double threshold, // Threshold that triggered alert
    String source = 'app', // 'app', 'cgm', 'health_connect'
    String? actionSuggested,
  }) async {
    try {
      await _logEvent(
        eventType: 'glucose_alert_triggered',
        eventData: {
          'alert_type': alertType,
          'value': value,
          'threshold': threshold,
          'source': source,
          'action_suggested': actionSuggested,
          'triggered_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged glucose alert');
    } catch (e) {
      debugPrint('Failed to log glucose alert');
    }
  }

  /// Log Health Connect sync for diabetes data
  Future<void> logHealthConnectDiabetesSync({
    required int glucoseCount,
    required int insulinCount,
    int syncRangeHours = 24,
    String syncStatus = 'success', // 'success', 'partial', 'failed'
    String? errorMessage,
  }) async {
    try {
      await _logEvent(
        eventType: 'health_connect_diabetes_sync',
        eventData: {
          'glucose_count': glucoseCount,
          'insulin_count': insulinCount,
          'sync_range_hours': syncRangeHours,
          'sync_status': syncStatus,
          'error_message': errorMessage,
          'synced_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged Health Connect diabetes sync');
    } catch (e) {
      debugPrint('Failed to log Health Connect diabetes sync');
    }
  }

  /// Log a pre-workout glucose check
  Future<void> logPreWorkoutGlucoseCheck({
    required double value, // mg/dL
    required String riskLevel, // 'safe', 'caution', 'delay_recommended', 'unsafe'
    String? workoutId,
    String? actionTaken, // 'proceeded', 'delayed', 'ate_snack', 'cancelled'
    String? recommendation,
  }) async {
    try {
      await _logEvent(
        eventType: 'pre_workout_glucose_check',
        eventData: {
          'value': value,
          'risk_level': riskLevel,
          'workout_id': workoutId,
          'action_taken': actionTaken,
          'recommendation': recommendation,
          'checked_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged pre-workout glucose check');
    } catch (e) {
      debugPrint('Failed to log pre-workout glucose check');
    }
  }

  /// Log when user sets a diabetes-related goal
  Future<void> logDiabetesGoalSet({
    required String goalType, // 'a1c', 'fasting_glucose', 'time_in_range', 'weight'
    required double targetValue,
    double? currentValue,
    String? targetDate,
    double? previousGoal,
  }) async {
    try {
      await _logEvent(
        eventType: 'diabetes_goal_set',
        eventData: {
          'goal_type': goalType,
          'target_value': targetValue,
          'current_value': currentValue,
          'target_date': targetDate,
          'previous_goal': previousGoal,
          'gap_to_goal': currentValue != null ? (targetValue - currentValue) : null,
          'set_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged diabetes goal set');
    } catch (e) {
      debugPrint('Failed to log diabetes goal set');
    }
  }

  // ============================================
  // Nutrition Preferences Events
  // ============================================

  /// Log when user updates nutrition preferences
  Future<void> logNutritionPreferencesUpdated({
    bool? disableAiTips,
    bool? quickLogMode,
    bool? compactTrackerView,
  }) async {
    try {
      await _logEvent(
        eventType: 'nutrition_preferences_updated',
        eventData: {
          'disable_ai_tips': disableAiTips,
          'quick_log_mode': quickLogMode,
          'compact_tracker_view': compactTrackerView,
          'updated_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged nutrition preferences updated');
    } catch (e) {
      debugPrint('Failed to log nutrition preferences updated: $e');
    }
  }

  /// Log when user resets nutrition preferences to defaults
  Future<void> logNutritionPreferencesReset() async {
    try {
      await _logEvent(
        eventType: 'nutrition_preferences_reset',
        eventData: {
          'reset_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged nutrition preferences reset');
    } catch (e) {
      debugPrint('Failed to log nutrition preferences reset: $e');
    }
  }

  /// Log when user uses quick log feature
  Future<void> logQuickLogUsed({
    required String foodName,
    required String mealType,
    required int calories,
    double servings = 1.0,
  }) async {
    try {
      await _logEvent(
        eventType: 'quick_log_used',
        eventData: {
          'food_name': foodName,
          'meal_type': mealType,
          'calories': calories,
          'servings': servings,
          'logged_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged quick log used: $foodName ($calories cal)');
    } catch (e) {
      debugPrint('Failed to log quick log used: $e');
    }
  }

  /// Log when user creates a meal template
  Future<void> logMealTemplateCreated({
    required String templateName,
    required int totalCalories,
    required int foodCount,
  }) async {
    try {
      await _logEvent(
        eventType: 'meal_template_created',
        eventData: {
          'template_name': templateName,
          'total_calories': totalCalories,
          'food_count': foodCount,
          'created_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged meal template created: $templateName');
    } catch (e) {
      debugPrint('Failed to log meal template created: $e');
    }
  }

  /// Log when user logs a meal using a template
  Future<void> logMealTemplateLogged({
    required String templateId,
    required String templateName,
    required String mealType,
    required int totalCalories,
  }) async {
    try {
      await _logEvent(
        eventType: 'meal_template_logged',
        eventData: {
          'template_id': templateId,
          'template_name': templateName,
          'meal_type': mealType,
          'total_calories': totalCalories,
          'logged_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged meal template logged: $templateName');
    } catch (e) {
      debugPrint('Failed to log meal template logged: $e');
    }
  }

  /// Log when user deletes a meal template
  Future<void> logMealTemplateDeleted({
    required String templateId,
    required String templateName,
  }) async {
    try {
      await _logEvent(
        eventType: 'meal_template_deleted',
        eventData: {
          'template_id': templateId,
          'template_name': templateName,
          'deleted_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged meal template deleted: $templateName');
    } catch (e) {
      debugPrint('Failed to log meal template deleted: $e');
    }
  }

  /// Log when user searches for foods
  Future<void> logFoodSearchPerformed({
    required String query,
    required int resultCount,
    bool cacheHit = false,
    String source = 'api',
  }) async {
    try {
      await _logEvent(
        eventType: 'food_search_performed',
        eventData: {
          'query': query,
          'result_count': resultCount,
          'cache_hit': cacheHit,
          'source': source,
          'has_results': resultCount > 0,
          'searched_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged food search: "$query" ($resultCount results)');
    } catch (e) {
      debugPrint('Failed to log food search: $e');
    }
  }

  /// Log when user toggles AI food tips
  Future<void> logAiTipsToggled({required bool disabled}) async {
    try {
      final eventType = disabled ? 'ai_tips_disabled' : 'ai_tips_enabled';
      await _logEvent(
        eventType: eventType,
        eventData: {
          'disabled': disabled,
          'toggled_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged AI tips ${disabled ? 'disabled' : 'enabled'}');
    } catch (e) {
      debugPrint('Failed to log AI tips toggled: $e');
    }
  }

  /// Log when user toggles compact tracker view
  Future<void> logCompactViewToggled({required bool enabled}) async {
    try {
      final eventType = enabled ? 'compact_view_enabled' : 'compact_view_disabled';
      await _logEvent(
        eventType: eventType,
        eventData: {
          'enabled': enabled,
          'toggled_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('Logged compact view ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('Failed to log compact view toggled: $e');
    }
  }

  // ============================================
  // Habit Tracking Events
  // ============================================

  /// Log when user creates a new habit
  Future<void> logHabitCreated({
    required String habitId,
    required String habitName,
    required String category,
    required String habitType, // 'positive' or 'negative'
    required String frequency, // 'daily', 'weekly', 'specific_days'
    int? targetCount,
    String? unit,
    String? source, // 'manual', 'template', 'ai_suggestion'
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_created',
        eventData: {
          'habit_id': habitId,
          'habit_name': habitName,
          'category': category,
          'habit_type': habitType,
          'frequency': frequency,
          'target_count': targetCount,
          'unit': unit,
          'source': source ?? 'manual',
          'created_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged habit created: $habitName');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log habit created: $e');
    }
  }

  /// Log when user completes/logs a habit for the day
  Future<void> logHabitCompleted({
    required String habitId,
    required String habitName,
    required String category,
    required String habitType,
    int? currentStreak,
    double? value,
    int? targetCount,
    bool isQuantitative = false,
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_completed',
        eventData: {
          'habit_id': habitId,
          'habit_name': habitName,
          'category': category,
          'habit_type': habitType,
          'current_streak': currentStreak,
          'value': value,
          'target_count': targetCount,
          'is_quantitative': isQuantitative,
          'completion_percentage': targetCount != null && value != null
              ? ((value / targetCount) * 100).clamp(0, 100)
              : 100.0,
          'completed_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged habit completed: $habitName (streak: $currentStreak)');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log habit completed: $e');
    }
  }

  /// Log when user uncompletes/removes a habit log
  Future<void> logHabitUncompleted({
    required String habitId,
    required String habitName,
    required String category,
    int? previousStreak,
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_uncompleted',
        eventData: {
          'habit_id': habitId,
          'habit_name': habitName,
          'category': category,
          'previous_streak': previousStreak,
          'uncompleted_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged habit uncompleted: $habitName');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log habit uncompleted: $e');
    }
  }

  /// Log when user deletes a habit
  Future<void> logHabitDeleted({
    required String habitId,
    required String habitName,
    required String category,
    int? totalCompletions,
    int? longestStreak,
    int? daysActive,
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_deleted',
        eventData: {
          'habit_id': habitId,
          'habit_name': habitName,
          'category': category,
          'total_completions': totalCompletions,
          'longest_streak': longestStreak,
          'days_active': daysActive,
          'deleted_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged habit deleted: $habitName');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log habit deleted: $e');
    }
  }

  /// Log when user edits/updates a habit
  Future<void> logHabitUpdated({
    required String habitId,
    required String habitName,
    Map<String, dynamic>? changedFields,
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_updated',
        eventData: {
          'habit_id': habitId,
          'habit_name': habitName,
          'changed_fields': changedFields ?? {},
          'updated_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged habit updated: $habitName');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log habit updated: $e');
    }
  }

  /// Log when user views the habit tracker screen
  Future<void> logHabitTrackerViewed({
    int? totalHabits,
    int? completedToday,
    double? completionPercentage,
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_tracker_viewed',
        eventData: {
          'total_habits': totalHabits,
          'completed_today': completedToday,
          'completion_percentage': completionPercentage,
          'viewed_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged habit tracker viewed');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log habit tracker viewed: $e');
    }
  }

  /// Log when user achieves a streak milestone
  Future<void> logHabitStreakMilestone({
    required String habitId,
    required String habitName,
    required int streakDays,
    required String milestoneType, // '7_days', '30_days', '100_days', etc.
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_streak_milestone',
        eventData: {
          'habit_id': habitId,
          'habit_name': habitName,
          'streak_days': streakDays,
          'milestone_type': milestoneType,
          'achieved_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged streak milestone: $habitName ($streakDays days)');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log streak milestone: $e');
    }
  }

  /// Log when user uses a habit template
  Future<void> logHabitTemplateUsed({
    required String templateName,
    required String category,
    required String habitType,
    bool customized = false,
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_template_used',
        eventData: {
          'template_name': templateName,
          'category': category,
          'habit_type': habitType,
          'customized': customized,
          'used_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged habit template used: $templateName');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log habit template used: $e');
    }
  }

  /// Log when user requests AI habit suggestions
  Future<void> logHabitAISuggestionsRequested({
    int? suggestionsCount,
    List<String>? suggestedHabits,
    int? generationTimeMs,
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_ai_suggestions_requested',
        eventData: {
          'suggestions_count': suggestionsCount,
          'suggested_habits': suggestedHabits ?? [],
          'generation_time_ms': generationTimeMs,
          'requested_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged AI habit suggestions requested');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log AI suggestions requested: $e');
    }
  }

  /// Log when user accepts an AI-suggested habit
  Future<void> logHabitAISuggestionAccepted({
    required String habitName,
    required String category,
    required String habitType,
    String? suggestionReason,
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_ai_suggestion_accepted',
        eventData: {
          'habit_name': habitName,
          'category': category,
          'habit_type': habitType,
          'suggestion_reason': suggestionReason,
          'accepted_at': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged AI habit suggestion accepted: $habitName');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log AI suggestion accepted: $e');
    }
  }

  /// Log daily habit summary (for analytics)
  Future<void> logHabitDailySummary({
    required int totalHabits,
    required int completedHabits,
    required double completionRate,
    int? positiveHabitsCompleted,
    int? negativeHabitsAvoided,
    int? longestActiveStreak,
    List<String>? categoriesCompleted,
  }) async {
    try {
      await _logEvent(
        eventType: 'habit_daily_summary',
        eventData: {
          'total_habits': totalHabits,
          'completed_habits': completedHabits,
          'completion_rate': completionRate,
          'positive_habits_completed': positiveHabitsCompleted,
          'negative_habits_avoided': negativeHabitsAvoided,
          'longest_active_streak': longestActiveStreak,
          'categories_completed': categoriesCompleted ?? [],
          'summary_date': DateTime.now().toIso8601String(),
        },
        context: {
          'time_of_day': _getTimeOfDay(),
          'day_of_week': _getDayOfWeek(),
        },
      );
      debugPrint('✅ [ContextLog] Logged habit daily summary: $completedHabits/$totalHabits');
    } catch (e) {
      debugPrint('⚠️ [ContextLog] Failed to log daily summary: $e');
    }
  }

  // ============================================
  // Private Methods
  // ============================================

  /// Core logging method that sends events to the backend
  Future<void> _logEvent({
    required String eventType,
    required Map<String, dynamic> eventData,
    Map<String, dynamic>? context,
  }) async {
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        debugPrint('⚠️ [ContextLog] No user ID, skipping log');
        return;
      }

      await _apiClient.post(
        '/analytics/context-log',
        data: {
          'user_id': userId,
          'event_type': eventType,
          'event_data': eventData,
          'context': {
            ...?context,
            'platform': defaultTargetPlatform.name,
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );
    } catch (e) {
      // Silently fail - logging should not break the app
      debugPrint('⚠️ [ContextLog] Failed to log event $eventType: $e');
    }
  }

  /// Get time of day category
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  /// Get day of week
  String _getDayOfWeek() {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[DateTime.now().weekday - 1];
  }
}

// ============================================
// Provider
// ============================================

/// Context logging service provider
final contextLoggingServiceProvider = Provider<ContextLoggingService>((ref) {
  return ContextLoggingService(ref.watch(apiClientProvider));
});
