/// Editable-card preset for the **Neural Analysis** template — a radar/web
/// chart as the "neural net" centerpiece with input node dots around it,
/// captioned "ANALYZED BY ZEALOVA AI" and a mono latency/result line bound to
/// the hero string. Sells the "AI looked at your whole training" moment.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiNeuralAnalysisDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);

  // Node dots ringing the radar — pure decoration over the web chart.
  const nodes = <Offset>[
    Offset(0.5, 0.18),
    Offset(0.78, 0.3),
    Offset(0.82, 0.5),
    Offset(0.66, 0.62),
    Offset(0.34, 0.62),
    Offset(0.18, 0.5),
    Offset(0.22, 0.3),
  ];

  return cardDoc(
    aspect: aspect,
    presetId: 'aiNeuralAnalysis',
    accent: accent,
    background: solidBg(const Color(0xFF070B12)),
    elements: [
      // Radar "neural web" — the analysis centerpiece.
      chartEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.72, 0.46),
        kind: ChartKind.radar,
      ),
      // Glowing node dots around the web.
      for (final n in nodes)
        shapeEl(
          pos: n,
          size: const Size(0.04, 0.023),
          shape: ShapeKind.circle,
          fill: accent,
        ),
      // Caption.
      textEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.84, 0.04),
        literal: 'ANALYZED BY ZEALOVA AI',
        font: CardFontIx.cond,
        fontSize: 22,
        color: white,
        letterSpacing: 2.4,
        align: TextAlign.center,
      ),
      // Mono result/latency line — binds to hero string.
      textEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 18,
        color: muted,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
