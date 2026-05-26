/// Editable-card preset for the **Plate Spotlight** food template — a
/// circular-masked food photo spotlit on a dark stage, ringed by a soft
/// radial glow, with the meal title above and macro chips arranged below.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc plateSpotlightDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'plateSpotlight',
    accent: accent,
    background: gradientBg(
      [
        Color.lerp(const Color(0xFF101015), accent, 0.18)!,
        const Color(0xFF050507),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Soft radial spotlight behind the plate.
      shapeEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.95, 0.62),
        shape: ShapeKind.circle,
        gradient: [
          accent.withValues(alpha: 0.4),
          const Color(0x00000000),
        ],
        radial: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.045),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 26,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.17),
        size: const Size(0.86, 0.085),
        binding: const DataBinding(BindingSource.title),
        fontSize: 44,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // The circular plate.
      photoEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.66, 0.66),
        mask: PhotoMask.circle,
        frameColor: Colors.white,
        frameWidth: 6,
      ),
      // Calorie callout — number right-aligned ending around x=0.55, the
      // "kcal" suffix left-aligned starting at x=0.58 with a 0.03 gap.
      // shrinkToFit guards 3-4 digit values from blowing past the box.
      // Previous layout collided when calorie was 3 digits ("680") because
      // the two boxes overlapped from x=0.68→0.82.
      textEl(
        pos: const Offset(0.15, 0.73),
        size: const Size(0.4, 0.07),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 52,
        color: Colors.white,
        align: TextAlign.right,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.58, 0.745),
        size: const Size(0.24, 0.05),
        literal: 'kcal',
        font: 2,
        fontSize: 28,
        color: accent,
        align: TextAlign.left,
        letterSpacing: 1,
      ),
      // Macro chips arranged below the plate.
      chartEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.84, 0.09),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: Colors.white70),
    ],
  );
}
