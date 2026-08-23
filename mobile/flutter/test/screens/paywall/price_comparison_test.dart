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

  testWidgets('collapsed shows AI-coach rivals + Zealova; expand reveals all', (
    tester,
  ) async {
    await tester.pumpWidget(buildPrice());
    await tester.pumpAndSettle();

    expect(find.text('WHAT APPS LIKE THESE CHARGE'), findsOneWidget);
    // Premium "ceiling" anchor — a human coach (positions Zealova as value),
    // distinguishing online coaching from in-person training.
    expect(find.textContaining('Future'), findsOneWidget);
    expect(find.textContaining(r'$149'), findsOneWidget);
    expect(find.textContaining('in-person'), findsOneWidget);

    // Collapsed by default: the three AI-coach rivals + Zealova show…
    expect(find.text('Gravl'), findsOneWidget);
    expect(find.text('Google Health'), findsOneWidget);
    expect(find.text('Bevel'), findsOneWidget);
    expect(find.text('Zealova'), findsOneWidget);
    expect(find.text(r'$7.99'), findsOneWidget);
    expect(find.text('all of it'), findsOneWidget);
    // …but the rest stay hidden until expanded (keeps the screen non-scroll).
    expect(find.text('MyFitnessPal'), findsNothing);
    expect(find.text('Cronometer'), findsNothing);

    // Expand to compare every single-job app, incl. fasting + hydration.
    expect(find.text('See all 10 apps'), findsOneWidget);
    await tester.tap(find.text('See all 10 apps'));
    await tester.pumpAndSettle();

    expect(find.text('MyFitnessPal'), findsOneWidget);
    expect(find.text('Fitbod'), findsOneWidget);
    expect(find.text('Noom'), findsOneWidget);
    expect(find.text('MacroFactor'), findsOneWidget);
    expect(find.text('Cronometer'), findsOneWidget);
    expect(find.text('Zero'), findsOneWidget); // fasting
    expect(find.text('WaterMinder'), findsOneWidget); // hydration
    expect(find.text('Show fewer'), findsOneWidget);

    expect(find.text('MO'), findsOneWidget);
    expect(find.text('YR'), findsOneWidget);
  });

  // REGRESSION (pricing source-of-truth refresh, verified 2026-08-23 — see
  // the doc comment on `PaywallPriceComparison`): Gravl and Bevel's monthly
  // prices were stale/incorrect ($14.99 for both) and have been corrected to
  // their real published tiers (Gravl $10.99/mo, $59.99/yr; Bevel $5.99/mo,
  // $49.99/yr). Assert the current, verified prices rather than the old
  // placeholder figures.
  testWidgets('toggling to Yearly switches to annual prices', (tester) async {
    await tester.pumpWidget(buildPrice());
    await tester.pumpAndSettle();

    // Gravl and Bevel are visible while collapsed (monthly), each at its own
    // correct price — no longer sharing a stale $14.99 placeholder.
    expect(find.text(r'$10.99'), findsOneWidget); // Gravl monthly
    expect(find.text(r'$5.99'), findsOneWidget); // Bevel monthly
    await tester.tap(find.text('YR'));
    await tester.pumpAndSettle();

    // Annual prices now shown for the visible rivals. Gravl's yearly price
    // ($59.99) happens to match Zealova's own yearly price, so both render.
    expect(find.text(r'$59.99'), findsNWidgets(2)); // Gravl yearly & Zealova yearly
    expect(find.text(r'$49.99'), findsOneWidget); // Bevel yearly
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
