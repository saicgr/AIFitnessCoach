/// Editable-card preset for the **Macro Bars** food template — eyebrow +
/// title + period, then a centered linear progress-bar macro chart.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroBarsCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'macroBarsCard',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0C0E13), accent, 0.15)!,
      const Color(0xFF06070A),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.045),
        binding: const DataBinding(BindingSource.mealLabel),
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
        fontSize: 44,
        align: TextAlign.center,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.24),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        fontSize: 22,
        color: const Color(0x80FFFFFF),
        align: TextAlign.center,
      ),
      chartEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.82, 0.4),
        style: MacroVizStyle.progressBars,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70),
    ],
  );
}
