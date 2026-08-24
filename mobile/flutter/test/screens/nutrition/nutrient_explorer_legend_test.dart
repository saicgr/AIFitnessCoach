/// Regression coverage for E2E row #272.
///
/// The register claimed a legend was added next to the Vitamins & Minerals
/// bars alongside the attainment-color and 'adequate' status-enum fixes, but
/// no legend widget ever shipped — the bar colors were (correctly) keyed to
/// NutrientStatus, yet nothing on screen explained what amber/light-green/
/// green/orange/red meant. This test asserts the legend is actually
/// rendered above the nutrient sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/micronutrients.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/nutrition/nutrient_explorer.dart';

NutrientProgress _nutrient(String key, String status) => NutrientProgress(
      nutrientKey: key,
      displayName: key,
      unit: 'mg',
      category: 'vitamin',
      currentValue: 10,
      targetValue: 20,
      percentage: 50,
      status: status,
    );

void main() {
  testWidgets('#272: nutrient explorer renders a status-color legend', (tester) async {
    final summary = DailyMicronutrientSummary(
      date: '2026-08-23',
      userId: 'u1',
      vitamins: [_nutrient('vitamin_d', 'low'), _nutrient('vitamin_c', 'adequate')],
      minerals: [_nutrient('calcium', 'optimal')],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: NutrientExplorerTab(
            userId: 'u1',
            summary: summary,
            isLoading: false,
            onRefresh: () {},
            isDark: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The legend must name every status the bars can render.
    expect(find.text('Below Target'), findsOneWidget);
    expect(find.text('Adequate'), findsOneWidget);
    expect(find.text('Optimal'), findsOneWidget);
    expect(find.text('Above Target'), findsOneWidget);
    expect(find.text('Over Limit'), findsOneWidget);
  });
}
