// Workout-card state machine — pure Dart, no Flutter widgets, no I/O.
//
// Implements §1 of the home-screen v2 plan: a deterministic resolver that
// chooses exactly ONE primary `WorkoutCardMode` from a snapshot of state.
//
// Consumers (the UI in `hero_workout_card.dart`) call `chooseWorkoutCardMode`
// once per rebuild. The resolver is total + side-effect free + unit-tested.

/// All primary card modes, declared in resolver-precedence order
/// (the first match in `chooseWorkoutCardMode` wins).
///
/// `yesterdayMissedRecovery` is a distinct enum value — although the plan
/// folds it into `restDayWithCoach` for UI grouping, keeping a separate
/// value lets the UI render the yesterday-missed flavor distinctly without
/// losing precedence clarity. It sits at the same priority slot as
/// `restDayWithCoach` and is checked first when applicable.
enum WorkoutCardMode {
  error,
  loading,
  inProgress,
  completedToday,
  postWorkoutRefuel,
  vacationOrPaused,
  noPlan,
  overtrainingAlert,
  windDown,
  fastingActive,
  recoveryLighter,
  cycleAdjusted,
  preWorkoutFuelGap,
  equipmentMismatch,
  comebackSession,
  prOpportunityToday,
  scheduledNotStarted,
  nextWorkoutInFuture,
  nothingScheduled,
  bonus,
  restDayWithCoach,
  yesterdayMissedRecovery,
}

/// Time-of-day buckets in user-local hours. `quiet` wraps midnight.
///
/// Buckets per §1:
///   early   5-7   morning 7-11   midday 11-14   afternoon 14-17
///   evening 17-21 late    21-23  quiet   23-5
enum TimeOfDay {
  early,
  morning,
  midday,
  afternoon,
  evening,
  late,
  quiet;

  static TimeOfDay fromHour(int hour) {
    // Normalise into [0, 24) so callers can pass 24+ or negatives safely.
    final h = ((hour % 24) + 24) % 24;
    if (h >= 5 && h < 7) return TimeOfDay.early;
    if (h >= 7 && h < 11) return TimeOfDay.morning;
    if (h >= 11 && h < 14) return TimeOfDay.midday;
    if (h >= 14 && h < 17) return TimeOfDay.afternoon;
    if (h >= 17 && h < 21) return TimeOfDay.evening;
    if (h >= 21 && h < 23) return TimeOfDay.late;
    return TimeOfDay.quiet; // 23-24 and 0-5
  }
}

enum PlanState { noPlan, paused, active }

enum WorkoutState {
  none,
  restDay,
  scheduledNotStarted,
  inProgress,
  completed,
  skipped,
}

enum RecoveryBucket { green, yellow, red, unknown }

/// Cycle phase. `unknown` replaces nullability so the data class stays
/// non-nullable (matches `feedback_no_silent_fallbacks` discipline — we
/// don't want a silent null masquerading as "no cycle data").
enum CyclePhase { follicular, ovulation, luteal, menstrual, unknown }

enum BodyPhase { cut, recomp, maintain, bulk, unknown }

enum NextMealSlot { breakfast, lunch, dinner, snack, none }

enum PreWorkoutWindow { recent, midRange, longGap, fasted }

enum PostWorkoutWindow { unloggedWithin30min, logged, expired }

enum VolumeTrend { under, flat, up, unknown }

enum WeightDirection { losing, stable, gaining, unknown }

enum EquipmentMatch { match, missing, unknown }

/// Derived `body asks rest` signal — set to `alert` by upstream when
/// the overtraining heuristic is independently confirmed (e.g. wearable
/// strain coach). Not currently consulted in the resolver — kept for
/// future composition with `overtrainingAlert`.
enum BodyAskState { normal, alert }

