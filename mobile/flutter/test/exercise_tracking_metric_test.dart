import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/utils/exercise_tracking_metric.dart';

void main() {
  group('ExerciseTrackingMetric.resolve', () {
    TrackingMetric m(String name,
            {String? equipment,
            bool isTimed = false,
            int? holdSeconds,
            int? durationSeconds,
            String? hint,
            num? distanceMeters,
            String? repsSpec}) =>
        ExerciseTrackingMetric.resolve(
          name: name,
          equipment: equipment,
          isTimed: isTimed,
          holdSeconds: holdSeconds,
          durationSeconds: durationSeconds,
          trackingTypeHint: hint,
          distanceMeters: distanceMeters,
          repsSpec: repsSpec,
        );

    test('backend hint wins', () {
      expect(m('Anything', hint: 'distance'), TrackingMetric.distance);
      expect(m('Back Squat', hint: 'bodyweight'), TrackingMetric.bodyweight);
      expect(m('SkiErg', hint: 'weight'), TrackingMetric.weight);
    });

    test('cardio machines + sled + carries → distance', () {
      expect(m('SkiErg Interval'), TrackingMetric.distance);
      expect(m('Sled Push'), TrackingMetric.distance);
      expect(m('Sled Pull'), TrackingMetric.distance);
      expect(m("Farmer's Carry"), TrackingMetric.distance);
      expect(m('Sandbag Lunges'), TrackingMetric.distance);
      expect(m('Rowing Machine Intervals'), TrackingMetric.distance);
      expect(m('Burpee Broad Jumps'), TrackingMetric.distance);
    });

    test('explicit distance_meters → distance even for a generic name', () {
      expect(m('Station 3', distanceMeters: 1000), TrackingMetric.distance);
    });

    test('distance-unit target string → distance', () {
      expect(m('Mystery Move', repsSpec: '1000 m'), TrackingMetric.distance);
      expect(m('Mystery Move', repsSpec: '1 km'), TrackingMetric.distance);
    });

    test('holds / is_timed → time', () {
      expect(m('Plank Hold'), TrackingMetric.time);
      expect(m('Plank', isTimed: true), TrackingMetric.time);
      expect(m('Wall Sit'), TrackingMetric.time);
      expect(m('Dead Hang', holdSeconds: 30), TrackingMetric.time);
    });

    test('bodyweight rep moves → bodyweight', () {
      expect(m('Burpees'), TrackingMetric.bodyweight);
      expect(m('Air Squat'), TrackingMetric.bodyweight);
      expect(m('Push-up'), TrackingMetric.bodyweight);
      expect(m('Pistol Squat', equipment: 'Bodyweight'),
          TrackingMetric.bodyweight);
    });

    test('loaded lifts → weight', () {
      expect(m('Back Squat', equipment: 'Barbell'), TrackingMetric.weight);
      expect(m('Dumbbell Goblet Squat', equipment: 'Dumbbells'),
          TrackingMetric.weight);
      expect(m('Wall Balls'), TrackingMetric.bodyweight); // med-ball reps, no load tracked
    });
  });

  group('parseTarget', () {
    test('distance', () {
      expect(ExerciseTrackingMetric.parseTarget('1000 m').metric,
          TrackingMetric.distance);
      expect(ExerciseTrackingMetric.parseTarget('1000 m').value, 1000);
      expect(ExerciseTrackingMetric.parseTarget('1 km').value, 1000);
      expect(ExerciseTrackingMetric.parseTarget('1.5 km').value, 1500);
    });

    test('time', () {
      expect(ExerciseTrackingMetric.parseTarget('8 minutes').metric,
          TrackingMetric.time);
      expect(ExerciseTrackingMetric.parseTarget('8 minutes').value, 480);
      expect(ExerciseTrackingMetric.parseTarget('45s hold').metric,
          TrackingMetric.time);
      expect(ExerciseTrackingMetric.parseTarget('45s hold').value, 45);
    });

    test('reps', () {
      expect(ExerciseTrackingMetric.parseTarget('100 reps').metric,
          TrackingMetric.bodyweight);
      expect(ExerciseTrackingMetric.parseTarget('100 reps').value, 100);
    });

    test('"min" is not mistaken for meters', () {
      expect(ExerciseTrackingMetric.parseTarget('5 min').metric,
          TrackingMetric.time);
    });
  });
}
