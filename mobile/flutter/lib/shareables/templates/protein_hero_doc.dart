/// Editable-card preset for the **Protein Hero** food template — one
/// oversized protein-gram number centred, a small unit beside it, a thin
/// progress bar below, and calories/carbs/fat as three tiny chips at the
/// bottom.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc proteinHeroDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const protein = Color(0xFF34D399);
  return cardDoc(
    aspect: aspect,
    presetId: 'proteinHero',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0B1410), protein, 0.16)!,
      const Color(0xFF060807),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.86, 0.045),
        literal: 'PROTEIN LOGGED',
        font: 5,
        fontSize: 24,
        color: protein,
        align: TextAlign.center,
        letterSpacing: 6,
      ),
      textEl(
        pos: const Offset(0.5, 0.23),
        size: const Size(0.86, 0.045),
        binding: const DataBinding(BindingSource.title),
        font: 6,
        fontSize: 30,
        color: Colors.white70,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Oversized protein-gram number.
      textEl(
        pos: const Offset(0.43, 0.46),
        size: const Size(0.7, 0.32),
        binding: const DataBinding(BindingSource.proteinG),
        font: 1,
        fontSize: 320,
        color: Colors.white,
        align: TextAlign.right,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Small unit beside it.
      textEl(
        pos: const Offset(0.82, 0.52),
        size: const Size(0.24, 0.06),
        literal: 'grams',
        font: 6,
        fontSize: 40,
        color: protein,
        align: TextAlign.left,
      ),
      // Thin progress bar — track + fill.
      shapeEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.78, 0.022),
        shape: ShapeKind.pill,
        fill: const Color(0x22FFFFFF),
      ),
      shapeEl(
        pos: const Offset(0.34, 0.68),
        size: const Size(0.46, 0.022),
        shape: ShapeKind.pill,
        fill: protein,
      ),
      textEl(
        pos: const Offset(0.5, 0.73),
        size: const Size(0.78, 0.04),
        literal: 'on track for your daily target',
        font: 6,
        fontSize: 22,
        color: Colors.white54,
        align: TextAlign.center,
      ),
      // Three tiny macro chips at the bottom.
      chipsEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.88, 0.06),
        binding: const DataBinding(BindingSource.foodItemName),
        literalItems: const ['calories', 'carbs', 'fat'],
        layout: ChipLayout.row,
        maxItems: 3,
        spacing: 12,
        chipColor: const Color(0x1FFFFFFF),
        fontSize: 20,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: Colors.white54),
    ],
  );
}
