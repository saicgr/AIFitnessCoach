/// Regression gate for the light-mode "black block" bug: the coach's chat
/// bubble was painted with `AppColors.elevated` (a dark-theme literal)
/// regardless of the active theme, so in light mode it rendered as a
/// near-black card with white text on an otherwise white page — jarring and
/// low-contrast rather than following the theme.
///
/// `ChatMessageBubble` now resolves its bubble fill, border, and text color
/// through `ThemeColors.of(context)`, which branches on the theme's actual
/// brightness (`AppColorsLight.*` in light mode). This test pumps the bubble
/// under `ThemeData.light()` and asserts the RESOLVED colors — not just that
/// the widget renders — so a regression back to a raw `AppColors.*` literal
/// fails the assertion instead of silently reintroducing the bug.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/data/models/chat_message.dart';
import 'package:fitwiz/data/models/coach_persona.dart';
import 'package:fitwiz/screens/chat/widgets/chat_message_bubble.dart';

Widget _harness(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(body: child),
    ),
  );
}

/// Walks up from a `Text` widget to the nearest ancestor `Container` and
/// returns its decoration's fill color — i.e. the bubble's actual painted
/// background, not a color read off some unrelated theme default.
Color? _bubbleFillFor(WidgetTester tester, Finder textFinder) {
  final containers = find
      .ancestor(of: textFinder, matching: find.byType(Container))
      .evaluate()
      .map((e) => e.widget as Container);
  for (final c in containers) {
    final deco = c.decoration;
    if (deco is BoxDecoration && deco.color != null) {
      return deco.color;
    }
  }
  return null;
}

void main() {
  group('ChatMessageBubble in light theme', () {
    testWidgets(
        "coach bubble background is a light-theme fill, distinct from the "
        "page background, with dark (readable) text on top of it",
        (tester) async {
      const coachText = "Here's your plan for today.";
      await tester.pumpWidget(_harness(ChatMessageBubble(
        message: const ChatMessage(role: 'assistant', content: coachText),
        coach: CoachPersona.defaultCoach,
      )));
      await tester.pump();

      final fill = _bubbleFillFor(tester, find.text(coachText));
      expect(fill, isNotNull,
          reason: 'The bubble Container must resolve a background fill.');

      // The dark-theme literal this bug regresses to — the bubble must NOT
      // resolve to it while running under a light Theme.
      expect(fill, isNot(equals(AppColors.elevated)),
          reason: 'Bubble fill must not be the dark-theme literal '
              '(AppColors.elevated) while the active theme is light.');
      expect(fill, equals(AppColorsLight.elevated),
          reason: 'In light theme the coach bubble should paint '
              'AppColorsLight.elevated.');

      // Resolve the actual painted text color and assert it reads against
      // the resolved fill — this is the "contrast is real" check, not a
      // mechanical token swap.
      final textWidget = tester.widget<Text>(find.text(coachText));
      final textColor = textWidget.style?.color;
      expect(textColor, isNotNull);
      expect(textColor, isNot(equals(Colors.white)),
          reason: 'White text on a light bubble is the exact "unreadable" '
              'failure mode this fix removes.');
      expect(textColor, equals(AppColorsLight.textPrimary));

      // The two colors must actually differ enough to read — luminance gap,
      // not identical/near-identical values.
      final fillLuminance = fill!.computeLuminance();
      final textLuminance = textColor!.computeLuminance();
      expect((fillLuminance - textLuminance).abs(), greaterThan(0.3),
          reason: 'Fill and text luminance must contrast; a near-equal '
              'pair (e.g. dark-on-dark) is unreadable even if both are '
              '"correct" colors individually.');
    });
  });
}
