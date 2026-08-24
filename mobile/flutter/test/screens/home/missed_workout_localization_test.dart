/// Regression coverage for E2E row #333.
///
/// `MissedWorkout.missedDescription` / `.dayPossessive`
/// (`scheduling_repository.dart:58-73`) hardcoded English ('Yesterday',
/// '2 days ago', 'Monday'…'Sunday'), which then got interpolated into the
/// ALREADY-localized `{missedDescription}` / `{dayPossessive}` placeholders,
/// so a Spanish user read mixed-language text like
/// "Yesterday · 45min · 8 ejercicios". This asserts the widget-layer
/// `MissedWorkoutLocalization` extension produces real Spanish text instead.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/repositories/scheduling_repository.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/home/widgets/missed_workout_localization.dart';

MissedWorkout _workout({required int daysMissed, required DateTime scheduledDate}) =>
    MissedWorkout(
      id: 'w1',
      name: 'Full Body',
      type: 'full_body',
      difficulty: 'intermediate',
      scheduledDate: scheduledDate,
      durationMinutes: 45,
      daysMissed: daysMissed,
      canReschedule: true,
      exercisesCount: 8,
    );

class _Probe extends StatelessWidget {
  final MissedWorkout workout;
  final void Function(BuildContext context) onBuild;
  const _Probe({required this.workout, required this.onBuild});

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox.shrink();
  }
}

Future<String> _pumpAndGet(
  WidgetTester tester, {
  required Locale locale,
  required MissedWorkout workout,
  required String Function(BuildContext, MissedWorkout) extract,
}) async {
  late String result;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _Probe(
        workout: workout,
        onBuild: (context) => result = extract(context, workout),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('#333: missedDescription is localized, not hardcoded English', (tester) async {
    final yesterday = _workout(daysMissed: 1, scheduledDate: DateTime(2026, 8, 20));
    final twoDaysAgo = _workout(daysMissed: 2, scheduledDate: DateTime(2026, 8, 19));

    final esYesterday = await _pumpAndGet(
      tester,
      locale: const Locale('es'),
      workout: yesterday,
      extract: (c, w) => w.localizedMissedDescription(c),
    );
    expect(esYesterday, 'Ayer');
    expect(esYesterday, isNot(contains('Yesterday')));

    final esDaysAgo = await _pumpAndGet(
      tester,
      locale: const Locale('es'),
      workout: twoDaysAgo,
      extract: (c, w) => w.localizedMissedDescription(c),
    );
    expect(esDaysAgo, 'Hace 2 días');
    expect(esDaysAgo, isNot(contains('days ago')));
  });

  testWidgets('#333: dayPossessive weekday name is localized via intl, not a hardcoded English list', (tester) async {
    // 2026-08-20 is a Thursday.
    final workout = _workout(daysMissed: 1, scheduledDate: DateTime(2026, 8, 20));

    final esDay = await _pumpAndGet(
      tester,
      locale: const Locale('es'),
      workout: workout,
      extract: (c, w) => w.localizedDayPossessive(c),
    );
    expect(esDay, 'jueves');

    final enDay = await _pumpAndGet(
      tester,
      locale: const Locale('en'),
      workout: workout,
      extract: (c, w) => w.localizedDayPossessive(c),
    );
    expect(enDay, "Thursday's");
  });
}
