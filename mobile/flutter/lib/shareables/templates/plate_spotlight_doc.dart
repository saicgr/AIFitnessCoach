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
      // Calorie callout.
      textEl(
        pos: const Offset(0.42, 0.73),
        size: const Size(0.4, 0.06),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 56,
        color: Colors.white,
        align: TextAlign.right,
      ),
      textEl(
        pos: const Offset(0.68, 0.74),
        size: const Size(0.24, 0.05),
        literal: 'kcal',
        font: 2,
        fontSize: 30,
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
