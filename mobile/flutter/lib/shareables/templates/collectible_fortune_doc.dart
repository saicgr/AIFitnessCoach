/// Editable-card preset for the **Fortune** collectible — a fortune-cookie
/// slip on a warm dark field: a cream paper slip (tilted) carrying an italic
/// serif fortune, the cookie glyph, and a mono "LUCKY LIFT" line that spells
/// the hero stat as lucky numbers. Every text is editable; the fortune + lucky
/// numbers bind to / quote live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleFortuneDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const slip = Color(0xFFF7F3E8);
  const ink = Color(0xFF2A2A2A);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleFortune',
    accent: accent,
    background: solidBg(const Color(0xFF1A1410)),
    elements: [
      // Cookie glyph.
      iconEl(
        pos: const Offset(0.5, 0.26),
        size: const Size(0.22, 0.12),
        emoji: '🥠',
      ),
      // Paper slip.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.26),
        fill: slip,
        cornerRadius: 3,
      ),
      // Fortune text (editable proverb).
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.7, 0.2),
        literal: '"A new PR comes to those who do not skip."',
        font: CardFontIx.serif,
        fontSize: 26,
        color: ink,
        align: TextAlign.center,
        lineHeight: 1.35,
        maxLines: 4,
      ),
      // Lucky-lift label.
      textEl(
        pos: const Offset(0.32, 0.72),
        size: const Size(0.34, 0.04),
        literal: 'LUCKY LIFT:',
        font: CardFontIx.mono,
        fontSize: 20,
        color: accent,
        align: TextAlign.right,
        letterSpacing: 1.5,
        maxLines: 1,
      ),
      // Lucky-lift value (bound).
      textEl(
        pos: const Offset(0.66, 0.72),
        size: const Size(0.3, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 20,
        color: accent,
        align: TextAlign.left,
        letterSpacing: 2,
        maxLines: 1,
      ),
      // Period stamp.
      textEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 15,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.94), color: muted),
    ],
  );
}
