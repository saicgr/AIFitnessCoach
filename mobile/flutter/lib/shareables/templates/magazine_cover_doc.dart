/// Editable-card preset for the **Magazine Cover** template — full accent
/// gradient, ZEALOVA masthead, one huge hero word centered, rotated subscript
/// on the right edge, title + kicker rule at the bottom.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc magazineCoverDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'magazineCover',
    accent: accent,
    background: gradientBg([
      accent,
      Color.lerp(accent, Colors.black, 0.55)!,
      const Color(0xFF000000),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.32, 0.06),
        size: const Size(0.5, 0.07),
        literal: 'ZEALOVA',
        font: 8,
        fontSize: 64,
        letterSpacing: -2,
      ),
      textEl(
        pos: const Offset(0.82, 0.055),
        size: const Size(0.34, 0.05),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 22,
        align: TextAlign.right,
        letterSpacing: 2.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.9, 0.4),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 240,
        align: TextAlign.center,
        lineHeight: 0.9,
        letterSpacing: -8,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.7, 0.03),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 22,
        color: Colors.white70,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
        maxLines: 1,
      ),
      shapeEl(
        pos: const Offset(0.13, 0.85),
        size: const Size(0.1, 0.004),
        shape: ShapeKind.rect,
      ),
      textEl(
        pos: const Offset(0.4, 0.89),
        size: const Size(0.66, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 32,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 2,
      ),
      watermarkEl(pos: const Offset(0.78, 0.92), color: Colors.white),
    ],
  );
}
