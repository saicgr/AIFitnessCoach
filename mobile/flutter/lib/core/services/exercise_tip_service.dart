/// Exercise Tip Service
///
/// Generates personalized, per-exercise AI coach tips using the backend
/// Gemini endpoint. Tips reflect the user's selected coach persona
/// (tone, style, encouragement) and incorporate previous performance data.
///
/// Tips are pre-fetched in parallel at workout start so they're instant
/// when each exercise begins. In-flight deduplication prevents double API calls.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_client.dart';
import '../../screens/ai_settings/ai_settings_screen.dart';

final exerciseTipServiceProvider = Provider<ExerciseTipService>((ref) {
  return ExerciseTipService(ref.read(apiClientProvider));
});

class ExerciseTipService {
  final ApiClient _apiClient;

  /// Cache: exerciseName -> tip (one per workout session)
  final Map<String, String> _tipCache = {};

  /// In-flight requests: exerciseName -> future (prevents duplicate API calls)
  final Map<String, Future<String>> _inFlight = {};

  ExerciseTipService(this._apiClient);

  /// Fetch a personalized AI coach tip for the given exercise.
  ///
  /// Returns instantly from cache if pre-fetched.
  /// Deduplicates concurrent requests for the same exercise.
  /// Falls back to a local tip on API failure.
  Future<String> getExerciseTip({
    required String exerciseName,
    required AISettings aiSettings,
    String? bodyPart,
    String? equipment,
    int sets = 3,
    int? reps,
    double? targetWeight,
    bool useKg = false,
    String? userGoal,
    String? progressionPattern,
    List<Map<String, dynamic>>? previousSets,
    double? prWeight,
  }) {
    // 1. Instant cache hit
    final cached = _tipCache[exerciseName];
    if (cached != null) {
      return Future.value(cached);
    }

    // 2. Return existing in-flight request (dedup)
    final existing = _inFlight[exerciseName];
    if (existing != null) {
      return existing;
    }

    // 3. Start new request
    final future = _fetchTip(
      exerciseName: exerciseName,
      aiSettings: aiSettings,
      bodyPart: bodyPart,
      equipment: equipment,
      sets: sets,
      reps: reps,
      targetWeight: targetWeight,
      useKg: useKg,
      userGoal: userGoal,
      progressionPattern: progressionPattern,
      previousSets: previousSets,
      prWeight: prWeight,
    ).whenComplete(() => _inFlight.remove(exerciseName));

    _inFlight[exerciseName] = future;
    return future;
  }

  Future<String> _fetchTip({
    required String exerciseName,
    required AISettings aiSettings,
    String? bodyPart,
    String? equipment,
    int sets = 3,
    int? reps,
    double? targetWeight,
    bool useKg = false,
    String? userGoal,
    String? progressionPattern,
    List<Map<String, dynamic>>? previousSets,
    double? prWeight,
  }) async {
    final coach = aiSettings.getCurrentCoach();

    try {
      debugPrint('💡 [ExerciseTip] Fetching AI tip for $exerciseName (${coach.name})');

      // Build previous sets data
      List<Map<String, dynamic>>? prevSetsPayload;
      if (previousSets != null && previousSets.isNotEmpty) {
        prevSetsPayload = previousSets.map((s) => {
          'weight': s['weight'],
          'reps': s['reps'],
          'rpe': s['rpe'],
          'rir': s['rir'],
        }).toList();
      }

      final response = await _apiClient.post(
        '/workouts/exercise-tip',
        data: {
          'exercise_name': exerciseName,
          if (bodyPart != null) 'body_part': bodyPart,
          if (equipment != null) 'equipment': equipment,
          'sets': sets,
          if (reps != null) 'reps': reps,
          if (targetWeight != null && targetWeight > 0) 'target_weight': targetWeight,
          'use_kg': useKg,
          if (userGoal != null) 'user_goal': userGoal,
          if (progressionPattern != null) 'progression_pattern': progressionPattern,
          if (prevSetsPayload != null) 'previous_sets': prevSetsPayload,
          if (prWeight != null && prWeight > 0) 'pr_weight': prWeight,
          'coach_name': coach.name,
          'coaching_style': coach.coachingStyle,
          'communication_tone': coach.communicationTone,
          'encouragement_level': coach.encouragementLevel,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final tip = response.data['tip'] as String;
        _tipCache[exerciseName] = tip;
        debugPrint('✅ [ExerciseTip] Got AI tip for $exerciseName');
        return tip;
      }
    } catch (e) {
      debugPrint('❌ [ExerciseTip] API failed for $exerciseName: $e');
    }

    // Fallback: generate a local tip
    final fallback = _getLocalFallback(exerciseName, coach.coachingStyle);
    _tipCache[exerciseName] = fallback;
    return fallback;
  }

  /// Get cached tip for a specific exercise (returns null if not yet fetched)
  String? getCachedTip(String exerciseName) => _tipCache[exerciseName];

  String _getLocalFallback(String exerciseName, String style) {
    switch (style) {
      case 'drill-sergeant':
        return 'Lock in. Control every rep. No half reps on $exerciseName.';
      case 'zen-master':
        return 'Breathe into the movement. Feel each rep of $exerciseName with intention.';
      case 'hype-beast':
        return 'Time to GO OFF on $exerciseName! Every rep counts, let\'s get it!';
      case 'scientist':
        return 'Focus on full range of motion and controlled tempo for $exerciseName.';
      default:
        return 'You\'ve got this! Focus on strong, controlled reps for $exerciseName.';
    }
  }

  /// Clear the tip cache (call when starting a new workout)
  void clearCache() {
    _tipCache.clear();
    _inFlight.clear();
    debugPrint('💡 [ExerciseTip] Cache cleared');
  }
}
