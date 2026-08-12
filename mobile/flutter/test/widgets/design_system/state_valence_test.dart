/// Guards the semantic state ramp (supports · neutral · strains).
///
/// The bug this file exists to prevent: colouring a deviation from the SIGN of
/// the number instead of the metric's valence, which paints a resting-heart-
/// rate reading 2% ABOVE baseline green ("up is good!") when an elevated
/// resting HR is exactly the reading you want flagged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/core/stats/state_valence.dart';

/// HSL saturation of a colour, 0..1. Used to prove the dark ramp is the
/// desaturated one.
double _saturation(Color c) => HSLColor.fromColor(c).saturation;

Widget _host({required bool dark, required Widget child}) => MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('valence resolution — colour follows valence, never the sign', () {
    test('inverted metric ABOVE baseline strains (the exact bug guarded)', () {
      // Resting HR declares lower-is-better.
      expect(MetricValence.forKey('resting_heart_rate'), GoodDirection.lower);

      final state = SemanticState.resolve(
        valence: MetricValence.forKey('resting_heart_rate'),
        deviation: 2.0, // +2% vs the 30-day baseline
      );

      expect(
        state,
        SemanticState.strains,
        reason: 'an elevated resting HR strains recovery; sign alone would '
            'have called +2% an improvement',
      );
      // ...and the mirror case still supports, so this is not a blanket invert.
      expect(
        SemanticState.resolve(
          valence: MetricValence.forKey('resting_heart_rate'),
          deviation: -2.0,
        ),
        SemanticState.supports,
      );
    });

    test('normal metric ABOVE baseline supports', () {
      expect(MetricValence.forKey('steps'), GoodDirection.higher);
      expect(
        SemanticState.resolve(
          valence: MetricValence.forKey('steps'),
          deviation: 2.0,
        ),
        SemanticState.supports,
      );
      expect(
        SemanticState.resolve(
          valence: MetricValence.forKey('steps'),
          deviation: -12.0,
        ),
        SemanticState.strains,
      );
    });

    test('the SAME +2% deviation resolves opposite for steps vs resting HR',
        () {
      const deviation = 2.0;
      final steps = SemanticState.resolve(
          valence: MetricValence.forKey('steps'), deviation: deviation);
      final rhr = SemanticState.resolve(
          valence: MetricValence.forKey('resting_heart_rate'),
          deviation: deviation);
      expect(steps, SemanticState.supports);
      expect(rhr, SemanticState.strains);
      expect(steps.colorFor(true), isNot(rhr.colorFor(true)));
    });

    test('weight and calories have no goal → neutral in either direction', () {
      for (final key in ['weight', 'body_weight', 'calories', 'calories_eaten']) {
        expect(MetricValence.forKey(key), GoodDirection.neutral,
            reason: '$key is goal-dependent (a cut and a bulk disagree)');
        for (final deviation in [-4.0, 4.0]) {
          expect(
            SemanticState.resolve(
                valence: MetricValence.forKey(key), deviation: deviation),
            SemanticState.neutral,
            reason: '$key must never be tinted, in either direction',
          );
        }
      }
    });

    test('an undeclared metric is neutral, never a guessed tint', () {
      expect(MetricValence.forKey('some_custom_user_metric'),
          GoodDirection.neutral);
    });

    test('key lookup normalises camelCase and spacing', () {
      expect(MetricValence.forKey('restingHeartRate'), GoodDirection.lower);
      expect(MetricValence.forKey('Resting Heart Rate'), GoodDirection.lower);
      expect(MetricValence.forKey('respiratory-rate'), GoodDirection.lower);
      expect(MetricValence.forKey('HRV'), GoodDirection.higher);
      expect(MetricValence.forKey('skinTemp'), GoodDirection.lower);
      expect(MetricValence.forKey('stress'), GoodDirection.lower);
    });

    test('deviations inside the noise floor read neutral (on baseline)', () {
      expect(
        SemanticState.resolve(
            valence: GoodDirection.higher, deviation: 0.02, epsilon: 0.05),
        SemanticState.neutral,
      );
      expect(
        SemanticState.resolve(valence: GoodDirection.higher, deviation: 0),
        SemanticState.neutral,
      );
    });

    test('backend direction strings map onto the ramp vocabulary', () {
      expect(MetricValence.fromBackendDirection('high_bad'),
          GoodDirection.lower);
      expect(
          MetricValence.fromBackendDirection('low_bad'), GoodDirection.higher);
      expect(
          MetricValence.fromBackendDirection('either'), GoodDirection.neutral);
    });
  });

  group('the ramp itself', () {
    test('dark rungs are measurably less saturated than light rungs', () {
      final darkSupports = _saturation(AppColors.stateSupports);
      final lightSupports = _saturation(AppColorsLight.stateSupports);
      final darkStrains = _saturation(AppColors.stateStrains);
      final lightStrains = _saturation(AppColorsLight.stateStrains);

      // Saturated colour vibrates against a near-black surface, so the dark
      // theme deliberately carries the pastel end of each pair.
      expect(darkSupports, lessThan(lightSupports),
          reason: 'dark supports S=$darkSupports vs light S=$lightSupports');
      expect(darkStrains, lessThan(lightStrains),
          reason: 'dark strains S=$darkStrains vs light S=$lightStrains');

      // Not a rounding-error difference — at least 20% relative desaturation.
      expect(darkSupports, lessThan(lightSupports * 0.8));
      expect(darkStrains, lessThan(lightStrains * 0.8));
    });

    test('supports and strains are distinct in both themes, neutral is muted',
        () {
      expect(SemanticState.supports.colorFor(true),
          isNot(SemanticState.strains.colorFor(true)));
      expect(SemanticState.supports.colorFor(false),
          isNot(SemanticState.strains.colorFor(false)));
      expect(SemanticState.neutral.colorFor(true), AppColors.textMuted);
      expect(SemanticState.neutral.colorFor(false), AppColorsLight.textMuted);
    });

    test('the ramp is not the alert palette', () {
      // success/warning/error are event outcomes; a baseline deviation is a
      // state. Reusing the alert palette made every ordinary day look alarming.
      expect(AppColors.stateSupports, isNot(AppColors.success));
      expect(AppColors.stateStrains, isNot(AppColors.warning));
      expect(AppColors.stateStrains, isNot(AppColors.error));
      expect(AppColorsLight.stateSupports, isNot(AppColorsLight.success));
      expect(AppColorsLight.stateStrains, isNot(AppColorsLight.warning));
    });

    // Separate tests per brightness on purpose: MaterialApp lerps its theme
    // through AnimatedTheme, so flipping brightness inside one pump sequence
    // reads a half-interpolated palette.
    testWidgets('resolves the dark rung under a dark theme', (tester) async {
      late Color seen;
      await tester.pumpWidget(_host(
        dark: true,
        child: Builder(builder: (context) {
          seen = SemanticState.supports.color(context);
          return const SizedBox.shrink();
        }),
      ));
      expect(seen, AppColors.stateSupports);
    });

    testWidgets('resolves the light rung under a light theme', (tester) async {
      late Color seen;
      await tester.pumpWidget(_host(
        dark: false,
        child: Builder(builder: (context) {
          seen = SemanticState.strains.color(context);
          return const SizedBox.shrink();
        }),
      ));
      expect(seen, AppColorsLight.stateStrains);
    });
  });

  group('DeviationLine — colour is never the sole encoding (WCAG 1.4.1)', () {
    Future<Color> pumpAndReadTint(
      WidgetTester tester, {
      required GoodDirection valence,
      required double deviation,
      required String label,
      bool dark = true,
    }) async {
      await tester.pumpWidget(_host(
        dark: dark,
        child: DeviationLine(
          valence: valence,
          deviation: deviation,
          label: label,
        ),
      ));
      final text = tester.widget<Text>(find.text(label));
      return text.style!.color!;
    }

    testWidgets('every state renders its text label, not colour alone',
        (tester) async {
      const cases = <(GoodDirection, double, String)>[
        (GoodDirection.higher, 6, '6 pts above your 30-day baseline'),
        (GoodDirection.higher, -12, '12% below your 30-day baseline'),
        (GoodDirection.lower, 2, '2% above baseline'),
        (GoodDirection.neutral, 0, 'On your 30-day baseline'),
      ];
      for (final (valence, deviation, label) in cases) {
        await tester.pumpWidget(_host(
          dark: true,
          child: DeviationLine(
            valence: valence,
            deviation: deviation,
            label: label,
          ),
        ));
        expect(find.text(label), findsOneWidget,
            reason: 'the sentence must always ship with the tint');
      }
    });

    testWidgets('the dot is tinted by valence + sign, not sign alone',
        (tester) async {
      // Same "+2% vs baseline", opposite metrics, opposite rungs.
      final stepsTint = await pumpAndReadTint(
        tester,
        valence: MetricValence.forKey('steps'),
        deviation: 2,
        label: '2% above your 30-day baseline',
      );
      final rhrTint = await pumpAndReadTint(
        tester,
        valence: MetricValence.forKey('resting_heart_rate'),
        deviation: 2,
        label: '2% above your 30-day baseline',
      );

      expect(stepsTint, AppColors.stateSupports);
      expect(rhrTint, AppColors.stateStrains);
    });

    testWidgets('a neutral metric renders the sentence untinted',
        (tester) async {
      final tint = await pumpAndReadTint(
        tester,
        valence: MetricValence.forKey('weight'),
        deviation: -1.4,
        label: '1.4 lb below your 30-day baseline',
      );
      expect(tint, AppColors.stateNeutral);
    });

    testWidgets('the dot carries the same colour as its sentence',
        (tester) async {
      const label = '12% below your 30-day baseline';
      await tester.pumpWidget(_host(
        dark: true,
        child: const DeviationLine(
          valence: GoodDirection.higher,
          deviation: -12,
          label: label,
        ),
      ));
      final dot = tester.widget<Container>(
        find.descendant(
          of: find.byType(DeviationLine),
          matching: find.byType(Container),
        ),
      );
      final decoration = dot.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, AppColors.stateStrains);
      expect(tester.widget<Text>(find.text(label)).style!.color,
          AppColors.stateStrains);
    });
  });
}
