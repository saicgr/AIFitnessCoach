/// Editable-card preset — **Why I Train**: a desaturated, dimmed photo behind a
/// centred manifesto. A volt "WHY I TRAIN" eyebrow over a big Fraunces serif
/// line ("So the hard days find me ready."). Photo-forward and purpose-driven;
/// the scrim keeps the type legible over any image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulWhyITrainDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0xB3FFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulWhyITrain',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.customPhotoPath),
    ),
    elements: [
      // Full-bleed darkening scrim for legibility.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x99000000), Color(0xCC000000)],
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.86, 0.03),
        literal: 'WHY I TRAIN',
        font: CardFontIx.cond,
        fontSize: 19,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 6,
        maxLines: 1,
      ),
      // The manifesto line — Fraunces serif, big.
      textEl(
        pos: const Offset(0.5, 0.53),
        size: const Size(0.84, 0.18),
        literal: 'So the hard days\nfind me ready.',
        font: CardFontIx.serif,
        fontSize: 46,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.12,
        maxLines: 3,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(
          color: Color(0x88000000),
          blur: 18,
          offset: Offset(0, 4),
        ),
      ),
      // The user's name as a quiet attribution.
      textEl(
        pos: const Offset(0.5, 0.67),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.cond,
        fontSize: 17,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 2,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: muted),
    ],
  );
}
