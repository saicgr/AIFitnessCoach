/// Editable-card preset for the **AI Confidence** template — a model-style
/// confidence read-out: an "✦ AI CONFIDENCE" eyebrow, a giant percentage, a
/// reassuring verdict line, and a gradient confidence bar (a ring stat backs
/// the figure). The percentage and verdict are editable; the ring binds its
/// fill to the recovery percentage so it tracks real readiness.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiConfidenceDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cyan = Color(0xFF22D3EE);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiConfidence',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0D1117), Color(0xFF070709)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.32),
        size: const Size(0.84, 0.03),
        literal: '✦ AI CONFIDENCE',
        font: CardFontIx.cond,
        fontSize: 18,
        color: muted,
        letterSpacing: 2.8,
        align: TextAlign.center,
      ),
      // Big percentage.
      textEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.84, 0.12),
        literal: '98%',
        font: CardFontIx.display,
        fontSize: 130,
        color: accent,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Verdict line.
      textEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.84, 0.04),
        literal: 'you crushed it',
        font: CardFontIx.cond,
        fontSize: 28,
        color: white,
        align: TextAlign.center,
      ),
      // Confidence bar track.
      shapeEl(
        pos: const Offset(0.5, 0.65),
        size: const Size(0.74, 0.012),
        shape: ShapeKind.pill,
        fill: const Color(0x1FFFFFFF),
      ),
      // Confidence bar fill (gradient).
      shapeEl(
        pos: const Offset(0.5 - 0.74 * (1 - 0.98) / 2, 0.65),
        size: const Size(0.74 * 0.98, 0.012),
        shape: ShapeKind.pill,
        gradient: [accent, cyan],
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
