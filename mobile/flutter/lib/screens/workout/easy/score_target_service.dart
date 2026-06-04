// In-workout Strength-Score target service (B6 — gamification, vs Gravl).
//
// Fetches the deterministic weight×reps target that would raise a muscle's
// strength score into its NEXT level band, so the active-workout screen can
// render a "Hit 80 lb × 8 to level up Chest" pill. Backend source:
//   GET /api/v1/scores/targets/{muscle_group}?target_reps=N
//
// All math is server-side + deterministic (no LLM). This client only converts
// the returned kg target → the user's workout-weight unit (lb default per the
// user's feedback_weight_units rule).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/api_client.dart';

/// Parsed score-target for one muscle. `null` instances are not produced —
/// callers receive `null` from [ScoreTargetService.fetch] when the muscle is
/// already at the top (elite) band, is excluded, or the request failed.
class ScoreTarget {
  /// Muscle group the target is for (lowercased, e.g. "chest").
  final String muscleGroup;

  /// Current 0-100 strength score for the muscle.
  final int currentScore;

  /// Next level label the target unlocks (e.g. "intermediate").
  final String nextLevel;

  /// Score points still needed to cross into [nextLevel].
  final int pointsToNextLevel;

  /// Target working weight to hit at [targetReps], in KG (raw from backend).
  final double targetWorkingWeightKg;

  /// Target rep count the working weight is anchored to.
  final int targetReps;

  /// Whether the muscle's underlying score data is stale (>threshold days).
  final bool isStale;

  const ScoreTarget({
    required this.muscleGroup,
    required this.currentScore,
    required this.nextLevel,
    required this.pointsToNextLevel,
    required this.targetWorkingWeightKg,
    required this.targetReps,
    required this.isStale,
  });

  /// Working weight in the user's display unit (kg or lb).
  double displayWeight({required bool useKg}) =>
      useKg ? targetWorkingWeightKg : targetWorkingWeightKg * 2.20462;

  /// e.g. "80 lb × 8" — rounded to a clean increment for the pill label.
  String displayLabel({required bool useKg}) {
    final w = displayWeight(useKg: useKg);
    // Round to the nearest 0.5 so the pill reads cleanly without implying
    // false precision; trailing ".0" is dropped.
    final rounded = (w * 2).round() / 2;
    final wStr = rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
    return '$wStr ${useKg ? 'kg' : 'lb'} × $targetReps';
  }
}

class ScoreTargetService {
  /// Fetch the score target for [muscleGroup]. Returns null on any non-target
  /// outcome (elite, excluded, error, missing data) — the pill simply hides.
  ///
  /// Accepts [WidgetRef] (the in-workout state is a `ConsumerState`).
  static Future<ScoreTarget?> fetch({
    required WidgetRef ref,
    required String muscleGroup,
    int targetReps = 8,
  }) async {
    final muscle = muscleGroup.trim().toLowerCase();
    if (muscle.isEmpty) return null;
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get<dynamic>(
        '/scores/targets/$muscle',
        queryParameters: {'target_reps': targetReps},
      );
      if (resp.statusCode != 200 || resp.data is! Map) return null;
      final map = Map<String, dynamic>.from(resp.data as Map);
      if (map['excluded'] == true) return null;
      final target = map['target'];
      if (target is! Map) return null; // null when already elite
      final t = Map<String, dynamic>.from(target);

      final weightKg = (t['target_working_weight_kg'] as num?)?.toDouble();
      final reps = (t['target_reps'] as num?)?.toInt();
      final nextLevel = (t['next_level'] as String?) ?? '';
      if (weightKg == null || weightKg <= 0 || reps == null || reps <= 0) {
        return null;
      }
      return ScoreTarget(
        muscleGroup: muscle,
        currentScore: (map['current_score'] as num?)?.toInt() ?? 0,
        nextLevel: nextLevel,
        pointsToNextLevel:
            (t['points_to_next_level'] as num?)?.toInt() ?? 0,
        targetWorkingWeightKg: weightKg,
        targetReps: reps,
        isStale: map['is_stale'] == true,
      );
    } catch (_) {
      // Score-target pill is a nicety; never surface an error in-workout.
      return null;
    }
  }
}
