/// Editable-card preset — **Swiss Grid**: a strict typographic Swiss layout —
/// thin ruled grid lines, tiny mono labels, the calorie figure set very large
/// in one cell, and the meal photo confined to a single grid module.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc swissGridDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const paper = Color(0xFFF2F1EC);
  const ink = Color(0xFF181818);
  const rule = Color(0x33181818);

  return cardDoc(
    aspect: aspect,
    presetId: 'swissGrid',
    accent: accent,
    background: solidBg(paper),
    elements: [
      // Horizontal ruled grid lines.
      dividerEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.86, 0.002),
        color: rule,
        thickness: 1.5,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.86, 0.002),
        color: rule,
        thickness: 1.5,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.86, 0.002),
        color: rule,
        thickness: 1.5,
      ),
      // Vertical centre rule splitting the lower row into two modules.
      dividerEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(0.002, 0.3),
        color: rule,
        thickness: 1.5,
      ),
      // Tiny mono label — top cell.
      textEl(
        pos: const Offset(0.16, 0.115),
        size: const Size(0.3, 0.035),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 4,
        fontSize: 18,
        color: ink,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      // Meal name — set in the top module.
      textEl(
        pos: const Offset(0.5, 0.35),
        size: const Size(0.84, 0.3),
        binding: const DataBinding(BindingSource.title),
        font: 10,
        fontSize: 56,
        color: ink,
        lineHeight: 1.0,
        maxLines: 3,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // The calorie figure — very large in the lower-left module.
      textEl(
        pos: const Offset(0.3, 0.71),
        size: const Size(0.44, 0.22),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 150,
        color: accent,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.3, 0.82),
        size: const Size(0.44, 0.03),
        literal: 'KCAL',
        font: 4,
        fontSize: 18,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 4,
        maxLines: 1,
      ),
      // Photo confined to the lower-right module.
      photoEl(
        pos: const Offset(0.71, 0.71),
        size: const Size(0.4, 0.26),
        mask: PhotoMask.rect,
        cornerRadius: 0,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: const Color(0x99181818)),
    ],
  );
}
