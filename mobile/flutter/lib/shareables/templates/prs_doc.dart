/// Editable-card preset for the **PRs** template — an indigo medal card: a
/// "Personal Records" kicker, period label, a large hero number, and a
/// ranked list of recent PRs (label/value rows).
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc prsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const gold = Color(0xFFFCD34D);
  return cardDoc(
    aspect: aspect,
    presetId: 'prs',
    accent: accent,
    background: gradientBg(
      [const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF0F0F1F)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.09),
        size: const Size(0.84, 0.03),
        literal: 'PERSONAL RECORDS',
        font: 1,
        fontSize: 26,
        color: gold,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.5, 0.13),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 2,
        fontSize: 26,
        color: const Color(0xA6FFFFFF),
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(0.9, 0.14),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 150,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      repeaterEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.86, 0.5),
        maxItems: 5,
        fontSize: 28,
        textColor: const Color(0xFFFFFFFF),
        showCalories: false,
      ),
      watermarkEl(pos: const Offset(0.5, 0.95), color: const Color(0xFFFFFFFF)),
    ],
  );
}
