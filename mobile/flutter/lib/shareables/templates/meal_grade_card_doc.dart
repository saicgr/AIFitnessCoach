/// Editable-card preset for **F10 — Meal Grade (A+ … D-)**.
///
/// A giant report-card letter grade derived **deterministically** from the
/// meal's existing health score (`Shareable.healthScore`, 1–10) via
/// [letterGrade] — no AI, no network. The meal photo sits as a coin above the
/// grade, the macros run as a P/C/F pill row beneath it, and the qualitative
/// label ("Solid", "Excellent") fills the eyebrow.
///
/// The grade letter + band color are baked into the doc at build time as
/// literal text (the score→grade mapping is pure, so re-rendering re-derives
/// the same letter). Editing the letter flips it to the user's value, as with
/// every other preset.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../grade.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealGradeCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  // Deterministic: the existing 1–10 health score → letter grade. Default to a
  // mid "B" (score 6.5) when a log carries no score, so the card never renders
  // a blank glyph.
  final grade = letterGrade(data.healthScore ?? 6);
  final hasPhoto =
      (data.foodImageUrls != null && data.foodImageUrls!.isNotEmpty);

  return cardDoc(
    aspect: aspect,
    presetId: 'mealGrade',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0A0B10), grade.color, 0.22)!,
      const Color(0xFF050608),
    ]),
    elements: [
      // Eyebrow: the meal label (or a generic "MEAL GRADE").
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: CardFontIx.cond,
        fontSize: 26,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3.4,
        allCaps: true,
      ),
      // Meal title.
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        fontSize: 40,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Meal photo coin (only when the log carries a photo).
      if (hasPhoto)
        photoEl(
          pos: const Offset(0.5, 0.34),
          size: const Size(0.42, 0.24),
          binding: const DataBinding(BindingSource.foodImageUrl, index: 0),
          mask: PhotoMask.circle,
          frameColor: grade.color,
          frameWidth: 5,
        ),
      // The giant grade letter.
      textEl(
        pos: Offset(0.5, hasPhoto ? 0.58 : 0.46),
        size: const Size(0.9, 0.26),
        literal: grade.letter,
        font: CardFontIx.display,
        fontSize: 340,
        color: grade.color,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Qualitative label below the grade.
      textEl(
        pos: Offset(0.5, hasPhoto ? 0.74 : 0.64),
        size: const Size(0.84, 0.04),
        literal: grade.label.toUpperCase(),
        font: CardFontIx.cond,
        fontSize: 30,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // Macro pill row — P/C/F.
      chartEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.86, 0.09),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white70),
    ],
  );
}
