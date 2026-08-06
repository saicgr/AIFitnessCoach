// Regression gate for row 39 (E2E): the quick-action pill strip above the
// composer sliced its 3rd chip down to a book icon plus the bare letter "A"
// hard against the trailing "..." (More) button — fully opaque, unreadable,
// with no way to tell what tapping it would do.
//
// `ChatQuickPills` scrolls its pills inside a `ShaderMask`-faded viewport
// with a FIXED 12px fade at the trailing edge. A fixed-width fade cannot
// distinguish "a pill that legitimately ends right at the boundary" (must
// stay fully opaque — this is the E2E #33 / row-108 regression it was
// already tuned not to reintroduce) from "a pill that's 90% clipped by the
// viewport" (must be hidden) — it only knows pixels-from-the-edge, and
// whichever pill happens to land there varies with locale, text scale, and
// the user's chosen quick-action order. The fix measures: every pill gets a
// key, and after each layout/scroll `_recomputeClippedPills` checks whether
// each pill's bounds are fully inside the viewport (`ShaderMask`'s own
// render box). A pill that is only partially inside fades all the way to 0
// instead of rendering readable-but-truncated.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/models/chat_quick_action.dart';
import 'package:fitwiz/data/providers/chat_quick_action_provider.dart';
import 'package:fitwiz/screens/chat/widgets/chat_quick_pills.dart';

/// 5 pills, deliberately labeled so more than 2 fit but the 3rd cannot fit
/// wholly inside a narrow phone-width viewport — the exact geometry the
/// screenshot (`ui_stats_05b_cont3_s.png`) showed: "Scan Food", "Quick
/// Workout" fully visible, then "Analyze Menu" sliced to "🍽A".
final _testPills = <ChatQuickAction>[
  chatQuickActionRegistry['scan_food']!, // "Scan Food"
  chatQuickActionRegistry['quick_workout']!, // "Quick Workout"
  chatQuickActionRegistry['analyze_menu']!, // "Analyze Menu"
  chatQuickActionRegistry['check_form']!, // "Check My Form"
  chatQuickActionRegistry['nutrition_advice']!, // "Nutrition Tips"
];

Widget _harness() {
  return ProviderScope(
    overrides: [
      chatVisiblePillsProvider.overrideWithValue(_testPills),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        // Wide enough that "Scan Food" + "Quick Workout" both fit fully, but
        // narrow enough that "Analyze Menu" straddles the viewport edge —
        // reproduces the reported geometry ("Scan Food, Quick Workout,
        // 🍽A|…") without depending on a specific device width or on the
        // test harness's fallback font matching the app's real font metrics.
        body: SizedBox(
          width: 480,
          child: ChatQuickPills(
            onSendPrompt: (_) {},
            onOpenMediaPicker: (_, __) {},
            isLoading: false,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'a pill that does not fully fit the viewport is fully hidden, never '
      'rendered as a readable truncated fragment', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    AnimatedOpacity opacityOf(String label) => tester.widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedOpacity),
          ),
        );

    // The two pills that comfortably fit stay fully opaque and readable —
    // this is the E2E #33 / row-108 regression the fix must not reintroduce.
    expect(opacityOf('Scan Food').opacity, 1.0);
    expect(opacityOf('Quick Workout').opacity, 1.0);

    // "Analyze Menu" is laid out (it's in the scrollable content) but must
    // not be legible — this is the actual defect: the pre-fix strip left it
    // rendered at opacity 1.0, sliced down to "🍽A".
    final analyzeMenuOpacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Analyze Menu'),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(analyzeMenuOpacity.opacity, 0.0,
        reason: 'A pill that is only partially inside the viewport must be '
            'faded to fully invisible, not left readable-but-truncated.');
  });

  testWidgets('scrolling the strip reveals the previously-clipped pill fully',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Jump the strip's own ScrollController directly rather than simulating
    // a drag gesture — a drag's actual scroll delta depends on touch-slop
    // and velocity decay, which makes "scroll exactly far enough to reveal
    // pill 2 without also clipping it on the left" flaky to hit via gesture
    // pixels. A direct jump is deterministic and still exercises the same
    // `ScrollController` listener (`_recomputeClippedPills`) production
    // scrolling drives.
    final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView));
    scrollView.controller!.jumpTo(250);
    await tester.pumpAndSettle();

    final analyzeMenuOpacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Analyze Menu'),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(analyzeMenuOpacity.opacity, 1.0,
        reason: 'Once fully scrolled into view, the pill must become fully '
            'readable again — the fix hides PARTIAL pills, not this one '
            'permanently.');
  });
}
