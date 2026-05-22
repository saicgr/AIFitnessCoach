/// Editable-card preset for the **Macro Sparkline** food template — a wide
/// card with a small left photo square, a 7-point sparkline approximated
/// with shapeEl bars for the week, and a label + delta chip on the right.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroSparklineDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  // Relative 7-day bar heights (0..1) — an editable placeholder week.
  const heights = <double>[0.4, 0.62, 0.55, 0.78, 0.5, 0.85, 0.7];
  return cardDoc(
    aspect: aspect,
    presetId: 'macroSparkline',
    accent: accent,
    background: gradientBg([
      const Color(0xFF14161C),
      const Color(0xFF090A0D),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.13),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 42,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.19),
        size: const Size(0.86, 0.04),
        literal: 'THIS WEEK IN MACROS',
        font: 5,
        fontSize: 20,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // The wide card panel.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.36),
        shape: ShapeKind.rounded,
        fill: const Color(0xFF1C1F27),
        cornerRadius: 24,
      ),
      // Small left photo square.
      photoEl(
        pos: const Offset(0.22, 0.5),
        size: const Size(0.2, 0.2),
        mask: PhotoMask.rounded,
        cornerRadius: 16,
      ),
      // 7-point sparkline approximated with shapeEl bars.
      for (var i = 0; i < heights.length; i++)
        shapeEl(
          pos: Offset(0.4 + i * 0.054, 0.56 - heights[i] * 0.09),
          size: Size(0.03, heights[i] * 0.18),
          shape: ShapeKind.rounded,
          fill: accent,
          cornerRadius: 6,
        ),
      // Sparkline baseline.
      shapeEl(
        pos: const Offset(0.56, 0.58),
        size: const Size(0.42, 0.006),
        shape: ShapeKind.rounded,
        fill: const Color(0x33FFFFFF),
        cornerRadius: 3,
      ),
      // Label + delta chip on the right.
      textEl(
        pos: const Offset(0.5, 0.69),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.calories),
        font: 4,
        fontSize: 26,
        color: Colors.white70,
        align: TextAlign.center,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.4, 0.07),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.38, 0.05),
        literal: 'up 8% on protein',
        font: 7,
        fontSize: 24,
        color: const Color(0xFF101013),
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.87),
        size: const Size(0.84, 0.045),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 6,
        fontSize: 24,
        color: Colors.white54,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white54),
    ],
  );
}
