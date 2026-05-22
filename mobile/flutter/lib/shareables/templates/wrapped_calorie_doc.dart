/// Editable-card preset for the **Wrapped Calorie** food template — a
/// Spotify-Wrapped-style splash: a bold saturated gradient, one giant
/// calorie number that shrinks to fit, a tiny unit label, and a playful
/// "your meal, wrapped" sign-off.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc wrappedCalorieDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  final hot = Color.lerp(accent, const Color(0xFFFF2D87), 0.5)!;
  return cardDoc(
    aspect: aspect,
    presetId: 'wrappedCalorie',
    accent: accent,
    background: gradientBg(
      [hot, accent, const Color(0xFF120A1E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.42, 1.0],
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.13),
        size: const Size(0.84, 0.045),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 7,
        fontSize: 28,
        color: const Color(0xFF120A1E),
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.22),
        size: const Size(0.84, 0.05),
        literal: 'You fueled up with',
        font: 6,
        fontSize: 34,
        color: Colors.white,
        align: TextAlign.center,
      ),
      // The giant calorie number.
      textEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.94, 0.34),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 360,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.6, 0.05),
        literal: 'CALORIES',
        font: 5,
        fontSize: 30,
        color: const Color(0xFF120A1E),
        align: TextAlign.center,
        letterSpacing: 8,
      ),
      chartEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.82, 0.085),
        style: MacroVizStyle.pills,
      ),
      textEl(
        pos: const Offset(0.5, 0.89),
        size: const Size(0.84, 0.05),
        literal: 'your meal, wrapped',
        font: 6,
        fontSize: 30,
        color: Colors.white,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white),
    ],
  );
}
