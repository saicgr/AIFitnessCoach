/// Editable-card preset for the **AI Rep Count** template — a computer-vision
/// rep tally over the hero photo: a darkened action shot, a huge centered rep
/// number, an "✦ AI REP COUNT" eyebrow, and an "✓ all reps clean" verdict.
/// Sells auto rep counting. The number and verdict are editable layers.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiRepCounterDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiRepCounter',
    accent: accent,
    background: photoBg(binding: const DataBinding(BindingSource.heroImageUrl)),
    elements: [
      // Darken the action shot.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x59000000), Color(0x80000000)],
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.36),
        size: const Size(0.84, 0.03),
        literal: '✦ AI REP COUNT',
        font: CardFontIx.cond,
        fontSize: 18,
        color: accent,
        letterSpacing: 3.2,
        align: TextAlign.center,
      ),
      // Huge rep number.
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.84, 0.18),
        binding: const DataBinding(BindingSource.exerciseCount),
        font: CardFontIx.display,
        fontSize: 180,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
        shadow: const ShadowSpec(
          color: Color(0x99000000),
          blur: 24,
          offset: Offset(0, 4),
        ),
      ),
      // Verdict.
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.84, 0.04),
        literal: '✓ all reps clean',
        font: CardFontIx.cond,
        fontSize: 26,
        color: white,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.955), color: const Color(0xCCFFFFFF)),
    ],
  );
}
