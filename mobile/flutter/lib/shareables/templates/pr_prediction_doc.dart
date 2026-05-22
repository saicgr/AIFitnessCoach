/// Editable-card preset for the **PR Prediction** template — a dark
/// projection card: a "Projection" kicker, lift title, current PR in big
/// type with a "Next" pill, a trajectory line chart, and a projection
/// caption.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc prPredictionDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'prPrediction',
    accent: accent,
    background: gradientBg(
      [const Color(0xFF0B0F19), const Color(0xFF050810)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      iconEl(
        pos: const Offset(0.13, 0.1),
        size: const Size(0.06, 0.03),
        emoji: '✨',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.45, 0.1),
        size: const Size(0.6, 0.03),
        literal: 'PROJECTION',
        font: 1,
        fontSize: 26,
        color: accent,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.5, 0.18),
        size: const Size(0.84, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 52,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.36, 0.28),
        size: const Size(0.5, 0.1),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 128,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // "Next PR" projection pill.
      shapeEl(
        pos: const Offset(0.78, 0.27),
        size: const Size(0.34, 0.05),
        shape: ShapeKind.pill,
        fill: const Color(0x00000000),
        stroke: accent,
        strokeWidth: 1.4,
        cornerRadius: 8,
      ),
      textEl(
        pos: const Offset(0.78, 0.27),
        size: const Size(0.32, 0.035),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 1,
        fontSize: 24,
        color: accent,
        align: TextAlign.center,
      ),
      // Trajectory chart placeholder.
      chartEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.84, 0.3),
        style: MacroVizStyle.columnChart,
      ),
      textEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 0),
        font: 0,
        fontSize: 28,
        color: const Color(0xD9FFFFFF),
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.84, 0.03),
        literal: 'Based on your current cadence — keep the volume steady.',
        fontSize: 22,
        color: const Color(0x8CFFFFFF),
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.2, 0.93), color: const Color(0xFFFFFFFF)),
    ],
  );
}
