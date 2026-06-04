/// Editable-card preset for the **Box Score** data/meme template — your
/// session styled like a sports box score: a mono "BOX SCORE" header, a
/// monospaced exercise ledger (real exercises via the repeater), a tidy
/// stat-tile footer, and a right-aligned TOTAL volume line. Every cell editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataBoxScoreDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const ink = Color(0xFF0A0A0A);
  const sub = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataBoxScore',
    accent: volt,
    background: solidBg(ink),
    elements: [
      // Header — title + "BOX SCORE".
      textEl(
        pos: const Offset(0.5, 0.075),
        size: const Size(0.86, 0.035),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 40,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.125),
        size: const Size(0.86, 0.025),
        literal: 'BOX SCORE',
        font: CardFontIx.mono,
        fontSize: 18,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 5,
      ),
      // Column header row.
      textEl(
        pos: const Offset(0.5, 0.185),
        size: const Size(0.86, 0.02),
        literal: 'EXERCISE              SETS    VOL',
        font: CardFontIx.mono,
        fontSize: 14,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 0.5,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.205),
        size: const Size(0.86, 0.002),
        color: const Color(0x33FFFFFF),
      ),
      // The real exercise ledger.
      repeaterEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.86, 0.40),
        maxItems: 6,
        fontSize: 24,
        textColor: const Color(0xFFCFD2D8),
        exerciseMode: true,
        showImage: false,
        showCalories: false,
        rowSpacing: 8,
      ),
      // Stat-tile footer — three quick aggregates.
      statGridEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(0.86, 0.12),
        columns: 3,
        tiles: const [
          ['16', 'SETS'],
          ['1', 'PR'],
          ['61', 'MINUTES'],
        ],
        tileColor: const Color(0x10FFFFFF),
        valueColor: Colors.white,
        valueFontSize: 38,
        valueFont: CardFontIx.display,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.86, 0.002),
        color: const Color(0x33FFFFFF),
      ),
      // Right-aligned TOTAL — the hero volume.
      textEl(
        pos: const Offset(0.5, 0.875),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 30,
        color: volt,
        align: TextAlign.right,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.875),
        size: const Size(0.4, 0.04),
        literal: 'TOTAL',
        font: CardFontIx.mono,
        fontSize: 22,
        color: sub,
        align: TextAlign.left,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: const Color(0xFFFFFFFF)),
    ],
  );
}
