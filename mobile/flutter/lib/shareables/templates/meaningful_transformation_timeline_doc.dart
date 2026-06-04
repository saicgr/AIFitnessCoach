/// Editable-card preset — **Transformation Timeline**: a vertical progress
/// story. A serif header ("how it's going"), a long progress scrubber standing
/// in for the journey-so-far with start/now labels, a milestone stat strip
/// (start → milestone → now), and a Fraunces coda. Reads as a single timeline
/// from where you began to where you are.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulTransformationTimelineDoc(
    Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulTransformationTimeline',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF111821), Color(0xFF070709)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.03),
        literal: 'THE TIMELINE',
        font: CardFontIx.cond,
        fontSize: 17,
        color: muted,
        align: TextAlign.left,
        letterSpacing: 5,
        maxLines: 1,
      ),
      // Serif header.
      textEl(
        pos: const Offset(0.5, 0.175),
        size: const Size(0.84, 0.08),
        literal: "how it's going",
        font: CardFontIx.serif,
        fontSize: 50,
        color: white,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // The journey scrubber — start → now.
      scrubberEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.84, 0.08),
        progress: 0.82,
        leftLabel: 'START',
        rightLabel: 'NOW',
        trackColor: const Color(0x22FFFFFF),
        fillColor: accent,
        knobColor: accent,
        textColor: muted,
        trackHeight: 8,
        fontSize: 16,
      ),
      // Milestone stat strip — three points along the journey.
      statGridEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.84, 0.22),
        columns: 3,
        tileColor: const Color(0x0FFFFFFF),
        valueFont: CardFontIx.display,
        valueFontSize: 36,
        labelFontSize: 13,
        cornerRadius: 14,
        tiles: const [
          ['135', 'START'],
          ['185', 'HALFWAY'],
          ['225', 'NOW'],
        ],
      ),
      // Coda.
      textEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.serif,
        fontSize: 22,
        color: muted,
        align: TextAlign.left,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.62, 0.95), color: muted),
    ],
  );
}
