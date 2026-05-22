/// Editable-card preset for the **Smart Insight** template — sparkle-badged
/// INSIGHT eyebrow, period label, a big auto-generated insight headline, a
/// one-line rationale, and a supporting mini bar chart.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc smartInsightDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'smartInsight',
    accent: accent,
    background: gradientBg([
      const Color(0xFF0B0F19),
      Color.lerp(accent, const Color(0xFF0B0F19), 0.85)!,
    ]),
    elements: [
      shapeEl(
        pos: const Offset(0.13, 0.075),
        size: const Size(0.1, 0.045),
        shape: ShapeKind.rounded,
        gradient: [
          accent.withValues(alpha: 0.85),
          accent.withValues(alpha: 0.45),
        ],
        cornerRadius: 12,
      ),
      iconEl(
        pos: const Offset(0.13, 0.075),
        size: const Size(0.06, 0.03),
        emoji: '✨',
      ),
      textEl(
        pos: const Offset(0.34, 0.075),
        size: const Size(0.4, 0.04),
        literal: 'INSIGHT',
        font: 1,
        fontSize: 26,
        color: accent,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.22, 0.14),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 24,
        color: Colors.white54,
        letterSpacing: 2.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(0.84, 0.18),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 72,
        lineHeight: 1.1,
        letterSpacing: -0.5,
        maxLines: 4,
      ),
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.84, 0.08),
        binding: const DataBinding(BindingSource.caption),
        fontSize: 28,
        color: Colors.white70,
        lineHeight: 1.4,
        maxLines: 3,
      ),
      chartEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.84, 0.28),
        style: MacroVizStyle.columnChart,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: Colors.white),
    ],
  );
}
