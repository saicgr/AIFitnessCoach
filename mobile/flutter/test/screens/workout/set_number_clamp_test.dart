// E2E register #47 — "SET 3 OF 2" after both sets of a 2-set exercise.
//
// The set-count index (`completedCount + 1`, or the rest-controller's
// `completed.length + 1`) points one PAST the plan the instant the last set
// of an exercise is logged. `easy_exercise_header.dart` already guards this
// (`currentSet > totalSets ? 'ALL … DONE' : 'SET … OF …'`), but
// `FuturisticSetCard` and `EasyRestOverlay` had no such guard and would
// render an impossible "SET 3 OF 2". This gate asserts no widget renders
// n > m, across every render site that carries a set-number/total-sets pair.
//
// Negative-tested: reverting either guard (feeding the raw unclamped number
// straight into the "SET n OF m" string) reproduces "SET 3 OF 2" and fails
// this test; see the sibling commit message / PR diff for the before/after.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workout/widgets/futuristic_set_card.dart';
import 'package:fitwiz/screens/workout/easy/widgets/easy_rest_overlay.dart';
import 'package:fitwiz/data/models/exercise.dart';

void main() {
  group('FuturisticSetCard — set-number clamp (#47)', () {
    Widget buildCard({required int currentSetNumber, required int totalSets}) {
      return MaterialApp(
        theme: ThemeData.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: supportedAppLocales,
        home: Scaffold(
          body: FuturisticSetCard(
            exerciseName: 'Bird Dog',
            currentSetNumber: currentSetNumber,
            totalSets: totalSets,
            weight: 0,
            reps: 10,
            onWeightChanged: (_) {},
            onRepsChanged: (_) {},
            onComplete: () {},
            completedSets: const [],
            isLastSet: true,
            setType: 'working',
          ),
        ),
      );
    }

    testWidgets('mid-plan: shows "SET n OF m"', (tester) async {
      await tester.pumpWidget(
          buildCard(currentSetNumber: 1, totalSets: 2));
      expect(find.text('SET 1 OF 2'), findsOneWidget);
    });

    testWidgets(
        'both sets of a 2-set exercise done: never renders "SET 3 OF 2"',
        (tester) async {
      await tester.pumpWidget(
          buildCard(currentSetNumber: 3, totalSets: 2));

      expect(find.textContaining('SET 3 OF'), findsNothing);
      expect(find.text('ALL 2 SETS DONE'), findsOneWidget);
    });
  });

  group('EasyRestOverlay — next-set-number clamp (#47)', () {
    WorkoutExercise exercise() =>
        const WorkoutExercise(id: 'ex1', nameValue: 'Bird Dog', sets: 2, reps: 10);

    Widget buildOverlay({required int nextSetNumber, required int totalSets}) {
      return ProviderScope(
        child: MaterialApp(
          theme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
          home: EasyRestOverlay(
            initialSeconds: 30,
            remainingStream: const Stream<int>.empty(),
            nextExercise: exercise(),
            nextSetNumber: nextSetNumber,
            totalSets: totalSets,
            nextTargetWeightKg: 0,
            nextTargetReps: 10,
            useKg: true,
            onSkip: () {},
            onDone: () {},
          ),
        ),
      );
    }

    testWidgets('mid-plan: shows "SET n/m"', (tester) async {
      await tester.pumpWidget(buildOverlay(nextSetNumber: 2, totalSets: 2));
      await tester.pump();
      expect(find.textContaining('SET 2/2'), findsOneWidget);
    });

    testWidgets('resolver hands an out-of-range next set: clamps, never "SET 3/2"',
        (tester) async {
      await tester.pumpWidget(buildOverlay(nextSetNumber: 3, totalSets: 2));
      await tester.pump();

      expect(find.textContaining('SET 3/2'), findsNothing);
      expect(find.textContaining('SET 2/2'), findsOneWidget);
    });
  });
}
