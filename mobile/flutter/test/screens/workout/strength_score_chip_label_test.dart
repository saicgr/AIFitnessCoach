// E2E register #135 — an unlabeled glowing "8" hexagon with no unit, scale
// or label in the exercise-card header chip-row.
//
// `HexagonBadge`'s own docstring says its design assumes 3-digit values
// (the "232"/"252" chip), so a bare single-digit per-exercise strength score
// read as broken or a 1-10 rating. `_buildStrengthScoreChip`
// (expanded_exercise_card_ui_1.dart) now renders a labeled pill — "STR n"
// (+ "· Level" when known) — matching the row's sibling chips
// (_buildFinisherChip / _buildMovementCategoryChip) instead of a bare glyph.
//
// Negative-tested: reverting to the bare `HexagonBadge` (value only, no "STR"
// prefix) reproduces the bare "8" and fails this test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/core/providers/user_provider.dart' show useKgForWorkoutProvider;
import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/data/models/exercise_strength_score.dart';
import 'package:fitwiz/data/providers/exercise_strength_score_provider.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workout/widgets/expanded_exercise_card.dart';

void main() {
  testWidgets(
      '#135 strength-score chip is labeled ("STR n"), never a bare number',
      (tester) async {
    final exercise = WorkoutExercise(
      id: 'ex1',
      nameValue: 'Bird Dog',
      sets: 3,
      reps: 10,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Avoid the Supabase-backed auth chain entirely for this render-only
          // assertion — the chip's label logic doesn't depend on units.
          useKgForWorkoutProvider.overrideWithValue(false),
          exerciseStrengthScoreProvider('Bird Dog').overrideWith(
            (ref) async => const ExerciseStrengthScore(
              exerciseName: 'Bird Dog',
              hasData: true,
              score: 8,
              level: 'advanced',
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpandedExerciseCard(
                exercise: exercise,
                index: 0,
                workoutId: 'w1',
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      ),
    );

    // Let the FutureProvider resolve.
    await tester.pump();
    await tester.pump();

    // The chip must carry a unit/label — never a bare "8".
    expect(find.text('8'), findsNothing);
    expect(find.textContaining('STR 8'), findsOneWidget);
  });
}
