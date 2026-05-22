/// Editable-card preset for the **Workout Muscle Card** template — a navy
/// two-column Hevy-style card: left is the workout title + compact exercise
/// list + watermark/@handle footer, right is the worked-muscle heat-map
/// (rendered here as a chart placeholder).
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc workoutMuscleCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'workoutMuscleCard',
    accent: accent,
    background: gradientBg(
      [const Color(0xFF0B1326), const Color(0xFF080E1C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // ─── Left column ───────────────────────────────────────────────
      textEl(
        pos: const Offset(0.31, 0.13),
        size: const Size(0.52, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: 0,
        fontSize: 56,
        maxLines: 2,
        lineHeight: 1.05,
      ),
      repeaterEl(
        pos: const Offset(0.31, 0.52),
        size: const Size(0.52, 0.62),
        maxItems: 10,
        fontSize: 30,
        textColor: const Color(0xEBFFFFFF),
        showAmount: false,
        showCalories: false,
      ),
      textEl(
        pos: const Offset(0.31, 0.92),
        size: const Size(0.52, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: 0,
        fontSize: 24,
        color: const Color(0x99FFFFFF),
      ),
      // ─── Right column: anatomical heat-map placeholder ─────────────
      chartEl(
        pos: const Offset(0.76, 0.5),
        size: const Size(0.4, 0.78),
        style: MacroVizStyle.plate,
      ),
      watermarkEl(pos: const Offset(0.2, 0.95), color: const Color(0xFFFFFFFF)),
    ],
  );
}
