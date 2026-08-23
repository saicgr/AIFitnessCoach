import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_theme.dart';

/// A compact animated "Did you know?" hint chip for the onboarding quiz.
///
/// Shows a lightbulb icon with a contextual fact about the app.
/// Animates in with fade + slide when it appears.
/// Uses glassmorphic styling adapted for light and dark modes.
class DidYouKnowChip extends StatelessWidget {
  final String text;

  const DidYouKnowChip({super.key, required this.text});

  /// Height to RESERVE for the chip slot above a pinned CTA.
  ///
  /// The chip sits between the question and the Continue button and swaps
  /// between hint / acknowledgment / nothing as the user answers. Rendered
  /// inline, each swap resized the slot by up to ~50px and the CTA jumped —
  /// a tap aimed at the freshly-enabled button landed where it used to be.
  /// Callers wrap the slot in `SizedBox(height: DidYouKnowChip.slotHeight(ctx))`
  /// so the button never moves.
  ///
  /// Derived from the chip's own metrics, not a magic number: outer padding
  /// (4 + 6) + inner padding (7 × 2) + border (1 × 2) + two lines of 11pt text
  /// at height 1.2, scaled by the platform text scaler, plus a small safety
  /// margin.
  ///
  /// The 1.25 line-height factor is an ESTIMATE of the real two-line text
  /// block — actual font metrics for the "Did you know?" run (below) run
  /// slightly taller, and on the goals/equipment steps' two-line facts that
  /// shortfall was enough for this reserved slot to come in a few px under
  /// the real content, so the outer `ClipRRect` cropped the descenders off
  /// the last line ("...ramp up over time." rendering with its "p"/"g" cut).
  /// The `+3` buffer absorbs that estimate error instead of chasing the
  /// exact metric.
  static double slotHeight(BuildContext context) {
    const chrome = 4 + 6 + 14 + 2.0 + 3.0;
    final lineHeight = MediaQuery.textScalerOf(context).scale(11) * 1.25;
    return chrome + lineHeight * 2;
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            // Single-line, low-height chip: keeps the educational moment
            // without consuming the vertical space that option lists need.
            // Long facts gracefully ellipsize — full text is still spoken
            // by accessibility readers via the Tooltip below.
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: t.cardFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.borderDefault),
            ),
            child: Tooltip(
              message: text,
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: t.textPrimary)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.15, 1.15),
                        duration: 1200.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Did you know?  ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          TextSpan(
                            text: text,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: t.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 600.ms, curve: Curves.easeOutCubic);
  }
}
