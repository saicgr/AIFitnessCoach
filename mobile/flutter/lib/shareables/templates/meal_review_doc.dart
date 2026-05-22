/// Editable-card preset for the **Meal Review** food template — a faux
/// review-site card: a meal photo thumbnail, a star-rating row, a reviewer
/// name chip, a punchy mock-review paragraph, and "helpful" vote chips at
/// the bottom.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealReviewDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const card = Color(0xFF15161B);
  const star = Color(0xFFF5C542);

  // A row of five filled stars.
  List<CardElement> stars(double y) {
    const start = 0.34, gap = 0.08;
    return [
      for (var i = 0; i < 5; i++)
        iconEl(
          pos: Offset(start + i * gap, y),
          size: const Size(0.05, 0.03),
          emoji: '⭐',
          color: star,
        ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'mealReview',
    accent: accent,
    background: solidBg(const Color(0xFF0A0B0F)),
    elements: [
      // Review card surface.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.82),
        shape: ShapeKind.rounded,
        fill: card,
        stroke: const Color(0x14FFFFFF),
        strokeWidth: 1,
        cornerRadius: 26,
      ),
      // Meal photo thumbnail.
      photoEl(
        pos: const Offset(0.5, 0.26),
        size: const Size(0.78, 0.26),
        mask: PhotoMask.rounded,
        cornerRadius: 18,
      ),
      // Star rating row.
      ...stars(0.44),
      textEl(
        pos: const Offset(0.78, 0.44),
        size: const Size(0.16, 0.035),
        literal: '5.0',
        font: 1,
        fontSize: 26,
        color: star,
        align: TextAlign.left,
      ),
      // Reviewer name chip.
      shapeEl(
        pos: const Offset(0.32, 0.51),
        size: const Size(0.34, 0.05),
        shape: ShapeKind.pill,
        fill: accent.withValues(alpha: 0.18),
        cornerRadius: 999,
      ),
      textEl(
        pos: const Offset(0.32, 0.51),
        size: const Size(0.3, 0.03),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 7,
        fontSize: 18,
        color: accent,
        align: TextAlign.center,
        allCaps: true,
      ),
      // Mock review paragraph drawn from the meal title.
      textEl(
        pos: const Offset(0.5, 0.64),
        size: const Size(0.78, 0.16),
        binding: const DataBinding(BindingSource.title),
        font: 6,
        fontSize: 30,
        color: Colors.white,
        align: TextAlign.left,
        maxLines: 4,
        lineHeight: 1.25,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Helpful vote chips.
      shapeEl(
        pos: const Offset(0.3, 0.82),
        size: const Size(0.34, 0.06),
        shape: ShapeKind.pill,
        fill: const Color(0x14FFFFFF),
        cornerRadius: 999,
      ),
      textEl(
        pos: const Offset(0.3, 0.82),
        size: const Size(0.3, 0.035),
        literal: '👍 Helpful',
        font: 0,
        fontSize: 19,
        color: Colors.white70,
        align: TextAlign.center,
      ),
      shapeEl(
        pos: const Offset(0.68, 0.82),
        size: const Size(0.34, 0.06),
        shape: ShapeKind.pill,
        fill: const Color(0x14FFFFFF),
        cornerRadius: 999,
      ),
      textEl(
        pos: const Offset(0.68, 0.82),
        size: const Size(0.3, 0.035),
        binding: const DataBinding(BindingSource.calories),
        font: 0,
        fontSize: 19,
        color: Colors.white70,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: Colors.white70),
    ],
  );
}
