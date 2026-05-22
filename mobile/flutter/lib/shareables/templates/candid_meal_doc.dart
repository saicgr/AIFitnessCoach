/// Editable-card preset for the **Candid Meal** food template — an
/// off-centre food photo, a handwritten-style timestamp chip top-left, and
/// one macro line bottom-right: a "real, not polished" candid snapshot look.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc candidMealDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const paper = Color(0xFF14110D);
  return cardDoc(
    aspect: aspect,
    presetId: 'candidMeal',
    accent: accent,
    background: gradientBg([
      Color.lerp(paper, accent, 0.06)!,
      const Color(0xFF0A0805),
    ]),
    elements: [
      // Off-centre food photo, slightly low and to the right.
      photoEl(
        pos: const Offset(0.56, 0.46),
        size: const Size(0.78, 0.6),
        mask: PhotoMask.rounded,
        cornerRadius: 28,
        frameColor: Colors.white,
        frameWidth: 5,
      ),
      // Handwritten-style timestamp chip, top-left, italic + pill backing.
      shapeEl(
        pos: const Offset(0.27, 0.13),
        size: const Size(0.34, 0.07),
        shape: ShapeKind.pill,
        fill: const Color(0xFFFDF8EC),
      ),
      dateEl(
        pos: const Offset(0.27, 0.13),
        size: const Size(0.32, 0.06),
        binding: const DataBinding(BindingSource.periodLabel),
        color: paper,
        fontSize: 26,
      ),
      // Candid sign-off, top-right.
      textEl(
        pos: const Offset(0.74, 0.13),
        size: const Size(0.4, 0.05),
        literal: 'shot it before i ate it',
        font: 6,
        fontSize: 24,
        color: Colors.white60,
        align: TextAlign.right,
      ),
      // The meal name, lower-left, casual italic.
      textEl(
        pos: const Offset(0.32, 0.82),
        size: const Size(0.56, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: 6,
        fontSize: 40,
        color: Colors.white,
        align: TextAlign.left,
        maxLines: 2,
      ),
      // One macro line, bottom-right.
      textEl(
        pos: const Offset(0.7, 0.91),
        size: const Size(0.56, 0.05),
        binding: const DataBinding(BindingSource.calories),
        font: 4,
        fontSize: 28,
        color: accent,
        align: TextAlign.right,
      ),
      watermarkEl(pos: const Offset(0.06, 0.95), color: Colors.white54),
    ],
  );
}
