/// A distinctive "AI coach" glyph: a speech bubble with a sparkle inside it,
/// so the coach affordance reads as an *AI message* rather than a generic
/// sparkle. Used by the persistent coach FAB (`CoachFloatingButton`) and the
/// floating-tab-bar coach slot so both surfaces share one identical mark.
///
/// The outlined bubble is hollow, so a same-colored sparkle nested in its body
/// stays legible on the accent fill (both strokes are `color`, the gaps show
/// the fill through). Render it on an accent background with
/// `color = accentContrast` (white on the orange FAB).
library;

import 'package:flutter/material.dart';

class CoachSparkIcon extends StatelessWidget {
  /// Overall square extent in logical pixels. The bubble fills this box; the
  /// sparkle is scaled to ~half and nested inside the bubble body.
  final double size;

  /// Stroke/fill color for both the bubble and the sparkle. On the accent FAB
  /// this is `accentContrast`.
  final Color color;

  /// Forwarded to the bubble for screen readers.
  final String semanticLabel;

  const CoachSparkIcon({
    super.key,
    this.size = 18,
    required this.color,
    this.semanticLabel = 'Ask coach',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Speech-bubble outline — tail sits bottom-left, hollow body centered.
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: size,
            color: color,
            semanticLabel: semanticLabel,
          ),
          // Sparkle nested in the bubble body. Nudged up so it clears the tail
          // and sits visually centered inside the rounded body.
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.14),
            child: Icon(
              Icons.auto_awesome,
              size: size * 0.52,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
