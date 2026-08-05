import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/widgets/xp_earned_animation.dart';

/// Regression test for `XPEarnedOverlay` (lib/widgets/xp_earned_animation.dart).
///
/// The toast's own `Future.delayed(2000ms, () { if (mounted) onDismiss(); })`
/// is the primary removal path. `XPEarnedOverlay.show` also schedules an
/// independent backstop `Future.delayed(3200ms, remove)` so the entry is
/// still cleaned up if the primary path is ever starved.
///
/// Because the backstop (3200ms) always fires AFTER the toast's own normal
/// dismissal (2000ms) under completely ordinary usage, the two triggers
/// racing on the SAME entry is not a rare edge case — it happens on every
/// single toast that lives long enough. Without an idempotent, `mounted`-
/// guarded `remove()`, the backstop's later call to `entry.remove()` throws
/// ("An OverlayEntry should be removed only once") because the entry was
/// already removed by the toast's own dismissal.
void main() {
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
    'normal lifecycle: the toast auto-dismisses, then the backstop fires '
    'later on the same (already-removed) entry — must not throw',
    (tester) async {
      final context = await pumpHost(tester);
      XPEarnedOverlay.show(context, xpAmount: 25, goalType: XPGoalType.mealLog);
      await tester.pump();
      expect(find.textContaining('+25 XP'), findsOneWidget);

      // Past the toast's own 2s auto-dismiss.
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('+25 XP'), findsNothing);

      // Past the manager's 3.2s backstop, which fires on the very same
      // entry the toast's own timer already removed.
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "external dismiss() before the toast's own timer, then time passes "
    'the internal timer and the backstop — must not throw, overlay stays empty',
    (tester) async {
      final context = await pumpHost(tester);
      XPEarnedOverlay.show(context, xpAmount: 10, goalType: XPGoalType.weightLog);
      await tester.pump();
      expect(find.textContaining('+10 XP'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      XPEarnedOverlay.dismiss();
      await tester.pump();
      expect(find.textContaining('+10 XP'), findsNothing);

      // Advance past where the toast's own timer AND the backstop would
      // have fired.
      await tester.pump(const Duration(milliseconds: 3200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'showing a second toast while the first is still up removes the first '
    'cleanly and only the second remains',
    (tester) async {
      final context = await pumpHost(tester);
      XPEarnedOverlay.show(context, xpAmount: 5, goalType: XPGoalType.dailyLogin);
      await tester.pump();
      expect(find.textContaining('+5 XP'), findsOneWidget);

      XPEarnedOverlay.show(context, xpAmount: 40, goalType: XPGoalType.workoutComplete);
      await tester.pump();
      expect(find.textContaining('+5 XP'), findsNothing);
      expect(find.textContaining('+40 XP'), findsOneWidget);

      // Let both toasts' timers and backstops run out without throwing.
      await tester.pump(const Duration(milliseconds: 3300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
