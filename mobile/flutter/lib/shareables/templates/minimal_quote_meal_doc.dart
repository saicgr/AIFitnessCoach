/// Editable-card preset for the **Minimal Quote Meal** food template — a calm
/// solid-colour card: the meal name set large in a serif, one quiet macro
/// line, generous whitespace and a tiny watermark.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc minimalQuoteMealDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  // A soft, deep paper tone tinted toward the accent — quiet, not loud.
  final bg = Color.lerp(const Color(0xFF14130F), accent, 0.16)!;
  const muted = Color(0xFFB7B3A8);

  return cardDoc(
    aspect: aspect,
    presetId: 'minimalQuoteMeal',
    accent: accent,
    background: solidBg(bg),
    elements: [
      // A small accent tick — the only ornament.
      shapeEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.07, 0.006),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.39),
        size: const Size(0.78, 0.035),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 9,
        fontSize: 20,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 5,
        allCaps: true,
      ),
      // The meal name — large serif centrepiece.
      textEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.82, 0.22),
        binding: const DataBinding(BindingSource.title),
        font: 8,
        fontSize: 78,
        color: const Color(0xFFF4F1E8),
        align: TextAlign.center,
        lineHeight: 1.0,
        maxLines: 3,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // One quiet macro line.
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.heroString),
        font: 6,
        fontSize: 24,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1,
      ),
      watermarkEl(
        pos: const Offset(0.34, 0.93),
        color: const Color(0x66B7B3A8),
        iconSize: 16,
        fontSize: 11,
      ),
    ],
  );
}
