/// Editable-card preset — **Cassette Meal**: a cassette-tape graphic (body
/// rectangle + two reel circles) with a "Side A" track listing where each
/// track is a logged food item, and the meal name printed on the spine strip.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc cassetteMealDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ground = Color(0xFF1A1B22);
  const shell = Color(0xFF2C2E38);
  const label = Color(0xFFEDE7D6);

  return cardDoc(
    aspect: aspect,
    presetId: 'cassetteMeal',
    accent: accent,
    background: solidBg(ground),
    elements: [
      // Cassette body — the outer shell rectangle.
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.84, 0.5),
        shape: ShapeKind.rounded,
        fill: shell,
        cornerRadius: 28,
      ),
      // Paper label area on the cassette.
      shapeEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.72, 0.26),
        shape: ShapeKind.rounded,
        fill: label,
        cornerRadius: 10,
      ),
      // "Side A" header on the label.
      textEl(
        pos: const Offset(0.24, 0.25),
        size: const Size(0.26, 0.04),
        literal: 'SIDE A',
        font: 4,
        fontSize: 22,
        color: accent,
        letterSpacing: 3,
        maxLines: 1,
      ),
      // Meal name on the spine strip.
      textEl(
        pos: const Offset(0.66, 0.25),
        size: const Size(0.42, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: 6,
        fontSize: 26,
        color: const Color(0xFF2A2118),
        align: TextAlign.right,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Track listing — each track is a logged food item.
      repeaterEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.62, 0.16),
        maxItems: 4,
        fontSize: 20,
        textColor: const Color(0xFF2A2118),
        showAmount: false,
        showCalories: false,
      ),
      // Two reel circles.
      shapeEl(
        pos: const Offset(0.34, 0.55),
        size: const Size(0.16, 0.09),
        shape: ShapeKind.circle,
        fill: ground,
        stroke: const Color(0xFF54565F),
        strokeWidth: 6,
      ),
      shapeEl(
        pos: const Offset(0.66, 0.55),
        size: const Size(0.16, 0.09),
        shape: ShapeKind.circle,
        fill: ground,
        stroke: const Color(0xFF54565F),
        strokeWidth: 6,
      ),
      // Macro summary line below the cassette.
      textEl(
        pos: const Offset(0.5, 0.77),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: 4,
        fontSize: 24,
        color: label,
        align: TextAlign.center,
        letterSpacing: 1,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.9), color: Colors.white70),
    ],
  );
}
