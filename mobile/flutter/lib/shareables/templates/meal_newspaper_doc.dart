/// Editable-card preset for the **Meal Newspaper** food template — the meal
/// laid out as a newspaper front page: a cream paper field, a serif masthead
/// "THE DAILY PLATE", a serif headline drawn from the meal name, a scrimmed
/// food photo, and a nutrition sidebar column.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealNewspaperDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const paper = Color(0xFFF1ECDD);
  const ink = Color(0xFF1A1813);
  final faint = ink.withValues(alpha: 0.6);
  return cardDoc(
    aspect: aspect,
    presetId: 'mealNewspaper',
    accent: accent,
    background: solidBg(paper),
    elements: [
      // Masthead.
      textEl(
        pos: const Offset(0.5, 0.075),
        size: const Size(0.92, 0.07),
        literal: 'THE DAILY PLATE',
        font: 8,
        fontSize: 64,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.115),
        size: const Size(0.9, 0.006),
        style: DividerStyle.solid,
        color: ink,
        thickness: 3,
      ),
      textEl(
        pos: const Offset(0.5, 0.135),
        size: const Size(0.9, 0.028),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 9,
        fontSize: 17,
        color: faint,
        align: TextAlign.center,
        letterSpacing: 1.5,
        allCaps: true,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.155),
        size: const Size(0.9, 0.004),
        style: DividerStyle.solid,
        color: ink,
        thickness: 1.5,
      ),
      // Kicker / meal label.
      textEl(
        pos: const Offset(0.5, 0.185),
        size: const Size(0.9, 0.035),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 4,
        fontSize: 20,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      // Serif headline.
      textEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(0.92, 0.14),
        binding: const DataBinding(BindingSource.title),
        font: 8,
        fontSize: 58,
        color: ink,
        align: TextAlign.center,
        maxLines: 3,
        lineHeight: 1.0,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Lead photo.
      photoEl(
        pos: const Offset(0.34, 0.56),
        size: const Size(0.56, 0.34),
        mask: PhotoMask.rect,
      ),
      scrimEl(
        pos: const Offset(0.34, 0.65),
        size: const Size(0.56, 0.16),
        colors: const [Color(0x00000000), Color(0xCC000000)],
      ),
      textEl(
        pos: const Offset(0.34, 0.69),
        size: const Size(0.5, 0.04),
        binding: const DataBinding(BindingSource.logText),
        font: 9,
        fontSize: 17,
        color: Colors.white,
        align: TextAlign.left,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Sidebar rule.
      dividerEl(
        pos: const Offset(0.64, 0.56),
        size: const Size(0.34, 0.006),
        style: DividerStyle.solid,
        color: ink,
        thickness: 1.5,
      ),
      textEl(
        pos: const Offset(0.81, 0.43),
        size: const Size(0.3, 0.035),
        literal: 'BY THE NUMBERS',
        font: 4,
        fontSize: 16,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 1.5,
      ),
      // Nutrition sidebar column.
      chartEl(
        pos: const Offset(0.81, 0.6),
        size: const Size(0.32, 0.3),
        style: MacroVizStyle.progressBars,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.9, 0.004),
        style: DividerStyle.solid,
        color: ink,
        thickness: 1.5,
      ),
      // Footer with the calorie figure.
      textEl(
        pos: const Offset(0.3, 0.84),
        size: const Size(0.18, 0.05),
        literal: 'A',
        font: 8,
        fontSize: 40,
        color: ink,
        align: TextAlign.right,
      ),
      textEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.26, 0.05),
        binding: const DataBinding(BindingSource.calories),
        font: 8,
        fontSize: 40,
        color: accent,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.74, 0.84),
        size: const Size(0.34, 0.05),
        literal: 'CALORIE EDITION',
        font: 8,
        fontSize: 40,
        color: ink,
        align: TextAlign.left,
      ),
      watermarkEl(pos: const Offset(0.3, 0.92), color: ink),
    ],
  );
}
