part of 'context_logging_service.dart';

/// Methods extracted from ContextLoggingService
extension _ContextLoggingServiceExt2 on ContextLoggingService {

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

}
