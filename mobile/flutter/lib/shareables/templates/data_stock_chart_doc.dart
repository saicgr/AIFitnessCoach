/// Editable-card preset for the **Stock Chart** data/meme template — your
/// lifts framed like a trading terminal: a "$GAINS · ▲ +12%" ticker eyebrow,
/// a real line chart of the weekly-volume series (bound to `subMetrics`), and a
/// big green close-price hero. Every label is an editable layer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataStockChartDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F); // volt-lime brand accent
  const up = Color(0xFF16C784); // "market green"
  const ink = Color(0xFF0A0E12);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataStockChart',
    accent: volt,
    background: gradientBg(
      [ink, const Color(0xFF05070A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Ticker eyebrow.
      textEl(
        pos: const Offset(0.5, 0.085),
        size: const Size(0.9, 0.03),
        literal: r'$GAINS  ·  ▲ +12% TODAY',
        font: CardFontIx.cond,
        fontSize: 26,
        color: up,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      // Workout title as the "asset name".
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
      // Period label.
      textEl(
        pos: const Offset(0.5, 0.225),
        size: const Size(0.7, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 18,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 1.5,
      ),
      // Faint baseline behind the chart.
      shapeEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.86, 0.0015),
        shape: ShapeKind.pill,
        fill: const Color(0x22FFFFFF),
      ),
      // The real volume line chart (weekly bars → line).
      chartEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.86, 0.42),
        kind: ChartKind.line,
      ),
      // Big close-price hero (the hero string — volume / kcal).
      textEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.86, 0.06),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 46,
        color: up,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.895),
        size: const Size(0.86, 0.025),
        literal: 'CLOSE · ALL-TIME HIGH ▲',
        font: CardFontIx.mono,
        fontSize: 15,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: const Color(0xFFFFFFFF)),
    ],
  );
}
