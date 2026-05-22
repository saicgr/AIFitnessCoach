/// Editable-card preset for the **Food Magazine** food template — the meal
/// styled as a food-magazine cover: full-bleed dish photo, a bold serif
/// masthead, a health-score seal, food-name cover-line chips down the right
/// rail, the cover title, and a macro-pills strip.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc foodMagazineDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'foodMagazine',
    accent: accent,
    background: photoBg(),
    elements: [
      // Editorial scrims — top for the masthead, bottom for the strip.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: const [
          Color(0xCC000000),
          Color(0x33000000),
          Color(0x4D000000),
          Color(0xE6000000),
        ],
        stops: const [0.0, 0.26, 0.6, 1.0],
      ),
      // Masthead.
      textEl(
        pos: const Offset(0.32, 0.1),
        size: const Size(0.5, 0.1),
        literal: 'FUEL',
        font: 8,
        fontSize: 86,
      ),
      textEl(
        pos: const Offset(0.32, 0.16),
        size: const Size(0.5, 0.035),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 20,
        color: accent,
        letterSpacing: 2.6,
        allCaps: true,
      ),
      // Health-score seal, top-right corner.
      badgeEl(
        pos: const Offset(0.82, 0.11),
        size: const Size(0.22, 0.12),
        gradient: [Color.lerp(accent, Colors.white, 0.18)!, accent],
        label: 'HEALTH',
        valueBinding: const DataBinding(BindingSource.healthScore),
      ),
      // Cover-line chips down the right rail.
      chipsEl(
        pos: const Offset(0.66, 0.6),
        size: const Size(0.6, 0.26),
        binding: const DataBinding(BindingSource.foodItemName),
        layout: ChipLayout.column,
        maxItems: 3,
        chipColor: const Color(0x9E000000),
        fontSize: 22,
      ),
      // Cover title (the dish).
      textEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.86, 0.12),
        binding: const DataBinding(BindingSource.title),
        font: 8,
        fontSize: 50,
        allCaps: true,
        maxLines: 3,
        shadow: const ShadowSpec(color: Colors.black87, blur: 16),
      ),
      // Macro pills strip.
      chartEl(
        pos: const Offset(0.5, 0.92),
        size: const Size(0.82, 0.08),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.30, 0.97), color: Colors.white),
    ],
  );
}
