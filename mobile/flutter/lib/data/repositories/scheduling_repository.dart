import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../services/api_client.dart';

/// Scheduling repository provider
final schedulingRepositoryProvider = Provider<SchedulingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SchedulingRepository(apiClient);
});

/// A workout that was missed (not completed by scheduled date)
class MissedWorkout {
  final String id;
  final String name;
  final String type;
  final String difficulty;
  final DateTime scheduledDate;
  final DateTime? originalScheduledDate;
  final int durationMinutes;
  final int daysMissed;
  final bool canReschedule;
  final int rescheduleCount;
  final int exercisesCount;

  MissedWorkout({
    required this.id,
    required this.name,
    required this.type,
    required this.difficulty,
    required this.scheduledDate,
    this.originalScheduledDate,
    required this.durationMinutes,
    required this.daysMissed,
    required this.canReschedule,
    this.rescheduleCount = 0,
    this.exercisesCount = 0,
  });

  factory MissedWorkout.fromJson(Map<String, dynamic> json) {
    return MissedWorkout(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      originalScheduledDate: json['original_scheduled_date'] != null
          ? DateTime.parse(json['original_scheduled_date'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int? ?? 45,
      daysMissed: json['days_missed'] as int? ?? 0,
      canReschedule: json['can_reschedule'] as bool? ?? true,
      rescheduleCount: json['reschedule_count'] as int? ?? 0,
      exercisesCount: json['exercises_count'] as int? ?? 0,
    );
  }

  /// Get a human-readable description of when this was missed
  String get missedDescription {
    if (daysMissed == 1) {
      return 'Yesterday';
    } else if (daysMissed == 2) {
      return '2 days ago';
    } else {
      return '$daysMissed days ago';
    }
  }

  /// Get the day name (e.g., "Tuesday's")
  String get dayPossessive {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = weekdays[scheduledDate.weekday - 1];
    return "$dayName's";
  }
}

/// Skip reason category
class SkipReasonCategory {
  final String id;
  final String displayName;
  final String? emoji;

  SkipReasonCategory({
    required this.id,
    required this.displayName,
    this.emoji,
  });

  factory SkipReasonCategory.fromJson(Map<String, dynamic> json) {
    return SkipReasonCategory(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      emoji: json['emoji'] as String?,
    );
  }
}

/// Scheduling suggestion from AI
class SchedulingSuggestion {
  final String suggestionType; // reschedule_today, reschedule_tomorrow, swap, skip
  final String title;
  final String description;
  final String? recommendedDate;
  final String? swapWorkoutId;
  final String? swapWorkoutName;
  final double confidenceScore;
  final String reason;

  SchedulingSuggestion({
    required this.suggestionType,
    required this.title,
    required this.description,
    this.recommendedDate,
    this.swapWorkoutId,
    this.swapWorkoutName,
    required this.confidenceScore,
    required this.reason,
  });

  factory SchedulingSuggestion.fromJson(Map<String, dynamic> json) {
    return SchedulingSuggestion(
      suggestionType: json['suggestion_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      recommendedDate: json['recommended_date'] as String?,
      swapWorkoutId: json['swap_workout_id'] as String?,
      swapWorkoutName: json['swap_workout_name'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.5,
      reason: json['reason'] as String,
    );
  }

  bool get isRescheduleToday => suggestionType == 'reschedule_today';
  bool get isSwap => suggestionType == 'swap';
  bool get isSkip => suggestionType == 'skip';
}

/// Response from reschedule operation
class RescheduleResult {
  final bool success;
  final String message;
  final String workoutId;
  final String newDate;
  final String? swappedWith;
  final String? swappedWorkoutName;

  RescheduleResult({
    required this.success,
    required this.message,
    required this.workoutId,
    required this.newDate,
    this.swappedWith,
    this.swappedWorkoutName,
  });

  factory RescheduleResult.fromJson(Map<String, dynamic> json) {
    return RescheduleResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      workoutId: json['workout_id'] as String,
      newDate: json['new_date'] as String,
      swappedWith: json['swapped_with'] as String?,
      swappedWorkoutName: json['swapped_workout_name'] as String?,
    );
  }
}

/// Scheduling repository for missed workout management
class SchedulingRepository {
  final ApiClient _apiClient;

  SchedulingRepository(this._apiClient);

  /// Get missed workouts from the past N days
  Future<List<MissedWorkout>> getMissedWorkouts({
    required String userId,
    int daysBack = 7,
    bool includeScheduled = true,
  }) async {
    try {
      debugPrint('Getting missed workouts for user: $userId');

      // Get the user's timezone offset in minutes
      final timezoneOffset = DateTime.now().timeZoneOffset.inMinutes;

      final response = await _apiClient.get(
        '${ApiConstants.scheduling}/missed',
        queryParameters: {
          'user_id': userId,
          'days_back': daysBack,
          'include_scheduled': includeScheduled,
          'timezone_offset': timezoneOffset,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final workoutsList = data['missed_workouts'] as List<dynamic>? ?? [];
        final workouts = workoutsList
            .map((json) => MissedWorkout.fromJson(json as Map<String, dynamic>))
            .toList();

        debugPrint('Found ${workouts.length} missed workouts');
        return workouts;
      }

      return [];
    } catch (e) {
      debugPrint('Error getting missed workouts: $e');
      rethrow;
    }
  }

  /// Reschedule a workout to a new date
  Future<RescheduleResult> rescheduleWorkout({
    required String workoutId,
    required String newDate,
    String? swapWithWorkoutId,
    String? reason,
  }) async {
    try {
      debugPrint('Rescheduling workout $workoutId to $newDate');

      final response = await _apiClient.post(
        '${ApiConstants.scheduling}/reschedule',
        data: {
          'workout_id': workoutId,
          'new_date': newDate,
          if (swapWithWorkoutId != null) 'swap_with_workout_id': swapWithWorkoutId,
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return RescheduleResult.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to reschedule workout');
    } catch (e) {
      debugPrint('Error rescheduling workout: $e');
      rethrow;
    }
  }

  /// Skip a workout with optional reason
  Future<bool> skipWorkout({
    required String workoutId,
    String? reasonCategory,
    String? reasonText,
  }) async {
    try {
      debugPrint('Skipping workout $workoutId');

      final response = await _apiClient.post(
        '${ApiConstants.scheduling}/skip',
        data: {
          'workout_id': workoutId,
          if (reasonCategory != null) 'reason_category': reasonCategory,
          if (reasonText != null) 'reason_text': reasonText,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['success'] as bool? ?? true;
      }

      return false;
    } catch (e) {
      debugPrint('Error skipping workout: $e');
      rethrow;
    }
  }

  /// Get AI scheduling suggestions for a missed workout
  Future<List<SchedulingSuggestion>> getSchedulingSuggestions({
    required String workoutId,
    required String userId,
  }) async {
    try {
      debugPrint('Getting scheduling suggestions for workout $workoutId');

      final response = await _apiClient.get(
        '${ApiConstants.scheduling}/suggestions',
        queryParameters: {
          'workout_id': workoutId,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final suggestionsList = data['suggestions'] as List<dynamic>? ?? [];
        return suggestionsList
            .map((json) => SchedulingSuggestion.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting scheduling suggestions: $e');
      return [];
    }
  }

  /// Get available skip reason categories
  Future<List<SkipReasonCategory>> getSkipReasons() async {
    try {
      final response = await _apiClient.get('${ApiConstants.scheduling}/skip-reasons');

      if (response.statusCode == 200) {
        final reasonsList = response.data as List<dynamic>;
        return reasonsList
            .map((json) => SkipReasonCategory.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Return defaults
      return _defaultSkipReasons;
    } catch (e) {
      debugPrint('Error getting skip reasons: $e');
      return _defaultSkipReasons;
    }
  }

  /// Trigger missed workout detection
  Future<int> detectMissedWorkouts(String userId) async {
    try {
      // Get the user's timezone offset in minutes
      final timezoneOffset = DateTime.now().timeZoneOffset.inMinutes;

      final response = await _apiClient.post(
        '${ApiConstants.scheduling}/detect-missed',
        queryParameters: {
          'user_id': userId,
          'timezone_offset': timezoneOffset,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['marked_missed'] as int? ?? 0;
      }

      return 0;
    } catch (e) {
      debugPrint('Error detecting missed workouts: $e');
      return 0;
    }
  }

  /// Default skip reasons when API fails
  static final List<SkipReasonCategory> _defaultSkipReasons = [
    SkipReasonCategory(id: 'too_busy', displayName: 'Too Busy', emoji: '📅'),
    SkipReasonCategory(id: 'feeling_unwell', displayName: 'Feeling Unwell', emoji: '🤒'),
    SkipReasonCategory(id: 'need_rest', displayName: 'Need Rest', emoji: '😴'),
    SkipReasonCategory(id: 'travel', displayName: 'Traveling', emoji: '✈️'),
    SkipReasonCategory(id: 'injury', displayName: 'Injury/Pain', emoji: '🤕'),
    SkipReasonCategory(id: 'other', displayName: 'Other', emoji: '💭'),
  ];
}
