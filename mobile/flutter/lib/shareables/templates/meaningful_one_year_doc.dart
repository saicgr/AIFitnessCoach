/// Editable-card preset — **One Year Stronger**: an anniversary card. A
/// radial-spotlight dark field, a "ONE YEAR STRONGER" eyebrow, a giant Anton
/// "365" in volt, and a THEN → NOW comparison row (e.g. 135 → 225 bench). Built
/// to mark a full year of training with a single resonant before/after stat.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulOneYearDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const muted = Color(0x99FFFFFF);
  const white = Color(0xFFFFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulOneYear',
    accent: accent,
    background: CardBackground(
      kind: CardBackgroundKind.linearGradient,
      colors: const [Color(0xFF1A2410), Color(0xFF070709)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Radial spotlight behind the number.
      shapeEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(1.2, 0.9),
        shape: ShapeKind.circle,
        gradient: const [Color(0x3322C55E), Color(0x00000000)],
        radial: true,
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.31),
        size: const Size(0.86, 0.03),
        literal: 'ONE YEAR STRONGER',
        font: CardFontIx.cond,
        fontSize: 18,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 5,
        maxLines: 1,
      ),
      // The big "365".
      textEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.9, 0.16),
        literal: '365',
        font: CardFontIx.display,
        fontSize: 120,
        color: accent,
        align: TextAlign.center,
        lineHeight: 0.85,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.54),
        size: const Size(0.86, 0.03),
        literal: 'DAYS OF SHOWING UP',
        font: CardFontIx.cond,
        fontSize: 16,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 4,
        maxLines: 1,
      ),
      // THEN → NOW comparison row.
      textEl(
        pos: const Offset(0.27, 0.7),
        size: const Size(0.26, 0.03),
        literal: 'THEN',
        font: CardFontIx.cond,
        fontSize: 14,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 2,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.27, 0.755),
        size: const Size(0.26, 0.05),
        literal: '135',
        font: CardFontIx.display,
        fontSize: 40,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.745),
        size: const Size(0.12, 0.06),
        literal: '→',
        fontSize: 32,
        color: accent,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.73, 0.7),
        size: const Size(0.26, 0.03),
        literal: 'NOW',
        font: CardFontIx.cond,
        fontSize: 14,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 2,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.73, 0.755),
        size: const Size(0.26, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: CardFontIx.display,
        fontSize: 40,
        color: accent,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 0),
        font: CardFontIx.cond,
        fontSize: 14,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: muted),
    ],
  );
}
