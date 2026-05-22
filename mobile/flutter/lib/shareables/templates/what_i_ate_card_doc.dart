/// Editable-card preset for the **What I Ate** food template — a text/voice
/// log rendered as a large pull-quote of the user's own words, the parsed
/// food-name chips, and a macro-pills strip.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc whatIAteCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'whatIAteCard',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0B0D13), accent, 0.20)!,
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
        pos: const Offset(0.18, 0.2),
        size: const Size(0.3, 0.1),
        literal: '“',
        font: 7,
        fontSize: 120,
        color: accent.withValues(alpha: 0.55),
      ),
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.84, 0.34),
        binding: const DataBinding(BindingSource.logText),
        fontSize: 44,
        align: TextAlign.left,
        maxLines: 6,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      chipsEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.84, 0.1),
        binding: const DataBinding(BindingSource.foodItemName),
        layout: ChipLayout.wrap,
        maxItems: 6,
        fontSize: 21,
      ),
      chartEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.82, 0.09),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70),
    ],
  );
}
