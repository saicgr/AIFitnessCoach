/// Social-era preset — **Instagram Reel Cover**. A cinematic full-bleed photo
/// with a heavy bottom scrim, the "Reels ▸" badge top-left, a right-rail
/// engagement stack (likes / comments / share), and a bottom-left handle +
/// "Follow" + caption. Handle, caption and the counts are editable; the photo
/// binds to the share's hero image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialIgReelCoverDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialIgReelCover',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(1, 0.52),
        colors: const [Color(0x00000000), Color(0xD9000000)],
      ),
      // Reels badge.
      textEl(
        pos: const Offset(0.14, 0.05),
        size: const Size(0.34, 0.035),
        literal: 'Reels  ▸',
        font: CardFontIx.cond,
        fontSize: 24,
        color: white,
      ),
      // Right rail.
      textEl(
        pos: const Offset(0.92, 0.55),
        size: const Size(0.14, 0.05),
        literal: '❤\n88k',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.25,
      ),
      textEl(
        pos: const Offset(0.92, 0.64),
        size: const Size(0.14, 0.05),
        literal: '💬\n1.4k',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.25,
      ),
      iconEl(
        pos: const Offset(0.92, 0.72),
        size: const Size(0.1, 0.045),
        emoji: '↪',
      ),
      // Handle.
      textEl(
        pos: const Offset(0.32, 0.86),
        size: const Size(0.56, 0.04),
        binding: const DataBinding(BindingSource.socialHandle),
        font: CardFontIx.cond,
        fontSize: 26,
        color: white,
        maxLines: 1,
      ),
      // Follow pill.
      textEl(
        pos: const Offset(0.72, 0.86),
        size: const Size(0.18, 0.035),
        literal: '· Follow',
        font: CardFontIx.cond,
        fontSize: 22,
        color: accent,
        maxLines: 1,
      ),
      // Caption.
      textEl(
        pos: const Offset(0.42, 0.91),
        size: const Size(0.76, 0.045),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 22,
        color: white70,
        maxLines: 2,
      ),
      watermarkEl(pos: const Offset(0.04, 0.04), color: white70),
    ],
  );
}
