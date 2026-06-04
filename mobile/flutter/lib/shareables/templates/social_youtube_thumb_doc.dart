/// Social-era preset — **YouTube Thumbnail**. A punchy, high-contrast YT
/// thumbnail: a saturated full-bleed photo, a left-edge scrim, an oversized
/// Anton headline with a red drop-shadow, and the duration chip bottom-right.
/// The three-line headline and the duration are editable; the photo binds to
/// the share's hero image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialYoutubeThumbDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const ytRed = Color(0xFFFF0000);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialYoutubeThumb',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      // Left-edge readability scrim.
      scrimEl(
        pos: const Offset(0.3, 0.5),
        size: const Size(0.7, 1),
        colors: const [Color(0xCC000000), Color(0x00000000)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      // Oversized headline (red shadow for the YT look).
      textEl(
        pos: const Offset(0.42, 0.42),
        size: const Size(0.82, 0.4),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 96,
        color: white,
        lineHeight: 0.92,
        maxLines: 3,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(
          color: ytRed,
          blur: 0,
          offset: Offset(5, 5),
        ),
      ),
      // Duration chip.
      shapeEl(
        pos: const Offset(0.88, 0.93),
        size: const Size(0.16, 0.04),
        shape: ShapeKind.rounded,
        fill: const Color(0xE6000000),
        cornerRadius: 6,
      ),
      textEl(
        pos: const Offset(0.88, 0.93),
        size: const Size(0.16, 0.03),
        literal: '61:00',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: white,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.04, 0.04), color: white),
    ],
  );
}
