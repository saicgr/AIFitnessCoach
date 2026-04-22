// Easy tier — pre-set AI insight helper.
//
// Extracted from easy_active_workout_state.dart so the state class stays
// under the 300-line budget. Pure function — takes exercise + state +
// timestamps, returns a nullable copy string. No Widget / BuildContext
// dependencies, safe to unit-test in isolation.
//
// The Easy tier uses [InsightTone.easy] for warmer, more explanatory
// phrasing than Simple/Advanced. Easy doesn't run the
// `/exercise-history/batch` prefetch that Advanced does, so history is
// empty today and the engine returns null — the banner collapses to
// zero height, preserving Easy's fixed-heights no-scroll contract.
// When Easy grows its own history fetch, plumb the sessions into the
// `history:` arg below and the banner starts emitting with no UI change.

import '../../../core/models/set_progression.dart';
import '../../../core/services/pre_set_insight_engine.dart';
import '../../../data/models/exercise.dart';
import 'easy_active_workout_state_models.dart';

String? computeEasyPreSetInsight({
  required WorkoutExercise exercise,
  required EasyExerciseState state,
  required bool useKg,
  required int workoutStartEpochMs,
}) {
  final setIndex = state.completedCount; // 0-based index of the next set
  if (setIndex < 0) return null;

  final tmin = state.targetReps > 0 ? state.targetReps : exercise.reps;
  final tmax = tmin;
  if (tmin == null || tmax == null || tmin <= 0) return null;

  final isBodyweight = (exercise.weight == null || exercise.weight == 0) &&
      (exercise.equipment == null ||
          const {'bodyweight', 'bodyweight_only', 'none', ''}
              .contains(exercise.equipment!.toLowerCase()));

  final now = DateTime.now();
  final todayIso = DateTime(now.year, now.month, now.day)
      .toIso8601String()
      .split('T')
      .first;

  final input = ExerciseInsightInput(
    exerciseId: exercise.id ?? exercise.name,
    targetMinReps: tmin,
    targetMaxReps: tmax,
    pattern: SetProgressionPattern.pyramidUp,
    isBodyweight: isBodyweight,
    useKg: useKg,
    todayIso: todayIso,
    workoutStartEpochMs: workoutStartEpochMs,
    // Easy doesn't own a batch-history prefetch yet — engine returns null
    // with an empty list. Wire real sessions here when history lands.
    history: const <SessionSummary>[],
  );

  return PreSetInsightEngine.insightForSet(
    input: input,
    setIndex: setIndex,
    tone: InsightTone.easy,
  );
}
