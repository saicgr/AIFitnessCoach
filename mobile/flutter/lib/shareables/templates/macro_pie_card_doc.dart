/// Editable-card preset for the **Macro Pie** food template — an accent
/// kicker bar + eyebrow + title, a centered macro-pie donut, and a P/C/F
/// pills legend strip.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroPieCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'macroPieCard',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0C0E16), accent, 0.14)!,
      const Color(0xFF080A11),
    ]),
    elements: [
      shapeEl(
        pos: const Offset(0.1, 0.12),
        size: const Size(0.018, 0.03),
        shape: ShapeKind.pill,
        fill: accent,
        cornerRadius: 99,
      ),
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.78, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 24,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 2.6,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.09),
        binding: const DataBinding(BindingSource.title),
        fontSize: 42,
        align: TextAlign.center,
        maxLines: 2,
      ),
      chartEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.42),
        style: MacroVizStyle.macroPie,
      ),
      chartEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.82, 0.09),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70),
    ],
  );
}
