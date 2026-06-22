import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/theme/theme_colors.dart';
import 'package:fitwiz/screens/paywall/widgets/price_comparison.dart';
import 'package:fitwiz/screens/paywall/widgets/benefit_strip.dart';

/// Headless render check for the signature-v2 paywall PRICE anchor and the
/// "Built for how you train" benefit strip — pure presentational widgets, so a
/// bare MaterialApp + resolved [ThemeColors] is enough.
void main() {
  Widget harness(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  Widget buildPrice() => harness(
    Builder(
      builder: (context) =>
          PaywallPriceComparison(colors: ThemeColors.of(context)),
    ),
  );

  Widget buildBenefits() => harness(
    Builder(
      builder: (context) =>
          PaywallBenefitStrip(colors: ThemeColors.of(context)),
    ),
  );

  testWidgets('price anchor lists competitor prices and Zealova', (
    tester,
  ) async {
    await tester.pumpWidget(buildPrice());
    await tester.pumpAndSettle();

    expect(find.text('WHAT APPS LIKE THESE CHARGE'), findsOneWidget);
    // Premium "ceiling" anchor — a human coach (positions Zealova as value).
    expect(find.textContaining('Future'), findsOneWidget);
    expect(find.textContaining(r'$149'), findsOneWidget);
    // Premium comparable apps (each does one job).
    expect(find.text('MyFitnessPal'), findsOneWidget);
    expect(find.text('Fitbod'), findsOneWidget);
    expect(find.text('Gravl'), findsOneWidget);
    // Future anchor distinguishes online coaching from in-person training.
    expect(find.textContaining('in-person'), findsOneWidget);
    expect(find.text('Noom'), findsOneWidget);
    expect(find.text('MacroFactor'), findsOneWidget);
    expect(find.text('Cronometer'), findsOneWidget);
    // Default = MONTHLY prices (struck-through).
    expect(find.text(r'$19.99'), findsOneWidget);
    expect(find.text(r'$15.99'), findsOneWidget);
    expect(find.text(r'$11.99'), findsOneWidget);
    // Zealova anchored low, doing it all.
    expect(find.text('Zealova'), findsOneWidget);
    expect(find.text(r'$7.99'), findsOneWidget);
    expect(find.text('all of it'), findsOneWidget);
    // The Monthly/Yearly toggle is present.
    expect(find.text('MO'), findsOneWidget);
    expect(find.text('YR'), findsOneWidget);
  });

  testWidgets('toggling to Yearly switches to annual prices', (tester) async {
    await tester.pumpWidget(buildPrice());
    await tester.pumpAndSettle();

    expect(find.text(r'$19.99'), findsOneWidget); // monthly MFP
    await tester.tap(find.text('YR'));
    await tester.pumpAndSettle();

    // Annual prices now shown.
    expect(find.text(r'$79.99'), findsOneWidget); // MFP yearly
    expect(find.text(r'$209'), findsOneWidget); // Noom yearly
    expect(find.text(r'$59.99'), findsOneWidget); // Zealova yearly
    expect(find.text(r'$19.99'), findsNothing); // monthly gone
  });

  testWidgets('benefit strip renders the four non-attributed benefits', (
    tester,
  ) async {
    await tester.pumpWidget(buildBenefits());
    await tester.pumpAndSettle();

    expect(find.text('BUILT FOR HOW YOU TRAIN'), findsOneWidget);
    expect(find.text('Period-aware coaching that remembers'), findsOneWidget);
    expect(find.text('Scan & sort any menu'), findsOneWidget);
    expect(find.text('Food, fasting & hydration in one place'), findsOneWidget);
    expect(find.text('Beginner-friendly easy workouts'), findsOneWidget);
  });

  testWidgets('price anchor + benefit strip render together', (tester) async {
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) {
            final colors = ThemeColors.of(context);
            return Column(
              children: [
                PaywallPriceComparison(colors: colors),
                const SizedBox(height: 16),
                PaywallBenefitStrip(colors: colors),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WHAT APPS LIKE THESE CHARGE'), findsOneWidget);
    expect(find.text('BUILT FOR HOW YOU TRAIN'), findsOneWidget);
  });
}
