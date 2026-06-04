/// Editable-card preset for the **Daily Vibe** template — an AI-read mood
/// card: a cyan "✦ TODAY'S VIBE" eyebrow, one huge Anton mood word
/// ("UNSTOPPABLE"), and a row of vibe chips. The mood word and chips are
/// editable; punchy and centered for a story post.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiVibeCheckDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cyan = Color(0xFF22D3EE);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiVibeCheck',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF2A1040), Color(0xFF0A0712)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.84, 0.03),
        literal: "✦ TODAY'S VIBE",
        font: CardFontIx.cond,
        fontSize: 18,
        color: cyan,
        letterSpacing: 2.8,
        align: TextAlign.center,
      ),
      // Mood word.
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.92, 0.1),
        literal: 'UNSTOPPABLE',
        font: CardFontIx.display,
        fontSize: 88,
        color: accent,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Vibe chips.
      chipsEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.88, 0.06),
        literalItems: const ['🔥 intense', '💪 strong', '😤 locked-in'],
        layout: ChipLayout.row,
        maxItems: 3,
        chipColor: const Color(0x1FFFFFFF),
        textColor: white,
        fontSize: 22,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
