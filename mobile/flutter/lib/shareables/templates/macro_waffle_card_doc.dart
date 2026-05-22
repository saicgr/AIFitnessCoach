/// Editable-card preset for the **Macro Waffle** food template — eyebrow +
/// title + period, a 10×10 dot-grid macro chart, and a caption microcopy.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroWaffleCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'macroWaffleCard',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0B0D12), accent, 0.14)!,
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
        pos: const Offset(0.5, 0.54),
        size: const Size(0.8, 0.42),
        style: MacroVizStyle.waffle,
      ),
      textEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.84, 0.04),
        literal: 'Each square ≈ 1% of calories',
        fontSize: 20,
        color: const Color(0x8CFFFFFF),
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70),
    ],
  );
}
