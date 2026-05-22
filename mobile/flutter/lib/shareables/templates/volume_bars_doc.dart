/// Editable-card preset for the **Volume Bars** template — a tinted card
/// with a "Volume" kicker, period label, workout title, a total/avg/peak
/// stat row, and a vertical bar chart of volume across the period.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc volumeBarsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'volumeBars',
    accent: accent,
    background: gradientBg([
      Color.lerp(accent, const Color(0xFF0D1117), 0.80)!,
      const Color(0xFF0D1117),
    ]),
    elements: [
      iconEl(
        pos: const Offset(0.12, 0.08),
        size: const Size(0.055, 0.03),
        emoji: '📊',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.36, 0.08),
        size: const Size(0.42, 0.03),
        literal: 'VOLUME',
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
      // Total / avg / peak stat row.
      chartEl(
        pos: const Offset(0.5, 0.26),
        size: const Size(0.84, 0.08),
        style: MacroVizStyle.numbers,
      ),
      // Vertical bar chart placeholder.
      chartEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.84, 0.46),
        style: MacroVizStyle.columnChart,
      ),
      watermarkEl(pos: const Offset(0.2, 0.93), color: const Color(0xFFFFFFFF)),
    ],
  );
}
