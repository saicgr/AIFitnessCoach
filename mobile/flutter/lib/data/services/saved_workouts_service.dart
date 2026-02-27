import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Badge types for popular workouts
enum WorkoutBadgeType {
  trending('trending'),
  hallOfFame('hall_of_fame'),
  mostCopied('most_copied'),
  beastMode('beast_mode');

  final String value;
  const WorkoutBadgeType(this.value);
}

/// Status for scheduled workouts
enum ScheduledWorkoutStatus {
  scheduled('scheduled'),
  completed('completed'),
  skipped('skipped'),
  rescheduled('rescheduled');

  final String value;
  const ScheduledWorkoutStatus(this.value);
}

/// Service for saving, scheduling, and doing workouts from social feed
class SavedWorkoutsService {
  final ApiClient _apiClient;

  SavedWorkoutsService(this._apiClient);

  // ============================================================
  // SAVE WORKOUTS FROM SOCIAL FEED
  // ============================================================

  /// Save a workout from a friend's activity post to user's library
  Future<Map<String, dynamic>> saveWorkoutFromActivity({
    required String userId,
    required String activityId,
    String? folder,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/saved-workouts/save-from-activity',
        queryParameters: {'user_id': userId},
        data: {
          'activity_id': activityId,
          if (folder != null) 'folder': folder,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Saved Workouts] Workout saved to library');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to save workout: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error saving workout: $e');
      rethrow;
    }
  }

  /// Get all saved workouts for user
  Future<List<Map<String, dynamic>>> getSavedWorkouts({
    required String userId,
    String? folder,
  }) async {
    try {
      final queryParams = {
        if (folder != null) 'folder': folder,
      };

      final response = await _apiClient.get(
        '/social/saved-workouts/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get saved workouts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error getting saved workouts: $e');
      rethrow;
    }
  }

  /// Delete a saved workout
  Future<void> deleteSavedWorkout({
    required String userId,
    required String savedWorkoutId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/social/saved-workouts/$savedWorkoutId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Saved Workouts] Workout deleted from library');
      } else {
        throw Exception('Failed to delete workout: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error deleting workout: $e');
      rethrow;
    }
  }

  // ============================================================
  // SCHEDULE WORKOUTS
  // ============================================================

  /// Schedule a workout for a future date
  Future<Map<String, dynamic>> scheduleWorkout({
    required String userId,
    String? savedWorkoutId,
    String? workoutId,
    required DateTime scheduledDate,
    DateTime? scheduledTime,
    String? notes,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 60,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/saved-workouts/schedule',
        queryParameters: {'user_id': userId},
        data: {
          if (savedWorkoutId != null) 'saved_workout_id': savedWorkoutId,
          if (workoutId != null) 'workout_id': workoutId,
          'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
          if (scheduledTime != null)
            'scheduled_time': '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00',
          if (notes != null) 'notes': notes,
          'reminder_enabled': reminderEnabled,
          'reminder_minutes_before': reminderMinutesBefore,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Saved Workouts] Workout scheduled for ${scheduledDate.toIso8601String().split('T')[0]}');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to schedule workout: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error scheduling workout: $e');
      rethrow;
    }
  }

  /// Get scheduled workouts for user
  Future<List<Map<String, dynamic>>> getScheduledWorkouts({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    ScheduledWorkoutStatus? status,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
        if (status != null) 'status': status.value,
      };

      final response = await _apiClient.get(
        '/social/saved-workouts/scheduled/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get scheduled workouts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error getting scheduled workouts: $e');
      rethrow;
    }
  }

  /// Check for existing scheduled workouts on a specific date
  Future<List<Map<String, dynamic>>> getScheduledForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _apiClient.get(
        '/social/saved-workouts/scheduled/by-date',
        queryParameters: {'user_id': userId, 'date': dateStr},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ [Saved Workouts] Error checking schedule conflicts: $e');
      return [];
    }
  }

  /// Update scheduled workout status
  Future<void> updateScheduledWorkoutStatus({
    required String userId,
    required String scheduledWorkoutId,
    required ScheduledWorkoutStatus status,
  }) async {
    try {
      final response = await _apiClient.put(
        '/social/saved-workouts/scheduled/$scheduledWorkoutId',
        queryParameters: {'user_id': userId},
        data: {
          'status': status.value,
          if (status == ScheduledWorkoutStatus.completed)
            'completed_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Saved Workouts] Scheduled workout status updated to ${status.value}');
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error updating status: $e');
      rethrow;
    }
  }

  // ============================================================
  // CHALLENGE & BADGES
  // ============================================================

  /// Track when user clicks "BEAT THIS WORKOUT" button
  Future<Map<String, dynamic>> trackChallengeClick({
    required String userId,
    required String activityId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/saved-workouts/challenge/$activityId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('💪 [Saved Workouts] Challenge click tracked');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to track challenge: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error tracking challenge: $e');
      rethrow;
    }
  }

  /// Get badges for a workout (trending, hall of fame, beast mode, etc.)
  Future<Map<String, dynamic>> getWorkoutBadges({
    required String activityId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/social/saved-workouts/badges/$activityId',
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get badges: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error getting badges: $e');
      // Return empty badges on error
      return {
        'activity_id': activityId,
        'badges': [],
        'share_count': 0,
        'challenge_count': 0,
      };
    }
  }

  // ============================================================
  // DO WORKOUT NOW
  // ============================================================

  /// Start a saved workout immediately (creates active workout session)
  Future<Map<String, dynamic>> doWorkoutNow({
    required String userId,
    required String savedWorkoutId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/saved-workouts/do-now/$savedWorkoutId',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('🏋️ [Saved Workouts] Started workout session');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to start workout: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error starting workout: $e');
      rethrow;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Save and immediately start a workout from social feed (BEAT THIS flow)
  Future<Map<String, dynamic>> acceptChallenge({
    required String userId,
    required String activityId,
  }) async {
    try {
      // 1. Track challenge click
      await trackChallengeClick(userId: userId, activityId: activityId);

      // 2. Save the workout to library
      final savedWorkout = await saveWorkoutFromActivity(
        userId: userId,
        activityId: activityId,
        folder: 'Challenges',
        notes: 'Accepted challenge',
      );

      // 3. Start the workout immediately
      final workoutSession = await doWorkoutNow(
        userId: userId,
        savedWorkoutId: savedWorkout['id'],
      );

      debugPrint('🔥 [Saved Workouts] Challenge accepted and workout started!');
      return workoutSession;
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error accepting challenge: $e');
      rethrow;
    }
  }

  /// Save and schedule a workout from social feed
  Future<Map<String, dynamic>> saveAndSchedule({
    required String userId,
    required String activityId,
    required DateTime scheduledDate,
    DateTime? scheduledTime,
    String? notes,
  }) async {
    try {
      // 1. Save the workout to library
      final savedWorkout = await saveWorkoutFromActivity(
        userId: userId,
        activityId: activityId,
        folder: 'From Friends',
        notes: notes,
      );

      // 2. Schedule it
      final scheduledWorkout = await scheduleWorkout(
        userId: userId,
        savedWorkoutId: savedWorkout['id'],
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        notes: notes,
      );

      debugPrint('📅 [Saved Workouts] Workout saved and scheduled');
      return scheduledWorkout;
    } catch (e) {
      debugPrint('❌ [Saved Workouts] Error saving and scheduling: $e');
      rethrow;
    }
  }
}
