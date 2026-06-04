/// Social-era preset — **TikTok Post**. A full-bleed darkened photo with the
/// native TikTok furniture: a right-rail action stack (heart / comment / share
/// counts), a bottom-left handle + caption + hashtags, and the "♫ original
/// sound" music ticker. Every count, the handle and the caption are editable
/// text layers; the photo binds to the share's hero image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialTiktokPostDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialTiktokPost',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      // Darken the lower third so caption + chrome stay legible.
      scrimEl(
        pos: const Offset(0.5, 0.72),
        size: const Size(1, 0.56),
        colors: const [Color(0x00000000), Color(0xCC000000)],
      ),
      // "For You" top tab row.
      textEl(
        pos: const Offset(0.5, 0.05),
        size: const Size(0.7, 0.03),
        literal: 'Following    |    For You',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: white,
        align: TextAlign.center,
      ),
      // Right action rail — like / comment / share / sound.
      textEl(
        pos: const Offset(0.92, 0.5),
        size: const Size(0.14, 0.045),
        literal: '❤\n24.5k',
        font: CardFontIx.condMid,
        fontSize: 17,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.25,
      ),
      textEl(
        pos: const Offset(0.92, 0.58),
        size: const Size(0.14, 0.045),
        literal: '💬\n892',
        font: CardFontIx.condMid,
        fontSize: 17,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.25,
      ),
      textEl(
        pos: const Offset(0.92, 0.66),
        size: const Size(0.14, 0.045),
        literal: '↪\n1.2k',
        font: CardFontIx.condMid,
        fontSize: 17,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.25,
      ),
      // Spinning record disc.
      shapeEl(
        pos: const Offset(0.92, 0.745),
        size: const Size(0.1, 0.056),
        shape: ShapeKind.circle,
        fill: const Color(0xFF1A1A1A),
        stroke: accent,
        strokeWidth: 2,
      ),
      // Handle.
      textEl(
        pos: const Offset(0.42, 0.83),
        size: const Size(0.78, 0.035),
        binding: const DataBinding(BindingSource.socialHandle),
        font: CardFontIx.cond,
        fontSize: 28,
        color: white,
      ),
      // Caption + hashtags.
      textEl(
        pos: const Offset(0.42, 0.875),
        size: const Size(0.78, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 21,
        color: white,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.42, 0.915),
        size: const Size(0.78, 0.025),
        literal: '#gymtok #fitness #PR',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: white70,
      ),
      // Music ticker.
      textEl(
        pos: const Offset(0.42, 0.948),
        size: const Size(0.78, 0.025),
        literal: '♫  original sound — Zealova',
        font: CardFontIx.mono,
        fontSize: 15,
        color: white70,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.04, 0.04), color: white70),
    ],
  );
}
