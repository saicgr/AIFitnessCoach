/// Editable-card preset for the **Macro Tier List** food template — the meal
/// scored as an internet-meme tier list: coloured S/A/B/C bands, each labelled
/// with a big letter, and the parsed food-name chips dropped onto the S row.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroTierListDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF0E0F13);

  // One tier row: a coloured band + a square letter label on the left.
  List<CardElement> tier(String letter, Color band, double cy) => [
        shapeEl(
          pos: Offset(0.56, cy),
          size: const Size(0.78, 0.13),
          shape: ShapeKind.rounded,
          fill: band,
          cornerRadius: 10,
        ),
        shapeEl(
          pos: Offset(0.17, cy),
          size: const Size(0.16, 0.13),
          shape: ShapeKind.rounded,
          fill: Color.lerp(band, ink, 0.35)!,
          cornerRadius: 10,
        ),
        textEl(
          pos: Offset(0.17, cy),
          size: const Size(0.16, 0.1),
          literal: letter,
          font: 1,
          fontSize: 56,
          color: Colors.white,
          align: TextAlign.center,
        ),
      ];

  return cardDoc(
    aspect: aspect,
    presetId: 'macroTierList',
    accent: accent,
    background: gradientBg([
      Color.lerp(ink, accent, 0.10)!,
      const Color(0xFF050608),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.085),
        size: const Size(0.9, 0.06),
        literal: 'MEAL TIER LIST',
        font: 7,
        fontSize: 40,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.15),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 24,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      ...tier('S', const Color(0xFFEF4444), 0.30),
      ...tier('A', const Color(0xFFF59E0B), 0.45),
      ...tier('B', const Color(0xFF22C55E), 0.60),
      ...tier('C', const Color(0xFF3B82F6), 0.75),
      // The meal's foods land on the S row.
      chipsEl(
        pos: const Offset(0.56, 0.30),
        size: const Size(0.74, 0.11),
        binding: const DataBinding(BindingSource.foodItemName),
        layout: ChipLayout.wrap,
        maxItems: 5,
        fontSize: 19,
        chipColor: const Color(0x33000000),
      ),
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.84, 0.045),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 30,
        color: Colors.white,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white70),
    ],
  );
}
