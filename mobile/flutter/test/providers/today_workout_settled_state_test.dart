// REGRESSION GATE — E2E 2026-07-28, issue #92.
//
// After the day's workout was completed, /today legitimately returns
//   has_workout_today:false, today_workout:null, next_workout:null,
//   completed_today:true, completed_workout:{...}
// Two guards in TodayWorkoutNotifier each hand-rolled "is this response empty?"
// as `todayWorkout == null && nextWorkout == null`, which is TRUE for that
// perfectly valid settled state. The result was a deadlock:
//
//   watchdog: "state stuck" -> force refresh
//   cache:    "empty response" -> refuse to store it, keep the old workout
//   -> state never changes -> watchdog fires again, every ~5s, forever.
//
// Measured on device: 21 watchdog fires in 120s, ~2 network requests each,
// 28.7% CPU, and the UI rebuilt so constantly that taps stopped registering.
//
// The model already exposes the correct predicate — `hasDisplayableContent`,
// which counts completedToday and restDayMessage. These tests pin the SEMANTICS
// both guards depend on, so re-deriving the narrower check fails here.

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/today_workout.dart';

TodayWorkoutSummary _summary() => const TodayWorkoutSummary(
      id: 'w1',
      name: 'Quick Power Full Body',
      type: 'full body',
      difficulty: 'moderate',
      durationMinutes: 15,
      exerciseCount: 5,
      primaryMuscles: <String>['Full Body'],
      scheduledDate: '2026-07-28',
      isToday: true,
      isCompleted: false,
    );

void main() {
  group('TodayWorkoutResponse.hasDisplayableContent', () {
    test('a completed day is settled content, not an empty response', () {
      // The exact shape /today returns once the day's workout is finished.
      const response = TodayWorkoutResponse(
        hasWorkoutToday: false,
        todayWorkout: null,
        nextWorkout: null,
        completedToday: true,
      );

      expect(
        response.hasDisplayableContent,
        isTrue,
        reason: 'completedToday must count as content — otherwise the watchdog '
            'calls this "stuck" and the cache guard refuses to store it, which '
            'is the #92 refresh loop',
      );
    });

    test('a rest day is settled content too', () {
      const response = TodayWorkoutResponse(
        hasWorkoutToday: false,
        todayWorkout: null,
        nextWorkout: null,
        restDayMessage: 'Rest up — back at it tomorrow.',
      );

      expect(response.hasDisplayableContent, isTrue);
    });

    test('a genuinely empty response is still empty', () {
      // This one SHOULD be treated as nothing-to-show: it is the transient
      // failure the two guards were originally written to protect against.
      const response = TodayWorkoutResponse(
        hasWorkoutToday: false,
        todayWorkout: null,
        nextWorkout: null,
        completedToday: false,
      );

      expect(response.hasDisplayableContent, isFalse);
    });

    test('a scheduled workout is content', () {
      final response = TodayWorkoutResponse(
        hasWorkoutToday: true,
        todayWorkout: _summary(),
      );

      expect(response.hasDisplayableContent, isTrue);
    });

    test('the completed-day response is NOT confusable with the empty one', () {
      // The narrow check both guards used to hand-roll. It cannot tell the two
      // apart — which is precisely why it must not be reintroduced.
      const completed = TodayWorkoutResponse(
        hasWorkoutToday: false,
        completedToday: true,
      );
      const empty = TodayWorkoutResponse(hasWorkoutToday: false);

      bool narrowLooksEmpty(TodayWorkoutResponse r) =>
          r.todayWorkout == null && r.nextWorkout == null;

      expect(narrowLooksEmpty(completed), narrowLooksEmpty(empty),
          reason: 'sanity: the old check really is blind to the difference');
      expect(completed.hasDisplayableContent,
          isNot(empty.hasDisplayableContent),
          reason: 'hasDisplayableContent is what distinguishes them');
    });
  });
}
