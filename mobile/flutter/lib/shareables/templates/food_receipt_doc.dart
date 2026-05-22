/// Editable-card preset for the **Food Receipt** food template — the meal
/// itemized as a thermal till receipt: a mono masthead, a dashed rule, the
/// per-item line list, a TOTAL, the macro subtotal and a footer line.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc foodReceiptDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const paper = Color(0xFFF6F3EA);
  const ink = Color(0xFF1B1B1A);
  return cardDoc(
    aspect: aspect,
    presetId: 'foodReceipt',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0C0D11), accent, 0.12)!,
      const Color(0xFF050608),
    ]),
    elements: [
      // The receipt paper.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.82, 0.86),
        shape: ShapeKind.rounded,
        fill: paper,
        cornerRadius: 8,
      ),
      textEl(
        pos: const Offset(0.5, 0.12),
        size: const Size(0.72, 0.04),
        literal: 'ZEALOVA KITCHEN',
        font: 4,
        fontSize: 28,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.17),
        size: const Size(0.72, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 4,
        fontSize: 18,
        color: ink.withValues(alpha: 0.6),
        align: TextAlign.center,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.22),
        size: const Size(0.72, 0.006),
        style: DividerStyle.dashed,
        color: ink.withValues(alpha: 0.5),
        thickness: 2,
      ),
      // Itemized line list.
      repeaterEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.72, 0.36),
        maxItems: 9,
        fontSize: 22,
        textColor: ink,
        showAmount: true,
        showCalories: true,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.72, 0.006),
        style: DividerStyle.dashed,
        color: ink.withValues(alpha: 0.5),
        thickness: 2,
      ),
      textEl(
        pos: const Offset(0.27, 0.72),
        size: const Size(0.3, 0.045),
        literal: 'TOTAL',
        font: 4,
        fontSize: 28,
        color: ink,
        align: TextAlign.left,
      ),
      textEl(
        pos: const Offset(0.68, 0.72),
        size: const Size(0.34, 0.045),
        binding: const DataBinding(BindingSource.calories),
        font: 4,
        fontSize: 28,
        color: ink,
        align: TextAlign.right,
      ),
      textEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.72, 0.035),
        literal: 'FUEL LOGGED  ·  THANK YOU',
        font: 4,
        fontSize: 18,
        color: ink.withValues(alpha: 0.6),
        align: TextAlign.center,
        letterSpacing: 1.5,
      ),
      watermarkEl(pos: const Offset(0.30, 0.88), color: ink),
    ],
  );
}
