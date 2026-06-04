/// Editable-card preset for the **Infographic Stat Sheet** data/meme template —
/// "[WORKOUT] BY THE NUMBERS": a bold accent headline over a 2×2 grid of big
/// stat tiles (volume, sets, PR, minutes), then a streak strip at the foot.
/// Every tile value + label is an editable layer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataInfographicDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataInfographic',
    accent: volt,
    background: gradientBg(
      [const Color(0xFF101820), const Color(0xFF07080A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    elements: [
      // Period eyebrow.
      textEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.86, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 16,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      // Headline.
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.9, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 58,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.225),
        size: const Size(0.86, 0.03),
        literal: 'BY THE NUMBERS',
        font: CardFontIx.cond,
        fontSize: 28,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 5,
      ),
      // 2×2 big-stat grid (emoji baked into the value cell for punch).
      statGridEl(
        pos: const Offset(0.5, 0.53),
        size: const Size(0.86, 0.46),
        columns: 2,
        tiles: const [
          ['💪  9,128', 'KG MOVED'],
          ['🔁  16', 'SETS'],
          ['🏆  225', 'BENCH PR'],
          ['⏱  61', 'MINUTES'],
        ],
        tileColor: const Color(0x0FFFFFFF),
        valueColor: Colors.white,
        labelColor: const Color(0x99FFFFFF),
        valueFontSize: 40,
        labelFontSize: 18,
        valueFont: CardFontIx.display,
        spacing: 14,
        cornerRadius: 18,
      ),
      // Streak strip foot.
      shapeEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.86, 0.06),
        shape: ShapeKind.rounded,
        fill: const Color(0x16B8FF2F),
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.8, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 26,
        color: volt,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.955), color: const Color(0xFFFFFFFF)),
    ],
  );
}
