/// Editable-card preset for the **Elite** template — a gold-chrome stats
/// card: ELITE eyebrow + title, a giant hero number, and a stacked list of
/// up to four highlight rows.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc eliteDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const gold = Color(0xFFFDE68A);
  const goldBright = Color(0xFFFCD34D);
  return cardDoc(
    aspect: aspect,
    presetId: 'elite',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF181208), Color(0xFF3A2A0F), Color(0xFF0E0905)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.04),
        literal: 'ELITE',
        font: 1,
        fontSize: 28,
        color: goldBright,
        align: TextAlign.center,
        letterSpacing: 6,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 36,
        align: TextAlign.center,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.9, 0.2),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 200,
        color: gold,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Highlight rows.
      for (var i = 0; i < 4; i++) ...[
        textEl(
          pos: Offset(0.16, 0.64 + i * 0.075),
          size: const Size(0.5, 0.05),
          binding: DataBinding(BindingSource.highlightLabel, index: i),
          font: 1,
          fontSize: 24,
          color: gold.withValues(alpha: 0.85),
          letterSpacing: 1.6,
          allCaps: true,
        ),
        textEl(
          pos: Offset(0.84, 0.64 + i * 0.075),
          size: const Size(0.36, 0.05),
          binding: DataBinding(BindingSource.highlightValue, index: i),
          font: 1,
          fontSize: 28,
          align: TextAlign.right,
        ),
        dividerEl(
          pos: Offset(0.5, 0.675 + i * 0.075),
          size: const Size(0.84, 0.003),
          color: goldBright.withValues(alpha: 0.25),
          thickness: 1,
        ),
      ],
      watermarkEl(pos: const Offset(0.3, 0.95), color: gold),
    ],
  );
}
