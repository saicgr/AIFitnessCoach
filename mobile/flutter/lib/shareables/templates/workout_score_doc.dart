/// Editable-card preset for the **Workout Score** template — a dark
/// scorecard: a "Workout Score" kicker, period label, workout title, a big
/// center score ring (out of 100), and a row of four sub-score mini-rings.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc workoutScoreDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'workoutScore',
    accent: accent,
    background: gradientBg(
      [
        const Color(0xFF06080F),
        Color.lerp(accent, const Color(0xFF06080F), 0.85)!,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      iconEl(
        pos: const Offset(0.12, 0.08),
        size: const Size(0.055, 0.03),
        emoji: '✨',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.4, 0.08),
        size: const Size(0.5, 0.03),
        literal: 'WORKOUT SCORE',
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
        color: const Color(0x80FFFFFF),
        align: TextAlign.right,
        allCaps: true,
        letterSpacing: 1.6,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 44,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Big center score ring with hero value in the middle.
      chartEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.6, 0.42),
        style: MacroVizStyle.gauge,
      ),
      textEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.5, 0.12),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 150,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.5, 0.025),
        literal: 'OUT OF 100',
        font: 7,
        fontSize: 20,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 2.4,
      ),
      // Four sub-score mini-rings.
      chartEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.84, 0.12),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.2, 0.93), color: const Color(0xFFFFFFFF)),
    ],
  );
}
