/// Editable-card preset for the **Macro Compare** food template — two
/// side-by-side vertical stacked bars ("Today" vs "Goal"), each segmented
/// into P/C/F bands in the macro colours, with a difference badge between
/// them and the meal title across the top.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroCompareDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const proteinC = Color(0xFFA855F7);
  const carbsC = Color(0xFF06B6D4);
  const fatC = Color(0xFFF97316);

  // A stacked column at fractional x — three macro segments + a caption.
  // Segment heights are visual (a typical P/C/F balance), the editor lets
  // the user re-fit them; the data binding still drives the macro figures.
  List<CardElement> column(double x, String label, BindingSource src) {
    const top = 0.36; // top of the bar
    const totalH = 0.4; // overall bar height
    const w = 0.26;
    // Segment heights (carbs widest band, fat thinnest).
    const ph = totalH * 0.32, ch = totalH * 0.42, fh = totalH * 0.26;
    return [
      shapeEl(
        pos: Offset(x, top + ph / 2),
        size: Size(w, ph),
        shape: ShapeKind.rect,
        fill: proteinC,
      ),
      shapeEl(
        pos: Offset(x, top + ph + ch / 2),
        size: Size(w, ch),
        shape: ShapeKind.rect,
        fill: carbsC,
      ),
      shapeEl(
        pos: Offset(x, top + ph + ch + fh / 2),
        size: Size(w, fh),
        shape: ShapeKind.rect,
        fill: fatC,
      ),
      textEl(
        pos: Offset(x, top + totalH + 0.045),
        size: Size(w + 0.06, 0.035),
        literal: label,
        font: 5,
        fontSize: 22,
        color: const Color(0xCCFFFFFF),
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: Offset(x, top + totalH + 0.095),
        size: Size(w + 0.06, 0.05),
        binding: DataBinding(src),
        font: 1,
        fontSize: 40,
        color: Colors.white,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'macroCompare',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0B0D13), accent, 0.16)!,
      const Color(0xFF06070A),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 5,
        fontSize: 24,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.88, 0.09),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 48,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      ...column(0.27, 'Today', BindingSource.calories),
      ...column(0.73, 'Goal', BindingSource.proteinG),
      // Difference badge floating between the two columns.
      badgeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.2, 0.2),
        gradient: [accent, Color.lerp(accent, Colors.black, 0.4)!],
        label: 'VS GOAL',
        valueBinding: const DataBinding(BindingSource.calories),
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: Colors.white70),
    ],
  );
}
