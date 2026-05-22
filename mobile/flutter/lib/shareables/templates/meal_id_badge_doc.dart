/// Editable-card preset for the **Meal ID Badge** food template — a lanyard
/// ID card: a vertical badge panel, a headshot-style food photo, the meal
/// "name", a macro field table, and a hole-punch at the top.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealIdBadgeDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const card = Color(0xFFEFF1F4);
  const ink = Color(0xFF1E2128);

  // An ID field — small caps label paired with a bound value.
  List<CardElement> field(double y, String label, BindingSource src) {
    return [
      textEl(
        pos: Offset(0.34, y),
        size: const Size(0.34, 0.03),
        literal: label,
        font: 1,
        fontSize: 16,
        color: ink.withValues(alpha: 0.45),
        align: TextAlign.left,
        letterSpacing: 2,
        allCaps: true,
      ),
      textEl(
        pos: Offset(0.66, y),
        size: const Size(0.34, 0.035),
        binding: DataBinding(src),
        font: 7,
        fontSize: 30,
        color: ink,
        align: TextAlign.right,
      ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'mealIdBadge',
    accent: accent,
    background: gradientBg([const Color(0xFF1A1C22), const Color(0xFF080A0F)]),
    elements: [
      // Lanyard strap.
      shapeEl(
        pos: const Offset(0.5, 0.05),
        size: const Size(0.16, 0.12),
        fill: accent,
        cornerRadius: 4,
      ),
      // Badge card body.
      shapeEl(
        pos: const Offset(0.5, 0.54),
        size: const Size(0.78, 0.82),
        shape: ShapeKind.rounded,
        fill: card,
        cornerRadius: 22,
      ),
      // Hole punch.
      shapeEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.12, 0.04),
        shape: ShapeKind.pill,
        fill: const Color(0xFF080A0F),
      ),
      // Accent header band.
      shapeEl(
        pos: const Offset(0.5, 0.255),
        size: const Size(0.78, 0.07),
        fill: accent,
        cornerRadius: 0,
      ),
      textEl(
        pos: const Offset(0.5, 0.255),
        size: const Size(0.7, 0.035),
        literal: 'MEAL ACCESS PASS',
        font: 5,
        fontSize: 20,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      // Headshot-style food photo.
      photoEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.36, 0.2),
        mask: PhotoMask.rounded,
        cornerRadius: 14,
        frameColor: Colors.white,
        frameWidth: 4,
      ),
      textEl(
        pos: const Offset(0.5, 0.555),
        size: const Size(0.7, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: 7,
        fontSize: 38,
        color: ink,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.7, 0.03),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 4,
        fontSize: 16,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.65),
        size: const Size(0.62, 0.004),
        color: ink.withValues(alpha: 0.15),
      ),
      ...field(0.7, 'Calories (kcal)', BindingSource.calories),
      ...field(0.755, 'Protein (g)', BindingSource.proteinG),
      ...field(0.81, 'Carbs (g)', BindingSource.carbsG),
      ...field(0.865, 'Fat (g)', BindingSource.fatG),
      watermarkEl(pos: const Offset(0.30, 0.93), color: Colors.white60),
    ],
  );
}
