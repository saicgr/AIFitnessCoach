/// Editable-card preset for the **This or That** food template — a
/// split-screen face-off: a left panel for the logged meal and a right
/// panel for the daily goal, divided by a circular VS badge, with macro
/// numbers under each side.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc thisOrThatDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'thisOrThat',
    accent: accent,
    background: solidBg(const Color(0xFF06070A)),
    elements: [
      // Left panel — the logged meal.
      shapeEl(
        pos: const Offset(0.25, 0.5),
        size: const Size(0.48, 0.96),
        shape: ShapeKind.rect,
        gradient: [accent, Color.lerp(accent, const Color(0xFF120A06), 0.6)!],
      ),
      // Right panel — the daily goal.
      shapeEl(
        pos: const Offset(0.75, 0.5),
        size: const Size(0.48, 0.96),
        shape: ShapeKind.rect,
        gradient: [
          const Color(0xFF1E2230),
          const Color(0xFF0A0C12),
        ],
      ),
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.9, 0.06),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 7,
        fontSize: 34,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      // Left side title.
      textEl(
        pos: const Offset(0.25, 0.27),
        size: const Size(0.42, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: 0,
        fontSize: 32,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Right side label.
      textEl(
        pos: const Offset(0.75, 0.27),
        size: const Size(0.42, 0.07),
        literal: 'Daily Goal',
        font: 0,
        fontSize: 32,
        color: Colors.white,
        align: TextAlign.center,
      ),
      // Left calorie figure.
      textEl(
        pos: const Offset(0.25, 0.46),
        size: const Size(0.44, 0.12),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 92,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.25, 0.55),
        size: const Size(0.4, 0.04),
        literal: 'KCAL THIS MEAL',
        font: 5,
        fontSize: 17,
        color: Colors.white70,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      // Right macro readout.
      chartEl(
        pos: const Offset(0.75, 0.49),
        size: const Size(0.4, 0.26),
        style: MacroVizStyle.progressBars,
      ),
      // Left macro readout.
      chartEl(
        pos: const Offset(0.25, 0.72),
        size: const Size(0.4, 0.12),
        style: MacroVizStyle.pills,
      ),
      // Center VS badge with a checkmark.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.2, 0.2),
        shape: ShapeKind.circle,
        fill: Colors.white,
      ),
      iconEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.14, 0.14),
        emoji: '✓',
        color: accent,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white70),
    ],
  );
}
