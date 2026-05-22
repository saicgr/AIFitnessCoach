/// Editable-card preset for the **Macro Split Block** food template — three
/// full-height vertical colour bands, each holding a macro gram value, in a
/// bold infographic style.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroSplitBlockDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const proteinC = Color(0xFF3B82F6);
  const carbsC = Color(0xFFF59E0B);
  const fatC = Color(0xFFEF4444);

  // A full-height colour band carrying one macro's label + gram number.
  List<CardElement> band(double x, double w, Color fill, String label,
      BindingSource src) {
    return [
      shapeEl(
        pos: Offset(x, 0.5),
        size: Size(w, 1.0),
        shape: ShapeKind.rect,
        fill: fill,
      ),
      textEl(
        pos: Offset(x, 0.62),
        size: Size(w * 0.9, 0.16),
        binding: DataBinding(src),
        font: 1,
        fontSize: 96,
        color: Colors.white,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(color: Color(0x55000000), blur: 12),
      ),
      textEl(
        pos: Offset(x, 0.74),
        size: Size(w * 0.9, 0.04),
        literal: '$label (g)',
        font: 5,
        fontSize: 24,
        color: const Color(0xCCFFFFFF),
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
    ];
  }

  // Bands sized roughly by a typical P/C/F balance (carbs widest).
  const pw = 0.3, cw = 0.4, fw = 0.3;

  return cardDoc(
    aspect: aspect,
    presetId: 'macroSplitBlock',
    accent: accent,
    background: solidBg(const Color(0xFF0B0C10)),
    elements: [
      ...band(pw / 2, pw, proteinC, 'Protein', BindingSource.proteinG),
      ...band(pw + cw / 2, cw, carbsC, 'Carbs', BindingSource.carbsG),
      ...band(pw + cw + fw / 2, fw, fatC, 'Fat', BindingSource.fatG),
      // Top header band over the colour split.
      shapeEl(
        pos: const Offset(0.5, 0.115),
        size: const Size(1.0, 0.23),
        shape: ShapeKind.rect,
        fill: const Color(0xF20B0C10),
      ),
      textEl(
        pos: const Offset(0.5, 0.07),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 5,
        fontSize: 24,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 5,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.135),
        size: const Size(0.9, 0.09),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 52,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Bottom header band with the calorie total.
      shapeEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(1.0, 0.2),
        shape: ShapeKind.rect,
        fill: const Color(0xF20B0C10),
      ),
      textEl(
        pos: const Offset(0.5, 0.87),
        size: const Size(0.86, 0.1),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 80,
        color: Colors.white,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.95),
        size: const Size(0.6, 0.03),
        literal: 'TOTAL CALORIES',
        font: 5,
        fontSize: 16,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      watermarkEl(pos: const Offset(0.30, 0.97), color: Colors.white70),
    ],
  );
}
