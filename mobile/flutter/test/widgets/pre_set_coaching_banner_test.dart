import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/widgets/pre_set_coaching_banner.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.dark}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(body: child),
  );
}

void main() {
  group('PreSetCoachingBanner', () {
    testWidgets('renders the provided message', (tester) async {
      await tester.pumpWidget(_host(PreSetCoachingBanner(
        message: 'You hit 9 reps last session — below 10-12 range.',
        onDismiss: () {},
        animationKey: 'ex-1',
      )));

      await tester.pumpAndSettle();

      expect(
        find.text('You hit 9 reps last session — below 10-12 range.'),
        findsOneWidget,
      );
    });

    testWidgets('invokes onDismiss when ✕ button is tapped', (tester) async {
      var tapped = 0;

      await tester.pumpWidget(_host(PreSetCoachingBanner(
        message: 'Test message.',
        onDismiss: () => tapped++,
        animationKey: 'ex-1',
      )));

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('renders in light mode without errors', (tester) async {
      await tester.pumpWidget(_host(
        PreSetCoachingBanner(
          message: 'Light mode test.',
          onDismiss: () {},
          animationKey: 'ex-1',
        ),
        brightness: Brightness.light,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Light mode test.'), findsOneWidget);
    });

    testWidgets('has accessible semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_host(PreSetCoachingBanner(
        message: 'Accessibility check.',
        onDismiss: () {},
        animationKey: 'ex-1',
      )));

      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'Coaching insight\. Accessibility check\.')),
        findsOneWidget,
      );
      // The dismiss IconButton carries its own tooltip-based semantics
      // ("Dismiss") which screen readers announce. That's covered by the
      // tooltip param; the Dismiss test above verifies it's actionable.

      handle.dispose();
    });
  });
}
