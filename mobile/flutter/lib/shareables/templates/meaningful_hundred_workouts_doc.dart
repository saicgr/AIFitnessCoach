/// Editable-card preset — **100 Workouts**: a centred milestone counter built
/// on a contribution heatmap of every session. A "100 WORKOUTS" eyebrow, the
/// big Anton count in volt, a heatmap grid where each lit cell is one workout,
/// and a "EVERY ONE EARNED" footer. Marks a round-number commitment milestone.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulHundredWorkoutsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulHundredWorkouts',
    accent: accent,
    background: solidBg(const Color(0xFF070709)),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.86, 0.03),
        literal: 'A HUNDRED TIMES OVER',
        font: CardFontIx.cond,
        fontSize: 17,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 5,
        maxLines: 1,
      ),
      // Big count — bound to the exercise/workout count.
      textEl(
        pos: const Offset(0.5, 0.21),
        size: const Size(0.9, 0.13),
        binding: const DataBinding(BindingSource.exerciseCount),
        font: CardFontIx.display,
        fontSize: 108,
        color: accent,
        align: TextAlign.center,
        lineHeight: 0.85,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.31),
        size: const Size(0.86, 0.04),
        literal: 'WORKOUTS COMPLETED',
        font: CardFontIx.cond,
        fontSize: 22,
        color: white,
        align: TextAlign.center,
        letterSpacing: 5,
        maxLines: 1,
      ),
      // Heatmap — one lit cell per workout.
      gridHeatmapEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.86, 0.44),
        columns: 10,
        cellColor: accent,
        emptyColor: const Color(0x14FFFFFF),
        cellRadius: 4,
        gapFraction: 0.22,
      ),
      // Footer.
      textEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(0.86, 0.03),
        literal: 'EVERY ONE EARNED',
        font: CardFontIx.cond,
        fontSize: 16,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 4,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: muted),
    ],
  );
}