/// Immutable snapshot of every input the resolver needs. All fields are
/// non-nullable — use enum `unknown` / sentinel ints for missing values.
class WorkoutCardState {
  // ── Core ────────────────────────────────────────────────────────────
  final bool isLoading;
  final bool isError;
  final PlanState planState;
  final WorkoutState workoutState;
  final TimeOfDay time;

  /// Leading pillar from `dailyCoachInsightProvider`. Null is allowed
  /// here because the field is fundamentally optional ("no insight loaded
  /// yet"); the resolver tolerates null by treating it as `train` per
  /// §1 edge clarifications.
  final String? coachPillar;

  final RecoveryBucket recovery;
  final CyclePhase cyclePhase;
  final bool streakExtendsIfComplete;
  final bool yesterdayMissed;
  final bool hasNextWorkout;
  final EquipmentMatch equipmentMatch;

  // ── Nutrition ───────────────────────────────────────────────────────
  final int caloriesPctOfTarget;
  final int proteinPctOfTarget;
  final NextMealSlot nextMealSlot;
  final PreWorkoutWindow preWorkoutWindow;
  final PostWorkoutWindow postWorkoutWindow;
  final int hydrationCupsPct;

  // ── Fasting ─────────────────────────────────────────────────────────
  final bool fastingActive;
  final int fastHoursIn;
  final bool fastedTrainingWarningsOn;

  // ── Body ────────────────────────────────────────────────────────────
  final WeightDirection weightTrend30d;
  final int weightStagnantWeeks;
  final BodyPhase bodyPhase;

  // ── History ─────────────────────────────────────────────────────────
  final bool hasLastSimilarWorkout;
  final int prsLastWeekCount;
  final VolumeTrend volumeTrend4wk;
  final int daysSincePrimaryMuscleGroup;
  final bool hasPrOpportunityToday;
  final int priorTwoDaysHardCount;

  // ── Workout meta ────────────────────────────────────────────────────
  final bool todayWorkoutHighIntensity;

  const WorkoutCardState({
    required this.isLoading,
    required this.isError,
    required this.planState,
    required this.workoutState,
    required this.time,
    required this.coachPillar,
    required this.recovery,
    required this.cyclePhase,
    required this.streakExtendsIfComplete,
    required this.yesterdayMissed,
    required this.hasNextWorkout,
    required this.equipmentMatch,
    required this.caloriesPctOfTarget,
    required this.proteinPctOfTarget,
    required this.nextMealSlot,
    required this.preWorkoutWindow,
    required this.postWorkoutWindow,
    required this.hydrationCupsPct,
    required this.fastingActive,
    required this.fastHoursIn,
    required this.fastedTrainingWarningsOn,
    required this.weightTrend30d,
    required this.weightStagnantWeeks,
    required this.bodyPhase,
    required this.hasLastSimilarWorkout,
    required this.prsLastWeekCount,
    required this.volumeTrend4wk,
    required this.daysSincePrimaryMuscleGroup,
    required this.hasPrOpportunityToday,
    required this.priorTwoDaysHardCount,
    required this.todayWorkoutHighIntensity,
  });

  /// A neutral baseline for tests — active plan, mid-morning, nothing
  /// special triggered. Tests override only the fields they care about
  /// via `copyWith`.
  factory WorkoutCardState.empty() => const WorkoutCardState(
        isLoading: false,
        isError: false,
        planState: PlanState.active,
        workoutState: WorkoutState.scheduledNotStarted,
        time: TimeOfDay.morning,
        coachPillar: null,
        recovery: RecoveryBucket.unknown,
        cyclePhase: CyclePhase.unknown,
        streakExtendsIfComplete: false,
        yesterdayMissed: false,
        hasNextWorkout: false,
        equipmentMatch: EquipmentMatch.unknown,
        caloriesPctOfTarget: 0,
        proteinPctOfTarget: 0,
        nextMealSlot: NextMealSlot.none,
        preWorkoutWindow: PreWorkoutWindow.recent,
        postWorkoutWindow: PostWorkoutWindow.logged,
        hydrationCupsPct: 0,
        fastingActive: false,
        fastHoursIn: 0,
        fastedTrainingWarningsOn: false,
        weightTrend30d: WeightDirection.unknown,
        weightStagnantWeeks: 0,
        bodyPhase: BodyPhase.unknown,
        hasLastSimilarWorkout: false,
        prsLastWeekCount: 0,
        volumeTrend4wk: VolumeTrend.unknown,
        daysSincePrimaryMuscleGroup: 0,
        hasPrOpportunityToday: false,
        priorTwoDaysHardCount: 0,
        todayWorkoutHighIntensity: false,
      );

