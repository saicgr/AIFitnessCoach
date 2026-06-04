/// Editable-card preset — **The Comeback**: a dim, cinematic photo with a
/// bottom-anchored "Day 1. Again." headline. A volt "THE COMEBACK" eyebrow, a
/// huge Anton headline, and a quiet "BACK FROM INJURY · STRONGER THIS TIME"
/// subline. Story of resilience; bottom scrim keeps the type readable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulComebackDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0xB3FFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulComeback',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.customPhotoPath),
    ),
    elements: [
      // Bottom-weighted legibility scrim.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x33000000), Color(0xF2000000)],
        stops: const [0.35, 1.0],
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.86, 0.03),
        literal: 'THE COMEBACK',
        font: CardFontIx.cond,
        fontSize: 19,
        color: accent,
        align: TextAlign.left,
        letterSpacing: 6,
        maxLines: 1,
      ),
      // Headline.
      textEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.86, 0.16),
        literal: 'Day 1.\nAgain.',
        font: CardFontIx.display,
        fontSize: 76,
        color: white,
        align: TextAlign.left,
        lineHeight: 0.92,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Subline.
      textEl(
        pos: const Offset(0.5, 0.92),
        size: const Size(0.86, 0.03),
        literal: 'BACK FROM INJURY · STRONGER THIS TIME',
        font: CardFontIx.cond,
        fontSize: 15,
        color: muted,
        align: TextAlign.left,
        letterSpacing: 2,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.68, 0.95), color: muted),
    ],
  );
}
