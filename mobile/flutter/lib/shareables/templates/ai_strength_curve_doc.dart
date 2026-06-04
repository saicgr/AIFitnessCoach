/// Editable-card preset for the **Strength Curve** template — an ML
/// "loss-curve" reframed as a rising 1RM strength trend: a "✦ GETTING STRONGER
/// · 1RM" eyebrow, a smooth ascending line chart (ChartKind.line), and a
/// start→current value strip. The end label sits in accent. Chart + labels are
/// editable layers.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiStrengthCurveDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const muted = Color(0x99FFFFFF);
  const dim = Color(0xFF888888);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiStrengthCurve',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0D1117), Color(0xFF070709)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.3, 0.32),
        size: const Size(0.6, 0.03),
        literal: '✦ GETTING STRONGER · 1RM',
        font: CardFontIx.cond,
        fontSize: 18,
        color: muted,
        letterSpacing: 2.2,
      ),
      // Rising strength line.
      chartEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.82, 0.28),
        kind: ChartKind.line,
      ),
      // Start label.
      textEl(
        pos: const Offset(0.22, 0.7),
        size: const Size(0.3, 0.03),
        literal: '135 lb',
        font: CardFontIx.mono,
        fontSize: 20,
        color: dim,
      ),
      // Current label (accent, with rise marker).
      textEl(
        pos: const Offset(0.78, 0.7),
        size: const Size(0.34, 0.03),
        literal: '225 lb ▲',
        font: CardFontIx.mono,
        fontSize: 20,
        color: accent,
        align: TextAlign.right,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
