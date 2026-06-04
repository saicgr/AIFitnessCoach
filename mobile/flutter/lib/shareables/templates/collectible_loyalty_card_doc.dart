/// Editable-card preset for the **Loyalty Card** collectible — a coffee-shop
/// punch card on kraft paper: a "WORKOUT LOYALTY" header, a "10 workouts = 1
/// rest day earned" rule, a 5×2 grid of punch slots (filled circles for
/// completed workouts via a stat grid of muscle glyphs), and a progress footer.
/// Every text is editable; progress + reward line bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleLoyaltyCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const kraft = Color(0xFFF4F1E6);
  const ink = Color(0xFF2A2A2A);
  const sub = Color(0xFF888888);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleLoyaltyCard',
    accent: accent,
    background: solidBg(kraft),
    elements: [
      // Card panel border.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.9, 0.86),
        fill: const Color(0x00000000),
        stroke: accent,
        strokeWidth: 2,
        cornerRadius: 14,
      ),
      // Header — bound title + "LOYALTY".
      textEl(
        pos: const Offset(0.5, 0.15),
        size: const Size(0.82, 0.045),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 36,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.2),
        size: const Size(0.82, 0.03),
        literal: 'LOYALTY CARD',
        font: CardFontIx.cond,
        fontSize: 18,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 5,
        maxLines: 1,
      ),
      // Rule line.
      textEl(
        pos: const Offset(0.5, 0.24),
        size: const Size(0.82, 0.03),
        literal: '10 workouts = 1 rest day earned',
        font: CardFontIx.cond,
        fontSize: 16,
        color: sub,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // 5×2 punch grid — filled glyphs for completed, hollow for remaining.
      statGridEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.84, 0.32),
        columns: 5,
        tiles: const [
          ['💪', ''],
          ['💪', ''],
          ['💪', ''],
          ['💪', ''],
          ['💪', ''],
          ['💪', ''],
          ['💪', ''],
          ['💪', ''],
          ['○', ''],
          ['○', ''],
        ],
        tileColor: const Color(0x14000000),
        valueColor: accent,
        labelColor: sub,
        valueFontSize: 30,
        labelFontSize: 1,
        cornerRadius: 999,
        spacing: 10,
      ),
      // Progress footer — bound count + literal nudge.
      textEl(
        pos: const Offset(0.4, 0.74),
        size: const Size(0.42, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.condMid,
        fontSize: 24,
        color: ink,
        align: TextAlign.right,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.66, 0.74),
        size: const Size(0.3, 0.04),
        literal: '· keep going',
        font: CardFontIx.condMid,
        fontSize: 24,
        color: ink,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Holder line — "MEMBER" + bound name.
      textEl(
        pos: const Offset(0.4, 0.8),
        size: const Size(0.34, 0.03),
        literal: 'MEMBER ·',
        font: CardFontIx.cond,
        fontSize: 15,
        color: sub,
        align: TextAlign.right,
        letterSpacing: 2,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.66, 0.8),
        size: const Size(0.3, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.cond,
        fontSize: 15,
        color: sub,
        align: TextAlign.left,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.94), color: ink),
    ],
  );
}
