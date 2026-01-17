/// Exercise Info Service
///
/// Generates AI-powered exercise information, form cues, and tips.
/// Uses caching to minimize API calls.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';

/// Provider for ExerciseInfoService
final exerciseInfoServiceProvider = Provider<ExerciseInfoService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExerciseInfoService(apiClient);
});

/// AI-generated exercise insights
class ExerciseInsights {
  final String? formCues;
  final String? commonMistakes;
  final String? proTip;
  final List<String>? musclesFocused;

  const ExerciseInsights({
    this.formCues,
    this.commonMistakes,
    this.proTip,
    this.musclesFocused,
  });

  bool get isEmpty =>
      formCues == null &&
      commonMistakes == null &&
      proTip == null &&
      (musclesFocused == null || musclesFocused!.isEmpty);
}

/// Service for generating AI-powered exercise information
class ExerciseInfoService {
  final ApiClient _apiClient;

  /// Cache: exerciseName -> insights
  final Map<String, ExerciseInsights> _insightsCache = {};

  ExerciseInfoService(this._apiClient);

  /// Get AI insights for an exercise
  Future<ExerciseInsights?> getExerciseInsights({
    required String exerciseName,
    String? primaryMuscle,
    String? equipment,
    String? difficulty,
  }) async {
    // Check cache
    final cached = _insightsCache[exerciseName.toLowerCase()];
    if (cached != null) {
      debugPrint('💡 [ExerciseInfo] Using cached insights for $exerciseName');
      return cached;
    }

    // Fetch from API
    try {
      debugPrint('💡 [ExerciseInfo] Fetching insights for $exerciseName');

      final response = await _apiClient.post(
        '/ai/exercise-insights',
        data: {
          'exercise_name': exerciseName,
          if (primaryMuscle != null) 'primary_muscle': primaryMuscle,
          if (equipment != null) 'equipment': equipment,
          if (difficulty != null) 'difficulty': difficulty,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final insights = ExerciseInsights(
          formCues: data['form_cues'] as String?,
          commonMistakes: data['common_mistakes'] as String?,
          proTip: data['pro_tip'] as String?,
          musclesFocused: (data['muscles_focused'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
        );

        // Cache it
        _insightsCache[exerciseName.toLowerCase()] = insights;
        debugPrint('✅ [ExerciseInfo] Got insights for $exerciseName');
        return insights;
      }

      debugPrint('⚠️ [ExerciseInfo] No insights in response, using fallback');
      return _getLocalInsights(exerciseName, primaryMuscle, equipment);
    } catch (e) {
      debugPrint('❌ [ExerciseInfo] Error fetching insights: $e');
      return _getLocalInsights(exerciseName, primaryMuscle, equipment);
    }
  }

  /// Generate local insights when API is unavailable
  ExerciseInsights _getLocalInsights(
    String exerciseName,
    String? primaryMuscle,
    String? equipment,
  ) {
    final nameLower = exerciseName.toLowerCase();

    // Exercise-specific insights
    if (nameLower.contains('squat')) {
      return const ExerciseInsights(
        formCues: 'Keep chest up, knees tracking over toes, drive through heels.',
        commonMistakes: 'Letting knees cave inward, rounding the lower back.',
        proTip: 'Brace your core before descending - think about pushing your abs out against a belt.',
      );
    } else if (nameLower.contains('deadlift')) {
      return const ExerciseInsights(
        formCues: 'Engage lats, keep bar close to body, hinge at hips.',
        commonMistakes: 'Rounding the back, starting with hips too high or low.',
        proTip: 'Think about pushing the floor away rather than pulling the bar up.',
      );
    } else if (nameLower.contains('bench') && nameLower.contains('press')) {
      return const ExerciseInsights(
        formCues: 'Retract shoulder blades, arch upper back, feet firmly planted.',
        commonMistakes: 'Flaring elbows too wide, bouncing bar off chest.',
        proTip: 'Drive your feet into the ground and squeeze your glutes for more power.',
      );
    } else if (nameLower.contains('row')) {
      return const ExerciseInsights(
        formCues: 'Lead with your elbow, squeeze shoulder blades together at top.',
        commonMistakes: 'Using momentum, not fully extending at the bottom.',
        proTip: 'Pause at the top for a count to maximize back engagement.',
      );
    } else if (nameLower.contains('pull') && (nameLower.contains('up') || nameLower.contains('down'))) {
      return const ExerciseInsights(
        formCues: 'Initiate with lats, pull elbows down and back.',
        commonMistakes: 'Using too much arm, swinging for momentum.',
        proTip: 'Imagine pulling your elbows into your back pockets.',
      );
    } else if (nameLower.contains('curl')) {
      return const ExerciseInsights(
        formCues: 'Keep elbows pinned to sides, control the negative.',
        commonMistakes: 'Swinging the weight, using shoulder momentum.',
        proTip: 'Squeeze at the top and take 3 seconds on the way down.',
      );
    } else if (nameLower.contains('press') && (nameLower.contains('shoulder') || nameLower.contains('overhead'))) {
      return const ExerciseInsights(
        formCues: 'Brace core, press straight up, keep head neutral.',
        commonMistakes: 'Leaning back excessively, flaring ribs.',
        proTip: 'Think about pushing yourself away from the bar at the top.',
      );
    } else if (nameLower.contains('lunge')) {
      return const ExerciseInsights(
        formCues: 'Keep torso upright, step with control, knee over ankle.',
        commonMistakes: 'Knee going past toes, losing balance.',
        proTip: 'Focus on pushing up through your front heel.',
      );
    }

    // Generic insights
    return const ExerciseInsights(
      formCues: 'Maintain control throughout the movement. Focus on muscle contraction.',
      commonMistakes: 'Using momentum instead of controlled movement.',
      proTip: 'Quality reps beat quantity - slow down and feel the muscle working.',
    );
  }

  /// Clear the cache
  void clearCache() {
    _insightsCache.clear();
  }
}
