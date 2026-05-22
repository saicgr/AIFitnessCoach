/// Editable-card preset for the **Meal Trading Card** food template — the meal
/// styled as a holographic sports trading card: a foil-gradient body with a
/// holo stroke border, a framed food-photo window, the meal name as the card
/// title, a macro stat block, and a "rarity" pill.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealTradingCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  final foilLo = Color.lerp(accent, const Color(0xFF1A1030), 0.55)!;
  final foilHi = Color.lerp(accent, const Color(0xFFEFE3FF), 0.35)!;
  return cardDoc(
    aspect: aspect,
    presetId: 'mealTradingCard',
    accent: accent,
    background: gradientBg([
      const Color(0xFF0A0810),
      const Color(0xFF050409),
    ]),
    elements: [
      // Foil card body.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.84, 0.84),
        shape: ShapeKind.rounded,
        gradient: [foilHi, foilLo, foilHi],
        cornerRadius: 32,
      ),
      // Holo stroke border.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.79, 0.79),
        shape: ShapeKind.rounded,
        fill: const Color(0x00000000),
        stroke: const Color(0xFFF4ECFF),
        strokeWidth: 2.4,
        cornerRadius: 24,
      ),
      // Rarity pill.
      shapeEl(
        pos: const Offset(0.5, 0.155),
        size: const Size(0.46, 0.058),
        shape: ShapeKind.pill,
        fill: const Color(0xFF0E0B16),
        stroke: const Color(0xFFF4ECFF),
        strokeWidth: 1.6,
      ),
      textEl(
        pos: const Offset(0.5, 0.155),
        size: const Size(0.44, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 22,
        color: const Color(0xFFF4ECFF),
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      // Food-photo window.
      photoEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.66, 0.4),
        mask: PhotoMask.rounded,
        cornerRadius: 16,
        frameColor: const Color(0xFFF4ECFF),
        frameWidth: 4,
      ),
      // Meal name card title.
      textEl(
        pos: const Offset(0.5, 0.65),
        size: const Size(0.7, 0.085),
        binding: const DataBinding(BindingSource.title),
        font: 7,
        fontSize: 42,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Macro stat block.
      chartEl(
        pos: const Offset(0.5, 0.77),
        size: const Size(0.74, 0.085),
        style: MacroVizStyle.numbers,
      ),
      chipsEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.74, 0.06),
        binding: const DataBinding(BindingSource.foodItemName),
        layout: ChipLayout.row,
        maxItems: 3,
        fontSize: 18,
        chipColor: const Color(0x33F4ECFF),
      ),
      watermarkEl(pos: const Offset(0.3, 0.92), color: Colors.white70),
    ],
  );
}
