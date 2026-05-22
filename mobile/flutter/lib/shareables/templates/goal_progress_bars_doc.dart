/// Editable-card preset for the **Goal Progress Bars** food template — four
/// horizontal track/fill bars (protein / carbs / fat / calories) toward the
/// day's goal, each with its own value label.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc goalProgressBarsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF0C0E13);

  // One labelled bar: name on top-left, value on top-right, track + a
  // representative fill underneath. (Live fill % is rendered by the chart
  // layer; these shapes give the card a strong default silhouette.)
  List<CardElement> bar(
    double cy,
    String name,
    BindingSource src,
    Color tint,
    double fillFraction,
  ) {
    const trackW = 0.78;
    final fillW = trackW * fillFraction;
    final fillCx = 0.5 - trackW / 2 + fillW / 2;
    return [
      textEl(
        pos: Offset(0.5 - trackW / 2 + 0.12, cy - 0.045),
        size: const Size(0.34, 0.035),
        literal: name,
        font: 5,
        fontSize: 18,
        color: Colors.white,
        align: TextAlign.left,
        letterSpacing: 2,
      ),
      textEl(
        pos: Offset(0.5 + trackW / 2 - 0.14, cy - 0.045),
        size: const Size(0.32, 0.035),
        binding: DataBinding(src),
        font: 1,
        fontSize: 24,
        color: tint,
        align: TextAlign.right,
      ),
      shapeEl(
        pos: Offset(0.5, cy),
        size: const Size(trackW, 0.035),
        shape: ShapeKind.pill,
        fill: const Color(0x1FFFFFFF),
      ),
      shapeEl(
        pos: Offset(fillCx, cy),
        size: Size(fillW, 0.035),
        shape: ShapeKind.pill,
        gradient: [tint, Color.lerp(tint, Colors.white, 0.25)!],
      ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'goalProgressBars',
    accent: accent,
    background: gradientBg([
      Color.lerp(ink, accent, 0.16)!,
      const Color(0xFF050608),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 1,
        fontSize: 24,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.18),
        size: const Size(0.88, 0.09),
        binding: const DataBinding(BindingSource.title),
        fontSize: 50,
        align: TextAlign.center,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(0.84, 0.035),
        literal: 'PROGRESS TOWARD YOUR DAILY GOALS',
        font: 5,
        fontSize: 16,
        color: Colors.white54,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      ...bar(0.42, 'PROTEIN', BindingSource.proteinG,
          const Color(0xFFEF4444), 0.74),
      ...bar(0.55, 'CARBS', BindingSource.carbsG, const Color(0xFFF59E0B),
          0.58),
      ...bar(0.68, 'FAT', BindingSource.fatG, const Color(0xFF3B82F6), 0.46),
      ...bar(0.81, 'CALORIES', BindingSource.calories, accent, 0.82),
      watermarkEl(pos: const Offset(0.30, 0.93), color: Colors.white70),
    ],
  );
}
