/// Editable-card preset for the **MonthlyPlanGrid** template — a calendar
/// card on a light surface: title + month label, a Mon-first day-of-week
/// header, and a 6×7 grid of day cells approximated with shapes.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc monthlyPlanGridDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final elements = <CardElement>[
    // Light calendar card.
    shapeEl(
      pos: const Offset(0.5, 0.52),
      size: const Size(0.92, 0.84),
      shape: ShapeKind.rounded,
      fill: const Color(0xFFFAFAFA),
      cornerRadius: 24,
    ),
    textEl(
      pos: const Offset(0.5, 0.16),
      size: const Size(0.78, 0.06),
      binding: const DataBinding(BindingSource.title),
      font: 1,
      fontSize: 50,
      color: const Color(0xFF111111),
      maxLines: 1,
    ),
    textEl(
      pos: const Offset(0.5, 0.21),
      size: const Size(0.78, 0.04),
      binding: const DataBinding(BindingSource.periodLabel),
      fontSize: 24,
      color: const Color(0xFF7A7A7A),
      maxLines: 1,
    ),
  ];
  // Day-of-week header.
  for (var c = 0; c < 7; c++) {
    final x = 0.13 + c * 0.123;
    elements.add(textEl(
      pos: Offset(x, 0.27),
      size: const Size(0.1, 0.03),
      literal: dow[c],
      font: 1,
      fontSize: 18,
      color: const Color(0xFF888888),
      align: TextAlign.center,
      maxLines: 1,
    ));
  }
  // 6 rows × 7 columns of day cells.
  for (var r = 0; r < 6; r++) {
    for (var c = 0; c < 7; c++) {
      final x = 0.13 + c * 0.123;
      final y = 0.33 + r * 0.1;
      final workout = (r + c) % 3 == 0;
      elements.add(shapeEl(
        pos: Offset(x, y),
        size: const Size(0.11, 0.085),
        shape: ShapeKind.rounded,
        fill: workout
            ? accent.withValues(alpha: 0.14)
            : const Color(0xFFFFFFFF),
        stroke: workout
            ? accent.withValues(alpha: 0.5)
            : const Color(0xFFE5E5E5),
        strokeWidth: workout ? 1.2 : 0.6,
        cornerRadius: 8,
      ));
    }
  }
  elements.add(watermarkEl(
    pos: const Offset(0.32, 0.93),
    color: const Color(0xFF111111),
  ));
  return cardDoc(
    aspect: aspect,
    presetId: 'monthlyPlanGrid',
    accent: accent,
    background: gradientBg([
      Color.lerp(accent, const Color(0xFF0D1117), 0.82)!,
      const Color(0xFF0D1117),
    ]),
    elements: elements,
  );
}
