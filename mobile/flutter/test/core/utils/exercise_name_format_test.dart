/// Unit tests for [toExerciseTitleCase] (E2E #48 — client-side exercise
/// title-casing was still broken after the DB-half migration 2431 landed).
///
/// capWord() used to split only on whitespace and only capitalize
/// index 0 of each token, so:
///   - a letter immediately after '(' was never capitalized
///   - a missing space before '(' was never inserted
///   - re-running the formatter on already-correct output re-lowercased
///     the letter after '(' (not idempotent)
///
/// These three cases are reproduced verbatim from the original E2E #48
/// finding.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/utils/exercise_name_format.dart';

void main() {
  group('toExerciseTitleCase — E2E #48', () {
    test('capitalizes the letter after "(" instead of leaving it lowercase', () {
      // E2E #48: exact reproduction string from the original finding.
      expect(
        toExerciseTitleCase('cable pulldown (pro lat bar)'),
        'Cable Pulldown (Pro Lat Bar)',
      );
    });

    test('inserts the missing space before "(" when it runs on from the previous word', () {
      // E2E #48: exact reproduction string from the original finding.
      expect(
        toExerciseTitleCase('barbell full squat(back)'),
        'Barbell Full Squat (Back)',
      );
    });

    test('is idempotent on already-correctly-cased input', () {
      // E2E #48: previously, re-formatting correct output re-lowercased the
      // parenthetical ("(Pro Lat Bar)" -> "(pro Lat Bar)").
      const alreadyCorrect = 'Cable Pulldown (Pro Lat Bar)';
      expect(toExerciseTitleCase(alreadyCorrect), alreadyCorrect);
    });

    test('still handles plain multi-word names without parentheses', () {
      expect(toExerciseTitleCase('wide push ups bodyweight'), 'Wide Push Ups Bodyweight');
    });

    test('still lowercases small words except in first position', () {
      expect(toExerciseTitleCase('bench press with bands'), 'Bench Press with Bands');
    });

    test('still uppercases known acronyms', () {
      expect(toExerciseTitleCase('db bicep curl'), 'DB Bicep Curl');
    });

    test('still capitalizes each hyphenated segment', () {
      expect(toExerciseTitleCase('pull-up'), 'Pull-Up');
    });

    test('still passes through digit-prefixed tokens unchanged', () {
      expect(toExerciseTitleCase('21s bicep curl'), '21s Bicep Curl');
    });
  });
}
