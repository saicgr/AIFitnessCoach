/// Editable-card preset for the **Workout Details** template — REDESIGNED as
/// the editorial, photo-forward hero of the new direction: full-bleed workout
/// photo + film grain, a bottom legibility scrim, a huge Anton condensed
/// headline (the workout title), and a tight lift ledger (exercise list). The
/// old version was a white "Hevy" card; this is the FRIDAY look, Zealova-built.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc workoutDetailsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'workoutDetails',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      // Bottom-weighted scrim so the headline + ledger stay legible on any photo.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x00000000), Color(0x59000000), Color(0xF2000000)],
        stops: const [0.30, 0.55, 1.0],
      ),
      // Eyebrow: period / split + duration.
      textEl(
        pos: const Offset(0.5, 0.605),
        size: const Size(0.86, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 19,
        color: white70,
        letterSpacing: 2.4,
        allCaps: true,
      ),
      // Massive condensed headline (workout title).
      textEl(
        pos: const Offset(0.5, 0.685),
        size: const Size(0.86, 0.12),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 86,
        color: accent,
        lineHeight: 0.86,
        maxLines: 2,
        allCaps: true,
      ),
      // Lift ledger — exercise list, accent-tinted values, no calories.
      repeaterEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.86, 0.20),
        maxItems: 5,
        fontSize: 24,
        textColor: white,
        showAmount: true,
        showCalories: false,
      ),
      watermarkEl(pos: const Offset(0.22, 0.955), color: white70),
    ],
  );
}
