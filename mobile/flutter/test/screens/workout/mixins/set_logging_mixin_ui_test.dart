/// Coverage for `applyProgressionTargets`
/// (lib/screens/workout/mixins/set_logging_mixin_ui.dart) — this file had
/// zero test coverage before E2E #131, which is how two wrong "fixes"
/// shipped in a row (see the history in that method's comments).
///
/// E2E finding #131: 'Easy and Advanced modes prescribe different weights
/// and reps for the same set.' Observed: the same exercise in the same
/// session showed 22 lb flat in Easy mode and ramped to ~50 lb in Advanced.
///
/// Root cause: before anything is logged, `applyProgressionTargets` called
/// `pattern.deriveWorkingWeight(enteredWeight: ..., completedSetIndex: 0)`
/// (the default, since the call site never passed one). That tells the
/// pyramid math "set 0 was just completed at this weight" and extrapolates
/// a peak *above* it — but `enteredWeight` at that point is really just the
/// flat AI-prescribed number (see `initControllersForExercise` in
/// set_logging_mixin.dart, which passes `exercise.weight` straight through
/// as `overrideWeight`), the exact same number Easy mode renders flat for
/// every set of the exercise (see `seedEasyExerciseStates` in
/// easy_persistence_helpers.dart, which seeds `EasyExerciseState
/// .displayWeight` from `firstTarget?.targetWeightKg ?? ex.weight` — a
/// single scalar for the whole exercise, not a per-set value). Two tiers,
/// one prescription, two different answers.
///
/// The fix: when nothing has been logged yet, `applyProgressionTargets`
/// treats `enteredWeight` as the working/peak weight directly instead of
/// extrapolating a ramp above it — so Advanced's pyramid builds *up to* the
/// same number Easy shows flat, rather than ramping past it. Once a set is
/// actually completed, `updateControlsForNextSet`'s mid-workout
/// re-derivation (untouched by this fix — it always passed its own real
/// `completedSetIndex`, so it was never part of the bug) takes over and
/// legitimately extrapolates from the real completed weight + set index.
///
/// This test drives `applyProgressionTargets` directly through a minimal
/// fake host (implementing exactly `SetLoggingMixin`'s abstract surface)
/// rather than booting the full `ActiveWorkoutScreen` — that screen's
/// `initState` fans out into posthog analytics, PR history prefetch,
/// warmup loading timers, and other unrelated network/async side effects
/// that have nothing to do with this regression and only make the test
/// slower and flakier.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/models/set_progression.dart';
import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/screens/workout/mixins/set_logging_mixin.dart';
import 'package:fitwiz/screens/workout/models/workout_state.dart';
import 'package:fitwiz/screens/workout/widgets/exercise_options_sheet.dart'
    show RepProgressionType;

import '../../../helpers/fake_supabase.dart';

/// A bare-bones host widget that mixes in [SetLoggingMixin] — nothing else.
/// Every abstract member `applyProgressionTargets` doesn't touch is a
/// trivial stub; the ones it does touch (`exercises`, `completedSets`,
/// `totalSetsPerExercise`, `exerciseWorkingWeight`, `weightController`,
/// `useKg`, `ref`) are real, mutable, and readable back from the test.
class _FakeHost extends ConsumerStatefulWidget {
  const _FakeHost();

  @override
  ConsumerState<_FakeHost> createState() => _FakeHostState();
}

