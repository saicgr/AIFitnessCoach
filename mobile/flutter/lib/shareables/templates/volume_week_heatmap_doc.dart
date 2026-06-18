/// Editable-card preset for **F11a (workout) — Volume Week Heatmap**.
///
/// A 7-day training-volume grid: each cell's intensity is that day's training
/// volume relative to the week's peak, computed **deterministically** from the
/// weekly volume vector on `data.subMetrics` (≥7 entries). Zero AI. Pairs with
/// the body/muscle heatmap (`muscleMap` / `workoutMuscleCard`, which render the
/// real anatomical figure from `data.musclesWorked`).
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc volumeWeekHeatmapDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;

  // Parse the weekly volume vector, then normalize to 0..1 against the peak.
  final raw = <double>[];
  for (final m in data.subMetrics.take(7)) {
    final v = double.tryParse(
        m.value.replaceAll(RegExp(r'[^0-9.\-]'), '').trim());
    raw.add(v ?? 0);
  }
  final peak = raw.fold<double>(0, (a, b) => b > a ? b : a);
  final cells =
      peak <= 0 ? raw : raw.map((v) => (v / peak).clamp(0.0, 1.0)).toList();

  return cardDoc(
    aspect: aspect,
    presetId: 'volumeWeekHeatmap',
    accent: accent,
    background: gradientBg([
      const Color(0xFF06080F),
      Color.lerp(accent, const Color(0xFF06080F), 0.82)!,
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.11),
        size: const Size(0.84, 0.04),
        literal: 'TRAINING WEEK',
        font: CardFontIx.cond,
        fontSize: 28,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      textEl(
        pos: const Offset(0.5, 0.17),
        size: const Size(0.86, 0.06),
        binding: const DataBinding(BindingSource.title),
        fontSize: 44,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.23),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        fontSize: 22,
        color: const Color(0x80FFFFFF),
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.36),
        size: const Size(0.86, 0.04),
        literal: 'M   T   W   T   F   S   S',
        font: CardFontIx.mono,
        fontSize: 26,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 1,
      ),
      gridHeatmapEl(
        pos: const Offset(0.5, 0.54),
        size: const Size(0.86, 0.22),
        cells: cells,
        columns: 7,
        cellColor: accent,
        cellRadius: 6,
      ),
      textEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.86, 0.04),
        literal: 'VOLUME BY DAY',
        font: CardFontIx.condMid,
        fontSize: 24,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70),
    ],
  );
}
