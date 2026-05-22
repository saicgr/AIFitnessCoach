/// Editable-card preset for the **Stat Brag** template — a period pill, one
/// obscenely large hero number, accent unit label, title, and a PR/streak
/// pill below. The "I just hit X" lockscreen-screenshot format.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc statBragDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'statBrag',
    accent: accent,
    background: gradientBg([
      const Color(0xFF000000),
      Color.lerp(accent, Colors.black, 0.78)!,
    ]),
    elements: [
      shapeEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.4, 0.045),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      dateEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.4, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        color: const Color(0xFF000000),
        fontSize: 24,
      ),
      textEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.92, 0.36),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 320,
        align: TextAlign.center,
        lineHeight: 0.85,
        letterSpacing: -10,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.65),
        size: const Size(0.84, 0.05),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 44,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 6,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.73),
        size: const Size(0.84, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: 7,
        fontSize: 34,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 2,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.56, 0.06),
        shape: ShapeKind.pill,
        fill: accent.withValues(alpha: 0.18),
        stroke: accent,
        strokeWidth: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.52, 0.04),
        binding: const DataBinding(BindingSource.highlightValue),
        font: 1,
        fontSize: 28,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: Colors.white),
    ],
  );
}
