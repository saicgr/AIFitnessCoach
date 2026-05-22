/// Editable-card preset for the **WeeklyPlanGrid** template — a light card
/// with a title and a 2×4 grid of day tiles (Mon–Sun) approximated with
/// shapes + weekday labels for the week's workout plan.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc weeklyPlanGridDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  final elements = <CardElement>[
    // Light grid card.
    shapeEl(
      pos: const Offset(0.5, 0.52),
      size: const Size(0.92, 0.84),
      shape: ShapeKind.rounded,
      fill: const Color(0xFFFAFAFA),
      cornerRadius: 24,
    ),
    textEl(
      pos: const Offset(0.5, 0.15),
      size: const Size(0.82, 0.06),
      binding: const DataBinding(BindingSource.title),
      font: 1,
      fontSize: 46,
      color: const Color(0xFF111111),
      maxLines: 2,
    ),
    textEl(
      pos: const Offset(0.5, 0.2),
      size: const Size(0.82, 0.035),
      binding: const DataBinding(BindingSource.periodLabel),
      fontSize: 22,
      color: const Color(0xFF666666),
      maxLines: 1,
    ),
  ];
  // 2 columns × 4 rows = 8 tiles (7 days + spare).
  for (var i = 0; i < 7; i++) {
    final col = i % 2;
    final row = i ~/ 2;
    final x = col == 0 ? 0.29 : 0.71;
    final y = 0.3 + row * 0.16;
    elements.add(shapeEl(
      pos: Offset(x, y),
      size: const Size(0.4, 0.14),
      shape: ShapeKind.rounded,
      fill: const Color(0xFFFFFFFF),
      stroke: const Color(0xFFE0E0E0),
      strokeWidth: 0.8,
      cornerRadius: 12,
    ));
    elements.add(textEl(
      pos: Offset(x - 0.12, y - 0.05),
      size: const Size(0.14, 0.025),
      literal: weekdays[i],
      font: 1,
      fontSize: 16,
      color: const Color(0xFF888888),
      letterSpacing: 1.4,
      maxLines: 1,
    ));
  }
  elements.add(watermarkEl(
    pos: const Offset(0.32, 0.93),
    color: const Color(0xFF111111),
  ));
  return cardDoc(
    aspect: aspect,
    presetId: 'weeklyPlanGrid',
    accent: accent,
    background: gradientBg([
      Color.lerp(accent, const Color(0xFF0D1117), 0.82)!,
      const Color(0xFF0D1117),
    ]),
    elements: elements,
  );
}
