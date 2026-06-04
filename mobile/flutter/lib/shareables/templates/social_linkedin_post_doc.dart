/// Social-era preset — **LinkedIn Post**. A light, professional LinkedIn feed
/// card: an avatar-row header (name + headline + "· 1st"), a humble-brag body
/// paragraph bound to the share title, a stat-grid of the milestone numbers,
/// and a reactions + comments footer. Header sub-line, body and footer are
/// editable; the stat-grid carries the share's headline numbers.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialLinkedinPostDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF1A1A1A);
  const sub = Color(0xFF666666);
  const liBlue = Color(0xFF0A66C2);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialLinkedinPost',
    accent: accent,
    background: solidBg(const Color(0xFFFFFFFF)),
    elements: [
      // Header.
      avatarRowEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.9, 0.07),
        fallbackGlyph: '🏋️',
        sub: 'Athlete | 1% Stronger Daily · 1st',
        textColor: ink,
        subColor: sub,
        fontSize: 28,
      ),
      // Body paragraph.
      textEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(0.88, 0.16),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 26,
        color: ink,
        lineHeight: 1.4,
        maxLines: 6,
      ),
      // Stat grid of the milestone numbers.
      statGridEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.88, 0.24),
        columns: 3,
        tiles: const [
          ['225', 'BENCH PR LB'],
          ['9,128', 'VOLUME KG'],
          ['90', 'DAY JOURNEY'],
        ],
        tileColor: const Color(0x0F0A66C2),
        valueColor: liBlue,
        labelColor: sub,
        valueFontSize: 40,
        labelFontSize: 14,
        valueFont: CardFontIx.display,
      ),
      // Reactions + comments footer.
      dividerEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.88, 0.002),
        color: const Color(0x22000000),
      ),
      textEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.88, 0.035),
        literal: '👍 ❤ 👏  482  ·  64 comments',
        font: CardFontIx.condMid,
        fontSize: 20,
        color: sub,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: sub),
    ],
  );
}
