// Unit tests for the workout-card resolver.
//
// Strategy: every test starts from `WorkoutCardState.empty()` (a neutral
// baseline of `scheduledNotStarted` + active plan + morning + unknown
// recovery/cycle) and overrides ONLY the fields under test via
// `copyWith`. That keeps each test focused on one rule + makes
// tie-breakers explicit.

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/home/widgets/workout_card/workout_card_mode.dart';

void main() {
  group('TimeOfDay.fromHour buckets', () {
    test('maps every hour to the correct bucket', () {
      expect(TimeOfDay.fromHour(0), TimeOfDay.quiet);
      expect(TimeOfDay.fromHour(4), TimeOfDay.quiet);
      expect(TimeOfDay.fromHour(5), TimeOfDay.early);
      expect(TimeOfDay.fromHour(6), TimeOfDay.early);
      expect(TimeOfDay.fromHour(7), TimeOfDay.morning);
      expect(TimeOfDay.fromHour(10), TimeOfDay.morning);
      expect(TimeOfDay.fromHour(11), TimeOfDay.midday);
      expect(TimeOfDay.fromHour(13), TimeOfDay.midday);
      expect(TimeOfDay.fromHour(14), TimeOfDay.afternoon);
      expect(TimeOfDay.fromHour(16), TimeOfDay.afternoon);
      expect(TimeOfDay.fromHour(17), TimeOfDay.evening);
      expect(TimeOfDay.fromHour(20), TimeOfDay.evening);
      expect(TimeOfDay.fromHour(21), TimeOfDay.late);
      expect(TimeOfDay.fromHour(22), TimeOfDay.late);
      expect(TimeOfDay.fromHour(23), TimeOfDay.quiet);
    });

    test('normalises out-of-range hours', () {
      expect(TimeOfDay.fromHour(24), TimeOfDay.quiet);
      expect(TimeOfDay.fromHour(-1), TimeOfDay.quiet); // 23 → quiet bucket
      expect(TimeOfDay.fromHour(30), TimeOfDay.early); // 6
    });
  });

  group('Per-mode happy paths (one realistic state per mode)', () {
    test('error', () {
      final s = WorkoutCardState.empty().copyWith(isError: true);
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.error);
    });

    test('loading', () {
      final s = WorkoutCardState.empty().copyWith(isLoading: true);
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.loading);
    });

    test('inProgress', () {
      final s = WorkoutCardState.empty()
          .copyWith(workoutState: WorkoutState.inProgress);
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.inProgress);
    });

    test('completedToday', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.completed,
        postWorkoutWindow: PostWorkoutWindow.logged,
        recovery: RecoveryBucket.yellow,
        time: TimeOfDay.afternoon,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.completedToday);
    });

    test('postWorkoutRefuel (overrides completedToday)', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.completed,
        postWorkoutWindow: PostWorkoutWindow.unloggedWithin30min,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.postWorkoutRefuel);
    });

    test('vacationOrPaused', () {
      final s = WorkoutCardState.empty().copyWith(
        planState: PlanState.paused,
        workoutState: WorkoutState.scheduledNotStarted,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.vacationOrPaused);
    });

    test('noPlan', () {
      final s = WorkoutCardState.empty().copyWith(
        planState: PlanState.noPlan,
        workoutState: WorkoutState.none,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.noPlan);
    });

    test('overtrainingAlert', () {
      final s = WorkoutCardState.empty().copyWith(
        priorTwoDaysHardCount: 2,
        recovery: RecoveryBucket.red,
        volumeTrend4wk: VolumeTrend.up,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.overtrainingAlert);
    });

    test('windDown (late hour)', () {
      final s = WorkoutCardState.empty().copyWith(time: TimeOfDay.late);
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.windDown);
    });

    test('windDown (evening + sleep coach pillar)', () {
      final s = WorkoutCardState.empty().copyWith(
        time: TimeOfDay.evening,
        coachPillar: 'sleep',
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.windDown);
    });

    test('fastingActive', () {
      final s = WorkoutCardState.empty().copyWith(
        fastingActive: true,
        fastHoursIn: 14,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.fastingActive);
    });

    test('recoveryLighter', () {
      final s = WorkoutCardState.empty().copyWith(
        recovery: RecoveryBucket.red,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.recoveryLighter);
    });

    test('cycleAdjusted', () {
      final s = WorkoutCardState.empty().copyWith(
        cyclePhase: CyclePhase.luteal,
        todayWorkoutHighIntensity: true,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.cycleAdjusted);
    });

    test('preWorkoutFuelGap', () {
      final s = WorkoutCardState.empty().copyWith(
        time: TimeOfDay.midday,
        preWorkoutWindow: PreWorkoutWindow.longGap,
        todayWorkoutHighIntensity: true,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.preWorkoutFuelGap);
    });

    test('equipmentMismatch', () {
      final s = WorkoutCardState.empty().copyWith(
        equipmentMatch: EquipmentMatch.missing,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.equipmentMismatch);
    });

    test('comebackSession', () {
      final s = WorkoutCardState.empty().copyWith(
        daysSincePrimaryMuscleGroup: 14,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.comebackSession);
    });

    test('prOpportunityToday', () {
      final s = WorkoutCardState.empty().copyWith(
        hasPrOpportunityToday: true,
        recovery: RecoveryBucket.green,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.prOpportunityToday);
    });

    test('scheduledNotStarted (default)', () {
      final s = WorkoutCardState.empty();
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.scheduledNotStarted);
    });

    test('nextWorkoutInFuture', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.none,
        hasNextWorkout: true,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.nextWorkoutInFuture);
    });

    test('nothingScheduled', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.none,
        hasNextWorkout: false,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.nothingScheduled);
    });

    test('bonus (post-completion happy path)', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.completed,
        postWorkoutWindow: PostWorkoutWindow.logged,
        time: TimeOfDay.morning,
        recovery: RecoveryBucket.green,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.bonus);
    });

    test('restDayWithCoach', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.restDay,
        time: TimeOfDay.afternoon,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.restDayWithCoach);
    });

    test('yesterdayMissedRecovery (rest day morning, yesterday missed)', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.restDay,
        yesterdayMissed: true,
        time: TimeOfDay.morning,
      );
      expect(
          chooseWorkoutCardMode(s), WorkoutCardMode.yesterdayMissedRecovery);
    });
  });

  group('Precedence tie-breakers', () {
    test('error beats everything (even inProgress)', () {
      final s = WorkoutCardState.empty().copyWith(
        isError: true,
        workoutState: WorkoutState.inProgress,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.error);
    });

    test('loading beats inProgress', () {
      final s = WorkoutCardState.empty().copyWith(
        isLoading: true,
        workoutState: WorkoutState.inProgress,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.loading);
    });

    test('inProgress beats windDown at late hour', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.inProgress,
        time: TimeOfDay.late,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.inProgress);
    });

    test('inProgress beats overtrainingAlert', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.inProgress,
        priorTwoDaysHardCount: 3,
        recovery: RecoveryBucket.red,
        volumeTrend4wk: VolumeTrend.up,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.inProgress);
    });

    test('completedToday beats coach-pillar suggestions', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.completed,
        postWorkoutWindow: PostWorkoutWindow.logged,
        coachPillar: 'train',
        time: TimeOfDay.afternoon,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.completedToday);
    });

    test('postWorkoutRefuel beats bonus when both could fire', () {
      // Morning + green + completed + unlogged refuel — refuel wins
      // because the 30-min window is time-sensitive.
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.completed,
        postWorkoutWindow: PostWorkoutWindow.unloggedWithin30min,
        time: TimeOfDay.morning,
        recovery: RecoveryBucket.green,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.postWorkoutRefuel);
    });

    test('vacationOrPaused beats overtrainingAlert', () {
      // User explicitly paused — don't lecture about overtraining.
      final s = WorkoutCardState.empty().copyWith(
        planState: PlanState.paused,
        priorTwoDaysHardCount: 2,
        recovery: RecoveryBucket.red,
        volumeTrend4wk: VolumeTrend.up,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.vacationOrPaused);
    });

    test('overtrainingAlert beats windDown (only health signal that does)',
        () {
      final s = WorkoutCardState.empty().copyWith(
        time: TimeOfDay.late,
        priorTwoDaysHardCount: 2,
        recovery: RecoveryBucket.red,
        volumeTrend4wk: VolumeTrend.up,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.overtrainingAlert);
    });

    test('overtrainingAlert beats fastingActive', () {
      final s = WorkoutCardState.empty().copyWith(
        fastingActive: true,
        priorTwoDaysHardCount: 2,
        recovery: RecoveryBucket.red,
        volumeTrend4wk: VolumeTrend.up,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.overtrainingAlert);
    });

    test('windDown beats fastingActive at late hour', () {
      final s = WorkoutCardState.empty().copyWith(
        time: TimeOfDay.late,
        fastingActive: true,
        fastHoursIn: 18,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.windDown);
    });

    test('fastingActive beats recoveryLighter', () {
      final s = WorkoutCardState.empty().copyWith(
        fastingActive: true,
        recovery: RecoveryBucket.red,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.fastingActive);
    });

    test('recoveryLighter beats cycleAdjusted (recovery wins)', () {
      final s = WorkoutCardState.empty().copyWith(
        recovery: RecoveryBucket.red,
        cyclePhase: CyclePhase.luteal,
        todayWorkoutHighIntensity: true,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.recoveryLighter);
    });

    test('cycleAdjusted beats preWorkoutFuelGap', () {
      final s = WorkoutCardState.empty().copyWith(
        cyclePhase: CyclePhase.luteal,
        todayWorkoutHighIntensity: true,
        preWorkoutWindow: PreWorkoutWindow.longGap,
        time: TimeOfDay.midday,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.cycleAdjusted);
    });

    test('equipmentMismatch beats comebackSession (equipment wins)', () {
      final s = WorkoutCardState.empty().copyWith(
        equipmentMatch: EquipmentMatch.missing,
        daysSincePrimaryMuscleGroup: 30,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.equipmentMismatch);
    });

    test('comebackSession beats prOpportunityToday', () {
      final s = WorkoutCardState.empty().copyWith(
        daysSincePrimaryMuscleGroup: 12,
        hasPrOpportunityToday: true,
        recovery: RecoveryBucket.green,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.comebackSession);
    });

    test('prOpportunityToday SUPPRESSED when recovery is red', () {
      // recoveryLighter claims the slot — never push PR when red.
      final s = WorkoutCardState.empty().copyWith(
        hasPrOpportunityToday: true,
        recovery: RecoveryBucket.red,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.recoveryLighter);
    });

    test('prOpportunityToday beats scheduledNotStarted otherwise', () {
      final s = WorkoutCardState.empty().copyWith(
        hasPrOpportunityToday: true,
        recovery: RecoveryBucket.yellow,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.prOpportunityToday);
    });

    test('bonus does NOT fire when recovery is yellow', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.completed,
        postWorkoutWindow: PostWorkoutWindow.logged,
        time: TimeOfDay.morning,
        recovery: RecoveryBucket.yellow,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.completedToday);
    });

    test('bonus does NOT fire in the afternoon (only morning/midday)', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.completed,
        postWorkoutWindow: PostWorkoutWindow.logged,
        time: TimeOfDay.afternoon,
        recovery: RecoveryBucket.green,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.completedToday);
    });

    test('yesterdayMissedRecovery beats restDayWithCoach in morning', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.restDay,
        yesterdayMissed: true,
        time: TimeOfDay.morning,
      );
      expect(
          chooseWorkoutCardMode(s), WorkoutCardMode.yesterdayMissedRecovery);
    });

    test('yesterdayMissed at night falls back to restDayWithCoach', () {
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.restDay,
        yesterdayMissed: true,
        time: TimeOfDay.late,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.restDayWithCoach);
    });
  });

  group('Boundary conditions', () {
    test('priorTwoDaysHardCount = 1 does NOT trigger overtraining', () {
      final s = WorkoutCardState.empty().copyWith(
        priorTwoDaysHardCount: 1,
        recovery: RecoveryBucket.red,
        volumeTrend4wk: VolumeTrend.up,
      );
      // Falls through to recoveryLighter (red recovery).
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.recoveryLighter);
    });

    test('priorTwoDaysHardCount = 2 triggers overtraining (boundary)', () {
      final s = WorkoutCardState.empty().copyWith(
        priorTwoDaysHardCount: 2,
        recovery: RecoveryBucket.red,
        volumeTrend4wk: VolumeTrend.up,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.overtrainingAlert);
    });

    test('overtraining requires ALL three signals (volume flat → no)', () {
      final s = WorkoutCardState.empty().copyWith(
        priorTwoDaysHardCount: 3,
        recovery: RecoveryBucket.red,
        volumeTrend4wk: VolumeTrend.flat,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.recoveryLighter);
    });

    test('daysSincePrimaryMuscleGroup = 10 does NOT trigger comeback', () {
      final s = WorkoutCardState.empty().copyWith(
        daysSincePrimaryMuscleGroup: 10,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.scheduledNotStarted);
    });

    test('daysSincePrimaryMuscleGroup = 11 triggers comeback (boundary)',
        () {
      final s = WorkoutCardState.empty().copyWith(
        daysSincePrimaryMuscleGroup: 11,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.comebackSession);
    });

    test('cycleAdjusted only fires when workout is high-intensity', () {
      final s = WorkoutCardState.empty().copyWith(
        cyclePhase: CyclePhase.luteal,
        todayWorkoutHighIntensity: false,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.scheduledNotStarted);
    });

    test('preWorkoutFuelGap requires high-intensity workout', () {
      final s = WorkoutCardState.empty().copyWith(
        time: TimeOfDay.midday,
        preWorkoutWindow: PreWorkoutWindow.longGap,
        todayWorkoutHighIntensity: false,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.scheduledNotStarted);
    });

    test('preWorkoutFuelGap not in evening', () {
      // Evening is past the fueling window per §1; falls through.
      final s = WorkoutCardState.empty().copyWith(
        time: TimeOfDay.evening,
        preWorkoutWindow: PreWorkoutWindow.longGap,
        todayWorkoutHighIntensity: true,
      );
      // Evening with no sleep pillar → falls to scheduledNotStarted.
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.scheduledNotStarted);
    });

    test('preWorkoutFuelGap suppressed while fasting', () {
      // Fasting wins precedence-wise; verify we get fastingActive.
      final s = WorkoutCardState.empty().copyWith(
        time: TimeOfDay.midday,
        preWorkoutWindow: PreWorkoutWindow.longGap,
        todayWorkoutHighIntensity: true,
        fastingActive: true,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.fastingActive);
    });

    test('windDown does NOT fire in evening without sleep pillar', () {
      final s = WorkoutCardState.empty().copyWith(
        time: TimeOfDay.evening,
        coachPillar: 'train',
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.scheduledNotStarted);
    });

    test('windDown fires at quiet hour', () {
      final s = WorkoutCardState.empty().copyWith(time: TimeOfDay.quiet);
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.windDown);
    });

    test('nextWorkoutInFuture requires workoutState.none', () {
      // restDay doesn't count as "none"; it routes to rest-day modes.
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.restDay,
        hasNextWorkout: true,
        time: TimeOfDay.afternoon,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.restDayWithCoach);
    });

    test('skipped workout degrades to nothingScheduled', () {
      // Per the explicit terminal branch comment in the resolver.
      final s = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.skipped,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.nothingScheduled);
    });

    test('coachPillar null treated as non-sleep (no windDown in evening)',
        () {
      final s = WorkoutCardState.empty().copyWith(
        time: TimeOfDay.evening,
        coachPillar: null,
      );
      expect(chooseWorkoutCardMode(s), WorkoutCardMode.scheduledNotStarted);
    });
  });
}
