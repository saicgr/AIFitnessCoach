/// Editable-card preset for the **Macro Dashboard** food template — a 2×2
/// grid of mini stat tiles (calories, protein, fibre, water). Each tile is
/// an icon chip + a big number + a thin progress bar. A clean dashboard
/// look with no headline photo.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroDashboardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const tileC = Color(0xFF15171F);

  // One dashboard tile centred at (cx, cy): card + emoji + value + bar.
  List<CardElement> tile(double cx, double cy, String emoji, Color tint,
      String label, DataBinding value) {
    const w = 0.4, h = 0.22;
    return [
      shapeEl(
        pos: Offset(cx, cy),
        size: const Size(w, h),
        shape: ShapeKind.rounded,
        fill: tileC,
        stroke: const Color(0x14FFFFFF),
        strokeWidth: 1,
        cornerRadius: 22,
      ),
      shapeEl(
        pos: Offset(cx - 0.11, cy - 0.06),
        size: const Size(0.07, 0.04),
        shape: ShapeKind.circle,
        fill: tint.withValues(alpha: 0.22),
      ),
      iconEl(
        pos: Offset(cx - 0.11, cy - 0.06),
        size: const Size(0.045, 0.026),
        emoji: emoji,
      ),
      textEl(
        pos: Offset(cx + 0.06, cy - 0.06),
        size: const Size(0.22, 0.03),
        literal: label,
        font: 5,
        fontSize: 17,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      textEl(
        pos: Offset(cx, cy + 0.005),
        size: const Size(w * 0.88, 0.07),
        binding: value,
        font: 1,
        fontSize: 56,
        color: Colors.white,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Thin progress bar — track + fill.
      shapeEl(
        pos: Offset(cx, cy + 0.075),
        size: const Size(w * 0.78, 0.012),
        shape: ShapeKind.pill,
        fill: const Color(0x1FFFFFFF),
        cornerRadius: 999,
      ),
      shapeEl(
        pos: Offset(cx - w * 0.19, cy + 0.075),
        size: Size(w * 0.4, 0.012),
        shape: ShapeKind.pill,
        fill: tint,
        cornerRadius: 999,
      ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'macroDashboard',
    accent: accent,
    background: solidBg(const Color(0xFF0A0B10)),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.09),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 5,
        fontSize: 24,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.88, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 46,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      ...tile(0.28, 0.4, '🔥', const Color(0xFFF97316), 'Calories',
          const DataBinding(BindingSource.calories)),
      ...tile(0.72, 0.4, '💪', const Color(0xFFA855F7), 'Protein',
          const DataBinding(BindingSource.proteinG)),
      ...tile(0.28, 0.66, '🌾', const Color(0xFF22C55E), 'Fibre',
          const DataBinding(BindingSource.carbsG)),
      ...tile(0.72, 0.66, '💧', const Color(0xFF06B6D4), 'Water',
          const DataBinding(BindingSource.fatG)),
      watermarkEl(pos: const Offset(0.3, 0.9), color: Colors.white70),
    ],
  );
}
