import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workout/easy/widgets/easy_rest_overlay.dart';
import 'package:fitwiz/screens/workout/widgets/inline_rest_row.dart';

Widget _host({
  required Widget child,
  required double width,
  required Locale locale,
  required double scale,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(scale),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  );
}

const _widths = [402.0, 393.0, 375.0, 320.0];
const _scales = [1.0, 1.3, 1.35, 1.5];
const _locales = [Locale('en'), Locale('de'), Locale('id'), Locale('th')];

void main() {
  testWidgets('InlineRestRow never overflows at any width/locale/scale',
      (tester) async {
    final failures = <String>[];
    for (final w in _widths) {
      for (final s in _scales) {
        for (final l in _locales) {
          await tester.pumpWidget(_host(
            width: w,
            locale: l,
            scale: s,
            child: InlineRestRow(
              restDurationSeconds: 90,
              onRestComplete: () {},
              onSkipRest: () {},
              onAdjustTime: (_) {},
              onRateSet: (_) {},
              onAddNote: (_) {},
              onShowRpeInfo: () {},
            ),
          ));
          await tester.pump();
          final ex = tester.takeException();
          if (ex != null) failures.add('w=$w s=$s l=${l.languageCode} -> $ex');
        }
      }
    }
    // ignore: avoid_print
    print('InlineRestRow failures: ${failures.length}');
    for (final f in failures) {
      // ignore: avoid_print
      print('  $f');
    }
    expect(failures, isEmpty);
  });

  testWidgets('EasyRestOverlay never overflows at any width/locale/scale',
      (tester) async {
    final failures = <String>[];
    for (final w in _widths) {
      for (final s in _scales) {
        for (final l in _locales) {
          final ctl = StreamController<int>.broadcast();
          addTearDown(ctl.close);
          await tester.pumpWidget(_host(
            width: w,
            locale: l,
            scale: s,
            child: SizedBox(
              height: 900,
              child: EasyRestOverlay(
                initialSeconds: 60,
                remainingStream: ctl.stream,
                nextExercise: WorkoutExercise(
                  nameValue: 'Dumbbell Romanian Deadlift',
                  sets: 4,
                  reps: 10,
                ),
                nextSetNumber: 3,
                totalSets: 4,
                nextTargetWeightKg: 102.5,
                nextTargetReps: 12,
                useKg: false,
                onSkip: () {},
                onDone: () {},
                onAddTime: () {},
                onSubtractTime: () {},
                onPause: () {},
                onLogWater: () {},
              ),
            ),
          ));
          await tester.pump();
          final ex = tester.takeException();
          if (ex != null) failures.add('w=$w s=$s l=${l.languageCode} -> $ex');
        }
      }
    }
    // ignore: avoid_print
    print('EasyRestOverlay failures: ${failures.length}');
    for (final f in failures) {
      // ignore: avoid_print
      print('  $f');
    }
    expect(failures, isEmpty);
  });
}
