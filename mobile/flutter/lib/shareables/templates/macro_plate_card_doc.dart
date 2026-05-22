/// Editable-card preset for the **Macro Plate** food template — a warm
/// "on your plate" card: eyebrow + title, a plate-style macro chart, a
/// calorie figure, and the food-name chips of what the meal contained.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroPlateCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cream = Color(0xFFFBF3E7);
  const amber = Color(0xFFE9B872);
  return cardDoc(
    aspect: aspect,
    presetId: 'macroPlateCard',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF1C1209), Color(0xFF120B05), Color(0xFF0B0703)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.8, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 24,
        color: amber,
        align: TextAlign.center,
        letterSpacing: 2.8,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.09),
        binding: const DataBinding(BindingSource.title),
        fontSize: 42,
        color: cream,
        align: TextAlign.center,
        maxLines: 2,
      ),
      chartEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.74, 0.38),
        style: MacroVizStyle.plate,
      ),
      textEl(
        pos: const Offset(0.5, 0.69),
        size: const Size(0.7, 0.06),
        binding: const DataBinding(BindingSource.calories),
        fontSize: 54,
        color: cream,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.735),
        size: const Size(0.7, 0.03),
        literal: 'KCAL',
        fontSize: 20,
        color: amber,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      chipsEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.84, 0.1),
        binding: const DataBinding(BindingSource.foodItemName),
        layout: ChipLayout.wrap,
        maxItems: 5,
        chipColor: const Color(0x22E9B872),
        textColor: cream,
        fontSize: 20,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: cream),
    ],
  );
}
