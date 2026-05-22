/// Editable-card preset for the **Day in Meals** food template — a 2×2 grid
/// of the day's food photos with a macro-total banner pinned across the
/// bottom.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dayInMealsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const gap = 0.018;
  const cellW = 0.41;
  const cellH = 0.235;

  // 2×2 photo cell anchored on a grid centred at (0.5, 0.42).
  CardElement cell(int index) {
    final col = index % 2;
    final row = index ~/ 2;
    final cx = 0.5 + (col == 0 ? -1 : 1) * (cellW / 2 + gap / 2);
    final cy = 0.42 + (row == 0 ? -1 : 1) * (cellH / 2 + gap / 2);
    return photoEl(
      pos: Offset(cx, cy),
      size: const Size(cellW, cellH),
      binding: DataBinding(BindingSource.foodImageUrl, index: index),
      mask: PhotoMask.rounded,
      cornerRadius: 18,
    );
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'dayInMeals',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0C0D11), accent, 0.12)!,
      const Color(0xFF050608),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.075),
        size: const Size(0.86, 0.045),
        literal: 'A DAY ON MY PLATE',
        font: 7,
        fontSize: 34,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 1.5,
      ),
      textEl(
        pos: const Offset(0.5, 0.125),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 22,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      cell(0),
      cell(1),
      cell(2),
      cell(3),
      // Macro total banner.
      shapeEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.86, 0.16),
        shape: ShapeKind.rounded,
        fill: const Color(0xE6101216),
        stroke: accent.withValues(alpha: 0.4),
        strokeWidth: 1.5,
        cornerRadius: 20,
      ),
      textEl(
        pos: const Offset(0.5, 0.765),
        size: const Size(0.7, 0.045),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 44,
        color: Colors.white,
        align: TextAlign.center,
      ),
      chartEl(
        pos: const Offset(0.5, 0.855),
        size: const Size(0.78, 0.07),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white70),
    ],
  );
}
