/// Editable-card preset — **Diner Menu**: a cream card with a ruled border, a
/// "TODAY'S SPECIAL" header banner, the meal name in a vintage italic face,
/// the macros as menu line-items with dotted-leader dividers, and a starburst
/// seal badge.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dinerMenuDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cream = Color(0xFFF7EFDD);
  const ink = Color(0xFF2A2118);
  final banner = Color.lerp(const Color(0xFF7A1E1E), accent, 0.25)!;

  return cardDoc(
    aspect: aspect,
    presetId: 'dinerMenu',
    accent: accent,
    background: solidBg(cream),
    elements: [
      // Ruled border — a stroked rectangle inset from the edges.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.86),
        shape: ShapeKind.rect,
        fill: const Color(0x00000000),
        stroke: ink,
        strokeWidth: 3,
        cornerRadius: 4,
      ),
      // "TODAY'S SPECIAL" header banner.
      shapeEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.64, 0.07),
        shape: ShapeKind.rect,
        fill: banner,
        cornerRadius: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.6, 0.04),
        literal: "TODAY'S SPECIAL",
        font: 5,
        fontSize: 26,
        color: cream,
        align: TextAlign.center,
        letterSpacing: 4,
        maxLines: 1,
      ),
      // Meal name in a vintage italic face.
      textEl(
        pos: const Offset(0.5, 0.32),
        size: const Size(0.78, 0.12),
        binding: const DataBinding(BindingSource.title),
        font: 6,
        fontSize: 64,
        color: ink,
        align: TextAlign.center,
        lineHeight: 1.0,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Macros as menu line-items with dotted-leader dividers between them.
      dividerEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.74, 0.003),
        style: DividerStyle.dotted,
        color: const Color(0x882A2118),
        thickness: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.74, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: 3,
        fontSize: 28,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.74, 0.003),
        style: DividerStyle.dotted,
        color: const Color(0x882A2118),
        thickness: 2,
      ),
      // Macro pills as the lower menu line.
      chartEl(
        pos: const Offset(0.5, 0.67),
        size: const Size(0.7, 0.08),
        style: MacroVizStyle.pills,
      ),
      // Starburst seal badge — bottom corner.
      badgeEl(
        pos: const Offset(0.74, 0.83),
        size: const Size(0.26, 0.13),
        gradient: [Color.lerp(accent, Colors.white, 0.2)!, accent],
        label: 'HEALTH',
        valueBinding: const DataBinding(BindingSource.healthScore),
      ),
      watermarkEl(
        pos: const Offset(0.3, 0.9),
        color: const Color(0x992A2118),
        iconSize: 16,
        fontSize: 11,
      ),
    ],
  );
}
