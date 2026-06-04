/// Editable-card preset for the **AI Wrapped** template — a Spotify-Wrapped-
/// style year recap narrated by the AI: a cyan "✦ AI WRAPPED '26" eyebrow, a
/// serif personality verdict, and a huge "TOP 4%" percentile with a rank
/// sub-label. The percentile reads from a literal; the rank label binds to the
/// share's rank field.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiWrappedDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const cyan = Color(0xFF22D3EE);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiWrapped',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF1A1040), Color(0xFF0A0712)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.3, 0.2),
        size: const Size(0.6, 0.03),
        literal: "✦ AI WRAPPED '26",
        font: CardFontIx.cond,
        fontSize: 18,
        color: cyan,
        letterSpacing: 2.6,
      ),
      // Personality verdict — serif.
      textEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.84, 0.2),
        literal:
            '"You are a Morning Powerlifter. You train hardest on Fridays and never skip chest."',
        font: CardFontIx.serif,
        fontSize: 38,
        color: white,
        lineHeight: 1.28,
      ),
      // Big percentile.
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.84, 0.1),
        literal: 'TOP 4%',
        font: CardFontIx.display,
        fontSize: 92,
        color: accent,
        align: TextAlign.center,
      ),
      // Rank sub-label — binds to rank.
      textEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.rank),
        font: CardFontIx.cond,
        fontSize: 20,
        color: muted,
        letterSpacing: 2.4,
        align: TextAlign.center,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
