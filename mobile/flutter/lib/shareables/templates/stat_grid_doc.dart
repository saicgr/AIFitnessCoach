/// Editable-card preset for the **Stat Grid** template — title + hero on the
/// top half, a 2×2 grid of highlight tiles on the bottom half.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc statGridDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  // 2×2 tile centers within the bottom half of the card.
  const tileW = 0.41;
  const tileH = 0.16;
  const tileCenters = [
    Offset(0.295, 0.62),
    Offset(0.705, 0.62),
    Offset(0.295, 0.8),
    Offset(0.705, 0.8),
  ];
  return cardDoc(
    aspect: aspect,
    presetId: 'statGrid',
    accent: accent,
    background: gradientBg([
      Color.lerp(accent, const Color(0xFF0D1117), 0.82)!,
      const Color(0xFF0D1117),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 26,
        color: accent,
        letterSpacing: 2.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.15),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 2,
        fontSize: 26,
        color: Colors.white70,
      ),
      textEl(
        pos: const Offset(0.5, 0.32),
        size: const Size(0.9, 0.16),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 160,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      for (var i = 0; i < 4; i++) ...[
        shapeEl(
          pos: tileCenters[i],
          size: const Size(tileW, tileH),
          fill: const Color(0x0DFFFFFF),
          stroke: const Color(0x14FFFFFF),
          strokeWidth: 1,
          cornerRadius: 16,
        ),
        textEl(
          pos: tileCenters[i].translate(0, -0.035),
          size: const Size(tileW - 0.06, 0.03),
          binding: DataBinding(BindingSource.highlightLabel, index: i),
          font: 1,
          fontSize: 20,
          color: Colors.white60,
          letterSpacing: 1.2,
          allCaps: true,
        ),
        textEl(
          pos: tileCenters[i].translate(0, 0.03),
          size: const Size(tileW - 0.06, 0.05),
          binding: DataBinding(BindingSource.highlightValue, index: i),
          font: 1,
          fontSize: 44,
        ),
      ],
      watermarkEl(pos: const Offset(0.62, 0.93), color: Colors.white),
    ],
  );
}
