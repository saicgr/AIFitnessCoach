/// Social-era preset — **Snap Streak**. The instantly-recognizable Snapchat
/// yellow streak screen: a flame emoji, a giant streak-day count bound to the
/// share's current streak, the "DAY GYM STREAK" label and a "you & the grind"
/// sub-line — all dark ink on Snap yellow. The day count binds to live data;
/// label + sub-line are editable text.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialSnapStreakDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF111111);
  const inkSoft = Color(0xCC111111);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialSnapStreak',
    accent: accent,
    background: solidBg(const Color(0xFFFFFC00)),
    elements: [
      // Flame.
      iconEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.3, 0.13),
        emoji: '🔥',
      ),
      // Giant streak count.
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.9, 0.16),
        binding: const DataBinding(BindingSource.currentStreak),
        font: CardFontIx.display,
        fontSize: 200,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Label.
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.9, 0.04),
        literal: 'DAY GYM STREAK',
        font: CardFontIx.cond,
        fontSize: 34,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      // Sub-line.
      textEl(
        pos: const Offset(0.5, 0.67),
        size: const Size(0.9, 0.03),
        literal: 'you & the grind',
        font: CardFontIx.condMid,
        fontSize: 22,
        color: inkSoft,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: inkSoft),
    ],
  );
}
