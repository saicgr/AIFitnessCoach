/// Social-era preset — **X / Quote Tweet**. A dark X (Twitter) card: an
/// avatar-row header (name + @handle), the author's quote line, and an embedded
/// bordered "quoted tweet" card from @zealova carrying the stat brag. Below it,
/// the reply / repost / like engagement row. The quote line, the quoted card
/// text and the counts are editable; the avatar binds to the share avatar.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialQuoteTweetDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0xFF8B98A5);
  const border = Color(0xFF38444D);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialQuoteTweet',
    accent: accent,
    background: solidBg(const Color(0xFF15181C)),
    elements: [
      // Header.
      avatarRowEl(
        pos: const Offset(0.5, 0.13),
        size: const Size(0.88, 0.07),
        fallbackGlyph: '🏋️',
        sub: '',
        subBinding: const DataBinding(BindingSource.socialHandle),
        fontSize: 30,
        subColor: muted,
      ),
      // The author's quote line.
      textEl(
        pos: const Offset(0.5, 0.26),
        size: const Size(0.88, 0.07),
        literal: 'this is the one. screenshot it 👇',
        font: CardFontIx.condMid,
        fontSize: 30,
        color: white,
        maxLines: 2,
      ),
      // Embedded quoted-tweet card.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.28),
        shape: ShapeKind.rounded,
        fill: const Color(0x00000000),
        stroke: border,
        strokeWidth: 1.4,
        cornerRadius: 22,
      ),
      textEl(
        pos: const Offset(0.13, 0.4),
        size: const Size(0.6, 0.03),
        literal: '@zealova',
        font: CardFontIx.mono,
        fontSize: 16,
        color: muted,
      ),
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.13),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 26,
        color: white,
        maxLines: 4,
      ),
      // Engagement row.
      textEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.88, 0.04),
        literal: '💬 24      ↺ 89      ❤ 1.2k',
        font: CardFontIx.condMid,
        fontSize: 22,
        color: muted,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: muted),
    ],
  );
}
