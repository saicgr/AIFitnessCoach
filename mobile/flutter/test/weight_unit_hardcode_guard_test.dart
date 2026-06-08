// Regression guard for the workout weight-unit display bug.
//
// Workout lifting weights are stored in kg and MUST be rendered through the
// user's workout weight-unit preference (see WeightUtils.formatWorkoutWeight /
// useKgForWorkoutProvider). A user who logs in lbs once saw PRs/trophies/sets
// shown in kg because these surfaces hardcoded a "kg"/"lbs" suffix or did an
// ad-hoc `* 2.20462` conversion instead of honoring the preference.
//
// This test fails if any of the cleaned PR / trophy / active-set surfaces
// reintroduces a hardcoded unit label or an ad-hoc conversion. Lines that go
// through the sanctioned helpers (WeightUtils, useKg/displayInLbs ternaries,
// workoutUnitLabel/getUnitLabel) are allowed.
//
// Scope is intentionally the surfaces fixed for the reported bug. Broader
// workout-weight displays (advanced summary, rest-timer overlays, charts) are
// a tracked follow-up; add them here as they adopt the chokepoint.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Files that have been migrated to WeightUtils.formatWorkoutWeight and must
  // stay free of hardcoded workout-weight units.
  const guardedFiles = <String>[
    'lib/screens/workout/widgets/trophies_earned_sheet.dart',
    'lib/screens/workout/widgets/pr_details_sheet.dart',
    'lib/screens/workout/widgets/pr_inline_celebration.dart',
    'lib/screens/workout/widgets/next_set_preview_card.dart',
    'lib/screens/workout/widgets/expandable_summary_exercise_card.dart',
  ];

  // A hardcoded unit suffix right after a string interpolation/value, e.g.
  // `} kg'`, `}kg'`, `} lbs'`, or an ad-hoc kg->lbs factor `* 2.20462`.
  final hardcodedUnit = RegExp(r"\}\s?(kg|lbs?)'");
  final adHocConversion = RegExp(r'\*\s?2\.20[0-9]|2\.20[0-9]\s?\*');

  // Tokens that mark a line as legitimately unit-aware.
  final allowed = RegExp(
      r'useKg|WeightUtils|workoutUnitLabel|getUnitLabel|displayInLbs|formatWorkoutWeight');

  test('guarded workout-weight surfaces never hardcode a unit label', () {
    final violations = <String>[];

    for (final relPath in guardedFiles) {
      final file = File(relPath);
      expect(file.existsSync(), isTrue,
          reason: 'Guarded file missing (renamed?): $relPath');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (allowed.hasMatch(line)) continue; // unit-aware → fine
        if (hardcodedUnit.hasMatch(line) || adHocConversion.hasMatch(line)) {
          violations.add('$relPath:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Hardcoded workout-weight unit(s) found. Use '
          'WeightUtils.formatWorkoutWeight(kg, useKg: ...) instead:\n'
          '${violations.join('\n')}',
    );
  });
}
