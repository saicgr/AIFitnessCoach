/// Editable-card preset for the **Mesh Big Number** food template — a modern
/// mesh-gradient backdrop with one giant hero calorie metric and a sub-stat
/// row of macro chips.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meshBigNumberDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;

  // A mesh-style gradient blends the accent into vivid neighbours.
  final mesh = [
    Color.lerp(accent, const Color(0xFF7C3AED), 0.55)!,
    Color.lerp(accent, const Color(0xFFEC4899), 0.35)!,
    accent,
    Color.lerp(accent, const Color(0xFF0EA5E9), 0.5)!,
    const Color(0xFF1E1B2E),
  ];

  return cardDoc(
    aspect: aspect,
    presetId: 'meshBigNumber',
    accent: accent,
    background: gradientBg(
      mesh,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.3, 0.55, 0.78, 1.0],
    ),
    elements: [
      // Soft radial bloom behind the number.
      shapeEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.95, 0.55),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        gradient: const [Color(0x55FFFFFF), Color(0x00FFFFFF)],
        radial: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.13),
        size: const Size(0.86, 0.045),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 5,
        fontSize: 26,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 5,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.22),
        size: const Size(0.84, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: 10,
        fontSize: 40,
        color: const Color(0xE6FFFFFF),
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Giant hero calorie metric, shrink-to-fit.
      textEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.92, 0.3),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 320,
        color: Colors.white,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(color: Color(0x66000000), blur: 30),
      ),
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.7, 0.04),
        literal: 'CALORIES LOGGED',
        font: 5,
        fontSize: 22,
        color: const Color(0xCCFFFFFF),
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // Sub-stat macro chips.
      chipsEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.88, 0.08),
        literalItems: const ['Protein', 'Carbs', 'Fat'],
        layout: ChipLayout.row,
        maxItems: 3,
        chipColor: const Color(0x33FFFFFF),
        textColor: Colors.white,
        fontSize: 22,
      ),
      chartEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.84, 0.09),
        style: MacroVizStyle.stackedBar,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white),
    ],
  );
}
