/// Editable-card preset for the **Weight Graph** template — a dark card
/// with a "Weight Trend" kicker, period label, title, the latest value in
/// big type with a delta pill, a line chart, and start/peak/latest
/// milestones.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc weightGraphDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'weightGraph',
    accent: accent,
    background: gradientBg(
      [const Color(0xFF06080F), const Color(0xFF050810)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      iconEl(
        pos: const Offset(0.12, 0.08),
        size: const Size(0.055, 0.03),
        emoji: '📈',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.4, 0.08),
        size: const Size(0.5, 0.03),
        literal: 'WEIGHT TREND',
        font: 1,
        fontSize: 26,
        color: accent,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.82, 0.08),
        size: const Size(0.3, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 22,
        color: const Color(0x8CFFFFFF),
        align: TextAlign.right,
        allCaps: true,
        letterSpacing: 1.6,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 48,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.34, 0.26),
        size: const Size(0.5, 0.1),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 128,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Delta pill.
      shapeEl(
        pos: const Offset(0.78, 0.25),
        size: const Size(0.26, 0.05),
        shape: ShapeKind.pill,
        fill: const Color(0x00000000),
        stroke: accent,
        strokeWidth: 1.4,
        cornerRadius: 20,
      ),
      textEl(
        pos: const Offset(0.78, 0.25),
        size: const Size(0.24, 0.035),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 1,
        fontSize: 24,
        align: TextAlign.center,
      ),
      // Line chart placeholder.
      chartEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.84, 0.34),
        style: MacroVizStyle.columnChart,
      ),
      // Start / peak / latest milestone row.
      chartEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.84, 0.08),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.2, 0.93), color: const Color(0xFFFFFFFF)),
    ],
  );
}
