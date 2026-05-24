/// `workoutCardStateProvider` — assembles every input the pure
/// `chooseWorkoutCardMode` resolver needs into a single `WorkoutCardState`
/// snapshot. Computed; rebuilds whenever any input provider changes.
///
/// Returns a non-null `WorkoutCardState` even when sub-providers are still
/// loading — missing values use `unknown` sentinels (recovery, cycle phase,
/// equipment, etc.). This matches §1 of the home v2 plan, which requires
/// the card to render *something* on a partial load instead of blanking.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hormonal_health.dart' as hh;
import '../models/today_workout.dart';
import '../../screens/home/widgets/workout_card/workout_card_mode.dart';
import 'daily_coach_insight_provider.dart';
import 'fasting_provider.dart';
import 'hormonal_health_provider.dart';
import 'sleep_score_provider.dart';
import 'today_workout_provider.dart';
import 'user_history_snapshot_provider.dart';

/// Read-only computed snapshot consumed by `hero_workout_card.dart` and any
/// future widget that wants to share the same mode classification.
final workoutCardStateProvider = Provider.autoDispose<WorkoutCardState>((ref) {
  final today = ref.watch(todayWorkoutProvider);
  final coach = ref.watch(dailyCoachInsightProvider);
  final sleep = ref.watch(sleepScoreProvider);
  final fasting = ref.watch(fastingProvider);
  final cyclePhaseAsync = ref.watch(cyclePhaseProvider);
  final history = ref.watch(userHistorySnapshotProvider);

  final now = DateTime.now();
  final time = TimeOfDay.fromHour(now.hour);

  // Plan + workout state ----------------------------------------------------
  // Loading/error gates only when we have NO usable data at all. A late
  // history snapshot or sleep failure must not blank the whole card.
  final isLoading = today.isLoading && !today.hasValue;
  final isError = today.hasError && !today.hasValue;

  PlanState planState = PlanState.active;
  WorkoutState workoutState = WorkoutState.none;
  bool todayHighIntensity = false;

  final todayValue = today.valueOrNull;
  TodayWorkoutSummary? workoutForToday;
  if (todayValue != null) {
    if (todayValue.completedToday == true) {
      workoutState = WorkoutState.completed;
    } else if (todayValue.todayWorkout != null) {
      workoutState = WorkoutState.scheduledNotStarted;
      workoutForToday = todayValue.todayWorkout;
    } else if (todayValue.restDayMessage != null &&
        todayValue.restDayMessage!.isNotEmpty) {
      workoutState = WorkoutState.restDay;
    } else if (todayValue.nextWorkout != null) {
      // Today has nothing; carousel-style next-up exists.
      workoutState = WorkoutState.none;
    }
    if (workoutForToday != null) {
      final dur = workoutForToday.durationMinutes;
      // Heuristic: high-intensity proxy until backend ships an explicit flag.
      // 50+ minutes + 6+ exercises is the rough threshold the cycle/fuel-gap
      // modes care about ("don't lift hard mid-luteal").
      todayHighIntensity = dur >= 50 && workoutForToday.exerciseCount >= 6;
    }
  }

  final hasNext = todayValue?.nextWorkout != null;

  // Recovery bucket ---------------------------------------------------------
  // Map sleep score to coarse buckets per §1's table. Wearable HRV/RHR refine
  // this when available — keep `unknown` until the snapshot resolves.
  RecoveryBucket recovery = RecoveryBucket.unknown;
  final sleepValue = sleep.valueOrNull;
  if (sleepValue != null && sleepValue.score != null) {
    final total = sleepValue.score!.total;
    if (total >= 70) {
      recovery = RecoveryBucket.green;
    } else if (total >= 60) {
      recovery = RecoveryBucket.yellow;
    } else {
      recovery = RecoveryBucket.red;
    }
  }

  // Cycle phase -------------------------------------------------------------
  CyclePhase cyclePhase = CyclePhase.unknown;
  final phaseInfo = cyclePhaseAsync.valueOrNull;
  if (phaseInfo?.currentPhase != null) {
    switch (phaseInfo!.currentPhase!) {
      case hh.CyclePhase.menstrual:
        cyclePhase = CyclePhase.menstrual;
      case hh.CyclePhase.follicular:
        cyclePhase = CyclePhase.follicular;
      case hh.CyclePhase.ovulation:
        cyclePhase = CyclePhase.ovulation;
      case hh.CyclePhase.luteal:
        cyclePhase = CyclePhase.luteal;
    }
  }

  // Fasting -----------------------------------------------------------------
  final fastingActive = fasting.hasFast;
  final fastHoursIn = fasting.activeFast == null
      ? 0
      : (fasting.activeFast!.elapsedMinutes ~/ 60);
  // Fasted-training warnings preference isn't surfaced on FastingPreferences
  // yet (TODO §1 nutrition state) — default to false so the card never
  // overrides user intent without an explicit opt-in.
  const fastedWarnings = false;

  // History snapshot --------------------------------------------------------
  final hist = history.valueOrNull;
  final yesterdayMissed = hist?.yesterdayWorkoutScheduled == true &&
      hist?.yesterdayWorkoutCompleted == false;
  final prsLastWeek = hist?.prsLast7d ?? 0;
  VolumeTrend volumeTrend = VolumeTrend.unknown;
  switch (hist?.volumeTrend4wk) {
    case 'up':
      volumeTrend = VolumeTrend.up;
    case 'flat':
      volumeTrend = VolumeTrend.flat;
    case 'under':
      volumeTrend = VolumeTrend.under;
    default:
      volumeTrend = VolumeTrend.unknown;
  }
  final daysSinceMg = hist?.daysSincePrimaryMuscleGroup ?? 0;
  final prOpportunity = hist?.hasPrOpportunityToday ?? false;
  final priorHard = hist?.priorTwoDaysHardCount ?? 0;

  // Coach pillar — null is tolerated; resolver treats it as 'train'.
  final coachPillar = coach.valueOrNull?.leadingPillar;

  // Streak-extends signal — best-effort, leave false until the streak
  // provider exposes a per-week "this completes 5/5" flag.
  const streakExtends = false;

  return WorkoutCardState(
    isLoading: isLoading,
    isError: isError,
    planState: planState,
    workoutState: workoutState,
    time: time,
    coachPillar: coachPillar,
    recovery: recovery,
    cyclePhase: cyclePhase,
    streakExtendsIfComplete: streakExtends,
    yesterdayMissed: yesterdayMissed,
    hasNextWorkout: hasNext,
    equipmentMatch: EquipmentMatch.unknown,
    // Nutrition / hydration — defaults until the nutrition card mode work
    // wires these inputs in (§1d).
    caloriesPctOfTarget: 0,
    proteinPctOfTarget: 0,
    nextMealSlot: NextMealSlot.none,
    preWorkoutWindow: PreWorkoutWindow.recent,
    postWorkoutWindow: PostWorkoutWindow.logged,
    hydrationCupsPct: 0,
    fastingActive: fastingActive,
    fastHoursIn: fastHoursIn,
    fastedTrainingWarningsOn: fastedWarnings,
    weightTrend30d: WeightDirection.unknown,
    weightStagnantWeeks: 0,
    bodyPhase: BodyPhase.unknown,
    hasLastSimilarWorkout: false,
    prsLastWeekCount: prsLastWeek,
    volumeTrend4wk: volumeTrend,
    daysSincePrimaryMuscleGroup: daysSinceMg,
    hasPrOpportunityToday: prOpportunity,
    priorTwoDaysHardCount: priorHard,
    todayWorkoutHighIntensity: todayHighIntensity,
  );
});

/// Convenience — the resolved mode for the card. Cheap; recomputes only when
/// `workoutCardStateProvider` rebuilds.
final workoutCardModeProvider = Provider.autoDispose<WorkoutCardMode>((ref) {
  final state = ref.watch(workoutCardStateProvider);
  return chooseWorkoutCardMode(state);
});
