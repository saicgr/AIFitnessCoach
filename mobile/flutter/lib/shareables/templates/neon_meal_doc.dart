/// Editable-card preset for the **Neon Meal** food template — a neon-sign
/// look: a dark brick-dark wall with the meal name and a key calorie stat in
/// glowing neon-tube lettering.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc neonMealDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const wall = Color(0xFF0B0A12);
  const pink = Color(0xFFFF3D9A);
  const cyan = Color(0xFF2BE8FF);
  const lime = Color(0xFFC6FF3D);

  return cardDoc(
    aspect: aspect,
    presetId: 'neonMeal',
    accent: accent,
    background: gradientBg(
      [const Color(0xFF14111F), wall, const Color(0xFF050409)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Faint neon frame tube.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.84),
        fill: const Color(0x00000000),
        stroke: cyan.withValues(alpha: 0.5),
        strokeWidth: 3,
        cornerRadius: 28,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.78, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 6,
        fontSize: 26,
        color: cyan,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
        shadow: const ShadowSpec(color: Color(0xCC2BE8FF), blur: 22),
      ),
      // Glowing neon meal name.
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.84, 0.22),
        binding: const DataBinding(BindingSource.title),
        font: 6,
        fontSize: 84,
        color: pink,
        align: TextAlign.center,
        maxLines: 3,
        lineHeight: 1.05,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(color: Color(0xEEFF3D9A), blur: 34),
      ),
      iconEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.14, 0.06),
        emoji: '🍴',
      ),
      // Big glowing calorie stat.
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.8, 0.16),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 160,
        color: lime,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(color: Color(0xEEC6FF3D), blur: 38),
      ),
      textEl(
        pos: const Offset(0.5, 0.77),
        size: const Size(0.7, 0.04),
        literal: 'CALORIES TONIGHT',
        font: 5,
        fontSize: 22,
        color: cyan,
        align: TextAlign.center,
        letterSpacing: 5,
        shadow: const ShadowSpec(color: Color(0xAA2BE8FF), blur: 18),
      ),
      // Neon macro chips.
      chipsEl(
        pos: const Offset(0.5, 0.85),
        size: const Size(0.82, 0.07),
        literalItems: const ['PROTEIN', 'CARBS', 'FAT'],
        layout: ChipLayout.row,
        maxItems: 3,
        chipColor: const Color(0x22FF3D9A),
        textColor: pink,
        fontSize: 18,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70),
    ],
  );
}
