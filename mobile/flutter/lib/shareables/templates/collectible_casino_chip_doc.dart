/// Editable-card preset for the **Casino Chip** collectible — a felt-green
/// table backdrop with a stacked poker chip: a red disc with a dashed white
/// rim, the hero stat as the chip's denomination, an "ALL IN" sub-line, and a
/// gold tagline beneath. Every text is editable; the denomination + tagline
/// bind to / quote live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleCasinoChipDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const gold = Color(0xFFFFD700);
  const chipRed = Color(0xFFC0392B);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleCasinoChip',
    accent: accent,
    background: CardBackground(
      kind: CardBackgroundKind.linearGradient,
      colors: const [Color(0xFF1A6B3A), Color(0xFF0A2417)],
      begin: Alignment.center,
      end: Alignment.bottomRight,
    ),
    elements: [
      // Radial felt vignette.
      shapeEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(1.2, 0.7),
        shape: ShapeKind.circle,
        gradient: const [Color(0x331A6B3A), Color(0x000A2417)],
        radial: true,
      ),
      // Outer dashed rim ring.
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.62, 0.62),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        stroke: white,
        strokeWidth: 8,
      ),
      // Chip disc.
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.5, 0.5),
        shape: ShapeKind.circle,
        fill: chipRed,
        stroke: white,
        strokeWidth: 3,
      ),
      // Denomination (hero stat).
      textEl(
        pos: const Offset(0.5, 0.39),
        size: const Size(0.44, 0.08),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 64,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // ALL IN sub-line.
      textEl(
        pos: const Offset(0.5, 0.47),
        size: const Size(0.44, 0.03),
        literal: 'ALL IN',
        font: CardFontIx.cond,
        fontSize: 18,
        color: white,
        align: TextAlign.center,
        letterSpacing: 4,
        maxLines: 1,
      ),
      // Title pinned over the chip.
      textEl(
        pos: const Offset(0.5, 0.7),
        size: const Size(0.82, 0.045),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 40,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Gold tagline.
      textEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.82, 0.03),
        literal: 'HOUSE ALWAYS LIFTS',
        font: CardFontIx.cond,
        fontSize: 18,
        color: gold,
        align: TextAlign.center,
        letterSpacing: 4,
        maxLines: 1,
      ),
      // Period stamp.
      textEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.82, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 15,
        color: const Color(0xCCFFFFFF),
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: white),
    ],
  );
}
