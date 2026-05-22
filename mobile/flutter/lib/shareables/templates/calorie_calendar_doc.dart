/// Editable-card preset for the **Calorie Calendar** food template — a
/// tear-off desk calendar: a red header strip, a big date block, the meal
/// title, and a macro footer row.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc calorieCalendarDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const paper = Color(0xFFFBFAF5);
  const ink = Color(0xFF22242B);
  final header = Color.lerp(accent, const Color(0xFFD23B3B), 0.5)!;

  // A footer macro cell — label above, gram value below.
  List<CardElement> macroCell(double x, String label, BindingSource src,
      Color tint) {
    return [
      textEl(
        pos: Offset(x, 0.77),
        size: const Size(0.26, 0.03),
        literal: label,
        font: 1,
        fontSize: 16,
        color: ink.withValues(alpha: 0.5),
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      textEl(
        pos: Offset(x, 0.82),
        size: const Size(0.26, 0.05),
        binding: DataBinding(src),
        font: 1,
        fontSize: 38,
        color: tint,
        align: TextAlign.center,
      ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'calorieCalendar',
    accent: accent,
    background: gradientBg([const Color(0xFF15171C), const Color(0xFF05060A)]),
    elements: [
      // The calendar card.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.84, 0.78),
        shape: ShapeKind.rounded,
        fill: paper,
        cornerRadius: 18,
      ),
      // Red header strip with binder rings.
      shapeEl(
        pos: const Offset(0.5, 0.2),
        size: const Size(0.84, 0.18),
        shape: ShapeKind.rounded,
        fill: header,
        cornerRadius: 18,
      ),
      iconEl(
        pos: const Offset(0.38, 0.135),
        size: const Size(0.08, 0.035),
        emoji: '⚪',
      ),
      iconEl(
        pos: const Offset(0.62, 0.135),
        size: const Size(0.08, 0.035),
        emoji: '⚪',
      ),
      textEl(
        pos: const Offset(0.5, 0.21),
        size: const Size(0.74, 0.05),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 5,
        fontSize: 28,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      // Big calorie "date" block.
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.74, 0.2),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 200,
        color: ink,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.7, 0.03),
        literal: 'CALORIES LOGGED',
        font: 1,
        fontSize: 18,
        color: ink.withValues(alpha: 0.45),
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.5, 0.63),
        size: const Size(0.74, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: 8,
        fontSize: 42,
        color: ink,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.7),
        size: const Size(0.72, 0.004),
        color: ink.withValues(alpha: 0.18),
      ),
      ...macroCell(0.3, 'Protein', BindingSource.proteinG,
          const Color(0xFF3B7BE0)),
      ...macroCell(0.5, 'Carbs', BindingSource.carbsG,
          const Color(0xFFE0962F)),
      ...macroCell(0.7, 'Fat', BindingSource.fatG, const Color(0xFFD2495F)),
      watermarkEl(pos: const Offset(0.30, 0.92), color: Colors.white60),
    ],
  );
}