  WorkoutCardState copyWith({
    bool? isLoading,
    bool? isError,
    PlanState? planState,
    WorkoutState? workoutState,
    TimeOfDay? time,
    Object? coachPillar = _sentinel,
    RecoveryBucket? recovery,
    CyclePhase? cyclePhase,
    bool? streakExtendsIfComplete,
    bool? yesterdayMissed,
    bool? hasNextWorkout,
    EquipmentMatch? equipmentMatch,
    int? caloriesPctOfTarget,
    int? proteinPctOfTarget,
    NextMealSlot? nextMealSlot,
    PreWorkoutWindow? preWorkoutWindow,
    PostWorkoutWindow? postWorkoutWindow,
    int? hydrationCupsPct,
    bool? fastingActive,
    int? fastHoursIn,
    bool? fastedTrainingWarningsOn,
    WeightDirection? weightTrend30d,
    int? weightStagnantWeeks,
    BodyPhase? bodyPhase,
    bool? hasLastSimilarWorkout,
    int? prsLastWeekCount,
    VolumeTrend? volumeTrend4wk,
    int? daysSincePrimaryMuscleGroup,
    bool? hasPrOpportunityToday,
    int? priorTwoDaysHardCount,
    bool? todayWorkoutHighIntensity,
  }) {
    return WorkoutCardState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      planState: planState ?? this.planState,
      workoutState: workoutState ?? this.workoutState,
      time: time ?? this.time,
      coachPillar: identical(coachPillar, _sentinel)
          ? this.coachPillar
          : coachPillar as String?,
      recovery: recovery ?? this.recovery,
      cyclePhase: cyclePhase ?? this.cyclePhase,
      streakExtendsIfComplete:
          streakExtendsIfComplete ?? this.streakExtendsIfComplete,
      yesterdayMissed: yesterdayMissed ?? this.yesterdayMissed,
      hasNextWorkout: hasNextWorkout ?? this.hasNextWorkout,
      equipmentMatch: equipmentMatch ?? this.equipmentMatch,
      caloriesPctOfTarget: caloriesPctOfTarget ?? this.caloriesPctOfTarget,
      proteinPctOfTarget: proteinPctOfTarget ?? this.proteinPctOfTarget,
      nextMealSlot: nextMealSlot ?? this.nextMealSlot,
      preWorkoutWindow: preWorkoutWindow ?? this.preWorkoutWindow,
      postWorkoutWindow: postWorkoutWindow ?? this.postWorkoutWindow,
      hydrationCupsPct: hydrationCupsPct ?? this.hydrationCupsPct,
      fastingActive: fastingActive ?? this.fastingActive,
      fastHoursIn: fastHoursIn ?? this.fastHoursIn,
      fastedTrainingWarningsOn:
          fastedTrainingWarningsOn ?? this.fastedTrainingWarningsOn,
      weightTrend30d: weightTrend30d ?? this.weightTrend30d,
      weightStagnantWeeks: weightStagnantWeeks ?? this.weightStagnantWeeks,
      bodyPhase: bodyPhase ?? this.bodyPhase,
      hasLastSimilarWorkout:
          hasLastSimilarWorkout ?? this.hasLastSimilarWorkout,
      prsLastWeekCount: prsLastWeekCount ?? this.prsLastWeekCount,
      volumeTrend4wk: volumeTrend4wk ?? this.volumeTrend4wk,
      daysSincePrimaryMuscleGroup:
          daysSincePrimaryMuscleGroup ?? this.daysSincePrimaryMuscleGroup,
      hasPrOpportunityToday:
          hasPrOpportunityToday ?? this.hasPrOpportunityToday,
      priorTwoDaysHardCount:
          priorTwoDaysHardCount ?? this.priorTwoDaysHardCount,
      todayWorkoutHighIntensity:
          todayWorkoutHighIntensity ?? this.todayWorkoutHighIntensity,
    );
  }
}

