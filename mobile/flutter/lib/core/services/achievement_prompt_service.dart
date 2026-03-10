/// Achievement Prompt Service
///
/// Generates motivational prompts during rest periods based on:
/// - Weight milestones
/// - Rep milestones
/// - Set progress
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for AchievementPromptService
final achievementPromptServiceProvider = Provider<AchievementPromptService>((ref) {
  return AchievementPromptService();
});

/// Service for generating achievement/motivational prompts
class AchievementPromptService {
  AchievementPromptService();

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
    return _generateLocalPrompt(
      currentWeight: currentWeight,
      currentReps: currentReps,
      setNumber: setNumber,
      totalSets: totalSets,
    );
  }

  /// Generate a motivational prompt based on current set data
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

}
