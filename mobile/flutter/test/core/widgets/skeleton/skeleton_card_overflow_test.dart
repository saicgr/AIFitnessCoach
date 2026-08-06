// Regression gate for FITWIZ-FLUTTER-J9 / FITWIZ-FLUTTER-J8 (Sentry,
// production, /xp-leaderboard, 16 + 10 occurrences on 2026-08-06): "A
// RenderFlex overflowed by 2.0 pixels on the bottom."
//
// ROOT CAUSE: `SkeletonCard` (lib/core/widgets/skeleton/skeleton_list.dart)
// paired an explicit `padding: EdgeInsets.all(16)` with a `Container` whose
// `decoration` carries a `Border.all(...)`. `Container` silently ADDS the
// border's own `border.dimensions` on top of the caller's `padding` (see
// `BoxDecoration.padding`), so the true interior height is
// `height - 2*padding - 2*borderWidth`, not `height - 2*padding`. Any caller
// whose `leadingSize`/`lines` content height lands on an EXACT fit against
// `height - 2*padding` (as `xp_leaderboard_screen.dart` did twice: two
// separate `SkeletonList` boards both passing `SkeletonCard(height: 64,
// leadingSize: 40, lines: 2)`, where the 2-line `SkeletonText` needs exactly
// 32px and `64 - 2*16 = 32` matches with zero slack) overflows the instant
// the border claims its ~2px — matching the exact "2.0 pixels" / "1.9
// pixels" Sentry reported.
//
// This is not `/xp-leaderboard`-specific: `SkeletonCard(height: ...)` is a
// shared primitive used by ~20 screens app-wide (settings, goals, social,
// streaks, nutrition, stats, ...), several of which pass the same
// razor-exact `height: 64` shape. The fix in `skeleton_list.dart` makes
// `height` a MINIMUM (`BoxConstraints(minHeight:)`) instead of a tight
// constraint, so the card grows to fit its content instead of ever clipping
// it — this test asserts that directly against `SkeletonCard`, not against
// one call site, so it cannot be defeated by nudging a magic-number height.
//
// Negative-tested: reverting the `constraints: BoxConstraints(minHeight:)`
// fix back to `height: height` reproduces `takeException()` returning the
// FlutterError overflow on every case below; restoring the fix clears it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/widgets/skeleton/skeleton_list.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required double width,
    required double height,
    required double leadingSize,
    required int lines,
    double textScale = 1.0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: SizedBox(
              width: width,
              child: SkeletonCard(
                height: height,
                leadingSize: leadingSize,
                lines: lines,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'SkeletonCard(height: 64, leadingSize: 40, lines: 2) — the exact '
    '/xp-leaderboard shape — never overflows at the reported iPhone 390pt '
    'width',
    (tester) async {
      await pumpCard(
        tester,
        width: 390, // iPhone17,5 logical width from the Sentry event
        height: 64,
        leadingSize: 40,
        lines: 2,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SkeletonCard must never overflow for the exact height/leadingSize/'
            'lines combination xp_leaderboard_screen.dart passes twice '
            '(XP board + streaks/workouts board loading state).',
      );
    },
  );

  testWidgets(
    'SkeletonCard stays overflow-free across a width × text-scale matrix, '
    'for both the /xp-leaderboard shape and other exact-fit-prone shapes '
    'used elsewhere in the app',
    (tester) async {
      const widths = [360.0, 390.0, 428.0];
      const textScales = [1.0, 1.3, 2.0];
      const shapes = [
        // (height, leadingSize, lines) — xp_leaderboard_screen.dart /
        // social/tabs/leaderboard_tab.dart shape.
        (64.0, 40.0, 2),
        // streaks_screen.dart shape — an even tighter target height.
        (60.0, 44.0, 2),
      ];

      for (final width in widths) {
        for (final scale in textScales) {
          for (final shape in shapes) {
            await pumpCard(
              tester,
              width: width,
              height: shape.$1,
              leadingSize: shape.$2,
              lines: shape.$3,
              textScale: scale,
            );
            final exception = tester.takeException();
            expect(
              exception,
              isNull,
              reason: 'SkeletonCard(height: ${shape.$1}, leadingSize: '
                  '${shape.$2}, lines: ${shape.$3}) overflowed at width '
                  '$width, textScale $scale: $exception',
            );
          }
        }
      }
    },
  );
}
