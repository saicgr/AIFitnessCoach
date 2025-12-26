import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Goal type enum matching backend
enum PersonalGoalType {
  singleMax('single_max'),
  weeklyVolume('weekly_volume');

  final String value;
  const PersonalGoalType(this.value);

  static PersonalGoalType fromString(String value) {
    return PersonalGoalType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PersonalGoalType.singleMax,
    );
  }
}

/// Goal status enum matching backend
enum PersonalGoalStatus {
  active('active'),
  completed('completed'),
  abandoned('abandoned');

  final String value;
  const PersonalGoalStatus(this.value);

  static PersonalGoalStatus fromString(String value) {
    return PersonalGoalStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PersonalGoalStatus.active,
    );
  }
}

/// Service for managing personal weekly goals
class PersonalGoalsService {
  final ApiClient _apiClient;

  PersonalGoalsService(this._apiClient);

  // ============================================================
  // CREATE GOAL
  // ============================================================

  /// Create a new weekly personal goal
  Future<Map<String, dynamic>> createGoal({
    required String userId,
    required String exerciseName,
    required PersonalGoalType goalType,
    required int targetValue,
    String? weekStart,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Creating goal: $exerciseName ($goalType)');

      final response = await _apiClient.post(
        '/personal-goals/goals',
        queryParameters: {'user_id': userId},
        data: {
          'exercise_name': exerciseName,
          'goal_type': goalType.value,
          'target_value': targetValue,
          if (weekStart != null) 'week_start': weekStart,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [PersonalGoals] Goal created successfully');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create goal: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error creating goal: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET CURRENT WEEK GOALS
  // ============================================================

  /// Get all goals for current week
  Future<Map<String, dynamic>> getCurrentGoals({
    required String userId,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Getting current goals for user: $userId');

      final response = await _apiClient.get(
        '/personal-goals/goals/current',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [PersonalGoals] Found ${data['current_week_goals']} goals');
        return data;
      } else {
        throw Exception('Failed to get goals: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error getting goals: $e');
      rethrow;
    }
  }

  // ============================================================
  // RECORD ATTEMPT (single_max)
  // ============================================================

  /// Record an attempt for a single_max goal
  Future<Map<String, dynamic>> recordAttempt({
    required String userId,
    required String goalId,
    required int attemptValue,
    String? attemptNotes,
    String? workoutLogId,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Recording attempt: $attemptValue reps');

      final response = await _apiClient.post(
        '/personal-goals/goals/$goalId/attempt',
        queryParameters: {'user_id': userId},
        data: {
          'attempt_value': attemptValue,
          if (attemptNotes != null) 'attempt_notes': attemptNotes,
          if (workoutLogId != null) 'workout_log_id': workoutLogId,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [PersonalGoals] Attempt recorded successfully');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to record attempt: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error recording attempt: $e');
      rethrow;
    }
  }

  // ============================================================
  // ADD VOLUME (weekly_volume)
  // ============================================================

  /// Add volume to a weekly_volume goal
  Future<Map<String, dynamic>> addVolume({
    required String userId,
    required String goalId,
    required int volumeToAdd,
    String? workoutLogId,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Adding volume: $volumeToAdd reps');

      final response = await _apiClient.post(
        '/personal-goals/goals/$goalId/volume',
        queryParameters: {'user_id': userId},
        data: {
          'volume_to_add': volumeToAdd,
          if (workoutLogId != null) 'workout_log_id': workoutLogId,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [PersonalGoals] Volume added successfully');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to add volume: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error adding volume: $e');
      rethrow;
    }
  }

  // ============================================================
  // COMPLETE GOAL
  // ============================================================

  /// Manually mark a goal as completed
  Future<Map<String, dynamic>> completeGoal({
    required String userId,
    required String goalId,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Completing goal: $goalId');

      final response = await _apiClient.post(
        '/personal-goals/goals/$goalId/complete',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [PersonalGoals] Goal completed successfully');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to complete goal: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error completing goal: $e');
      rethrow;
    }
  }

  // ============================================================
  // ABANDON GOAL
  // ============================================================

  /// Abandon a goal
  Future<Map<String, dynamic>> abandonGoal({
    required String userId,
    required String goalId,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Abandoning goal: $goalId');

      final response = await _apiClient.post(
        '/personal-goals/goals/$goalId/abandon',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [PersonalGoals] Goal abandoned');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to abandon goal: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error abandoning goal: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET GOAL HISTORY
  // ============================================================

  /// Get historical goals for an exercise/goal_type combination
  Future<Map<String, dynamic>> getGoalHistory({
    required String userId,
    required String exerciseName,
    required PersonalGoalType goalType,
    int limit = 12,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Getting history for: $exerciseName ($goalType)');

      final response = await _apiClient.get(
        '/personal-goals/goals/history',
        queryParameters: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'goal_type': goalType.value,
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error getting history: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET PERSONAL RECORDS
  // ============================================================

  /// Get all personal records for a user
  Future<Map<String, dynamic>> getPersonalRecords({
    required String userId,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Getting personal records for: $userId');

      final response = await _apiClient.get(
        '/personal-goals/records',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get records: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error getting records: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET SUMMARY
  // ============================================================

  /// Get quick summary of current week's goals
  Future<Map<String, dynamic>> getSummary({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/personal-goals/summary',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get summary: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error getting summary: $e');
      rethrow;
    }
  }
}
