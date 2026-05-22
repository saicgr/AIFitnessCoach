/// Editable-card preset for the **Meal Passport** food template — a passport
/// page: a navy cover panel with gold lettering, a white interior page, and a
/// circular "LOGGED" entry stamp.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealPassportDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const navy = Color(0xFF132042);
  const gold = Color(0xFFD9B14E);
  const page = Color(0xFFF3EEDF);
  const ink = Color(0xFF2A2D33);

  return cardDoc(
    aspect: aspect,
    presetId: 'mealPassport',
    accent: accent,
    background: gradientBg([const Color(0xFF0A1124), navy]),
    elements: [
      // Navy cover panel.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.9, 0.92),
        shape: ShapeKind.rounded,
        fill: navy,
        stroke: gold,
        strokeWidth: 2,
        cornerRadius: 20,
      ),
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.78, 0.035),
        literal: 'NUTRITION PASSPORT',
        font: 3,
        fontSize: 22,
        color: gold,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      iconEl(
        pos: const Offset(0.5, 0.17),
        size: const Size(0.16, 0.06),
        emoji: '🛂',
      ),
      // White interior page.
      shapeEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.78, 0.62),
        shape: ShapeKind.rounded,
        fill: page,
        cornerRadius: 12,
      ),
      textEl(
        pos: const Offset(0.5, 0.32),
        size: const Size(0.7, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 4,
        fontSize: 18,
        color: ink.withValues(alpha: 0.55),
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.72, 0.09),
        binding: const DataBinding(BindingSource.title),
        font: 8,
        fontSize: 50,
        color: ink,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.62, 0.004),
        style: DividerStyle.dotted,
        color: ink.withValues(alpha: 0.4),
      ),
      textEl(
        pos: const Offset(0.5, 0.57),
        size: const Size(0.6, 0.09),
        binding: const DataBinding(BindingSource.calories),
        font: 4,
        fontSize: 64,
        color: navy,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.625),
        size: const Size(0.5, 0.03),
        literal: 'CALORIES DECLARED',
        font: 4,
        fontSize: 15,
        color: ink.withValues(alpha: 0.5),
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      // Circular entry stamp, rotated for an inked feel.
      badgeEl(
        pos: const Offset(0.72, 0.73),
        size: const Size(0.28, 0.28),
        gradient: const [Color(0xFFB23A4A), Color(0xFF7E2532)],
        label: 'ENTRY',
        valueBinding: const DataBinding(BindingSource.literal),
        valueLiteral: 'LOGGED',
      ),
      watermarkEl(pos: const Offset(0.30, 0.85), color: ink),
    ],
  );
}
