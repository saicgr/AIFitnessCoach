/// Editable-card preset for the **Workout Summary** template — an Apple
/// Watch–style near-black card: workout title, an activity-type pill, and a
/// 2-column grid of stat cells (label + colored value).
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc workoutSummaryDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'workoutSummary',
    accent: accent,
    background: gradientBg(
      [const Color(0xFF0A0A0A), const Color(0xFF111111), const Color(0xFF0A0A0A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.12),
        size: const Size(0.86, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: 0,
        fontSize: 64,
        maxLines: 2,
        lineHeight: 1.05,
      ),
      // Activity-type pill.
      shapeEl(
        pos: const Offset(0.22, 0.19),
        size: const Size(0.26, 0.04),
        shape: ShapeKind.pill,
        fill: const Color(0x14FFFFFF),
        stroke: const Color(0x1AFFFFFF),
        strokeWidth: 1,
        cornerRadius: 999,
      ),
      textEl(
        pos: const Offset(0.22, 0.19),
        size: const Size(0.24, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 0,
        fontSize: 20,
        color: const Color(0xD9FFFFFF),
        align: TextAlign.center,
        allCaps: true,
        letterSpacing: 1.4,
      ),
      // 2-column stats grid.
      chartEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.86, 0.56),
        style: MacroVizStyle.numbers,
      ),
      watermarkEl(pos: const Offset(0.2, 0.93), color: const Color(0xFFFFFFFF)),
    ],
  );
}
