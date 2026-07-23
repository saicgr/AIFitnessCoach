import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/nutrition.dart';
import 'package:fitwiz/shareables/adapters/nutrition_adapter.dart';
import 'package:fitwiz/shareables/shareable_data.dart';
import 'package:fitwiz/shareables/widgets/macro_viz.dart';

/// A [FoodLog] whose protein macro is genuinely UNKNOWN (backend stored SQL
/// NULL) while calories + the other macros are known. This is the exact shape
/// the fabricated-"0 g" share card came from.
FoodLog _unknownProteinLog({
  String id = 'log-1',
  double? proteinG,
  double? carbsG = 55,
  double? fatG = 22,
}) =>
    FoodLog(
      id: id,
      userId: 'u1',
      mealType: 'lunch',
      loggedAt: DateTime(2026, 7, 21, 12, 30),
      createdAt: DateTime(2026, 7, 21, 12, 30),
      totalCalories: 620,
      proteinG: proteinG, // null == unknown
      carbsG: carbsG,
      fatG: fatG,
      foodItems: const [
        FoodItem(name: 'Mystery bowl', calories: 620),
      ],
    );

void main() {
  const accent = Color(0xFF06B6D4);

  group('shareableMacroGrams helper', () {
    test('renders "—" for a genuinely-unknown macro, never "0g"', () {
      expect(shareableMacroGrams(null), '—');
      expect(shareableMacroGramsValue(null), '—');
    });

    test('renders whole grams for a known macro', () {
      expect(shareableMacroGrams(48.4), '48g');
      expect(shareableMacroGrams(0), '0g'); // a KNOWN zero is still "0g"
      expect(shareableMacroGramsValue(48.4), '48');
    });
  });

  group('NutritionAdapter — single-item / single-meal null propagation', () {
    test('fromFoodLog carries the unknown macro as null (not 0)', () {
      final s = NutritionAdapter.fromFoodLog(
        _unknownProteinLog(),
        accent: accent,
      );
      expect(s, isNotNull);
      final n = s!.nutrition!;
      // The unknown macro stays null so the card can render "—".
      expect(n.proteinG, isNull);
      expect(shareableMacroGrams(n.proteinG), '—');
      // Known macros still carry their real value.
      expect(n.carbsG, 55);
      expect(n.fatG, 22);
      expect(n.calories, 620);
    });

    test('a one-log fromMeal is a single-dish card and propagates null', () {
      final s = NutritionAdapter.fromMeal(
        [_unknownProteinLog()],
        accent: accent,
      );
      expect(s?.nutrition?.proteinG, isNull);
    });

    test('a one-log fromFoodLogs propagates null', () {
      final s = NutritionAdapter.fromFoodLogs(
        [_unknownProteinLog()],
        accent: accent,
      );
      expect(s?.nutrition?.proteinG, isNull);
    });
  });

  group('NutritionAdapter — aggregates keep sum-of-known (never "—")', () {
    test(
        'fromFoodLogs across a day: one unknown-protein log does not null the '
        'whole-day protein total', () {
      final s = NutritionAdapter.fromFoodLogs(
        [
          _unknownProteinLog(id: 'a', proteinG: null),
          _unknownProteinLog(id: 'b', proteinG: 30),
        ],
        accent: accent,
      );
      final n = s!.nutrition!;
      // Sum-of-known: the null log contributes 0, the known 30 survives — the
      // aggregate is a non-null total, NOT "—".
      expect(n.proteinG, 30);
      expect(shareableMacroGrams(n.proteinG), '30g');
    });

    test('a multi-log fromMeal sums the known macros to a non-null total', () {
      final s = NutritionAdapter.fromMeal(
        [
          _unknownProteinLog(id: 'a', proteinG: null),
          _unknownProteinLog(id: 'b', proteinG: 25),
        ],
        accent: accent,
      );
      expect(s!.nutrition!.proteinG, 25);
    });
  });

  group('MacroViz renders "—" for an unknown macro', () {
    // The visual heart of food sharing — every gram label routes through it.
    // progressBars renders each macro value as a standalone Text, so the
    // "—" placeholder is directly findable.
    testWidgets(
        'progressBars shows "—" for the unknown protein, "22g" for fat',
        (tester) async {
      const nutrition = ShareableNutrition(
        calories: 620,
        proteinG: null, // unknown
        carbsG: 55,
        fatG: 22,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: MacroViz(
                  nutrition: nutrition,
                  style: MacroVizStyle.progressBars,
                  accentColor: accent,
                ),
              ),
            ),
          ),
        ),
      );
      // The unknown protein renders "—"; known macros render their grams.
      expect(find.text('—'), findsOneWidget);
      expect(find.text('22g'), findsOneWidget); // fat, known
      expect(find.text('55g'), findsOneWidget); // carbs, known
      // Never a fabricated "0g" for the unknown macro.
      expect(find.text('0g'), findsNothing);
    });

    testWidgets('pills style shows "—" for the unknown macro', (tester) async {
      const nutrition = ShareableNutrition(
        calories: 620,
        proteinG: null,
        carbsG: 55,
        fatG: 22,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MacroViz(
                nutrition: nutrition,
                style: MacroVizStyle.pills,
                accentColor: accent,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('—'), findsWidgets);
      expect(find.textContaining('0g'), findsNothing);
    });
  });
}
