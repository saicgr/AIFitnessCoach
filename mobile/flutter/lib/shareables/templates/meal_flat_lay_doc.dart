/// Editable-card preset — **Meal Flat-Lay**: an overhead meal photo with thin
/// leader lines drawn from food components out to small text labels around
/// the edges, plus a summary stat chip in a corner — like a diagram annotation.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

/// A thin rotated leader line — `shapeEl` exposes no rotation, so the
/// `CardElement` is built directly here with a rotation on its transform.
CardElement _leader(Offset pos, double width, double rotation, Color color) =>
    CardElement(
      id: CardDoc.newId(),
      type: CardElementType.shape,
      transform: ElementTransform(
        position: pos,
        size: Size(width, 0.004),
        rotation: rotation,
      ),
      props: ShapeProps(shape: ShapeKind.line, fillColor: color),
    );

CardDoc mealFlatLayDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const line = Color(0xCCFFFFFF);
  const ink = Color(0xFFFFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'mealFlatLay',
    accent: accent,
    background: photoBg(),
    elements: [
      // Gentle vignette so edge labels stay legible over the photo.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: const [Color(0x66000000), Color(0x00000000), Color(0x66000000)],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Leader line + label — top-left component.
      _leader(const Offset(0.32, 0.31), 0.26, -0.5, line),
      textEl(
        pos: const Offset(0.21, 0.18),
        size: const Size(0.34, 0.04),
        binding: const DataBinding(BindingSource.foodItemName, index: 0),
        font: 4,
        fontSize: 24,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Leader line + label — right component.
      _leader(const Offset(0.68, 0.5), 0.24, 0.0, line),
      textEl(
        pos: const Offset(0.84, 0.5),
        size: const Size(0.3, 0.04),
        binding: const DataBinding(BindingSource.foodItemName, index: 1),
        font: 4,
        fontSize: 24,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Leader line + label — bottom component.
      _leader(const Offset(0.36, 0.69), 0.26, 0.5, line),
      textEl(
        pos: const Offset(0.24, 0.82),
        size: const Size(0.34, 0.04),
        binding: const DataBinding(BindingSource.foodItemName, index: 2),
        font: 4,
        fontSize: 24,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Summary stat chip — bottom-right corner.
      shapeEl(
        pos: const Offset(0.78, 0.9),
        size: const Size(0.36, 0.07),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      textEl(
        pos: const Offset(0.78, 0.9),
        size: const Size(0.34, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 26,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.96), color: Colors.white70),
    ],
  );
}
