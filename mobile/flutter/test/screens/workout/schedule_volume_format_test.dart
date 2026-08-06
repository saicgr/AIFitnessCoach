// Regression tests for fix_workout.json rows 33 & 110: timed/interval
// exercises in the SCHEDULE tab must not render a meaningless "1" rep count
// or a fractional-minute duration ("0.5 min").
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/program_template.dart';
import 'package:fitwiz/screens/workout/schedule_volume_format.dart';

ProgramScheduleExercise _ex({
  required String name,
  String? sets,
  String? reps,
  int? durationSeconds,
  int? restSeconds,
  String? intensityGuidance,
}) {
  return ProgramScheduleExercise.fromJson({
    'name': name,
    'sets': sets,
    'reps': reps,
    'duration_seconds': durationSeconds,
    'rest_seconds': restSeconds,
    'intensity_guidance': intensityGuidance,
  });
}

void main() {
  group('formatScheduleSeconds', () {
    test('renders whole minutes without a fractional label', () {
      expect(formatScheduleSeconds(180), '3 min');
    });

    test('renders sub-minute durations in seconds', () {
      expect(formatScheduleSeconds(30), '30 sec');
      expect(formatScheduleSeconds(45), '45 sec');
    });

    test('renders non-round durations as "min sec", never a decimal', () {
      // Row 110: 90s must read "1 min 30 sec", not "1.5 min".
      expect(formatScheduleSeconds(90), '1 min 30 sec');
    });
  });

  group('resolveScheduleVolume', () {
    test(
      'row 33: single hold/timed exercise (Walking, sets:1 reps:1 '
      'duration_seconds:180) shows the duration, not "1 × 1"',
      () {
        final ex = _ex(
          name: 'Walking',
          sets: '1',
          reps: '1',
          durationSeconds: 180,
        );
        final resolved = resolveScheduleVolume(ex);
        expect(resolved.volume, '3 min');
        expect(resolved.volume, isNot(contains('1 × 1')));
      },
    );

    test(
      'row 33 (Chair Pose, hold_seconds — documented remaining gap): the '
      'backend schedule endpoint never surfaces hold_seconds as '
      'duration_seconds, so a hold exercise with no duration_seconds still '
      'falls back to the raw "sets × reps" label. This is the backend/model '
      'change tracked as OPEN for row 33 — not fixable from this file.',
      () {
        final ex = _ex(name: 'Chair Pose', sets: '2', reps: '1');
        final resolved = resolveScheduleVolume(ex);
        expect(resolved.volume, '2 × 1');
      },
    );

    test(
      'row 110: interval exercise (3 rounds, 60s work / 30s rest) gets a '
      'plain-English subtitle in whole seconds and drops the meaningless '
      '"3 × 1" trailing volume',
      () {
        final ex = _ex(
          name: 'Side plank',
          sets: '3',
          reps: '1',
          durationSeconds: 60,
          restSeconds: 30,
        );
        final resolved = resolveScheduleVolume(ex);
        expect(resolved.volume, '');
        expect(resolved.subtitle, '3 rounds: 1 min hard, 30 sec easy');
        expect(resolved.subtitle, isNot(contains('0.5 min')));
      },
    );

    test('untouched shape: plain rep-based exercise falls back unchanged', () {
      final ex = _ex(name: 'Bodyweight squat', sets: '2', reps: '10');
      final resolved = resolveScheduleVolume(ex);
      expect(resolved.volume, '2 × 10');
    });
  });

  group('restDayLabel', () {
    test(
      'row 111: authored name already saying "Rest" is not duplicated',
      () {
        expect(restDayLabel('Day 4 — Rest'), 'Day 4 — Rest');
        expect(restDayLabel('Day 28 — Rest'), 'Day 28 — Rest');
      },
    );

    test('a plain day name still gets the " · Rest" suffix', () {
      expect(restDayLabel('Wednesday'), 'Wednesday · Rest');
    });
  });
}
