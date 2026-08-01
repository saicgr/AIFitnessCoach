// Gate for the workout-complete "MUSCLES WORKED" chips.
//
// Reported symptom: on the recap, "Middle Back" and "Front Shoulders" showed a
// generic dumbbell glyph while "Shoulders" and "Biceps" beside them showed real
// anatomy. Not missing artwork — a NAMING mismatch. The lookup did exact match
// then case-insensitive match against 15 asset keys, and a live scan of
// `exercise_library` found **861 distinct** muscle strings across
// target_muscle + secondary_muscles.
//
// The data is genuinely dirty, and these cases are taken from that scan rather
// than invented: parenthetical anatomy, fragments left behind by comma-splitting
// a parenthetical list, bare anatomical names, and both spellings of
// "stabilis/zers".
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/widgets/workout_ai_recap_card.dart';

void main() {
  group('the two names from the bug report', () {
    test('Middle Back resolves to Back', () {
      expect(muscleAssetGroupFor('Middle Back'), 'Back');
    });
    test('Front Shoulders resolves to Shoulders', () {
      expect(muscleAssetGroupFor('Front Shoulders'), 'Shoulders');
    });
  });

  group('ordering traps — these are why the list order is fixed', () {
    test('"lateral deltoid" is a SHOULDER, not a lat', () {
      // "lateral" contains "lat"; Shoulders must be checked before Back.
      expect(muscleAssetGroupFor('lateral deltoid'), 'Shoulders');
      expect(muscleAssetGroupFor('anterior deltoid'), 'Shoulders');
      expect(muscleAssetGroupFor('posterior deltoid'), 'Shoulders');
    });

    test('"biceps femoris" is a HAMSTRING, not a bicep', () {
      expect(muscleAssetGroupFor('biceps femoris'), 'Hamstrings');
      expect(muscleAssetGroupFor('Hamstrings (Biceps Femoris'), 'Hamstrings');
    });

    test('"lower back" is not swallowed by "back"', () {
      expect(muscleAssetGroupFor('Lower Back (Erector Spinae)'), 'Lower Back');
      expect(muscleAssetGroupFor('erector spinae'), 'Lower Back');
    });

    test('brachioradialis is a forearm, brachialis is a bicep', () {
      expect(muscleAssetGroupFor('brachioradialis'), 'Forearms');
      expect(muscleAssetGroupFor('brachialis'), 'Biceps');
    });
  });

  group('real strings straight out of exercise_library', () {
    const cases = <String, String>{
      // Parenthetical anatomy — the most common shape in the table.
      'Shoulders (Deltoids)': 'Shoulders',
      'Biceps (Biceps Brachii)': 'Biceps',
      'Triceps (Triceps Brachii)': 'Triceps',
      'Core (Rectus Abdominis)': 'Core',
      'Chest (Pectoralis Major)': 'Chest',
      'Upper Back (Trapezius)': 'Back',
      'Forearms (Brachioradialis)': 'Forearms',
      'Calves (Gastrocnemius, Soleus)': 'Calves',
      'Hip Flexors (Iliopsoas)': 'Hips',
      'Abdominals (Rectus Abdominis)': 'Core',
      'Middle Back (Latissimus Dorsi, Teres Major)': 'Back',
      // Fragments left by comma-splitting a parenthetical list.
      'Semitendinosus': 'Hamstrings',
      'Semimembranosus)': 'Hamstrings',
      'Obliques)': 'Core',
      // Bare anatomical names.
      'serratus anterior': 'Chest',
      'rhomboids': 'Back',
      'teres major': 'Back',
      'upper trapezius': 'Back',
      'infraspinatus': 'Shoulders',
      'transverse abdominis': 'Core',
      'gluteus medius': 'Glutes',
      'tibialis anterior': 'Calves',
      'hip abductors': 'Hips',
      'adductors': 'Hips',
      'hip flexors': 'Hips',
      // Both spellings, both cases.
      'core stabilizers': 'Core',
      'core stabilisers': 'Core',
      'HAMSTRINGS': 'Hamstrings',
      'quadriceps': 'Quadriceps',
    };

    cases.forEach((input, expected) {
      test('"$input" → $expected', () {
        expect(muscleAssetGroupFor(input), expected);
      });
    });
  });

  test('an unrecognisable name returns null rather than guessing', () {
    // The caller keeps its neutral fallback glyph. Guessing at anatomy would
    // be worse than a generic icon — a wrong body diagram is a confident lie.
    expect(muscleAssetGroupFor('zzz not a muscle'), isNull);
    expect(muscleAssetGroupFor(''), isNull);
  });
}
