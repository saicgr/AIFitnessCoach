// The media-less exercise placeholder must never ASSERT a movement.
//
// WHY THIS EXISTS
// ---------------
// `_fallbackIconForEquipment` in lib/widgets/exercise_image.dart used to match
// substrings of the exercise NAME as well as the equipment hint, and rendered an
// icon claiming a movement it had no evidence for:
//
//     if (h('row'))        -> Icons.rowing          // a person in a rowing boat
//     if (h('kettlebell')) -> Icons.sports_handball // a figure mid-punch/throw
//     if (h('run'))        -> Icons.directions_run  // a runner
//
// So "Barbell Row", "Seated Row Machine Rows" and "Lawnmower Row" (a cable row)
// all showed a rowing boat; every kettlebell exercise showed a punching figure;
// "Treadmill Walking Lunge" showed a runner.
//
// It was worst in the program exercise list (program_detail_screen.dart), which
// passes no `equipmentHint` — so the icon was guessed purely from the name, for
// precisely the exercises that still have no illustration.
//
// This is the same wrong-identity failure the backend deliberately locked down
// for images (api/v1/videos.py "NEVER serves a sibling exercise's image";
// backend/tests/test_exercise_image_no_fuzzy.py), reintroduced as an icon. An
// icon asserting the WRONG movement is worse than one asserting nothing.
//
// These tests are source-level because the helper is private and the failure is
// a *policy* violation (guessing at all), not a wrong return value for one input.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strip `//` and `///` comments so the scan below only sees live code.
/// Without this, the doc comment in exercise_image.dart that *quotes* the
/// removed guessing lines (deliberately, so nobody reintroduces them) would
/// trip the very check it documents.
String _codeOnly(String src) => src
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  final imageWidget = File('lib/widgets/exercise_image.dart');
  final thumbnail =
      File('lib/screens/home/widgets/cards/exercise_image_thumbnail.dart');

  group('exercise placeholder never guesses a movement', () {
    test('the fallback helper does not read the exercise name', () {
      expect(imageWidget.existsSync(), isTrue,
          reason: 'lib/widgets/exercise_image.dart moved — update this test');
      final src = imageWidget.readAsStringSync();

      final signature = RegExp(
        r'IconData\?\s+_fallbackIconForEquipment\s*\(([^)]*)\)',
      ).firstMatch(src);

      expect(signature, isNotNull,
          reason: '_fallbackIconForEquipment must exist and return IconData? '
              '(nullable = "I do not know", so the caller can stay neutral)');

      final params = signature!.group(1)!;
      expect(
        params.contains('exerciseName'),
        isFalse,
        reason: 'The placeholder icon must be derived ONLY from a real '
            'equipment value, never inferred from the exercise name. Taking '
            'exerciseName back as a parameter re-opens the rowing-boat / '
            'punching-figure bug.',
      );
    });

    test('no sport or activity icon is used as an exercise placeholder', () {
      final src = _codeOnly(imageWidget.readAsStringSync());
      // Icons that depict a PERSON performing an activity. Any of these as a
      // fallback claims a movement we have not verified.
      const forbidden = <String>[
        'Icons.rowing',
        'Icons.sports_handball',
        'Icons.directions_run',
        'Icons.directions_bike',
        'Icons.sports_gymnastics',
        'Icons.accessibility_new',
        'Icons.sports_mma',
        'Icons.pool',
      ];
      for (final icon in forbidden) {
        expect(
          src.contains(icon),
          isFalse,
          reason: '$icon depicts a person doing a specific activity. It must '
              'not be used as a media-less exercise placeholder — it asserts a '
              'movement. Use kExercisePlaceholderIcon instead.',
        );
      }
    });

    test('a neutral placeholder constant is exported and used', () {
      final src = imageWidget.readAsStringSync();
      expect(src.contains('const IconData kExercisePlaceholderIcon'), isTrue,
          reason: 'the neutral placeholder must be a single shared constant');
      expect(src.contains('?? \n            kExercisePlaceholderIcon') ||
          src.contains('?? kExercisePlaceholderIcon') ||
          RegExp(r'\?\?\s*\n?\s*kExercisePlaceholderIcon').hasMatch(src),
          isTrue,
          reason: 'the unknown-equipment case must fall through to the neutral '
              'placeholder');
    });

    test('the sub-32px thumbnail does not default to a dumbbell', () {
      expect(thumbnail.existsSync(), isTrue,
          reason: 'exercise_image_thumbnail.dart moved — update this test');
      final src = _codeOnly(thumbnail.readAsStringSync());
      // A dumbbell for every unknown exercise is the original
      // "every fallback is a dumbbell" problem, and is wrong for bodyweight.
      expect(
        RegExp(r'Icon\(\s*Icons\.fitness_center').hasMatch(src),
        isFalse,
        reason: 'the small-tile fallback must be kExercisePlaceholderIcon, not '
            'a dumbbell — it asserts equipment for bodyweight exercises too',
      );
      expect(src.contains('kExercisePlaceholderIcon'), isTrue);
    });
  });
}
