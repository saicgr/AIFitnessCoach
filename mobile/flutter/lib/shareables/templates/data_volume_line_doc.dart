/// Editable-card preset for the **Weekly Volume Line** data template — a clean
/// data-viz card: a "WEEKLY VOLUME" kicker, the workout title, a total/peak
/// stat strip, and a large line chart of the weekly-volume series (bound to
/// `subMetrics`). Every label is an editable layer; the line tracks real data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataVolumeLineDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataVolumeLine',
    accent: volt,
    background: gradientBg(
      [const Color(0xFF0E141C), const Color(0xFF06080C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      iconEl(
        pos: const Offset(0.13, 0.085),
        size: const Size(0.05, 0.03),
        emoji: '📈',
        color: volt,
      ),
      textEl(
        pos: const Offset(0.42, 0.085),
        size: const Size(0.5, 0.03),
        literal: 'WEEKLY VOLUME',
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
      // Total / peak stat strip.
      statGridEl(
        pos: const Offset(0.5, 0.265),
        size: const Size(0.86, 0.1),
        columns: 2,
        tiles: const [
          ['9,128', 'TOTAL KG'],
          ['+12%', 'VS LAST WK'],
        ],
        tileColor: const Color(0x10FFFFFF),
        valueColor: Colors.white,
        valueFontSize: 36,
        valueFont: CardFontIx.display,
      ),
      // Chart baseline.
      shapeEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.86, 0.0015),
        shape: ShapeKind.pill,
        fill: const Color(0x22FFFFFF),
      ),
      // The real weekly-volume line.
      chartEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.86, 0.40),
        kind: ChartKind.line,
      ),
      // Hero close-out.
      textEl(
        pos: const Offset(0.5, 0.90),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 28,
        color: volt,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.955), color: const Color(0xFFFFFFFF)),
    ],
  );
}
