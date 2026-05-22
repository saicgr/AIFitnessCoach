/// Editable-card preset for the **Food Polaroid** food template — the meal
/// photo as a classic instant-camera print: an off-white frame card with a
/// gentle tilt, the dish name as a handwritten-style caption in the wide
/// bottom border, a one-line numeric macro readout, and the date footer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc foodPolaroidDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF1F1B16);
  return cardDoc(
    aspect: aspect,
    presetId: 'foodPolaroid',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF1A1714), accent, 0.16)!,
      Color.lerp(const Color(0xFF0C0A09), accent, 0.06)!,
    ]),
    elements: [
      // The off-white print card, gently tilted.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.78),
        shape: ShapeKind.rounded,
        fill: const Color(0xFFFBF8F1),
        cornerRadius: 8,
      ),
      // Photo window — near-square, the instant-print look.
      photoEl(
        pos: const Offset(0.5, 0.41),
        size: const Size(0.66, 0.5),
        mask: PhotoMask.rounded,
        cornerRadius: 4,
      ),
      // Meal eyebrow tucked into the photo's top-left corner.
      textEl(
        pos: const Offset(0.32, 0.2),
        size: const Size(0.3, 0.03),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 18,
        letterSpacing: 1.3,
        allCaps: true,
        shadow: const ShadowSpec(color: Colors.black54, blur: 6),
      ),
      // Handwritten-style caption (the dish name).
      textEl(
        pos: const Offset(0.5, 0.72),
        size: const Size(0.66, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: 6,
        fontSize: 42,
        color: ink,
        align: TextAlign.center,
        maxLines: 2,
      ),
      // One-line numeric macro readout.
      chartEl(
        pos: const Offset(0.5, 0.81),
        size: const Size(0.62, 0.06),
        style: MacroVizStyle.numbers,
      ),
      // Bottom strip — date.
      textEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.62, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        fontSize: 18,
        color: ink.withValues(alpha: 0.5),
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: ink),
    ],
  );
}
