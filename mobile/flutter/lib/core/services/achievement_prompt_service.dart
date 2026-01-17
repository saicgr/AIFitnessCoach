/// Achievement Prompt Service
///
/// Generates motivational prompts during rest periods based on:
/// - Personal records (PRs)
/// - Last session performance
/// - Friend comparisons (social)
/// - Weekly goals progress
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';

/// Provider for AchievementPromptService
final achievementPromptServiceProvider = Provider<AchievementPromptService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AchievementPromptService(apiClient);
});

/// Service for generating achievement/motivational prompts
class AchievementPromptService {
  final ApiClient _apiClient;

  AchievementPromptService(this._apiClient);

  /// Get an achievement prompt for the current set
  ///
  /// Returns null if there's no relevant achievement to highlight
  Future<String?> getPromptForSet({
    required String exerciseName,
    required double currentWeight,
    required int currentReps,
    required int setNumber,
    required int totalSets,
    String? userId,
  }) async {
    try {
      debugPrint('🏆 [Achievement] Checking achievements for $exerciseName');

      final response = await _apiClient.get(
        '/performance-db/exercise-achievements/${Uri.encodeComponent(exerciseName)}',
        queryParameters: {
          if (userId != null) 'user_id': userId,
          'current_weight': currentWeight.toString(),
          'current_reps': currentReps.toString(),
          'set_number': setNumber.toString(),
          'total_sets': totalSets.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Extract relevant data
        final prWeight = (data['pr_weight'] as num?)?.toDouble();
        final prReps = data['pr_reps'] as int?;
        final lastSessionWeight = (data['last_session_weight'] as num?)?.toDouble();
        final lastSessionReps = data['last_session_reps'] as int?;
        final friendBestWeight = (data['friend_best_weight'] as num?)?.toDouble();
        final friendName = data['friend_name'] as String?;
        final weeklyGoalSets = data['weekly_goal_sets'] as int?;
        final weeklyCompletedSets = data['weekly_completed_sets'] as int?;

        // Generate prompt based on achievements
        return _generatePrompt(
          currentWeight: currentWeight,
          currentReps: currentReps,
          prWeight: prWeight,
          prReps: prReps,
          lastSessionWeight: lastSessionWeight,
          lastSessionReps: lastSessionReps,
          friendBestWeight: friendBestWeight,
          friendName: friendName,
          weeklyGoalSets: weeklyGoalSets,
          weeklyCompletedSets: weeklyCompletedSets,
        );
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ [Achievement] Error checking achievements: $e');
      // Try local calculation as fallback
      return _generateLocalPrompt(
        currentWeight: currentWeight,
        currentReps: currentReps,
        setNumber: setNumber,
        totalSets: totalSets,
      );
    }
  }

  /// Generate prompt from API data
  String? _generatePrompt({
    required double currentWeight,
    required int currentReps,
    double? prWeight,
    int? prReps,
    double? lastSessionWeight,
    int? lastSessionReps,
    double? friendBestWeight,
    String? friendName,
    int? weeklyGoalSets,
    int? weeklyCompletedSets,
  }) {
    // Priority 1: Close to PR
    if (prWeight != null && prWeight > 0) {
      final diff = prWeight - currentWeight;
      if (diff <= 0) {
        return "You just matched your PR! 🎉";
      } else if (diff <= 5) {
        return "${diff.toStringAsFixed(0)} more kg to beat your PR!";
      } else if (diff <= 10) {
        return "Getting close to your ${prWeight.toStringAsFixed(0)}kg PR!";
      }
    }

    // Priority 2: Better than last session
    if (lastSessionWeight != null && lastSessionReps != null) {
      if (currentWeight > lastSessionWeight) {
        final increase = currentWeight - lastSessionWeight;
        return "${increase.toStringAsFixed(0)}kg more than last week! 🔥";
      }
      if (currentWeight == lastSessionWeight && currentReps > lastSessionReps) {
        final extraReps = currentReps - lastSessionReps;
        return "$extraReps more reps than last week! 💪";
      }
    }

    // Priority 3: Ahead of friend
    if (friendBestWeight != null && friendName != null && currentWeight > friendBestWeight) {
      return "You're ahead of $friendName on this one! 🏆";
    }

    // Priority 4: Weekly goal progress
    if (weeklyGoalSets != null && weeklyCompletedSets != null) {
      final remaining = weeklyGoalSets - weeklyCompletedSets;
      if (remaining > 0 && remaining <= 5) {
        return "$remaining sets to weekly goal!";
      } else if (remaining <= 0) {
        return "Weekly goal crushed! 🎯";
      }
    }

    // No achievement to highlight
    return null;
  }

  /// Local fallback prompt (no API data)
  String? _generateLocalPrompt({
    required double currentWeight,
    required int currentReps,
    int? setNumber,
    int? totalSets,
  }) {
    // Priority 1: Weight milestones
    if (currentWeight >= 100) {
      return "Triple digits! 💯";
    }
    if (currentWeight >= 60 && currentWeight % 20 == 0) {
      return "Nice round number - ${currentWeight.toStringAsFixed(0)}kg! 💪";
    }

    // Priority 2: Rep milestones
    if (currentReps >= 15) {
      return "Impressive endurance - $currentReps reps! 🔥";
    }
    if (currentReps >= 12) {
      return "Great volume! Keep it up!";
    }
    if (currentReps == 10) {
      return "Perfect 10 reps! ⭐";
    }

    // Priority 3: Set progress
    if (setNumber != null && totalSets != null) {
      if (setNumber == 1) {
        return "Strong start! ${totalSets - 1} more to go!";
      }
      if (setNumber == totalSets) {
        return "Final set complete! 🎯";
      }
      if (setNumber == totalSets - 1) {
        return "One more set to crush it! 💪";
      }
    }

    // Priority 4: Random encouragement (show 50% of the time)
    if (DateTime.now().second % 2 == 0) {
      final prompts = [
        "You're making progress! 📈",
        "Consistency is key! 🔑",
        "Every rep counts! 💪",
        "Keep pushing! 🚀",
      ];
      return prompts[DateTime.now().millisecond % prompts.length];
    }

    return null;
  }

  /// Pre-fetch achievement data for all exercises in a workout
  /// Call this at workout start to have data ready
  Future<Map<String, Map<String, dynamic>>> prefetchAchievements({
    required List<String> exerciseNames,
    required String userId,
  }) async {
    final results = <String, Map<String, dynamic>>{};

    try {
      final response = await _apiClient.post(
        '/performance-db/batch-achievements',
        data: {
          'user_id': userId,
          'exercise_names': exerciseNames,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            results[key] = value;
          }
        });
        debugPrint('🏆 [Achievement] Prefetched ${results.length} exercises');
      }
    } catch (e) {
      debugPrint('⚠️ [Achievement] Prefetch failed: $e');
    }

    return results;
  }
}
