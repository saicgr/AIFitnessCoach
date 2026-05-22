/// Editable-card preset for the **PhotoMagazine** template — user photo
/// full-bleed with a magazine-cover stack: a serif masthead + issue line,
/// a rule, cover-line chips, a giant italic headline and a hero pill.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc photoMagazineDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'photoMagazine',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.customPhotoPath),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: const [Color(0x80000000), Color(0x00000000), Color(0xB3000000)],
        stops: const [0.0, 0.4, 1.0],
      ),
      // Masthead.
      textEl(
        pos: const Offset(0.42, 0.09),
        size: const Size(0.64, 0.08),
        literal: 'ZEALOVA',
        font: 8,
        fontSize: 88,
        letterSpacing: -3,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.82, 0.085),
        size: const Size(0.3, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 20,
        align: TextAlign.right,
        letterSpacing: 2,
        allCaps: true,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.14),
        size: const Size(0.84, 0.004),
        color: const Color(0xFFFFFFFF),
        thickness: 2,
      ),
      // Cover-line chips.
      chipsEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.84, 0.06),
        binding: const DataBinding(BindingSource.highlightLabel),
        layout: ChipLayout.column,
        maxItems: 2,
        fontSize: 22,
        chipColor: const Color(0x8C000000),
      ),
      // Giant italic headline.
      textEl(
        pos: const Offset(0.5, 0.81),
        size: const Size(0.84, 0.12),
        binding: const DataBinding(BindingSource.title),
        font: 8,
        fontSize: 56,
        maxLines: 2,
        lineHeight: 1.0,
      ),
      // Hero pill.
      shapeEl(
        pos: const Offset(0.22, 0.9),
        size: const Size(0.34, 0.05),
        shape: ShapeKind.rounded,
        fill: accent,
        cornerRadius: 6,
      ),
      textEl(
        pos: const Offset(0.22, 0.9),
        size: const Size(0.3, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 30,
        color: const Color(0xFF000000),
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.62, 0.96), color: Colors.white),
    ],
  );
}