class _FakeHostState extends ConsumerState<_FakeHost>
    with SetLoggingMixin<_FakeHost> {
  @override
  List<WorkoutExercise> exercises = [];
  @override
  int currentExerciseIndex = 0;
  @override
  int viewingExerciseIndex = 0;
  @override
  final Map<int, List<SetLog>> completedSets = {};
  @override
  final Map<int, int> totalSetsPerExercise = {};
  @override
  final Map<int, List<Map<String, dynamic>>> previousSets = {};
  @override
  final Map<int, RepProgressionType> repProgressionPerExercise = {};
  @override
  final Map<int, SetProgressionPattern> exerciseProgressionPattern = {};
  @override
  final Map<int, double> exerciseWorkingWeight = {};
  @override
  final Map<int, String> exerciseBarType = {};
  @override
  final Map<String, double> exerciseMaxWeights = {};

  @override
  final TextEditingController repsController = TextEditingController();
  @override
  final TextEditingController repsRightController = TextEditingController();
  @override
  final TextEditingController weightController = TextEditingController();
  @override
  bool useKg = true;
  @override
  bool unitInitialized = true;
  @override
  double weightIncrement = 2.5;

  @override
  dynamic get workoutWidget => null;

  @override
  SetLog? pendingSetLog;
  @override
  int? lastSetRpe;
  @override
  int? lastSetRir;
  @override
  bool isLeftRightMode = false;
  @override
  bool isDoneButtonPressed = false;
  @override
  int? justCompletedSetIndex;
  @override
  DateTime? currentSetStartTime;
  @override
  final Map<int, List<int>> actualRestDurations = {};

  @override
  String? progressiveWorkoutLogId;

  // ── Cross-mixin hooks `applyProgressionTargets` never calls — no-ops ──
  @override
  void checkForPRs(SetLog setLog, WorkoutExercise exercise) {}
  @override
  void moveToNextExercise() {}
  @override
  void startRest(bool betweenExercises, {Duration? overrideDuration}) {}
  @override
  Future<void> fetchAIWeightSuggestion(SetLog setLog) async {}
  @override
  Future<void> fetchRestSuggestion() async {}
  @override
  Future<void> checkFatigue({double? justLoggedWeightKg}) async {}
  @override
  void autoAdjustWeightIfNeeded(SetLog setLog, WorkoutExercise exercise) {}
  @override
  void markSupersetExerciseDoneInRound(int exerciseIndex, int groupId) {}
  @override
  int? getNextSupersetExerciseIndex(int currentIndex, int groupId) => null;
  @override
  void resetSupersetRound(int groupId) {}
  @override
  void advanceToSupersetExercise(int nextIndex) {}
  @override
  void saveWeightUnitPreference(String unit) {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// A single exercise with NO `set_targets` supplied — this forces
/// `applyProgressionTargets` to derive per-set targets from `exercise
/// .weight` from scratch, exactly the code path E2E #131 broke. `weightKg`
/// is a clean multiple of the dumbbell increment (2.5 kg) so increment
/// snapping never perturbs the assertions.
WorkoutExercise _exerciseWithFlatPrescription(double weightKg) {
  return WorkoutExercise.fromJson({
    'id': 'exercise-0',
    'exercise_id': 'ex-0',
    'name': 'Dumbbell Curl',
    'sets': 5,
    'reps': 10,
    'rest_seconds': 60,
    'weight': weightKg,
    'muscle_group': 'arms',
    'primary_muscle': 'biceps',
    'equipment': 'Dumbbell',
    'instructions': 'Curl the weight up.',
    // Deliberately no 'set_targets' — nothing has been prescribed per-set
    // yet, matching a brand-new AI-generated workout.
  });
}

void main() {
  setUp(initFakeSupabase);

  group('applyProgressionTargets — E2E #131 (Easy/Advanced weight parity)', () {
    testWidgets(
      'Advanced peak weight matches the flat AI prescription when nothing '
      'has been logged yet (does not extrapolate past it)',
      (tester) async {
        const prescribedKg = 22.5; // clean multiple of the 2.5 kg increment

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: _FakeHost())),
        );
        final state =
            tester.state(find.byType(_FakeHost)) as _FakeHostState;

        state.exercises = [_exerciseWithFlatPrescription(prescribedKg)];
        state.totalSetsPerExercise[0] = 5;

        SetLoggingMixinUI(state)
            .applyProgressionTargets(0, SetProgressionPattern.pyramidUp);

        // exerciseWorkingWeight[0] is the derived pyramid peak (the final,
        // heaviest set). Before this fix it extrapolated to
        // 22.5 + 4×2.5 = 32.5 kg — well past the AI's own number. After the
        // fix it must equal the prescription itself, matching exactly what
        // Easy mode renders flat for every set of this exercise.
        final workingWeight = state.exerciseWorkingWeight[0];
        expect(workingWeight, isNotNull);
        expect(
          workingWeight,
          closeTo(prescribedKg, 0.001),
          reason: "Advanced's peak weight must equal the flat AI "
              'prescription (what Easy mode renders) until a real set has '
              'been logged — not an extrapolated ramp above it.',
        );

        // Sanity: the pre-fix bug would have produced this value instead.
        // Pin against it explicitly so a regression re-introducing the
        // extrapolation is caught even if the equality check above is
        // ever loosened.
        const oldBuggyPeak = prescribedKg + 4 * 2.5; // 32.5
        expect(workingWeight, isNot(closeTo(oldBuggyPeak, 0.001)));

        // The generated set targets should still be a genuine pyramid
        // (ramping *up to* the prescription, not flat) — confirming we
        // didn't accidentally flatten Advanced's pattern to match Easy,
        // only fixed where its peak anchors.
        final setTargets = state.exercises[0].setTargets!;
        expect(setTargets, hasLength(5));
        final firstWeightKg = setTargets.first.targetWeightKg!;
        final lastWeightKg = setTargets.last.targetWeightKg!;
        expect(lastWeightKg, closeTo(prescribedKg, 0.001));
        expect(firstWeightKg, lessThan(lastWeightKg));
      },
    );

    testWidgets(
      'mid-workout re-derivation (completedSetIndex from a real completed '
      'set) still ramps above the completed weight — untouched by the fix',
      (tester) async {
        // Direct pin on the pattern math itself (unchanged by this fix):
        // completing set 0 of a 5-set pyramid at 22.5 kg legitimately
        // implies a peak above it, unlike the "nothing logged yet" case.
        final peak = SetProgressionPattern.pyramidUp.deriveWorkingWeight(
          enteredWeight: 22.5,
          totalSets: 5,
          increment: 2.5,
          completedSetIndex: 0,
        );
        expect(peak, closeTo(32.5, 0.001)); // 22.5 + 4×2.5
      },
    );
  });
}
