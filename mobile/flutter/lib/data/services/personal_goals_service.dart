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

  // ============================================================
  // GOAL SUGGESTIONS
  // ============================================================

  /// Get AI-generated goal suggestions organized by category
  Future<GoalSuggestionsResponse> getGoalSuggestions({
    required String userId,
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Getting suggestions for user: $userId');

      final response = await _apiClient.get(
        '/personal-goals/goals/suggestions',
        queryParameters: {
          'user_id': userId,
          'force_refresh': forceRefresh.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [PersonalGoals] Got ${data['total_suggestions']} suggestions');
        return GoalSuggestionsResponse.fromJson(data);
      } else {
        throw Exception('Failed to get suggestions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error getting suggestions: $e');
      rethrow;
    }
  }

  /// Dismiss a suggestion
  Future<void> dismissSuggestion({
    required String userId,
    required String suggestionId,
    String? reason,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Dismissing suggestion: $suggestionId');

      final response = await _apiClient.post(
        '/personal-goals/goals/suggestions/$suggestionId/dismiss',
        queryParameters: {'user_id': userId},
        data: reason != null ? {'reason': reason} : null,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [PersonalGoals] Suggestion dismissed');
      } else {
        throw Exception('Failed to dismiss suggestion: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error dismissing suggestion: $e');
      rethrow;
    }
  }

  /// Accept a suggestion and create a goal from it
  Future<Map<String, dynamic>> acceptSuggestion({
    required String userId,
    required String suggestionId,
    int? targetOverride,
    GoalVisibility visibility = GoalVisibility.friends,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Accepting suggestion: $suggestionId');

      final response = await _apiClient.post(
        '/personal-goals/goals/suggestions/$suggestionId/accept',
        queryParameters: {'user_id': userId},
        data: {
          if (targetOverride != null) 'target_override': targetOverride,
          'visibility': visibility.value,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [PersonalGoals] Suggestion accepted, goal created');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to accept suggestion: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error accepting suggestion: $e');
      rethrow;
    }
  }

  /// Get a quick summary of available suggestions
  Future<GoalSuggestionsSummary> getSuggestionsSummary({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/personal-goals/goals/suggestions/summary',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return GoalSuggestionsSummary.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to get suggestions summary: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error getting suggestions summary: $e');
      rethrow;
    }
  }

  // ============================================================
  // WORKOUT SYNC - Auto-update goals from completed workouts
  // ============================================================

  /// Sync workout data with personal goals
  ///
  /// After completing a workout, this syncs the exercise reps
  /// with any matching weekly_volume goals.
  Future<WorkoutSyncResult> syncWorkoutWithGoals({
    required String userId,
    String? workoutLogId,
    required List<ExercisePerformanceData> exercises,
  }) async {
    try {
      debugPrint('🎯 [PersonalGoals] Syncing workout with goals: ${exercises.length} exercises');

      final response = await _apiClient.post(
        '/personal-goals/workout-sync',
        queryParameters: {'user_id': userId},
        data: {
          if (workoutLogId != null) 'workout_log_id': workoutLogId,
          'exercises': exercises.map((e) => e.toJson()).toList(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [PersonalGoals] Synced ${data['total_goals_updated']} goals');
        return WorkoutSyncResult.fromJson(data);
      } else {
        throw Exception('Failed to sync workout: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PersonalGoals] Error syncing workout: $e');
      rethrow;
    }
  }
}

// ============================================================
// WORKOUT SYNC MODELS
// ============================================================

/// Exercise performance data for workout sync
class ExercisePerformanceData {
  final String exerciseName;
  final int totalReps;
  final int totalSets;
  final int maxRepsInSet;

  ExercisePerformanceData({
    required this.exerciseName,
    this.totalReps = 0,
    this.totalSets = 0,
    this.maxRepsInSet = 0,
  });

  Map<String, dynamic> toJson() => {
    'exercise_name': exerciseName,
    'total_reps': totalReps,
    'total_sets': totalSets,
    'max_reps_in_set': maxRepsInSet,
  };
}

/// Result of syncing workout with goals
class WorkoutSyncResult {
  final List<SyncedGoalUpdate> syncedGoals;
  final int totalGoalsUpdated;
  final int totalVolumeAdded;
  final int newPrs;
  final String message;

  WorkoutSyncResult({
    this.syncedGoals = const [],
    this.totalGoalsUpdated = 0,
    this.totalVolumeAdded = 0,
    this.newPrs = 0,
    this.message = '',
  });

  factory WorkoutSyncResult.fromJson(Map<String, dynamic> json) {
    return WorkoutSyncResult(
      syncedGoals: (json['synced_goals'] as List<dynamic>?)
          ?.map((e) => SyncedGoalUpdate.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      totalGoalsUpdated: json['total_goals_updated'] as int? ?? 0,
      totalVolumeAdded: json['total_volume_added'] as int? ?? 0,
      newPrs: json['new_prs'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }

  bool get hasUpdates => totalGoalsUpdated > 0;
  bool get hasNewPrs => newPrs > 0;
}

/// Individual goal update from workout sync
class SyncedGoalUpdate {
  final String goalId;
  final String exerciseName;
  final PersonalGoalType goalType;
  final int volumeAdded;
  final int newCurrentValue;
  final int targetValue;
  final bool isNowCompleted;
  final bool isNewPr;
  final double progressPercentage;

  SyncedGoalUpdate({
    required this.goalId,
    required this.exerciseName,
    required this.goalType,
    this.volumeAdded = 0,
    required this.newCurrentValue,
    required this.targetValue,
    this.isNowCompleted = false,
    this.isNewPr = false,
    this.progressPercentage = 0.0,
  });

  factory SyncedGoalUpdate.fromJson(Map<String, dynamic> json) {
    return SyncedGoalUpdate(
      goalId: json['goal_id'] as String,
      exerciseName: json['exercise_name'] as String,
      goalType: PersonalGoalType.fromString(json['goal_type'] as String),
      volumeAdded: json['volume_added'] as int? ?? 0,
      newCurrentValue: json['new_current_value'] as int,
      targetValue: json['target_value'] as int,
      isNowCompleted: json['is_now_completed'] as bool? ?? false,
      isNewPr: json['is_new_pr'] as bool? ?? false,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ============================================================
// GOAL SUGGESTION MODELS
// ============================================================

/// Suggestion type enum
enum SuggestionType {
  performanceBased('performance_based'),
  scheduleBased('schedule_based'),
  popularWithFriends('popular_with_friends'),
  newChallenge('new_challenge');

  final String value;
  const SuggestionType(this.value);

  static SuggestionType fromString(String value) {
    return SuggestionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SuggestionType.performanceBased,
    );
  }
}

/// Suggestion category enum
enum SuggestionCategory {
  beatYourRecords('beat_your_records'),
  popularWithFriends('popular_with_friends'),
  newChallenges('new_challenges');

  final String value;
  const SuggestionCategory(this.value);

  static SuggestionCategory fromString(String value) {
    return SuggestionCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SuggestionCategory.newChallenges,
    );
  }
}

/// Goal visibility enum
enum GoalVisibility {
  private('private'),
  friends('friends'),
  public('public');

  final String value;
  const GoalVisibility(this.value);

  static GoalVisibility fromString(String value) {
    return GoalVisibility.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GoalVisibility.friends,
    );
  }
}

/// Friend preview for suggestions
class FriendPreview {
  final String userId;
  final String name;
  final String? avatarUrl;

  FriendPreview({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  factory FriendPreview.fromJson(Map<String, dynamic> json) {
    return FriendPreview(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// Individual goal suggestion
class GoalSuggestionItem {
  final String id;
  final String exerciseName;
  final PersonalGoalType goalType;
  final int suggestedTarget;
  final String reasoning;
  final SuggestionType suggestionType;
  final SuggestionCategory category;
  final double confidenceScore;
  final Map<String, dynamic>? sourceData;
  final List<FriendPreview> friendsOnGoal;
  final int friendsCount;
  final DateTime createdAt;
  final DateTime expiresAt;

  GoalSuggestionItem({
    required this.id,
    required this.exerciseName,
    required this.goalType,
    required this.suggestedTarget,
    required this.reasoning,
    required this.suggestionType,
    required this.category,
    required this.confidenceScore,
    this.sourceData,
    this.friendsOnGoal = const [],
    this.friendsCount = 0,
    required this.createdAt,
    required this.expiresAt,
  });

  factory GoalSuggestionItem.fromJson(Map<String, dynamic> json) {
    return GoalSuggestionItem(
      id: json['id'] as String,
      exerciseName: json['exercise_name'] as String,
      goalType: PersonalGoalType.fromString(json['goal_type'] as String),
      suggestedTarget: json['suggested_target'] as int,
      reasoning: json['reasoning'] as String,
      suggestionType: SuggestionType.fromString(json['suggestion_type'] as String),
      category: SuggestionCategory.fromString(json['category'] as String),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      sourceData: json['source_data'] as Map<String, dynamic>?,
      friendsOnGoal: (json['friends_on_goal'] as List<dynamic>?)
              ?.map((e) => FriendPreview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      friendsCount: json['friends_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// Category group of suggestions
class SuggestionCategoryGroup {
  final String categoryId;
  final String categoryTitle;
  final String categoryIcon;
  final String accentColor;
  final List<GoalSuggestionItem> suggestions;

  SuggestionCategoryGroup({
    required this.categoryId,
    required this.categoryTitle,
    required this.categoryIcon,
    required this.accentColor,
    required this.suggestions,
  });

  factory SuggestionCategoryGroup.fromJson(Map<String, dynamic> json) {
    return SuggestionCategoryGroup(
      categoryId: json['category_id'] as String,
      categoryTitle: json['category_title'] as String,
      categoryIcon: json['category_icon'] as String,
      accentColor: json['accent_color'] as String,
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => GoalSuggestionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Response containing all suggestions
class GoalSuggestionsResponse {
  final List<SuggestionCategoryGroup> categories;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final int totalSuggestions;

  GoalSuggestionsResponse({
    required this.categories,
    required this.generatedAt,
    required this.expiresAt,
    required this.totalSuggestions,
  });

  factory GoalSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return GoalSuggestionsResponse(
      categories: (json['categories'] as List<dynamic>)
          .map((e) => SuggestionCategoryGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      totalSuggestions: json['total_suggestions'] as int,
    );
  }

  bool get isEmpty => totalSuggestions == 0;
  bool get hasRecordsSuggestions =>
      categories.any((c) => c.categoryId == 'beat_your_records' && c.suggestions.isNotEmpty);
  bool get hasFriendsSuggestions =>
      categories.any((c) => c.categoryId == 'popular_with_friends' && c.suggestions.isNotEmpty);
}

/// Summary of suggestions
class GoalSuggestionsSummary {
  final int totalSuggestions;
  final int categoriesWithSuggestions;
  final bool hasFriendSuggestions;
  final DateTime? suggestionsExpireAt;

  GoalSuggestionsSummary({
    required this.totalSuggestions,
    required this.categoriesWithSuggestions,
    required this.hasFriendSuggestions,
    this.suggestionsExpireAt,
  });

  factory GoalSuggestionsSummary.fromJson(Map<String, dynamic> json) {
    return GoalSuggestionsSummary(
      totalSuggestions: json['total_suggestions'] as int,
      categoriesWithSuggestions: json['categories_with_suggestions'] as int,
      hasFriendSuggestions: json['has_friend_suggestions'] as bool,
      suggestionsExpireAt: json['suggestions_expire_at'] != null
          ? DateTime.parse(json['suggestions_expire_at'] as String)
          : null,
    );
  }
}
