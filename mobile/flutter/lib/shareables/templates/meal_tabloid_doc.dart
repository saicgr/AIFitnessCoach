/// Editable-card preset for the **Meal Tabloid** food template — a loud
/// all-caps tabloid front page: a screaming headline, a circled meal photo
/// ringed by a faux red marker stroke, a "DEVELOPING" badge, and a small
/// macro sub-deck caption.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealTabloidDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const markerRed = Color(0xFFE3262B);
  const ink = Color(0xFF14130F);
  const paper = Color(0xFFF3EDDC);
  return cardDoc(
    aspect: aspect,
    presetId: 'mealTabloid',
    accent: accent,
    background: solidBg(paper),
    elements: [
      // Top banner strip.
      shapeEl(
        pos: const Offset(0.5, 0.05),
        size: const Size(1.0, 0.1),
        shape: ShapeKind.rect,
        fill: ink,
      ),
      textEl(
        pos: const Offset(0.5, 0.05),
        size: const Size(0.9, 0.05),
        literal: 'THE PLATE TIMES',
        font: 8,
        fontSize: 40,
        color: paper,
        align: TextAlign.center,
        letterSpacing: 2,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Loud all-caps headline.
      textEl(
        pos: const Offset(0.5, 0.22),
        size: const Size(0.94, 0.2),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 110,
        color: ink,
        align: TextAlign.center,
        allCaps: true,
        maxLines: 3,
        lineHeight: 0.92,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Circled meal photo.
      photoEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.62, 0.34),
        mask: PhotoMask.circle,
      ),
      // Faux red marker ring around the photo.
      shapeEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.7, 0.4),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        stroke: markerRed,
        strokeWidth: 8,
      ),
      // DEVELOPING badge.
      shapeEl(
        pos: const Offset(0.74, 0.36),
        size: const Size(0.3, 0.07),
        shape: ShapeKind.rounded,
        fill: markerRed,
        cornerRadius: 6,
      ),
      textEl(
        pos: const Offset(0.74, 0.36),
        size: const Size(0.28, 0.04),
        literal: 'DEVELOPING',
        font: 1,
        fontSize: 26,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 1.5,
        allCaps: true,
      ),
      // Macro sub-deck caption.
      dividerEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.86, 0.005),
        style: DividerStyle.solid,
        color: ink,
        thickness: 3,
      ),
      textEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.9, 0.05),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 9,
        fontSize: 24,
        color: markerRed,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.89),
        size: const Size(0.9, 0.045),
        binding: const DataBinding(BindingSource.calories),
        font: 9,
        fontSize: 22,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: ink),
    ],
  );
}
