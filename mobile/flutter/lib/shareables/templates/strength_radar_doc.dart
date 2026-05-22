/// Editable-card preset for the **Strength Radar** template — a dark card
/// with a "Strength Radar" kicker, period label, workout title, a balance
/// pill, and a six-axis radar / spider chart of strength balance.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc strengthRadarDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'strengthRadar',
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
        emoji: '🎯',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.4, 0.08),
        size: const Size(0.5, 0.03),
        literal: 'STRENGTH RADAR',
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
      // Balance pill.
      shapeEl(
        pos: const Offset(0.26, 0.22),
        size: const Size(0.32, 0.045),
        shape: ShapeKind.pill,
        fill: const Color(0x00000000),
        stroke: accent,
        strokeWidth: 1.4,
        cornerRadius: 20,
      ),
      textEl(
        pos: const Offset(0.26, 0.22),
        size: const Size(0.3, 0.035),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 1,
        fontSize: 24,
        align: TextAlign.center,
      ),
      // Radar chart placeholder.
      chartEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.82, 0.5),
        style: MacroVizStyle.plate,
      ),
      watermarkEl(pos: const Offset(0.2, 0.93), color: const Color(0xFFFFFFFF)),
    ],
  );
}
