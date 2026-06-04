/// Editable-card preset — **Quiet Wins**: the un-flashy progress that never
/// makes a highlight reel. A soft dark field, a Fraunces serif header ("the
/// quiet wins"), and a checklist of small victories rendered as a repeater over
/// the user's sub-metrics — better sleep, one more rep, showing up tired.
/// Reflective, low-key, designed to honour invisible progress.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulQuietWinsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulQuietWins',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF13161B), Color(0xFF080A0D)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.11),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 16,
        color: muted,
        align: TextAlign.left,
        letterSpacing: 4,
        allCaps: true,
        maxLines: 1,
      ),
      // Serif header.
      textEl(
        pos: const Offset(0.5, 0.18),
        size: const Size(0.84, 0.08),
        literal: 'the quiet wins',
        font: CardFontIx.serif,
        fontSize: 50,
        color: white,
        align: TextAlign.left,
        maxLines: 1,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.25),
        size: const Size(0.18, 0.005),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      // Checklist of small victories — bound to the user's sub-metrics.
      repeaterEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.84, 0.6),
        maxItems: 5,
        fontSize: 27,
        textColor: white,
        showAmount: false,
        showCalories: false,
        rowSpacing: 16,
      ),
      // Coda.
      textEl(
        pos: const Offset(0.5, 0.93),
        size: const Size(0.84, 0.04),
        literal: 'progress nobody else sees.',
        font: CardFontIx.serif,
        fontSize: 22,
        color: muted,
        align: TextAlign.left,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.62, 0.94), color: muted),
    ],
  );
}
