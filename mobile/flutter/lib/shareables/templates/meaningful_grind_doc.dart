/// Editable-card preset — **The Grind**: a gritty, high-contrast photo with a
/// bottom-anchored manifesto. A volt "THE GRIND" eyebrow, a hard Anton headline
/// ("Nobody saw\nthe reps."), and a hero-stat subline as the receipt for the
/// work. Photo-forward; bottom scrim keeps the type readable on any image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulGrindDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0xB3FFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulGrind',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.customPhotoPath),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x40000000), Color(0xF2000000)],
        stops: const [0.3, 1.0],
      ),
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.86, 0.03),
        literal: 'THE GRIND',
        font: CardFontIx.cond,
        fontSize: 19,
        color: accent,
        align: TextAlign.left,
        letterSpacing: 6,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.86, 0.18),
        literal: 'Nobody saw\nthe reps.',
        font: CardFontIx.display,
        fontSize: 66,
        color: white,
        align: TextAlign.left,
        lineHeight: 0.92,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Hero stat as the receipt for the work.
      textEl(
        pos: const Offset(0.5, 0.92),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 16,
        color: muted,
        align: TextAlign.left,
        letterSpacing: 1,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.68, 0.95), color: muted),
    ],
  );
}
