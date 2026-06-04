/// Editable-card preset for the **Workout Plan** template — a clean Hevy-style
/// white card: the workout title, date / duration, an accent rule, and the full
/// exercise list rendered with per-exercise thumbnails + the top set of each
/// (via the repeater's exercise mode). Every text and every list row is an
/// editable layer; the thumbnails bind to each exercise's real illustration.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc workoutPlanDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF141414);
  const sub = Color(0xFF8A8A8A);
  return cardDoc(
    aspect: aspect,
    presetId: 'workoutPlan',
    accent: accent,
    background: solidBg(const Color(0xFFFAFAFA)),
    elements: [
      // Workout title (condensed display).
      textEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.84, 0.055),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 52,
        color: ink,
        maxLines: 1,
      ),
      // Date / duration line.
      textEl(
        pos: const Offset(0.5, 0.127),
        size: const Size(0.84, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 18,
        color: sub,
        letterSpacing: 1.5,
        allCaps: true,
      ),
      // Accent rule.
      shapeEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.004),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      // Exercise list: thumbnail + name + top set per row.
      repeaterEl(
        pos: const Offset(0.5, 0.585),
        size: const Size(0.84, 0.74),
        maxItems: 6,
        fontSize: 30,
        textColor: ink,
        exerciseMode: true,
        showImage: true,
        showCalories: false,
        rowSpacing: 12,
      ),
      watermarkEl(pos: const Offset(0.2, 0.955), color: const Color(0xFF141414)),
    ],
  );
}
