/// Editable-card preset for the **Recipe Card** food template — a kitchen
/// index-card look: a cream card with a dotted inner border, the ingredient
/// list on the left and a macro panel on the right, set in a handwritten-ish
/// serif.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc recipeCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cream = Color(0xFFF7F1E1);
  const ink = Color(0xFF2A2620);

  return cardDoc(
    aspect: aspect,
    presetId: 'recipeCard',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0D0C0A), accent, 0.10)!,
      const Color(0xFF050404),
    ]),
    elements: [
      // The index card.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.84),
        shape: ShapeKind.rounded,
        fill: cream,
        cornerRadius: 14,
      ),
      // Dotted inner border frame (four dotted rules).
      dividerEl(
        pos: const Offset(0.5, 0.13),
        size: const Size(0.74, 0.006),
        style: DividerStyle.dotted,
        color: accent.withValues(alpha: 0.7),
        thickness: 3,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.87),
        size: const Size(0.74, 0.006),
        style: DividerStyle.dotted,
        color: accent.withValues(alpha: 0.7),
        thickness: 3,
      ),
      // Accent ruled header band.
      textEl(
        pos: const Offset(0.5, 0.17),
        size: const Size(0.78, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: 8,
        fontSize: 50,
        color: ink,
        align: TextAlign.center,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.235),
        size: const Size(0.74, 0.035),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 9,
        fontSize: 22,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      // Left column heading + ingredient list.
      textEl(
        pos: const Offset(0.31, 0.31),
        size: const Size(0.4, 0.035),
        literal: 'INGREDIENTS',
        font: 4,
        fontSize: 18,
        color: ink,
        align: TextAlign.left,
        letterSpacing: 2,
      ),
      repeaterEl(
        pos: const Offset(0.33, 0.56),
        size: const Size(0.44, 0.44),
        maxItems: 8,
        fontSize: 21,
        textColor: ink,
        showAmount: true,
        showCalories: false,
      ),
      // Vertical rule between columns.
      shapeEl(
        pos: const Offset(0.57, 0.56),
        size: const Size(0.004, 0.44),
        shape: ShapeKind.rect,
        fill: ink.withValues(alpha: 0.18),
      ),
      // Right column — macro panel.
      textEl(
        pos: const Offset(0.74, 0.31),
        size: const Size(0.34, 0.035),
        literal: 'PER SERVING',
        font: 4,
        fontSize: 18,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      chartEl(
        pos: const Offset(0.74, 0.47),
        size: const Size(0.34, 0.22),
        style: MacroVizStyle.donutTrio,
      ),
      chartEl(
        pos: const Offset(0.74, 0.69),
        size: const Size(0.34, 0.16),
        style: MacroVizStyle.label,
      ),
      watermarkEl(pos: const Offset(0.30, 0.92), color: ink),
    ],
  );
}
