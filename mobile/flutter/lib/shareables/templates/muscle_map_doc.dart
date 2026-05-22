/// Editable-card preset for the **Muscle Map** template — sparkle eyebrow +
/// period, title, a centered anatomical heat-map chart, and a top-three
/// muscle-group legend rail.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc muscleMapDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'muscleMap',
    accent: accent,
    background: gradientBg([
      const Color(0xFF06080F),
      Color.lerp(accent, const Color(0xFF06080F), 0.85)!,
    ]),
    elements: [
      iconEl(
        pos: const Offset(0.11, 0.07),
        size: const Size(0.06, 0.03),
        emoji: '✨',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.32, 0.07),
        size: const Size(0.4, 0.04),
        literal: 'MUSCLE MAP',
        font: 1,
        fontSize: 26,
        color: accent,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.82, 0.07),
        size: const Size(0.3, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 22,
        color: Colors.white60,
        align: TextAlign.right,
        letterSpacing: 1.6,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.13),
        size: const Size(0.86, 0.06),
        binding: const DataBinding(BindingSource.title),
        fontSize: 52,
        align: TextAlign.center,
        maxLines: 1,
      ),
      chartEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.56),
        style: MacroVizStyle.appleRings,
      ),
      chipsEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.86, 0.07),
        layout: ChipLayout.row,
        maxItems: 3,
        chipColor: const Color(0x10FFFFFF),
        fontSize: 22,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: Colors.white),
    ],
  );
}
