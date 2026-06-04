/// Editable-card preset for the **AI Calorie Scan** template — a food-vision
/// scan over the food photo: a bracketed scan reticle, a glowing scan-line, and
/// a glass result card reading "✦ AI SCANNED" with the food name + calories +
/// protein. Sells instant photo-to-macros. The result card binds calories /
/// protein to the live nutrition totals.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiCalorieScanDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiCalorieScan',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.foodImageUrl, index: 0),
    ),
    elements: [
      // Light darken.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x33000000), Color(0x59000000)],
      ),
      // Scan reticle (accent stroked box).
      shapeEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.72, 0.4),
        shape: ShapeKind.rounded,
        fill: const Color(0x00000000),
        stroke: accent,
        strokeWidth: 2.2,
        cornerRadius: 12,
      ),
      // Glowing scan line.
      shapeEl(
        pos: const Offset(0.5, 0.31),
        size: const Size(0.72, 0.006),
        shape: ShapeKind.pill,
        fill: accent,
      ).copyWith(
        effects: ElementEffects(glow: ShadowSpec(color: accent, blur: 12)),
      ),
      // Glass result card.
      shapeEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.86, 0.14),
        shape: ShapeKind.rounded,
        fill: const Color(0x8C000000),
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.78, 0.025),
        literal: '✦ AI SCANNED',
        font: CardFontIx.cond,
        fontSize: 16,
        color: accent,
        letterSpacing: 2.2,
      ),
      // Title + macro line (editable).
      textEl(
        pos: const Offset(0.5, 0.85),
        size: const Size(0.78, 0.05),
        literal: 'Chicken Bowl · 620 kcal · 48g protein',
        font: CardFontIx.condMid,
        fontSize: 28,
        color: white,
        maxLines: 2,
        lineHeight: 1.25,
      ),
      watermarkEl(pos: const Offset(0.3, 0.955), color: const Color(0xCCFFFFFF)),
    ],
  );
}
