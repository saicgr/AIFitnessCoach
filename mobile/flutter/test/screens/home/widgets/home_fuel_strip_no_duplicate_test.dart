/// Regression test for Home → FUEL strip (E2E row 195, LOW).
///
/// With no calorie target configured, the strip printed the same number
/// twice on one line: "FUEL / 648 logged" on the left and a display-size
/// "648 KCAL LOGGED" on the right — the whole right side (the strip's most
/// prominent element) carried zero information beyond what the left side
/// already said.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/nutrition.dart'
    show DailyNutritionSummary, FoodLog, FoodItem;
import 'package:fitwiz/data/providers/nutrition_preferences_provider.dart';
import 'package:fitwiz/data/repositories/nutrition_repository.dart'
    show dailyNutritionProvider, todayNutritionKey, DailyNutritionState,
        DailyNutritionNotifier;
import 'package:fitwiz/screens/home/widgets/home/unified_home_widgets.dart'
    show HomeFuelStrip;

class _StubDailyNutritionNotifier extends StateNotifier<DailyNutritionState>
    implements DailyNutritionNotifier {
  _StubDailyNutritionNotifier(super.initial);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubNutritionPrefsNotifier
    extends StateNotifier<NutritionPreferencesState>
    implements NutritionPreferencesNotifier {
  _StubNutritionPrefsNotifier(super.initial);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _dinnerLog = FoodLog(
  id: 'log-1',
  userId: 'u1',
  mealType: 'dinner',
  loggedAt: DateTime(2026, 8, 5, 18, 0),
  createdAt: DateTime(2026, 8, 5, 18, 0),
  totalCalories: 648,
  proteinG: 34,
  carbsG: 32,
  fatG: 41,
  foodItems: const [FoodItem(name: 'Dinner', calories: 648)],
);

void main() {
  testWidgets(
      'with no calorie target configured, the FUEL strip does not print '
      'the same eaten-calorie number on both halves of the row',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyNutritionProvider(todayNutritionKey()).overrideWith(
            (ref) => _StubDailyNutritionNotifier(DailyNutritionState(
              // `logs` non-empty is what selects the full strip layout
              // (row-195's bug) over the separate "nothing logged yet"
              // one-liner HomeFuelStrip renders when logs is empty.
              logs: [_dinnerLog],
              summary: const DailyNutritionSummary(
                date: '2026-08-05',
                totalCalories: 648,
                totalProteinG: 34,
                totalCarbsG: 32,
                totalFatG: 41,
              ),
            )),
          ),
          // Default NutritionPreferencesState() -> hasConfiguredTargets ==
          // false (no preferences, no dynamicTargets) — the exact "no
          // target set" case the finding was about.
          nutritionPreferencesProvider.overrideWith(
              (ref) => _StubNutritionPrefsNotifier(const NutritionPreferencesState())),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HomeFuelStrip()),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Old bug: both halves rendered "648" — one via "648 logged", the other
    // as the big "648" numeral. The left half must no longer repeat the
    // eaten total.
    expect(find.text('648 logged'), findsNothing,
        reason: 'the left-side line must not repeat the number the large '
            'display already shows (E2E row 195)');
    expect(find.text('No target set'), findsOneWidget,
        reason: 'left side should name what is missing instead of '
            'duplicating the eaten total');
    // The large display-size number is still the real eaten total —
    // legitimately shown once.
    expect(find.text('648'), findsOneWidget);
  });
}
