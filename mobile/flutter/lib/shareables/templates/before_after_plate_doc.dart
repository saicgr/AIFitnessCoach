/// Editable-card preset for the **Before / After Plate** food template — the
/// meal as a full plate beside an empty plate with a rotated "CLEANED IT"
/// stamp, and a macro footer of P/C/F pills.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc beforeAfterPlateDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const plateRim = Color(0xFFE7E3D8);

  return cardDoc(
    aspect: aspect,
    presetId: 'beforeAfterPlate',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF12100E), accent, 0.14)!,
      const Color(0xFF070605),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        fontSize: 44,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 22,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      // BEFORE — the full plate (food photo masked into a plate rim).
      shapeEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.66, 0.37),
        shape: ShapeKind.circle,
        fill: plateRim,
      ),
      photoEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.54, 0.30),
        binding: const DataBinding(BindingSource.foodImageUrl, index: 0),
        mask: PhotoMask.circle,
      ),
      textEl(
        pos: const Offset(0.5, 0.555),
        size: const Size(0.5, 0.035),
        literal: 'BEFORE',
        font: 5,
        fontSize: 20,
        color: Colors.white60,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // AFTER — an empty plate.
      shapeEl(
        pos: const Offset(0.5, 0.7),
        size: const Size(0.4, 0.22),
        shape: ShapeKind.circle,
        fill: plateRim,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.7),
        size: const Size(0.31, 0.17),
        shape: ShapeKind.circle,
        fill: const Color(0xFFCFCABA),
      ),
      // The stamp.
      shapeEl(
        pos: const Offset(0.62, 0.66),
        size: const Size(0.44, 0.09),
        shape: ShapeKind.rounded,
        fill: const Color(0x00000000),
        stroke: const Color(0xFFEF4444),
        strokeWidth: 4,
        cornerRadius: 8,
      ),
      textEl(
        pos: const Offset(0.62, 0.66),
        size: const Size(0.42, 0.06),
        literal: 'CLEANED IT',
        font: 1,
        fontSize: 30,
        color: const Color(0xFFEF4444),
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      // Macro footer.
      chartEl(
        pos: const Offset(0.5, 0.87),
        size: const Size(0.84, 0.08),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white70),
    ],
  );
}
