import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/animations/celebration_animations.dart';

/// Regression test for the ring-100% celebration overlay in
/// `today_score_card.dart` (`_maybeCelebrateRing`). That function is private
/// to its library, so this mirrors its exact overlay-insertion logic against
/// the real, public `ConfettiOverlay` widget it wires up — the same shape
/// that was fixed in `daily_crate_banner.dart`'s `_showRewardToast`.
///
/// The bug shape: `ConfettiOverlay.onComplete` fires from an
/// `AnimationStatus.completed` listener with no re-entrancy guard. If
/// anything else removes the same `OverlayEntry` first (a backstop, another
/// dismiss trigger), the animation's own completion notification still
/// fires afterward and calls `entry.remove()` a second time — which throws
/// ("An OverlayEntry should be removed only once") because a bare
/// `entry.remove()` has no idempotency guard.
void main() {
  Future<OverlayState> pumpHost(WidgetTester tester) async {
    late OverlayState overlay;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        overlay = Overlay.of(context);
        return const Scaffold(body: SizedBox());
      }),
    ));
    return overlay;
  }

  /// Old (pre-fix) shape: bare `entry.remove()`, no idempotency guard, no
  /// independent backstop. Returns the entry so the test can independently
  /// trigger a second removal.
  OverlayEntry showOld(OverlayState overlay) {
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) {
      return Positioned.fill(
        child: IgnorePointer(
          child: ConfettiOverlay(
            particleCount: 60,
            duration: const Duration(milliseconds: 2200),
            onComplete: () => entry.remove(),
          ),
        ),
      );
    });
    overlay.insert(entry);
    return entry;
  }

  /// New (fixed) shape, copied verbatim from `_maybeCelebrateRing` in
  /// `lib/screens/home/widgets/today_score_card.dart`. Returns the `remove`
  /// closure so the test can independently trigger it too.
  ({OverlayEntry entry, VoidCallback remove}) showFixed(OverlayState overlay) {
    late OverlayEntry entry;
    var removed = false;
    void remove() {
      if (removed) return;
      removed = true;
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(builder: (_) {
      return Positioned.fill(
        child: IgnorePointer(
          child: ConfettiOverlay(
            particleCount: 60,
            duration: const Duration(milliseconds: 2200),
            onComplete: remove,
          ),
        ),
      );
    });
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 3500), remove);
    return (entry: entry, remove: remove);
  }

  testWidgets(
    'OLD shape: a second removal before the animation completes crashes '
    'when the completion notification still fires',
    (tester) async {
      final overlay = await pumpHost(tester);
      final entry = showOld(overlay);
      await tester.pump();
      expect(find.byType(ConfettiOverlay), findsOneWidget);

      // Something else removes this same entry mid-animation — mirrors a
      // backstop, or any other code independently tearing it down early.
      await tester.pump(const Duration(milliseconds: 500));
      entry.remove();

      // Advance past when the animation would complete naturally — its
      // status listener still fires and calls the unguarded `entry.remove()`
      // a second time.
      await tester.pump(const Duration(milliseconds: 2000));
      expect(tester.takeException(), isNotNull,
          reason: 'expected the unguarded double-remove to throw');
    },
  );

  testWidgets(
    'FIXED shape: the same race does not throw and the overlay ends up empty',
    (tester) async {
      final overlay = await pumpHost(tester);
      final shown = showFixed(overlay);
      await tester.pump();
      expect(find.byType(ConfettiOverlay), findsOneWidget);

      // Same race as above: something else removes the entry mid-animation.
      await tester.pump(const Duration(milliseconds: 500));
      shown.remove();

      // Advance past natural completion, then past the backstop too.
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ConfettiOverlay), findsNothing);
    },
  );

  testWidgets(
    'FIXED shape: the natural completion and the backstop converge without '
    'a double-remove crash, and the entry ends up gone',
    (tester) async {
      final overlay = await pumpHost(tester);
      showFixed(overlay);
      await tester.pump();
      expect(find.byType(ConfettiOverlay), findsOneWidget);

      // Jump straight past both the 2.2s animation completion and the 3.5s
      // backstop in one pump — both removal triggers land in the same
      // window, which is exactly when the idempotency guard matters.
      await tester.pump(const Duration(milliseconds: 3600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ConfettiOverlay), findsNothing);
    },
  );
}
