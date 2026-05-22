/// Editable-card preset for the **Receipt** template — a thermal-receipt
/// paper panel listing highlights as line items between dashed rules, with
/// the hero value as the bottom TOTAL.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc receiptDoc(Shareable data, ShareableAspect aspect) {
  const paper = Color(0xFFF6F2E8);
  const ink = Color(0xFF1A1A1A);
  return cardDoc(
    aspect: aspect,
    presetId: 'receipt',
    accent: data.accentColor,
    background: gradientBg(
      const [Color(0xFF0F0F10), Color(0xFF1A1A1C), Color(0xFF0F0F10)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Receipt paper panel.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.84, 0.66),
        shape: ShapeKind.rounded,
        fill: paper,
        cornerRadius: 4,
      ),
      textEl(
        pos: const Offset(0.5, 0.22),
        size: const Size(0.72, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: 4,
        fontSize: 26,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.26),
        size: const Size(0.72, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 4,
        fontSize: 22,
        color: const Color(0xFF555555),
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.31),
        size: const Size(0.72, 0.003),
        style: DividerStyle.dashed,
        color: const Color(0x801A1A1A),
        thickness: 1,
      ),
      repeaterEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.72, 0.32),
        maxItems: 8,
        fontSize: 24,
        textColor: ink,
        showAmount: true,
        showCalories: false,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.69),
        size: const Size(0.72, 0.003),
        style: DividerStyle.dashed,
        color: const Color(0x801A1A1A),
        thickness: 1,
      ),
      textEl(
        pos: const Offset(0.32, 0.74),
        size: const Size(0.3, 0.04),
        literal: 'TOTAL',
        font: 4,
        fontSize: 28,
        color: ink,
        letterSpacing: 1.4,
      ),
      textEl(
        pos: const Offset(0.68, 0.74),
        size: const Size(0.36, 0.05),
        binding: const DataBinding(BindingSource.heroString),
        font: 4,
        fontSize: 36,
        color: ink,
        align: TextAlign.right,
      ),
      watermarkEl(pos: const Offset(0.3, 0.79), color: ink),
    ],
  );
}
