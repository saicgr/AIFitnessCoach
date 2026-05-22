/// Editable-card preset for the **Macro Export** food template — an
/// app-export style sheet: a header bar with a logo chip + date, a clean
/// keyed macro list with dotted-leader dividers, and a faux barcode strip
/// plus a "verified" badge at the bottom.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroExportDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const paper = Color(0xFFF7F6F1);
  const ink = Color(0xFF1A1B1E);
  final faint = ink.withValues(alpha: 0.55);

  // A keyed macro row: label left, value right, dotted leader between.
  List<CardElement> row(double y, String label, DataBinding value,
      String unit) {
    return [
      textEl(
        pos: Offset(0.3, y),
        size: const Size(0.36, 0.04),
        literal: label,
        font: 4,
        fontSize: 22,
        color: ink,
        align: TextAlign.left,
      ),
      dividerEl(
        pos: Offset(0.5, y + 0.018),
        size: const Size(0.72, 0.004),
        style: DividerStyle.dotted,
        color: faint,
        thickness: 2,
      ),
      textEl(
        pos: Offset(0.7, y),
        size: const Size(0.36, 0.04),
        binding: value,
        font: 4,
        fontSize: 22,
        color: ink,
        align: TextAlign.right,
      ),
      textEl(
        pos: Offset(0.86, y),
        size: const Size(0.12, 0.04),
        literal: unit,
        font: 4,
        fontSize: 18,
        color: faint,
        align: TextAlign.left,
      ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'macroExport',
    accent: accent,
    background: solidBg(const Color(0xFF0B0C10)),
    elements: [
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.84),
        shape: ShapeKind.rounded,
        fill: paper,
        cornerRadius: 14,
      ),
      // Header bar.
      shapeEl(
        pos: const Offset(0.5, 0.135),
        size: const Size(0.86, 0.11),
        shape: ShapeKind.rounded,
        fill: ink,
        cornerRadius: 14,
      ),
      shapeEl(
        pos: const Offset(0.21, 0.135),
        size: const Size(0.085, 0.045),
        shape: ShapeKind.circle,
        gradient: [accent, Color.lerp(accent, Colors.black, 0.4)!],
      ),
      iconEl(
        pos: const Offset(0.21, 0.135),
        size: const Size(0.05, 0.03),
        emoji: '⚡',
      ),
      textEl(
        pos: const Offset(0.42, 0.12),
        size: const Size(0.4, 0.035),
        literal: 'ZEALOVA EXPORT',
        font: 4,
        fontSize: 20,
        color: Colors.white,
        align: TextAlign.left,
        letterSpacing: 2,
      ),
      textEl(
        pos: const Offset(0.42, 0.155),
        size: const Size(0.4, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 4,
        fontSize: 16,
        color: Colors.white60,
        align: TextAlign.left,
      ),
      textEl(
        pos: const Offset(0.5, 0.26),
        size: const Size(0.72, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 9,
        fontSize: 36,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      ...row(0.36, 'Calories', const DataBinding(BindingSource.calories),
          'kcal'),
      ...row(0.44, 'Protein', const DataBinding(BindingSource.proteinG), 'g'),
      ...row(0.52, 'Carbs', const DataBinding(BindingSource.carbsG), 'g'),
      ...row(0.6, 'Fat', const DataBinding(BindingSource.fatG), 'g'),
      // Faux barcode strip.
      shapeEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.6, 0.06),
        shape: ShapeKind.rect,
        fill: ink,
      ),
      textEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.6, 0.025),
        binding: const DataBinding(BindingSource.calories),
        font: 4,
        fontSize: 15,
        color: faint,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // Verified seal.
      badgeEl(
        pos: const Offset(0.5, 0.87),
        size: const Size(0.16, 0.075),
        gradient: const [Color(0xFF22C55E), Color(0xFF15803D)],
        label: 'VERIFIED',
        valueLiteral: '✓',
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white70),
    ],
  );
}
