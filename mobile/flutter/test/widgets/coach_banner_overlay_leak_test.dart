import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/widgets/coach_banner_overlay.dart';
import 'package:fitwiz/data/models/coach_persona.dart';

/// Regression test for `CoachBannerOverlay` (lib/widgets/coach_banner_overlay.dart).
///
/// The banner's own dismiss path (`_CoachBannerState._dismiss`, triggered by
/// either its auto-dismiss timer or a tap) awaits `_ctl.reverse()` before
/// calling `onDismissed`. `CoachBannerOverlay.show` also schedules an
/// independent backstop `Future.delayed(duration + 2s, remove)`.
///
/// Because the backstop always fires AFTER the banner's own normal dismissal
/// under completely ordinary usage, the two triggers racing on the SAME
/// entry happens on every banner that lives long enough. Without an
/// idempotent, `mounted`-guarded `remove()`, the backstop's later call to
/// `entry.remove()` throws ("An OverlayEntry should be removed only once")
/// because the entry was already removed by the banner's own dismissal.
void main() {
  final coach = CoachPersona.predefinedCoaches.first;

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        ctx = context;
        return const Scaffold(body: SizedBox());
      }),
    ));
    return ctx;
  }

  testWidgets(
    'normal lifecycle: the banner auto-dismisses (timer + reverse anim), '
    'then the backstop fires later on the same (already-removed) entry — '
    'must not throw',
    (tester) async {
      final context = await pumpHost(tester);
      CoachBannerOverlay.show(
        context,
        coach: coach,
        title: 'Milestone',
        message: 'Great work today!',
        duration: const Duration(milliseconds: 500),
      );
      await tester.pump();
      expect(find.text('Great work today!'), findsOneWidget);

      // Past the banner's own auto-dismiss timer (500ms) plus its reverse
      // animation (350ms).
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Great work today!'), findsNothing);

      // Past the manager's backstop (duration + 2s = 2500ms from show),
      // which fires on the very same entry the banner's own dismiss path
      // already removed.
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tap-to-dismiss, then the backstop fires later on the same entry — '
    'must not throw',
    (tester) async {
      final context = await pumpHost(tester);
      CoachBannerOverlay.show(
        context,
        coach: coach,
        title: 'Milestone',
        message: 'Tap-dismiss banner',
        duration: const Duration(milliseconds: 4500),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // slide-in settles
      expect(find.text('Tap-dismiss banner'), findsOneWidget);

      await tester.tap(find.text('Tap-dismiss banner'));
      await tester.pump(const Duration(milliseconds: 400)); // reverse anim
      await tester.pumpAndSettle();
      expect(find.text('Tap-dismiss banner'), findsNothing);

      // Advance past where the backstop (duration + 2s) would fire.
      await tester.pump(const Duration(milliseconds: 6500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'showing a second banner while the first is still up removes the first '
    'cleanly and only the second remains',
    (tester) async {
      final context = await pumpHost(tester);
      CoachBannerOverlay.show(
        context,
        coach: coach,
        title: 'First',
        message: 'First banner',
        duration: const Duration(milliseconds: 4500),
      );
      await tester.pump();
      expect(find.text('First banner'), findsOneWidget);

      CoachBannerOverlay.show(
        context,
        coach: coach,
        title: 'Second',
        message: 'Second banner',
        duration: const Duration(milliseconds: 4500),
      );
      await tester.pump();
      expect(find.text('First banner'), findsNothing);
      expect(find.text('Second banner'), findsOneWidget);

      // Let both banners' timers/backstops run out without throwing.
      await tester.pump(const Duration(milliseconds: 7000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
