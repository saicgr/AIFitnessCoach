/// Editable-card preset for the **Nutrition Facts** food template — the whole
/// card is a parody of the FDA "Nutrition Facts" panel: black-on-cream,
/// thick rules, a giant calorie row, a macro label chart and ingredient list.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc nutritionFactsCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF111111);
  const paper = Color(0xFFFBFAF6);
  return cardDoc(
    aspect: aspect,
    presetId: 'nutritionFactsCard',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF101013), accent, 0.12)!,
      const Color(0xFF050608),
    ]),
    elements: [
      // The panel surface.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.84),
        shape: ShapeKind.rounded,
        fill: paper,
        stroke: ink,
        strokeWidth: 4,
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.5, 0.14),
        size: const Size(0.76, 0.06),
        literal: 'Nutrition Facts',
        font: 1,
        fontSize: 44,
        color: ink,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.2),
        size: const Size(0.76, 0.04),
        binding: const DataBinding(BindingSource.title),
        fontSize: 22,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.25),
        size: const Size(0.76, 0.012),
        color: ink,
        thickness: 8,
      ),
      // Calorie headline.
      textEl(
        pos: const Offset(0.27, 0.33),
        size: const Size(0.34, 0.06),
        literal: 'Calories',
        font: 1,
        fontSize: 32,
        color: ink,
        align: TextAlign.left,
      ),
      textEl(
        pos: const Offset(0.7, 0.33),
        size: const Size(0.34, 0.08),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 60,
        color: ink,
        align: TextAlign.right,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.39),
        size: const Size(0.76, 0.008),
        color: ink,
        thickness: 5,
      ),
      // Macro nutrient panel.
      chartEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.74, 0.2),
        style: MacroVizStyle.label,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.63),
        size: const Size(0.76, 0.008),
        color: ink,
        thickness: 5,
      ),
      // Ingredients list.
      repeaterEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.74, 0.2),
        maxItems: 6,
        fontSize: 22,
        textColor: ink,
        showAmount: true,
        showCalories: true,
      ),
      watermarkEl(pos: const Offset(0.30, 0.9), color: ink),
    ],
  );
}
