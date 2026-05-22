/// Editable-card preset — **Editorial Split**: a left-third solid colour column
/// carrying a large serif pull-quote, the photo filling the right two-thirds,
/// and a thin macro byline running along the bottom.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc editorialSplitDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  // The column is a deep ink tinted toward the accent.
  final column = Color.lerp(const Color(0xFF14130F), accent, 0.22)!;
  const paper = Color(0xFFF4F1E8);

  return cardDoc(
    aspect: aspect,
    presetId: 'editorialSplit',
    accent: accent,
    background: photoBg(),
    elements: [
      // Left solid colour column — occupies the left third.
      shapeEl(
        pos: const Offset(0.165, 0.5),
        size: const Size(0.33, 1.0),
        shape: ShapeKind.rect,
        fill: column,
        cornerRadius: 0,
      ),
      // Eyebrow inside the column.
      textEl(
        pos: const Offset(0.165, 0.14),
        size: const Size(0.26, 0.05),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 5,
        fontSize: 18,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      // Large serif pull-quote — the meal name, set vertically down the column.
      textEl(
        pos: const Offset(0.165, 0.5),
        size: const Size(0.3, 0.6),
        binding: const DataBinding(BindingSource.title),
        font: 8,
        fontSize: 62,
        color: paper,
        align: TextAlign.center,
        lineHeight: 1.0,
        maxLines: 6,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Thin macro byline along the bottom edge.
      dividerEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(0.92, 0.003),
        color: const Color(0x66FFFFFF),
        thickness: 1.5,
      ),
      textEl(
        pos: const Offset(0.5, 0.945),
        size: const Size(0.9, 0.035),
        binding: const DataBinding(BindingSource.heroString),
        font: 9,
        fontSize: 22,
        color: paper,
        align: TextAlign.center,
        letterSpacing: 1,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.78, 0.945), color: Colors.white70),
    ],
  );
}
