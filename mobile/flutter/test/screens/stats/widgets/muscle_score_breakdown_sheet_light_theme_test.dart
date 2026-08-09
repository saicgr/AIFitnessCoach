/// Regression gate for the light-mode "black block" bug: the per-exercise
/// contribution bar's track fill was painted with `AppColors.hairlineStrong`
/// (a dark-theme literal) regardless of the active theme, so in light mode
/// the thin progress track rendered as a near-black bar on an otherwise
/// white sheet instead of the pale hairline the design intends.
///
/// `MuscleScoreBreakdownSheet` (and its private `_ExerciseRow`) now resolve
/// every fill/border/text color through `ThemeColors.of(context)`, which
/// branches on the theme's actual brightness (`AppColorsLight.*` in light
/// mode). This test pumps the sheet under `ThemeData.light()` with a mocked
/// API response and asserts the RESOLVED decoration color of the track —
/// not just that the widget renders — so a regression back to a raw
/// `AppColors.*` literal fails the assertion instead of silently
/// reintroducing the bug.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/stats/widgets/muscle_score_breakdown_sheet.dart';

import '../../../helpers/test_helpers.dart';

Map<String, dynamic> _breakdownJson() => {
      'header': {
        'strength_score': 72,
        'strength_level': 'Advanced',
        'best_exercise_name': 'Barbell Bench Press',
        'best_estimated_1rm_kg': 100,
        'trend': 'improving',
      },
      'exercises': [
        {
          'exercise_name': 'Barbell Bench Press',
          'contribution_pct': 45.0,
          'e1rm': 100.0,
        },
      ],
    };

Widget _harness(MockApiClient api) {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(api),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedAppLocales,
      home: const Scaffold(
        body: MuscleScoreBreakdownSheet(muscleGroup: 'chest'),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient api;

  setUp(() {
    setUpMocks();
    api = MockApiClient();
    when(() => api.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/scores/breakdown/chest'),
          statusCode: 200,
          data: _breakdownJson(),
        ));
  });

  group('MuscleScoreBreakdownSheet in light theme', () {
    testWidgets(
        'exercise contribution track resolves a light-theme fill, distinct '
        'from the dark-theme literal', (tester) async {
      await tester.pumpWidget(_harness(api));
      // Let the async _load() (mocked API call) resolve and rebuild.
      await tester.pumpAndSettle();

      // Appears twice: once as the header's "Best Lift" value, once as the
      // contribution row's exercise name.
      expect(find.text('Barbell Bench Press'), findsNWidgets(2));

      // The contribution track is built inside a LayoutBuilder as a Stack of
      // two 2px-tall Containers with `BorderRadius.circular(1)` — a shape
      // used nowhere else in this widget, so it uniquely identifies the
      // track (background) and fill (accent) pair.
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).color != null &&
              (c.decoration as BoxDecoration).borderRadius ==
                  BorderRadius.circular(1))
          .toList();

      expect(containers.length, 2,
          reason: 'Expected exactly the track + fill Containers.');

      // Find the background track: the one whose BoxDecoration color is
      // NOT the accent color (black in monochrome light theme) — i.e. the
      // hairline track fill.
      final trackFill = containers
          .map((c) => (c.decoration as BoxDecoration).color!)
          .where((color) => color != AppColorsLight.accent)
          .toList();

      expect(trackFill, isNotEmpty,
          reason: 'Expected to find the hairline progress-track fill.');

      for (final fill in trackFill) {
        // Must NOT be the dark-theme literal this bug regresses to.
        expect(fill, isNot(equals(AppColors.hairlineStrong)),
            reason: 'Progress-track fill must not be the dark-theme '
                'literal (AppColors.hairlineStrong) while the active '
                'theme is light.');
      }

      // At least one non-accent fill must resolve to the real light-theme
      // value `ThemeColors.hairlineStrong` paints in light mode (inlined
      // there rather than added to `AppColorsLight` — see that getter's
      // doc comment for why the light hairline literal isn't a palette
      // member).
      const lightHairlineStrong = Color(0xFFD4D4D8);
      expect(trackFill, contains(lightHairlineStrong));

      // Contrast is real: the light hairline track must be meaningfully
      // brighter than the near-black dark-theme literal it used to paint.
      final lightLuminance = lightHairlineStrong.computeLuminance();
      final darkLiteralLuminance = AppColors.hairlineStrong.computeLuminance();
      expect(lightLuminance - darkLiteralLuminance, greaterThan(0.5),
          reason: 'The resolved light-theme track must be dramatically '
              'brighter than the dark-theme literal it replaces — a '
              'near-equal pair means the bug is still effectively present.');
    });
  });
}
