/// Editable-card preset for the **PhotoStats** template — user photo
/// full-bleed, an eyebrow + title stacked top-left, and a frosted-glass
/// stat strip across the bottom carrying the highlight metrics.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc photoStatsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'photoStats',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.customPhotoPath),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: const [Color(0x33000000), Color(0x00000000), Color(0x8C000000)],
        stops: const [0.0, 0.45, 1.0],
      ),
      textEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 24,
        color: accent,
        align: TextAlign.left,
        letterSpacing: 2.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.14),
        size: const Size(0.84, 0.09),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 52,
        maxLines: 2,
      ),
      // Frosted stat strip.
      shapeEl(
        pos: const Offset(0.5, 0.87),
        size: const Size(0.86, 0.1),
        shape: ShapeKind.rounded,
        fill: const Color(0x1AFFFFFF),
        stroke: const Color(0x38FFFFFF),
        strokeWidth: 1.5,
        cornerRadius: 24,
      ),
      chipsEl(
        pos: const Offset(0.5, 0.87),
        size: const Size(0.8, 0.08),
        binding: const DataBinding(BindingSource.highlightLabel),
        layout: ChipLayout.row,
        maxItems: 3,
        fontSize: 22,
      ),
      watermarkEl(pos: const Offset(0.62, 0.96), color: Colors.white),
    ],
  );
}
