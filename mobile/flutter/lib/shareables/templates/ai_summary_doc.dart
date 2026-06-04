/// Editable-card preset for the **AI Summary** template — a ✦ eyebrow, a
/// serif (Fraunces) pull-quote of the coach's verdict, and a row of glanceable
/// stat chips at the bottom. The quote and chips are editable; the chip rail
/// binds to the share highlights so it tracks the real session.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiSummaryDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiSummary',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF10131F), Color(0xFF070709)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // ✦ eyebrow glyph.
      textEl(
        pos: const Offset(0.15, 0.16),
        size: const Size(0.08, 0.04),
        literal: '✦',
        fontSize: 26,
        color: accent,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.46, 0.16),
        size: const Size(0.46, 0.03),
        literal: 'AI SUMMARY',
        font: CardFontIx.cond,
        fontSize: 18,
        color: muted,
        letterSpacing: 2.6,
      ),
      // The serif verdict pull-quote.
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.82, 0.28),
        literal:
            '"Your best Push Day in 6 weeks. Bench is trending up — push for 230 next time."',
        font: CardFontIx.serif,
        fontSize: 40,
        color: white,
        lineHeight: 1.28,
      ),
      // Glanceable stat chip rail — binds to highlight labels.
      chipsEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.84, 0.07),
        binding: const DataBinding(BindingSource.highlightLabel),
        literalItems: const ['Volume ↑12%', 'PR ×1', 'Form A'],
        layout: ChipLayout.row,
        maxItems: 3,
        chipColor: const Color(0x14FFFFFF),
        textColor: white,
        fontSize: 22,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