const Object _sentinel = Object();

/// Pure resolver. Walks the precedence ladder from §1 top-to-bottom and
/// returns the first matching mode. NEVER returns null — there is always
/// a sensible mode (worst case: `nothingScheduled`).
WorkoutCardMode chooseWorkoutCardMode(WorkoutCardState s) {
  // 1. error — provider failure beats everything, even an in-progress
  //    session, because we cannot trust any other field.
  if (s.isError) return WorkoutCardMode.error;

  // 2. loading — providers haven't resolved yet.
  if (s.isLoading) return WorkoutCardMode.loading;

  // 3. inProgress — a started session is sacrosanct per §1
  //    ("ALWAYS wins except error"). Coach insights / wind-down /
  //    fasting all yield to a live session.
  if (s.workoutState == WorkoutState.inProgress) {
    return WorkoutCardMode.inProgress;
  }

  // 4. completedToday — celebrate, never suggest more work on top.
  //    `postWorkoutRefuel` is a sub-mode that takes over when the
  //    30-min anabolic window is still open and no meal logged.
  if (s.workoutState == WorkoutState.completed) {
    if (s.postWorkoutWindow == PostWorkoutWindow.unloggedWithin30min) {
      return WorkoutCardMode.postWorkoutRefuel;
    }
    // `bonus` is a happy-path opportunity that only fires post-completion
    // when the user has capacity (green) and it's still early enough to
    // realistically squeeze in a second session. Lowest-priority mode.
    if (s.time == TimeOfDay.morning || s.time == TimeOfDay.midday) {
      if (s.recovery == RecoveryBucket.green) {
        return WorkoutCardMode.bonus;
      }
    }
    return WorkoutCardMode.completedToday;
  }

  // 5. vacationOrPaused — explicit user opt-out trumps further nudges.
  if (s.planState == PlanState.paused) {
    return WorkoutCardMode.vacationOrPaused;
  }

  // 6. noPlan — onboarding case; nothing else makes sense without a plan.
  if (s.planState == PlanState.noPlan) {
    return WorkoutCardMode.noPlan;
  }

  // 7. overtrainingAlert — body fatigue trumps time-of-day, but only
  //    fires when ALL three independent signals corroborate
  //    (two hard days + red recovery + rising 4wk tonnage). Per §1 this
  //    is the only health mode allowed to beat windDown.
  if (s.priorTwoDaysHardCount >= 2 &&
      s.recovery == RecoveryBucket.red &&
      s.volumeTrend4wk == VolumeTrend.up) {
    return WorkoutCardMode.overtrainingAlert;
  }

  // Modes below all require a scheduled-but-not-started workout — bail
  // early to the rest-day / future / empty branches if not the case.
  if (s.workoutState == WorkoutState.scheduledNotStarted) {
    // 8. windDown — late time OR explicit evening+sleep-coach combo.
    //    `evening` alone is not enough; the coach has to agree.
    final isWindDownTime = s.time == TimeOfDay.late ||
        s.time == TimeOfDay.quiet ||
        (s.time == TimeOfDay.evening && s.coachPillar == 'sleep');
    if (isWindDownTime) return WorkoutCardMode.windDown;

    // 9. fastingActive — visible state (active fast) beats recovery so
    //    the user isn't told to lift hard mid-fast without acknowledging
    //    the fast. Recovery can be folded into the sub-line by the UI.
    if (s.fastingActive) return WorkoutCardMode.fastingActive;

    // 10. recoveryLighter — red recovery during training hours.
    //     Suppresses cycleAdjusted (§1: "recovery is the stronger
    //     signal") so they're mutually exclusive at the primary slot.
    if (s.recovery == RecoveryBucket.red) {
      return WorkoutCardMode.recoveryLighter;
    }

    // 11. cycleAdjusted — luteal + high-intensity scheduled workout.
    //     Only fires when recovery hasn't already claimed the slot.
    if (s.cyclePhase == CyclePhase.luteal && s.todayWorkoutHighIntensity) {
      return WorkoutCardMode.cycleAdjusted;
    }

    // 12. preWorkoutFuelGap — long meal gap + high-intensity workout,
    //     in fueling-relevant hours, not during an active fast.
    final isFuelTime = s.time == TimeOfDay.morning ||
        s.time == TimeOfDay.midday ||
        s.time == TimeOfDay.afternoon;
    if (isFuelTime &&
        s.preWorkoutWindow == PreWorkoutWindow.longGap &&
        s.todayWorkoutHighIntensity &&
        !s.fastingActive) {
      return WorkoutCardMode.preWorkoutFuelGap;
    }

    // 13. equipmentMismatch — wins over comebackSession per §1 ("both
    //     can apply, equipment wins") because a missing piece of kit
    //     blocks the workout entirely.
    if (s.equipmentMatch == EquipmentMatch.missing) {
      return WorkoutCardMode.equipmentMismatch;
    }

    // 14. comebackSession — primary muscle group untrained > 10 days.
    //     Boundary: 10 days is the limit, 11+ triggers (strict `>`).
    if (s.daysSincePrimaryMuscleGroup > 10) {
      return WorkoutCardMode.comebackSession;
    }

    // 15. prOpportunityToday — opportunity flagged AND recovery is NOT
    //     red. (Red already returned at step 10 above; this guard is
    //     defensive — if a future change reorders things, the safety
    //     rule stays explicit.)
    if (s.hasPrOpportunityToday && s.recovery != RecoveryBucket.red) {
      return WorkoutCardMode.prOpportunityToday;
    }

    // 16. scheduledNotStarted — default happy path.
    return WorkoutCardMode.scheduledNotStarted;
  }

  // 17. nextWorkoutInFuture — no workout today but plan has more.
  //     Only valid when today is NOT a rest day (rest day handled below).
  if (s.workoutState == WorkoutState.none && s.hasNextWorkout) {
    return WorkoutCardMode.nextWorkoutInFuture;
  }

  // 18. nothingScheduled — has a plan but nothing today, no upcoming
  //     workout queued either. User needs a nudge to generate one.
  if (s.workoutState == WorkoutState.none && !s.hasNextWorkout) {
    return WorkoutCardMode.nothingScheduled;
  }

  // 19. restDay — `yesterdayMissedRecovery` is the morning/midday
  //     variant ("yesterday's leg day is still open"); regular
  //     `restDayWithCoach` otherwise.
  if (s.workoutState == WorkoutState.restDay) {
    final isRecoveryWindow =
        s.time == TimeOfDay.morning || s.time == TimeOfDay.midday;
    if (s.yesterdayMissed && isRecoveryWindow) {
      return WorkoutCardMode.yesterdayMissedRecovery;
    }
    return WorkoutCardMode.restDayWithCoach;
  }

  // 20. Skipped or any unhandled state — degrade gracefully to the
  //     "generate something" prompt. Per `feedback_no_silent_fallbacks`
  //     this is an explicit terminal branch, not a silent default.
  return WorkoutCardMode.nothingScheduled;
}
