/// The AI-coach glyph: a **standalone sparkle** (`Icons.auto_awesome`).
///
/// D3 (2026-08, real device): this used to be `Icons.chat_bubble_outline_rounded`
/// with a half-size sparkle nested inside it. At the 15 pt it was actually
/// rendered at, the composite lost its sparkle to antialiasing and the founder
/// read the remaining rounded outline as a **camera**. A messaging glyph is
/// also the wrong signal even when it renders perfectly: it advertises "send a
/// message", not "this control is AI".
///
/// The sparkle alone is the universal convention for that. Google standardised
/// it across Search/Workspace/Gemini in 2023; Copilot, OpenAI and Adobe all
/// follow it. The distinction that matters here: a sparkle *attached to*
/// something means "AI enhances this thing", while a **standalone** sparkle
/// means "AI is this control's entire job" — which is exactly what the coach
/// button is. `auto_awesome` (a four-point star with two companion sparks) over
/// a bare star because the companion sparks are what keep it reading as *AI*
/// rather than *favourite* at [kFloatGlyphSize].
///
/// Used by the persistent coach float (`CoachFloatingButton`) and the
/// floating-tab-bar coach slot so both surfaces share one identical mark.
/// Render it in [ThemeColors.accent] on a raised surface, or in
/// `accentContrast` on an accent fill.
library;

import 'package:flutter/material.dart';

class CoachSparkIcon extends StatelessWidget {
  /// Overall square extent in logical pixels. Defaults to the shared float
  /// glyph size so the coach ✦ and the Quick Log + are optically identical.
  final double size;

  /// Glyph colour. On the raised coach circle this is `ThemeColors.accent` —
  /// the one place the accent is spent on that control.
  final Color color;

  /// Forwarded to the icon for screen readers.
  final String semanticLabel;

  const CoachSparkIcon({
    super.key,
    this.size = 18,
    required this.color,
    this.semanticLabel = 'Ask coach',
  });

  @override
  Widget build(BuildContext context) {
    // ONE icon, no Stack, no offset Padding. Anything layered inside a 44 pt
    // float is sub-pixel mush on a real screen — the composite this replaced is
    // the proof.
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}
