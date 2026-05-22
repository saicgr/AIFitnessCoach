/// Editable-card preset for the **Polaroid** template — an off-white frame
/// on a slight rotation with a centered photo, a handwritten-style serif
/// caption, a hero subline and an all-caps period stamp.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc polaroidDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'polaroid',
    accent: accent,
    background: gradientBg(const [Color(0xFF1B1A18), Color(0xFF0F0E0C)]),
    elements: [
      // Off-white polaroid frame, rotated.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.72),
        shape: ShapeKind.rounded,
        fill: const Color(0xFFFAF6EE),
        cornerRadius: 10,
      ),
      // Photo window inside the frame.
      photoEl(
        pos: const Offset(0.5, 0.43),
        size: const Size(0.68, 0.5),
        binding: const DataBinding(BindingSource.customPhotoPath),
        mask: PhotoMask.rect,
      ),
      // Handwritten-style caption.
      textEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.68, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 6,
        fontSize: 44,
        color: const Color(0xFF1A1A1A),
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.68, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        fontSize: 26,
        color: const Color(0x8C1A1A1A),
        align: TextAlign.center,
        letterSpacing: 1.4,
        maxLines: 1,
      ),
      // Period stamp.
      textEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.6, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 18,
        color: const Color(0xB38B0000),
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(
        pos: const Offset(0.32, 0.84),
        color: const Color(0xFF1A1A1A),
      ),
    ],
  );
}
