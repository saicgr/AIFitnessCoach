/// Editable-card preset for the **POV Meal** food template — a full-bleed
/// food photo with a faux camera-UI overlay (corner brackets, a REC dot, a
/// time chip) and one bold caption strip near the bottom.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc povMealDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'povMeal',
    accent: accent,
    background: photoBg(),
    elements: [
      // Photo backdrop element so it stays editable too.
      photoEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        mask: PhotoMask.rect,
        cornerRadius: 0,
      ),
      scrimEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(1.0, 0.5),
        colors: const [Color(0x00000000), Color(0xCC000000)],
      ),
      // Faux camera-UI corner brackets.
      shapeEl(
        pos: const Offset(0.12, 0.1),
        size: const Size(0.12, 0.012),
        shape: ShapeKind.rect,
        fill: Colors.white,
      ),
      shapeEl(
        pos: const Offset(0.066, 0.14),
        size: const Size(0.012, 0.09),
        shape: ShapeKind.rect,
        fill: Colors.white,
      ),
      shapeEl(
        pos: const Offset(0.88, 0.9),
        size: const Size(0.12, 0.012),
        shape: ShapeKind.rect,
        fill: Colors.white,
      ),
      shapeEl(
        pos: const Offset(0.934, 0.86),
        size: const Size(0.012, 0.09),
        shape: ShapeKind.rect,
        fill: Colors.white,
      ),
      // REC dot chip.
      shapeEl(
        pos: const Offset(0.66, 0.1),
        size: const Size(0.04, 0.022),
        shape: ShapeKind.circle,
        fill: const Color(0xFFFF3B30),
      ),
      textEl(
        pos: const Offset(0.76, 0.1),
        size: const Size(0.2, 0.04),
        literal: 'REC',
        font: 4,
        fontSize: 26,
        color: Colors.white,
        align: TextAlign.left,
        letterSpacing: 2,
      ),
      // Time chip.
      dateEl(
        pos: const Offset(0.85, 0.95),
        size: const Size(0.28, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        color: Colors.white,
        fontSize: 22,
      ),
      // Bold caption strip near the bottom.
      shapeEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.86, 0.09),
        shape: ShapeKind.rounded,
        fill: accent,
        cornerRadius: 10,
      ),
      textEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.82, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 44,
        color: const Color(0xFF101013),
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.97), color: Colors.white),
    ],
  );
}
