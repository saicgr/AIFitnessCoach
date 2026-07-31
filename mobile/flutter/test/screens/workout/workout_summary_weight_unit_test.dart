// E2E register #18 (long tail) — workout_summary_advanced.dart and
// workout_summary_general.dart hard-converted lift weights to lb with a
// hardcoded ' lb' suffix at ~47 sites (one site had already been fixed —
// see the `_VolumeBreakdownSection` comment in workout_summary_advanced.dart
// — the rest were not). A kg user reading their Summary/Advanced tab saw
// pound numbers everywhere: PR weight, best-set weight, estimated 1RM.
//
// This test renders both summary widgets under `useKgForWorkoutProvider`
// true and false and asserts the displayed weight text follows the setting.
// Negative-tested per the task: reintroducing a hardcoded
// `(weightKg * 2.20462).toStringAsFixed(0)} lb` in either fixed call site
// makes the corresponding assertion below fail (verified manually, then
// reverted — see the PR/session notes for the before/after run).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/core/providers/user_provider.dart' show useKgForWorkoutProvider;
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workout/workout_summary_advanced.dart';
import 'package:fitwiz/screens/workout/workout_summary_general.dart';

void main() {
  group('WorkoutSummaryGeneral — PR weight follows useKgForWorkoutProvider (#18)', () {
    // 100 kg is a "clean" AI/backend value (multiple of 2.5), so
    // WeightUtils.formatWorkoutWeight snaps it via the gym-standard lookup
    // table rather than raw math: 100 kg -> exactly "225 lb" (not "220.5").
    final summaryData = WorkoutSummaryResponse(
      workout: const {'name': 'Push Day'}, // no 'id' -> no recap network fetch
      completionMethod: 'marked_done', // skip the AI recap card build path
      personalRecords: const [
        PersonalRecordInfo(
          exerciseName: 'Bench Press',
          weightKg: 100,
          reps: 5,
          estimated1rmKg: 115,
        ),
      ],
    );

    Widget buildGeneral({required bool useKg}) {
      return ProviderScope(
        overrides: [useKgForWorkoutProvider.overrideWithValue(useKg)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
          home: Scaffold(
            body: WorkoutSummaryGeneral(data: summaryData, metadata: null),
          ),
        ),
      );
    }

    testWidgets('useKg=true renders the PR weight in kg', (tester) async {
      await tester.pumpWidget(buildGeneral(useKg: true));
      await tester.pumpAndSettle();

      expect(find.textContaining('100 kg x 5'), findsOneWidget);
      expect(find.textContaining('225 lb'), findsNothing);
    });

    testWidgets('useKg=false renders the PR weight in lb', (tester) async {
      await tester.pumpWidget(buildGeneral(useKg: false));
      await tester.pumpAndSettle();

      expect(find.textContaining('225 lb x 5'), findsOneWidget);
      expect(find.textContaining('100 kg'), findsNothing);
    });
  });

  group('WorkoutSummaryAdvanced — Estimated 1RM follows useKgForWorkoutProvider (#18)', () {
    // A single-rep set: the Epley estimate is just the lifted weight itself
    // (100 kg), so the expected snapped conversion is exactly "225 lb".
    final summaryData = WorkoutSummaryResponse(
      workout: const {'name': 'Push Day'}, // no 'id' -> no recap network fetch
      setLogs: const [
        SetLogInfo(
          exerciseName: 'Bench Press',
          setNumber: 1,
          repsCompleted: 1,
          weightKg: 100,
          setType: 'working',
        ),
      ],
    );

    Widget buildAdvanced({required bool useKg}) {
      return ProviderScope(
        overrides: [useKgForWorkoutProvider.overrideWithValue(useKg)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
          home: Scaffold(
            body: WorkoutSummaryAdvanced(data: summaryData, metadata: null),
          ),
        ),
      );
    }

    testWidgets('useKg=true renders the estimated 1RM in kg', (tester) async {
      await tester.pumpWidget(buildAdvanced(useKg: true));
      await tester.pumpAndSettle();

      // Estimated 1RM lives in the collapsed "More details" section.
      await tester.tap(find.text('More details'));
      await tester.pumpAndSettle();

      expect(find.textContaining('100 kg'), findsWidgets);
      expect(find.textContaining('225 lb'), findsNothing);
    });

    testWidgets('useKg=false renders the estimated 1RM in lb', (tester) async {
      await tester.pumpWidget(buildAdvanced(useKg: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('More details'));
      await tester.pumpAndSettle();

      expect(find.textContaining('225 lb'), findsWidgets);
      expect(find.textContaining('100 kg'), findsNothing);
    });
  });
}
