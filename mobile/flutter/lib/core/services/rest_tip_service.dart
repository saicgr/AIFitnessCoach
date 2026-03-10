/// Rest Tip Service
///
/// Generates context-aware tips during rest periods between sets.
/// Uses smart caching to keep tips relevant.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for RestTipService
final restTipServiceProvider = Provider<RestTipService>((ref) {
  return RestTipService();
});

/// Service for generating tips during workout rest periods
class RestTipService {
  /// Cache: exerciseName -> (tip, lastRpe)
  /// Regenerates if RPE >= 8 (hard set) to provide more relevant advice
  final Map<String, _CachedTip> _tipCache = {};

  RestTipService();

  /// Generate a rest tip for the current exercise
  ///
  /// Uses smart caching:
  /// - Returns cached tip if available and RPE < 8
  /// - Generates new tip if first time or if user rated hard (RPE >= 8)
  Future<String?> getRestTip({
    required String exerciseName,
    required double weightKg,
    required int reps,
    required int? rpe,
    required int setsRemaining,
    String? exerciseInstructions,
    String? userId,
  }) async {
    // Check cache
    final cached = _tipCache[exerciseName];
    if (cached != null) {
      if (rpe == null || rpe < 8) {
        return cached.tip;
      }
    }

    final tip = _getLocalTip(exerciseName, weightKg, reps, rpe, setsRemaining);
    _tipCache[exerciseName] = _CachedTip(tip: tip, lastRpe: rpe);
    return tip;
  }

  /// Generate a local tip when API is unavailable
  String _getLocalTip(String exerciseName, double weightKg, int reps, int? rpe, int setsRemaining) {
    final exerciseLower = exerciseName.toLowerCase();

    // Tips based on exercise type
    if (exerciseLower.contains('squat')) {
      return "Keep your core braced and chest up on the descent.";
    } else if (exerciseLower.contains('deadlift')) {
      return "Engage your lats and keep the bar close to your body.";
    } else if (exerciseLower.contains('bench') || exerciseLower.contains('press')) {
      return "Control the eccentric and drive through your feet.";
    } else if (exerciseLower.contains('row')) {
      return "Squeeze your shoulder blades together at the top.";
    } else if (exerciseLower.contains('curl')) {
      return "Keep your elbows stationary for better bicep isolation.";
    } else if (exerciseLower.contains('pull')) {
      return "Focus on pulling with your back, not just your arms.";
    } else if (exerciseLower.contains('shoulder') || exerciseLower.contains('lateral')) {
      return "Control the movement - don't use momentum.";
    } else if (exerciseLower.contains('lunge') || exerciseLower.contains('leg')) {
      return "Keep your knee tracking over your toes.";
    }

    // Tips based on RPE
    if (rpe != null && rpe >= 8) {
      return "Great intensity! Focus on form for your remaining sets.";
    }

    // Tips based on sets remaining
    if (setsRemaining <= 1) {
      return "Last set coming up - give it everything you've got!";
    } else if (setsRemaining >= 3) {
      return "Pace yourself - you have $setsRemaining sets to go.";
    }

    // Generic tips
    final genericTips = [
      "Stay hydrated and maintain steady breathing.",
      "Focus on the mind-muscle connection.",
      "Quality reps beat quantity every time.",
      "You're doing great - keep up the good work!",
    ];
    return genericTips[DateTime.now().second % genericTips.length];
  }

  /// Clear the tip cache (e.g., when starting a new workout)
  void clearCache() {
    _tipCache.clear();
    debugPrint('💡 [RestTip] Cache cleared');
  }

  /// Clear cache for a specific exercise
  void clearCacheForExercise(String exerciseName) {
    _tipCache.remove(exerciseName);
  }
}

/// Cached tip entry
class _CachedTip {
  final String tip;
  final int? lastRpe;

  _CachedTip({required this.tip, this.lastRpe});
}
