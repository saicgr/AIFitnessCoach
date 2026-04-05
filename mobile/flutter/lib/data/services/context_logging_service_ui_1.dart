part of 'context_logging_service.dart';

/// Methods extracted from ContextLoggingService
extension _ContextLoggingServiceExt1 on ContextLoggingService {

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

}
