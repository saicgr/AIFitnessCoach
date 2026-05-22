/// Editable-card preset for the **Macro Receipt** food template — a thermal
/// till receipt: a cream paper panel, a mono masthead "NUTRITION RECEIPT",
/// dashed rules, the per-item line list, a TOTAL calories row, and a
/// faux-barcode block at the foot of the slip.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroReceiptDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const paper = Color(0xFFFBFAF4);
  const ink = Color(0xFF181715);
  final faint = ink.withValues(alpha: 0.55);
  return cardDoc(
    aspect: aspect,
    presetId: 'macroReceipt',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0B0C10), accent, 0.14)!,
      const Color(0xFF050608),
    ]),
    elements: [
      // The receipt slip.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.8, 0.88),
        shape: ShapeKind.rounded,
        fill: paper,
        cornerRadius: 6,
      ),
      textEl(
        pos: const Offset(0.5, 0.11),
        size: const Size(0.7, 0.045),
        literal: 'NUTRITION RECEIPT',
        font: 4,
        fontSize: 30,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 2.5,
      ),
      textEl(
        pos: const Offset(0.5, 0.155),
        size: const Size(0.7, 0.032),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 4,
        fontSize: 18,
        color: faint,
        align: TextAlign.center,
        allCaps: true,
        letterSpacing: 1.5,
      ),
      textEl(
        pos: const Offset(0.5, 0.19),
        size: const Size(0.7, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 4,
        fontSize: 16,
        color: faint,
        align: TextAlign.center,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.235),
        size: const Size(0.7, 0.006),
        style: DividerStyle.dashed,
        color: faint,
        thickness: 2,
      ),
      // Itemized line list.
      repeaterEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.7, 0.36),
        maxItems: 9,
        fontSize: 22,
        textColor: ink,
        showAmount: true,
        showCalories: true,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.7, 0.006),
        style: DividerStyle.dashed,
        color: faint,
        thickness: 2,
      ),
      textEl(
        pos: const Offset(0.27, 0.715),
        size: const Size(0.3, 0.05),
        literal: 'TOTAL KCAL',
        font: 4,
        fontSize: 26,
        color: ink,
        align: TextAlign.left,
      ),
      textEl(
        pos: const Offset(0.69, 0.715),
        size: const Size(0.34, 0.05),
        binding: const DataBinding(BindingSource.calories),
        font: 4,
        fontSize: 30,
        color: ink,
        align: TextAlign.right,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.755),
        size: const Size(0.7, 0.004),
        style: DividerStyle.dotted,
        color: faint,
        thickness: 2,
      ),
      // Faux barcode — a stack of thin bars.
      shapeEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.56, 0.05),
        shape: ShapeKind.rect,
        fill: ink,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.5, 0.05),
        shape: ShapeKind.rect,
        fill: paper,
      ),
      textEl(
        pos: const Offset(0.5, 0.875),
        size: const Size(0.7, 0.03),
        literal: 'FUEL LOGGED  ·  ZEALOVA',
        font: 4,
        fontSize: 16,
        color: faint,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.92), color: ink),
    ],
  );
}
