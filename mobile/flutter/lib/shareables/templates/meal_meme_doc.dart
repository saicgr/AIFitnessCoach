/// Editable-card preset for the **Meal Meme** food template — a classic
/// meme: a full-bleed food photo with bold white Impact-style caption text
/// top and bottom, plus a small macro chip in a corner.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealMemeDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const memeShadow = ShadowSpec(color: Color(0xFF000000), blur: 8);
  return cardDoc(
    aspect: aspect,
    presetId: 'mealMeme',
    accent: accent,
    background: photoBg(),
    elements: [
      // Slight scrims so the white caption text never washes out.
      scrimEl(
        pos: const Offset(0.5, 0.12),
        size: const Size(1.0, 0.24),
        colors: const [Color(0x99000000), Color(0x00000000)],
      ),
      scrimEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(1.0, 0.24),
        colors: const [Color(0x00000000), Color(0x99000000)],
      ),
      // Top meme caption — Impact-style heavy white all-caps.
      textEl(
        pos: const Offset(0.5, 0.11),
        size: const Size(0.94, 0.16),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 72,
        color: Colors.white,
        align: TextAlign.center,
        allCaps: true,
        maxLines: 2,
        lineHeight: 0.98,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: memeShadow,
      ),
      // Bottom meme caption.
      textEl(
        pos: const Offset(0.5, 0.89),
        size: const Size(0.94, 0.16),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 72,
        color: Colors.white,
        align: TextAlign.center,
        allCaps: true,
        maxLines: 2,
        lineHeight: 0.98,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: memeShadow,
      ),
      // Corner macro chip.
      shapeEl(
        pos: const Offset(0.78, 0.5),
        size: const Size(0.36, 0.07),
        shape: ShapeKind.pill,
        fill: const Color(0xCC000000),
        stroke: accent,
        strokeWidth: 2,
        cornerRadius: 999,
      ),
      textEl(
        pos: const Offset(0.78, 0.5),
        size: const Size(0.32, 0.045),
        binding: const DataBinding(BindingSource.calories),
        font: 7,
        fontSize: 30,
        color: Colors.white,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.96), color: Colors.white),
    ],
  );
}
