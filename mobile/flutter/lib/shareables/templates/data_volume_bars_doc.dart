/// Editable-card preset for the **Weekly Volume Bars** data template — the
/// weekly-volume series as a clean vertical bar chart: a "VOLUME / WEEK" kicker,
/// the title, a tall bar chart (`ChartKind.bars`, bound to `subMetrics`), and a
/// total / streak foot. Companion to the line variant. Every label editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataVolumeBarsDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataVolumeBars',
    accent: volt,
    background: gradientBg(
      [const Color(0xFF0D1117), const Color(0xFF06080C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      iconEl(
        pos: const Offset(0.13, 0.085),
        size: const Size(0.05, 0.03),
        emoji: '📊',
        color: volt,
      ),
      textEl(
        pos: const Offset(0.42, 0.085),
        size: const Size(0.5, 0.03),
        literal: 'VOLUME / WEEK',
        font: CardFontIx.cond,
        fontSize: 26,
        color: volt,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.82, 0.085),
        size: const Size(0.3, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 22,
        color: muted,
        align: TextAlign.right,
        allCaps: true,
        letterSpacing: 1.6,
      ),
      textEl(
        pos: const Offset(0.5, 0.165),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 50,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // The real weekly-volume bars.
      chartEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.86, 0.5),
        kind: ChartKind.bars,
      ),
      // Baseline.
      shapeEl(
        pos: const Offset(0.5, 0.80),
        size: const Size(0.86, 0.0015),
        shape: ShapeKind.pill,
        fill: const Color(0x22FFFFFF),
      ),
      // Total / streak foot.
      statGridEl(
        pos: const Offset(0.5, 0.89),
        size: const Size(0.86, 0.1),
        columns: 2,
        tiles: const [
          ['9,128', 'TOTAL KG'],
          ['14', 'DAY STREAK'],
        ],
        tileColor: const Color(0x10FFFFFF),
        valueColor: volt,
        valueFontSize: 34,
        valueFont: CardFontIx.display,
      ),
      watermarkEl(pos: const Offset(0.3, 0.965), color: const Color(0xFFFFFFFF)),
    ],
  );
}
