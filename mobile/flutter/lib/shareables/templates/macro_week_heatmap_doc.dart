/// Editable-card preset for **F11b — Macro Week Heatmap** (food).
///
/// A 7-day × macro-adherence grid: each cell's intensity is how close that day
/// landed to its calorie/macro goal, computed **deterministically** from the
/// weekly nutrition vector carried on `data.subMetrics` (one populated metric
/// per day, value 0–100 adherence %). Zero AI.
///
/// `subMetrics` convention (set by the nutrition adapter for a weekly share):
/// up to 7 entries, value parseable as an adherence percent. When fewer than 7
/// are present the grid renders the available days and leaves the rest empty —
/// it never fabricates data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc macroWeekHeatmapDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;

  // Build the 7-day intensity vector deterministically from sub-metrics.
  final cells = <double>[];
  for (final m in data.subMetrics.take(7)) {
    final v = double.tryParse(m.value.replaceAll('%', '').trim());
    cells.add(v == null ? 0.0 : (v / 100).clamp(0.0, 1.0));
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'macroWeekHeatmap',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0A0B10), accent, 0.16)!,
      const Color(0xFF050608),
    ]),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.11),
        size: const Size(0.84, 0.04),
        literal: 'MACRO WEEK',
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
      // Day-of-week labels.
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
      // The adherence heatmap — one column per day (7 columns).
      gridHeatmapEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.86, 0.2),
        cells: cells,
        columns: 7,
        cellColor: accent,
        cellRadius: 6,
      ),
      // Macro pill summary for the week.
      chartEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.86, 0.1),
        style: MacroVizStyle.pills,
      ),
      textEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.86, 0.035),
        literal: 'GOAL ADHERENCE BY DAY',
        font: CardFontIx.condMid,
        fontSize: 22,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      watermarkEl(pos: const Offset(0.30, 0.94), color: Colors.white70),
    ],
  );
}
