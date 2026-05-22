/// Editable-card preset for the **Vinyl** template — a black record disc with
/// concentric grooves and an orange brand-color center label that carries the
/// "SIDE A" tag and the hero number, plus a title caption below.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc vinylDoc(Shareable data, ShareableAspect aspect) {
  const orange = Color(0xFFFF7A1A);
  return cardDoc(
    aspect: aspect,
    presetId: 'vinyl',
    accent: orange,
    background: solidBg(const Color(0xFF050505)),
    elements: [
      // Record disc.
      shapeEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.84, 0.84),
        shape: ShapeKind.circle,
        fill: const Color(0xFF1A1A1A),
      ),
      // Concentric grooves.
      for (var i = 0; i < 5; i++)
        shapeEl(
          pos: const Offset(0.5, 0.44),
          size: Size(0.78 - i * 0.13, 0.78 - i * 0.13),
          shape: ShapeKind.circle,
          fill: const Color(0x00000000),
          stroke: const Color(0x10FFFFFF),
          strokeWidth: 1,
        ),
      // Orange center label.
      shapeEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.32, 0.32),
        shape: ShapeKind.circle,
        gradient: const [orange, Color(0xFFFF6B00)],
      ),
      textEl(
        pos: const Offset(0.5, 0.37),
        size: const Size(0.28, 0.03),
        literal: 'SIDE A',
        font: 1,
        fontSize: 22,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.28, 0.08),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 56,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Center hole.
      shapeEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.02, 0.02),
        shape: ShapeKind.circle,
        fill: const Color(0xFF000000),
      ),
      textEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.84, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 36,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 2,
      ),
      watermarkEl(pos: const Offset(0.32, 0.93), color: Colors.white60),
    ],
  );
}
