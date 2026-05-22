/// Editable-card preset for the **Food Score** food template — the meal's
/// 1-10 health score as the hero: eyebrow + title, a large circular score
/// badge, and a donut-trio macro mini block beneath it.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc foodScoreCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'foodScoreCard',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0A0C11), accent, 0.16)!,
      const Color(0xFF050608),
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
        letterSpacing: 3.2,
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
      badgeEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.5, 0.28),
        gradient: [accent, Color.lerp(accent, Colors.black, 0.45)!],
        label: 'OUT OF 10',
        valueBinding: const DataBinding(BindingSource.healthScore),
      ),
      chartEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.82, 0.2),
        style: MacroVizStyle.donutTrio,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70),
    ],
  );
}
