/// Editable-card preset for the **AI Suggests Next** template — a coach
/// recommendation card: "✦ AI SUGGESTS NEXT" eyebrow, the recommended session
/// name in accent, a reasoning line, and a volt-lime "START WORKOUT →" CTA pill.
/// The recommendation name binds to the workout title; the rest are editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiNextWorkoutDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiNextWorkout',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0D1117), Color(0xFF070709)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.3, 0.28),
        size: const Size(0.6, 0.03),
        literal: '✦ AI SUGGESTS NEXT',
        font: CardFontIx.cond,
        fontSize: 18,
        color: muted,
        letterSpacing: 2.2,
      ),
      // Recommended session name — binds to title.
      textEl(
        pos: const Offset(0.3, 0.37),
        size: const Size(0.7, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 56,
        color: accent,
        maxLines: 1,
      ),
      // Reasoning line.
      textEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.82, 0.14),
        literal:
            'Chest volume is up 12% and back is lagging — tomorrow targets lats + rear delts.',
        font: CardFontIx.condMid,
        fontSize: 28,
        color: white,
        lineHeight: 1.5,
      ),
      // CTA pill.
      shapeEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.74, 0.07),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.74, 0.04),
        literal: 'START WORKOUT →',
        font: CardFontIx.cond,
        fontSize: 24,
        color: const Color(0xFF0B0B0B),
        letterSpacing: 1.5,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: muted),
    ],
  );
}
