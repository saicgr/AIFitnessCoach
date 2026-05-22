/// Editable-card preset for the **Meal Scoreboard** food template — a
/// sports-arena LED scoreboard: a near-black panel with PROTEIN / CARBS / FAT
/// rendered as glowing segment-display rows in a mono face.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealScoreboardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const panel = Color(0xFF0A0B0E);
  const led = Color(0xFF3AE8B0);
  const ledDim = Color(0x223AE8B0);

  // One glowing scoreboard row: a dim slot bar + a bright LED number.
  List<CardElement> row(double y, String label, Color glow, BindingSource src) {
    return [
      shapeEl(
        pos: Offset(0.5, y),
        size: const Size(0.82, 0.13),
        shape: ShapeKind.rounded,
        fill: const Color(0xFF14161C),
        stroke: ledDim,
        strokeWidth: 1.5,
        cornerRadius: 14,
      ),
      textEl(
        pos: Offset(0.21, y),
        size: const Size(0.36, 0.05),
        literal: '$label  g',
        font: 4,
        fontSize: 24,
        color: glow.withValues(alpha: 0.85),
        align: TextAlign.left,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: Offset(0.72, y),
        size: const Size(0.36, 0.1),
        binding: DataBinding(src),
        font: 4,
        fontSize: 78,
        color: glow,
        align: TextAlign.right,
        shadow: ShadowSpec(color: glow.withValues(alpha: 0.7), blur: 26),
      ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'mealScoreboard',
    accent: accent,
    background: gradientBg(
      [const Color(0xFF050608), panel, const Color(0xFF02030A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.09),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 4,
        fontSize: 22,
        color: led.withValues(alpha: 0.8),
        align: TextAlign.center,
        letterSpacing: 6,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.165),
        size: const Size(0.88, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 44,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.275),
        size: const Size(0.6, 0.12),
        binding: const DataBinding(BindingSource.calories),
        font: 4,
        fontSize: 110,
        color: const Color(0xFFFFC53A),
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(color: Color(0xAAFFC53A), blur: 32),
      ),
      textEl(
        pos: const Offset(0.5, 0.345),
        size: const Size(0.5, 0.03),
        literal: 'KCAL',
        font: 4,
        fontSize: 22,
        color: const Color(0xCCFFC53A),
        align: TextAlign.center,
        letterSpacing: 8,
      ),
      ...row(0.46, 'PROTEIN', const Color(0xFF4F9EFF),
          BindingSource.proteinG),
      ...row(0.61, 'CARBS', const Color(0xFFFFB23A), BindingSource.carbsG),
      ...row(0.76, 'FAT', const Color(0xFFFF5C7A), BindingSource.fatG),
      watermarkEl(pos: const Offset(0.30, 0.93), color: led),
    ],
  );
}
