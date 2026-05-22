/// Editable-card preset for the **WeeklyReport** template — a deep-indigo
/// report card with an eyebrow + period header, a 7-bar weekly column
/// chart and a stacked highlight list below it.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc weeklyReportDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  // Decorative bar heights (the editor's chart layer is data-driven).
  const heights = [0.16, 0.24, 0.12, 0.28, 0.2, 0.3, 0.14];
  final elements = <CardElement>[
    textEl(
      pos: const Offset(0.5, 0.09),
      size: const Size(0.84, 0.04),
      literal: 'WEEKLY REPORT',
      font: 1,
      fontSize: 26,
      color: accent,
      letterSpacing: 3,
      allCaps: true,
    ),
    textEl(
      pos: const Offset(0.5, 0.13),
      size: const Size(0.84, 0.035),
      binding: const DataBinding(BindingSource.periodLabel),
      font: 2,
      fontSize: 24,
      color: const Color(0x99FFFFFF),
      maxLines: 1,
    ),
  ];
  // 7-bar weekly column chart.
  for (var i = 0; i < 7; i++) {
    final x = 0.16 + i * 0.113;
    final h = heights[i];
    final barCenterY = 0.5 - h / 2;
    elements.add(shapeEl(
      pos: Offset(x, barCenterY),
      size: Size(0.07, h),
      shape: ShapeKind.rounded,
      gradient: [accent, Color.lerp(accent, const Color(0xFFFFFFFF), 0.3)!],
      cornerRadius: 8,
    ));
    elements.add(textEl(
      pos: Offset(x, 0.55),
      size: const Size(0.08, 0.03),
      literal: weekdays[i],
      font: 1,
      fontSize: 18,
      color: const Color(0xA6FFFFFF),
      align: TextAlign.center,
      maxLines: 1,
    ));
  }
  // Highlight list backing.
  elements.add(shapeEl(
    pos: const Offset(0.5, 0.78),
    size: const Size(0.86, 0.26),
    shape: ShapeKind.rounded,
    fill: const Color(0x14FFFFFF),
    cornerRadius: 18,
  ));
  elements.add(chipsEl(
    pos: const Offset(0.5, 0.78),
    size: const Size(0.78, 0.22),
    binding: const DataBinding(BindingSource.highlightLabel),
    layout: ChipLayout.column,
    maxItems: 3,
    fontSize: 22,
  ));
  elements.add(watermarkEl(
    pos: const Offset(0.62, 0.95),
    color: Colors.white,
  ));
  return cardDoc(
    aspect: aspect,
    presetId: 'weeklyReport',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0E1226), Color(0xFF11193D), Color(0xFF050616)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: elements,
  );
}
