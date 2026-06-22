import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/onboarding/capability_and_community_screen.dart';

/// Regression guard: the "Built right." screen must PAINT without throwing.
/// It previously crashed with "A borderRadius can only be given on borders
/// with uniform colors" because a card used a non-uniform 4-side Border
/// (orange top, gray sides) together with a borderRadius. The fix uses a
/// top-only accent border. This test renders the screen (which forces a paint)
/// and asserts no exception escapes.
void main() {
  testWidgets('renders + paints without a non-uniform-border crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          theme: null,
          darkTheme: null,
          home: CapabilityAndCommunityScreen(),
        ),
      ),
    );
    // Let flutter_animate's entrance timers (delays + fades) drain so the
    // tree disposes cleanly; the paint that used to crash happens on frame 1.
    await tester.pumpAndSettle(const Duration(milliseconds: 1500));

    expect(tester.takeException(), isNull);
    expect(find.text('TALK TO A REAL HUMAN'), findsOneWidget);
    expect(find.textContaining('HD video demos'), findsOneWidget);
  });
}
