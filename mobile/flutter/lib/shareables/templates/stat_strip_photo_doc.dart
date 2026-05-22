/// Editable-card preset for the **Stat Strip Photo** food template — a
/// Strava-style edge-to-edge food photo with a bottom-pinned strip of four
/// metric tiles (calories / protein / carbs / fat).
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc statStripPhotoDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;

  // One metric tile: a translucent card with a big value + small label.
  List<CardElement> tile(
    double cx,
    BindingSource src,
    String label,
    Color tint,
  ) =>
      [
        shapeEl(
          pos: Offset(cx, 0.85),
          size: const Size(0.21, 0.13),
          shape: ShapeKind.rounded,
          fill: const Color(0xCC101216),
          stroke: tint.withValues(alpha: 0.6),
          strokeWidth: 1.5,
          cornerRadius: 16,
        ),
        textEl(
          pos: Offset(cx, 0.825),
          size: const Size(0.2, 0.05),
          binding: DataBinding(src),
          font: 1,
          fontSize: 30,
          color: Colors.white,
          align: TextAlign.center,
        ),
        textEl(
          pos: Offset(cx, 0.875),
          size: const Size(0.2, 0.03),
          literal: label,
          font: 5,
          fontSize: 14,
          color: tint,
          align: TextAlign.center,
          letterSpacing: 2,
        ),
      ];

  return cardDoc(
    aspect: aspect,
    presetId: 'statStripPhoto',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.foodImageUrl, index: 0),
    ),
    elements: [
      // Top scrim for the title, bottom scrim for the strip.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: const [Color(0xCC000000), Color(0x00000000), Color(0xE6000000)],
        stops: const [0.0, 0.42, 1.0],
      ),
      textEl(
        pos: const Offset(0.5, 0.085),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 24,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.155),
        size: const Size(0.88, 0.08),
        binding: const DataBinding(BindingSource.title),
        fontSize: 50,
        align: TextAlign.center,
        maxLines: 2,
        shadow: const ShadowSpec(blur: 18),
      ),
      ...tile(0.155, BindingSource.calories, 'KCAL', Colors.white),
      ...tile(0.385, BindingSource.proteinG, 'PROTEIN',
          const Color(0xFFEF4444)),
      ...tile(0.615, BindingSource.carbsG, 'CARBS', const Color(0xFFF59E0B)),
      ...tile(0.845, BindingSource.fatG, 'FAT', const Color(0xFF3B82F6)),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white70),
    ],
  );
}
