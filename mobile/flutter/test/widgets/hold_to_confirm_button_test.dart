import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/widgets/hold_to_confirm_button.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/core/providers/locale_provider.dart'
    show supportedAppLocales;

/// Wraps the button in a localized MaterialApp (it reads AppLocalizations
/// for its semantics label) at a fixed locale + size.
Widget _host(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: supportedAppLocales,
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );
}

void main() {
  group('HoldToConfirmButton', () {
    testWidgets('a full hold drives progress to 1.0 and fires onConfirmed', (
      tester,
    ) async {
      var confirmed = 0;

      await tester.pumpWidget(
        _host(
          HoldToConfirmButton(
            label: 'Hold to commit',
            accessibleLabel: "I'm in",
            holdDuration: const Duration(milliseconds: 1300),
            onConfirmed: () => confirmed++,
          ),
        ),
      );
      await tester.pump();

      // Press and hold the button.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToConfirmButton)),
      );

      // Drive past the full hold duration so the fill animation completes.
      await tester.pump(); // kick the controller forward
      await tester.pump(const Duration(milliseconds: 1400));

      // Completion shows a brief "COMMITTED" dwell BEFORE onConfirmed fires.
      expect(confirmed, 0, reason: 'should dwell on COMMITTED before firing');
      expect(find.text('COMMITTED'), findsOneWidget);

      // The circular progress ring should now be full.
      final ring = tester.widgetList<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(
        ring.any((r) => r.value == 1.0),
        isTrue,
        reason: 'progress ring should be full at completion',
      );

      // Let the dwell elapse — now onConfirmed fires exactly once.
      await tester.pump(const Duration(milliseconds: 400));
      expect(confirmed, 1);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('releasing before completion does not fire onConfirmed', (
      tester,
    ) async {
      var confirmed = 0;

      await tester.pumpWidget(
        _host(
          HoldToConfirmButton(
            label: 'Hold to commit',
            accessibleLabel: "I'm in",
            holdDuration: const Duration(milliseconds: 1300),
            onConfirmed: () => confirmed++,
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToConfirmButton)),
      );
      await tester.pump();
      // Hold only partway, then release.
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));

      expect(confirmed, 0);
    });

    testWidgets('shows the hold label initially and KEEP HOLDING while held', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          HoldToConfirmButton(
            label: 'Hold to commit',
            accessibleLabel: "I'm in",
            onConfirmed: () {},
          ),
        ),
      );
      await tester.pump();

      // Idle label is the uppercased hold label.
      expect(find.text('HOLD TO COMMIT'), findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToConfirmButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('KEEP HOLDING…'), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}
