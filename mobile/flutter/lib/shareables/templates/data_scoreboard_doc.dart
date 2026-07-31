/// Editable-card preset for the **Scoreboard** data/meme template — your
/// session on a stadium jumbotron: a "● LIVE · PUSH DAY" ticker, a glowing
/// jumbo total (the hero volume), a gold SETS / PR / MIN stat strip, and the
/// period foot. Every label is an editable layer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataScoreboardDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);  // accent-allowlist: Scoreboard data/meme template's fixed volt-lime + LED-red palette (template family identity)
  const gold = Color(0xFFFFD60A);  // accent-allowlist: Scoreboard data/meme template's fixed volt-lime + LED-red palette (template family identity)
  const muted = Color(0x8CFFFFFF);
  final stripTiles = highlightTiles(
    data,
    labels: const ['SETS', 'NEW PRS', 'DURATION'],
  );
  return cardDoc(
    aspect: aspect,
    presetId: 'dataScoreboard',
    accent: volt,
    background: solidBg(const Color(0xFF05060A)),
    elements: [
      // LIVE ticker.
      iconEl(
        pos: const Offset(0.28, 0.20),
        size: const Size(0.04, 0.025),
        emoji: '🔴',
        color: const Color(0xFFFF3B30),  // accent-allowlist: Scoreboard data/meme template's fixed volt-lime + LED-red palette (template family identity)
      ),
      textEl(
        pos: const Offset(0.56, 0.20),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.cond,
        fontSize: 22,
        color: volt,
        align: TextAlign.left,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.245),
        size: const Size(0.5, 0.025),
        literal: 'LIVE',
        font: CardFontIx.mono,
        fontSize: 14,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // Jumbo total — the real hero volume, glowing.
      textEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.92, 0.14),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 130,
        color: const Color(0xFFFF3B30),  // accent-allowlist: Scoreboard data/meme template's fixed volt-lime + LED-red palette (template family identity)
        align: TextAlign.center,
        maxLines: 1,
        shadow: const ShadowSpec(
          color: Color(0x99FF3B30),  // accent-allowlist: Scoreboard data/meme template's fixed volt-lime + LED-red palette (template family identity)
          blur: 36,
          offset: Offset.zero,
        ),
      ),
      textEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.86, 0.03),
        literal: 'TOTAL MOVED',
        font: CardFontIx.cond,
        fontSize: 22,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // Gold stat strip — real numbers, never fabricated (E2E #144).
      if (stripTiles.isNotEmpty)
        statGridEl(
          pos: const Offset(0.5, 0.74),
          size: const Size(0.86, 0.12),
          columns: stripTiles.length.clamp(1, 3),
          tiles: stripTiles,
          tileColor: const Color(0x0FFFFFFF),
          valueColor: gold,
          labelColor: muted,
          valueFontSize: 40,
          valueFont: CardFontIx.display,
        ),
      textEl(
        pos: const Offset(0.5, 0.875),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 16,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: const Color(0xFFFFFFFF)),
    ],
  );
}
