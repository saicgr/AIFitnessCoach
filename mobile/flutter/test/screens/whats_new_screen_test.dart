/// Headless widget test for [WhatsNewScreen].
///
/// Covers the two behaviours Phase 6 added:
///  1. Every slide renders with the image-or-icon hero fallback — because the
///     `assets/whats_new/*.png` screenshots don't exist yet (and aren't even
///     declared in pubspec), `Image.asset` fails to load and the slide MUST
///     fall back to the composed icon hero rather than a broken-image box.
///  2. Showing the carousel marks the standalone score-change sheet's
///     `score_change_v2_seen` flag true, so a user never sees both surfaces.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/screens/whats_new/whats_new_screen.dart';

void main() {
  testWidgets('renders first slide with the icon-hero fallback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: WhatsNewScreen()));
    // Let the entrance animation + async prefs write settle.
    await tester.pumpAndSettle();

    // The carousel chrome is present.
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // The active slide's headline renders.
    expect(find.text('Workout details got richer'), findsOneWidget);

    // Image.asset is attempted for the screenshot-backed hero...
    expect(find.byType(Image), findsWidgets);
    // ...but since the PNG doesn't exist, the errorBuilder fallback (composed
    // icon hero) renders icons — proving the image-or-icon fallback works.
    expect(find.byType(Icon), findsWidgets);
  });

  testWidgets('marks score-change announcement seen when shown', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('score_change_v2_seen'), isNull);

    await tester.pumpWidget(const MaterialApp(home: WhatsNewScreen()));
    await tester.pumpAndSettle();

    // initState fired the fire-and-forget prefs write; it should now be true.
    expect(prefs.getBool('score_change_v2_seen'), isTrue);
  });

  testWidgets('advances through slides via Continue and ends on Done', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: WhatsNewScreen()));
    await tester.pumpAndSettle();

    // First page shows Continue (not the last slide).
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Done'), findsNothing);

    // Tap Continue repeatedly until we reach the final slide. Six slides ⇒ at
    // most five advances; loop defensively and assert we land on Done.
    for (var i = 0; i < 8; i++) {
      if (find.text('Done').evaluate().isNotEmpty) break;
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });
}
