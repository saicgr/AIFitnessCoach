/// Editable-card preset for the **Calorie Gauge** food template — a
/// speedometer-style gauge chart for calories vs goal centre-stage, the
/// number echoed beneath, and the meal name as a caption below.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc calorieGaugeDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'calorieGauge',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF15171C), accent, 0.14)!,
      const Color(0xFF0A0B0E),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.12),
        size: const Size(0.86, 0.045),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 5,
        fontSize: 24,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 5,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.19),
        size: const Size(0.86, 0.055),
        literal: 'Calories vs Goal',
        font: 1,
        fontSize: 40,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // The gauge chart, centre-stage.
      chartEl(
        pos: const Offset(0.5, 0.49),
        size: const Size(0.84, 0.48),
        style: MacroVizStyle.gauge,
      ),
      // Echoed calorie number.
      textEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.7, 0.1),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 96,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.81),
        size: const Size(0.6, 0.04),
        literal: 'CALORIES',
        font: 5,
        fontSize: 22,
        color: Colors.white54,
        align: TextAlign.center,
        letterSpacing: 6,
      ),
      // Meal name caption.
      textEl(
        pos: const Offset(0.5, 0.89),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 6,
        fontSize: 30,
        color: accent,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white54),
    ],
  );
}
