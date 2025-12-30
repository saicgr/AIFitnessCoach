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
