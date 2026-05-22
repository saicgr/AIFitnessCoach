/// Editable-card preset for the **Calendar Heatmap** template — a
/// GitHub-style year-in-review grid card: eyebrow + title, a dotGrid chart
/// standing in for the contribution heatmap, a legend strip and stat chips.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc calendarHeatmapDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'calendarHeatmap',
    accent: accent,
    background: gradientBg([
      Color.lerp(accent, const Color(0xFF0D1117), 0.84)!,
      const Color(0xFF0D1117),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 26,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.17),
        size: const Size(0.86, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 46,
        align: TextAlign.center,
        maxLines: 2,
      ),
      // Heatmap panel.
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.86, 0.26),
        shape: ShapeKind.rounded,
        fill: const Color(0x14FFFFFF),
        stroke: accent.withValues(alpha: 0.3),
        strokeWidth: 1.5,
        cornerRadius: 18,
      ),
      chartEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.76, 0.2),
        style: MacroVizStyle.waffle,
      ),
      textEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.8, 0.03),
        literal: 'Less ▢▢▢▢ More',
        font: 0,
        fontSize: 18,
        color: Colors.white60,
        align: TextAlign.center,
        letterSpacing: 1,
      ),
      // Stat chips.
      textEl(
        pos: const Offset(0.27, 0.74),
        size: const Size(0.4, 0.06),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 1,
        fontSize: 36,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.73, 0.74),
        size: const Size(0.4, 0.06),
        binding: const DataBinding(BindingSource.highlightValue, index: 1),
        font: 1,
        fontSize: 36,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.27, 0.8),
        size: const Size(0.4, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 0),
        font: 0,
        fontSize: 18,
        color: Colors.white60,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.73, 0.8),
        size: const Size(0.4, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 1),
        font: 0,
        fontSize: 18,
        color: Colors.white60,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: Colors.white),
    ],
  );
}
