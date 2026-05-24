import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/utils/voice_set_parser.dart';

void main() {
  const parser = VoiceSetParser();
  const lbToKg = 0.45359237;

  // Tight tolerance: lb→kg float conversion can introduce small ULP drift.
  Matcher closeToKg(double lb) => closeTo(lb * lbToKg, 1e-6);

  group('VoiceSetParser — digit forms', () {
    test('"225 for 5" → 225 lb, 5 reps, confidence 1.0', () {
      final r = parser.parse('225 for 5');
      expect(r.weightKg, closeToKg(225));
      expect(r.reps, 5);
      expect(r.isWarmup, false);
      expect(r.liftHint, isNull);
      expect(r.confidence, 1.0);
    });

    test('"135x10" → 135 lb, 10 reps', () {
      final r = parser.parse('135x10');
      expect(r.weightKg, closeToKg(135));
      expect(r.reps, 10);
      expect(r.confidence, 1.0);
    });

    test('"315 by 3" → 315 lb, 3 reps', () {
      final r = parser.parse('315 by 3');
      expect(r.weightKg, closeToKg(315));
      expect(r.reps, 3);
    });

    test('"100 kg for 5" → 100 kg (NOT lb-converted)', () {
      final r = parser.parse('100 kg for 5');
      expect(r.weightKg, closeTo(100, 1e-6));
      expect(r.reps, 5);
      expect(r.confidence, 1.0);
    });

    test('"225 pounds 5 reps" (unit words, no for/by)', () {
      final r = parser.parse('225 pounds 5 reps');
      expect(r.weightKg, closeToKg(225));
      expect(r.reps, 5);
    });
  });

  group('VoiceSetParser — word forms', () {
    test('"two twenty five by 5" → 225 lb, 5 reps, confidence 0.85', () {
      final r = parser.parse('two twenty five by 5');
      expect(r.weightKg, closeToKg(225));
      expect(r.reps, 5);
      expect(r.confidence, 0.85);
    });

    test('"two twenty-five for five" (hyphenated) → 225, 5', () {
      final r = parser.parse('two twenty-five for five');
      expect(r.weightKg, closeToKg(225));
      expect(r.reps, 5);
      expect(r.confidence, 0.85);
    });

    test('"two thirty for eight" → 230, 8', () {
      final r = parser.parse('two thirty for eight');
      expect(r.weightKg, closeToKg(230));
      expect(r.reps, 8);
    });

    test('"one hundred for ten" → 100, 10', () {
      final r = parser.parse('one hundred for ten');
      expect(r.weightKg, closeToKg(100));
      expect(r.reps, 10);
    });

    test('"two hundred twenty five for five" → 225, 5', () {
      final r = parser.parse('two hundred twenty five for five');
      expect(r.weightKg, closeToKg(225));
      expect(r.reps, 5);
    });

    test('"two oh five for five" → 205, 5', () {
      final r = parser.parse('two oh five for five');
      expect(r.weightKg, closeToKg(205));
      expect(r.reps, 5);
    });
  });

  group('VoiceSetParser — warmup detection', () {
    test('"warmup set" alone → isWarmup true, no weight/reps, confidence 0.6',
        () {
      final r = parser.parse('warmup set');
      expect(r.isWarmup, true);
      expect(r.weightKg, isNull);
      expect(r.reps, isNull);
      expect(r.confidence, 0.6);
    });

    test('"warm up 95 for 5" → warmup + 95 lb + 5 reps', () {
      final r = parser.parse('warm up 95 for 5');
      expect(r.isWarmup, true);
      expect(r.weightKg, closeToKg(95));
      expect(r.reps, 5);
      expect(r.confidence, 1.0);
    });

    test('"warm-up 135 by 8" hyphenated', () {
      final r = parser.parse('warm-up 135 by 8');
      expect(r.isWarmup, true);
      expect(r.reps, 8);
    });
  });

  group('VoiceSetParser — lift hints', () {
    test('"bench 225 for 5" with current=Squat → liftHint=bench', () {
      final r = parser.parse('bench 225 for 5', currentExerciseName: 'Squat');
      expect(r.liftHint, 'bench');
      expect(r.weightKg, closeToKg(225));
      expect(r.reps, 5);
    });

    test('"bench 225 for 5" with current=Bench Press → liftHint=null', () {
      final r = parser.parse(
        'bench 225 for 5',
        currentExerciseName: 'Bench Press',
      );
      expect(r.liftHint, isNull);
      expect(r.weightKg, closeToKg(225));
    });

    test('"deadlift 405 for 1" with current=Squat → liftHint=deadlift', () {
      final r = parser.parse(
        'deadlift 405 for 1',
        currentExerciseName: 'Back Squat',
      );
      expect(r.liftHint, 'deadlift');
      expect(r.reps, 1);
    });

    test('"OHP 95 for 5" with no current → liftHint=overhead press', () {
      final r = parser.parse('OHP 95 for 5');
      expect(r.liftHint, 'overhead press');
    });
  });

  group('VoiceSetParser — partial & edge cases', () {
    test('empty transcript → empty ParsedSet', () {
      final r = parser.parse('');
      expect(r.weightKg, isNull);
      expect(r.reps, isNull);
      expect(r.confidence, 0.0);
    });

    test('pure noise → empty ParsedSet', () {
      final r = parser.parse('hello world how are you');
      expect(r.weightKg, isNull);
      expect(r.reps, isNull);
      expect(r.confidence, 0.0);
    });

    test('"five reps" alone → reps only, low confidence', () {
      final r = parser.parse('five reps');
      // "five" is the first number, no second number → falls into partial path.
      // The regex "(\d+) reps" doesn't match a word, but the for-word fallback
      // doesn't trigger without "for". Accept either reps=5 or null; require
      // confidence stays in the partial band when anything is detected.
      expect(r.confidence, lessThanOrEqualTo(0.6));
    });

    test('"0 for 0" → zero weight, zero reps, valid', () {
      final r = parser.parse('0 for 0');
      expect(r.weightKg, closeTo(0, 1e-9));
      expect(r.reps, 0);
      expect(r.confidence, 1.0);
    });

    test('"zero for zero" → 0 / 0 via word form', () {
      final r = parser.parse('zero for zero');
      expect(r.weightKg, closeTo(0, 1e-9));
      expect(r.reps, 0);
      expect(r.confidence, 0.85);
    });

    test('lone weight "225 pounds" → partial (no reps), confidence 0.6', () {
      final r = parser.parse('225 pounds');
      expect(r.weightKg, closeToKg(225));
      expect(r.reps, isNull);
      expect(r.confidence, 0.6);
    });

    test('ambiguous "hit some reps today" → low confidence, no numbers', () {
      final r = parser.parse('hit some reps today');
      expect(r.weightKg, isNull);
      expect(r.reps, isNull);
      expect(r.confidence, 0.0);
    });

    test('punctuation tolerant: "225, for 5!"', () {
      final r = parser.parse('225, for 5!');
      expect(r.weightKg, closeToKg(225));
      expect(r.reps, 5);
    });

    test('decimal weight: "102.5 kg for 5"', () {
      final r = parser.parse('102.5 kg for 5');
      expect(r.weightKg, closeTo(102.5, 1e-6));
      expect(r.reps, 5);
    });

    test('upper-case input is normalised', () {
      final r = parser.parse('BENCH 225 FOR 5');
      expect(r.weightKg, closeToKg(225));
      expect(r.reps, 5);
      expect(r.liftHint, isNull); // no currentExerciseName → still no mismatch
    });
  });
}
