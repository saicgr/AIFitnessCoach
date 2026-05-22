/// Editable-card preset for the **Meal Rating** food template — a big photo
/// across the top half, then a taste star row, a yes/no verdict chip, and a
/// one-line quote-marked verdict below.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealRatingDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'mealRating',
    accent: accent,
    background: solidBg(const Color(0xFF101013)),
    elements: [
      // Big photo, top half.
      photoEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(1.0, 0.54),
        mask: PhotoMask.rect,
        cornerRadius: 0,
      ),
      // Bottom-half panel.
      shapeEl(
        pos: const Offset(0.5, 0.77),
        size: const Size(1.0, 0.46),
        shape: ShapeKind.rect,
        fill: const Color(0xFF101013),
      ),
      textEl(
        pos: const Offset(0.5, 0.59),
        size: const Size(0.86, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 44,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Taste star row.
      iconEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.7, 0.08),
        emoji: '⭐⭐⭐⭐⭐',
        color: accent,
      ),
      // Yes/no verdict chip.
      shapeEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.34, 0.07),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.32, 0.05),
        literal: 'WOULD EAT AGAIN',
        font: 7,
        fontSize: 22,
        color: const Color(0xFF101013),
        align: TextAlign.center,
        letterSpacing: 1,
      ),
      // One-line quote-marked verdict.
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.84, 0.06),
        binding: const DataBinding(BindingSource.logText),
        font: 6,
        fontSize: 28,
        color: Colors.white70,
        align: TextAlign.center,
        maxLines: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.96), color: Colors.white54),
    ],
  );
}
