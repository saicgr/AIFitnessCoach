import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/tz.dart';
import '../models/mood.dart';
import 'api_client.dart';

part 'context_logging_service_ui_1.dart';
part 'context_logging_service_ui_2.dart';


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
          'healed_at': Tz.timestamp(),
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
          'acknowledged_at': Tz.timestamp(),
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
          'viewed_at': Tz.timestamp(),
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
          'action_at': Tz.timestamp(),
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
          'logged_at': Tz.timestamp(),
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
          'triggered_at': Tz.timestamp(),
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
          'synced_at': Tz.timestamp(),
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
          'checked_at': Tz.timestamp(),
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
          'updated_at': Tz.timestamp(),
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
          'reset_at': Tz.timestamp(),
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
          'logged_at': Tz.timestamp(),
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
          'created_at': Tz.timestamp(),
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
          'logged_at': Tz.timestamp(),
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
          'deleted_at': Tz.timestamp(),
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
          'searched_at': Tz.timestamp(),
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
          'toggled_at': Tz.timestamp(),
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
          'toggled_at': Tz.timestamp(),
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
          'uncompleted_at': Tz.timestamp(),
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
          'updated_at': Tz.timestamp(),
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
          'viewed_at': Tz.timestamp(),
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
          'achieved_at': Tz.timestamp(),
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
          'used_at': Tz.timestamp(),
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
          'requested_at': Tz.timestamp(),
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
          'accepted_at': Tz.timestamp(),
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
