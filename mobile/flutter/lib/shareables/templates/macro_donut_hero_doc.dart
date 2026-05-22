/// Editable-card preset for the **Macro Donut Hero** food template — a large
/// macro-pie donut centre-stage with a calorie label, an eyebrow + title
/// above, and a P/C/F legend chip strip beneath.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroDonutHeroDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'macroDonutHero',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0E1014), accent, 0.16)!,
      const Color(0xFF07080B),
    ]),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.045),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 5,
        fontSize: 26,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 5,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.17),
        size: const Size(0.86, 0.09),
        binding: const DataBinding(BindingSource.title),
        fontSize: 46,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Faint backing disc behind the donut.
      shapeEl(
        pos: const Offset(0.5, 0.48),
        size: const Size(0.84, 0.48),
        shape: ShapeKind.circle,
        fill: const Color(0x14FFFFFF),
      ),
      // The hero macro donut.
      chartEl(
        pos: const Offset(0.5, 0.48),
        size: const Size(0.72, 0.42),
        style: MacroVizStyle.macroPie,
      ),
      // Calorie label under the donut.
      textEl(
        pos: const Offset(0.39, 0.73),
        size: const Size(0.36, 0.05),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 34,
        color: Colors.white,
        align: TextAlign.right,
      ),
      textEl(
        pos: const Offset(0.66, 0.735),
        size: const Size(0.36, 0.05),
        literal: 'total calories',
        font: 2,
        fontSize: 26,
        color: Colors.white70,
        align: TextAlign.left,
        letterSpacing: 1,
      ),
      // P/C/F legend chips.
      chartEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.84, 0.09),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: Colors.white70),
    ],
  );
}
