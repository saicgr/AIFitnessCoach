/// Social-era preset — **YouTube Shorts**. A vertical Shorts cover: darkened
/// full-bleed photo, the red "Shorts" badge top-left, a right-rail like /
/// dislike / comment stack, and a bottom caption with the #shorts hashtag.
/// Counts and caption are editable; the photo binds to the share's hero image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialYoutubeShortsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const ytRed = Color(0xFFFF0000);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialYoutubeShorts',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(1, 0.44),
        colors: const [Color(0x00000000), Color(0xCC000000)],
      ),
      // Shorts badge.
      shapeEl(
        pos: const Offset(0.14, 0.05),
        size: const Size(0.2, 0.035),
        shape: ShapeKind.rounded,
        fill: ytRed,
        cornerRadius: 6,
      ),
      textEl(
        pos: const Offset(0.14, 0.05),
        size: const Size(0.2, 0.03),
        literal: 'Shorts',
        font: CardFontIx.cond,
        fontSize: 18,
        color: white,
        align: TextAlign.center,
      ),
      // Right rail.
      textEl(
        pos: const Offset(0.92, 0.55),
        size: const Size(0.14, 0.05),
        literal: '👍\n142k',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.25,
      ),
      iconEl(
        pos: const Offset(0.92, 0.63),
        size: const Size(0.1, 0.04),
        emoji: '👎',
      ),
      textEl(
        pos: const Offset(0.92, 0.7),
        size: const Size(0.14, 0.05),
        literal: '💬\n3.1k',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.25,
      ),
      // Caption.
      textEl(
        pos: const Offset(0.42, 0.89),
        size: const Size(0.78, 0.045),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 24,
        color: white,
        maxLines: 2,
      ),
      // Hashtag line.
      textEl(
        pos: const Offset(0.42, 0.93),
        size: const Size(0.78, 0.025),
        literal: '#shorts #gym #PR',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: const Color(0xB3FFFFFF),
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.04, 0.04), color: white),
    ],
  );
}
