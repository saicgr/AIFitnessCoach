/// Social-era preset — **Threads**. A near-black Threads post: an avatar-row
/// header (handle + timestamp), a roomy post body bound to the share title, and
/// the Threads engagement glyph row (like / reply / repost / share) with
/// counts. Body and counts are editable; the avatar binds to the share avatar.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialThreadsDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0xFF777777);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialThreads',
    accent: accent,
    background: solidBg(const Color(0xFF0A0A0A)),
    elements: [
      // Header.
      avatarRowEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.88, 0.07),
        fallbackGlyph: '🏋️',
        sub: '7h',
        textColor: white,
        subColor: muted,
        fontSize: 30,
      ),
      // Post body.
      textEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.88, 0.26),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 34,
        color: white,
        lineHeight: 1.35,
        maxLines: 6,
      ),
      // Engagement glyph row.
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.7, 0.05),
        literal: '♡     💬     ↻     ↪',
        fontSize: 30,
        color: white,
        align: TextAlign.center,
      ),
      // Counts.
      textEl(
        pos: const Offset(0.5, 0.73),
        size: const Size(0.88, 0.035),
        literal: '1,104 likes  ·  92 replies',
        font: CardFontIx.condMid,
        fontSize: 20,
        color: muted,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: muted),
    ],
  );
}
