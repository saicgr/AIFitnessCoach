/// Editable-card preset for the **Workout Details** template — a Hevy-style
/// white card: watermark + "Created by" credit, workout title, duration /
/// volume / exercise-count meta pills, and the full exercise list with
/// per-set breakdown.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc workoutDetailsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF111111);
  return cardDoc(
    aspect: aspect,
    presetId: 'workoutDetails',
    accent: accent,
    background: gradientBg([
      Color.lerp(accent, const Color(0xFF0D1117), 0.78)!,
      const Color(0xFF0D1117),
    ]),
    elements: [
      // White card surface.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.92, 0.88),
        fill: const Color(0xFFFAFAFA),
        cornerRadius: 20,
      ),
      textEl(
        pos: const Offset(0.72, 0.12),
        size: const Size(0.4, 0.025),
        binding: const DataBinding(BindingSource.userDisplayName),
        fontSize: 20,
        color: const Color(0xFF666666),
        align: TextAlign.right,
      ),
      textEl(
        pos: const Offset(0.5, 0.18),
        size: const Size(0.8, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 48,
        color: ink,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.24),
        size: const Size(0.8, 0.03),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 7,
        fontSize: 26,
        color: const Color(0xFF888888),
      ),
      repeaterEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.8, 0.62),
        maxItems: 12,
        fontSize: 28,
        textColor: ink,
        showCalories: false,
      ),
      watermarkEl(pos: const Offset(0.2, 0.1), color: const Color(0xFF111111)),
    ],
  );
}
