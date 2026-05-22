/// Editable-card preset for the **Food Photo Macros** food template — the
/// headline food card: the meal photo runs full-bleed under a bottom-up
/// scrim, a frosted macro coin floats in the lower third, the meal eyebrow
/// + dish title + period sit over the scrim.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc foodPhotoMacrosDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'foodPhotoMacros',
    accent: accent,
    background: photoBg(),
    elements: [
      // Bottom-up legibility scrim.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: const [
          Color(0x00000000),
          Color(0x33000000),
          Color(0xCC000000),
          Color(0xF2000000),
        ],
        stops: const [0.0, 0.40, 0.74, 1.0],
      ),
      // Soft top scrim for the watermark.
      scrimEl(
        pos: const Offset(0.5, 0.11),
        size: const Size(1.0, 0.22),
        colors: const [Color(0x66000000), Color(0x00000000)],
      ),
      watermarkEl(pos: const Offset(0.30, 0.06), color: Colors.white),
      // Floating frosted macro coin, lower third, right-aligned.
      chartEl(
        pos: const Offset(0.68, 0.6),
        size: const Size(0.4, 0.22),
        style: MacroVizStyle.coin,
        glass: true,
        showHealthScore: true,
      ),
      // Meal eyebrow.
      textEl(
        pos: const Offset(0.32, 0.78),
        size: const Size(0.5, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 22,
        color: accent,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      // Dish title.
      textEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.86, 0.12),
        binding: const DataBinding(BindingSource.title),
        fontSize: 44,
        maxLines: 3,
        shadow: const ShadowSpec(color: Colors.black87, blur: 14),
      ),
      textEl(
        pos: const Offset(0.5, 0.94),
        size: const Size(0.86, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        fontSize: 20,
        color: const Color(0xC7FFFFFF),
      ),
    ],
  );
}
