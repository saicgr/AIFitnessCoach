/// Editable-card preset for the **Trophy Shelf** collectible — a curated
/// trophy display on a warm dark gradient: a row of trophy / medal glyphs
/// resting on a glowing accent shelf, a "PRs · BADGES · STREAK" tally line
/// (from a stat grid of real counts), and the athlete name as the cabinet
/// plaque. Every text is editable; the tally + name bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleTrophyShelfDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleTrophyShelf',
    accent: accent,
    background: CardBackground(
      kind: CardBackgroundKind.linearGradient,
      colors: const [Color(0xFF1A160C), Color(0xFF070709)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.82, 0.03),
        literal: 'THE TROPHY CASE',
        font: CardFontIx.cond,
        fontSize: 18,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 5,
        maxLines: 1,
      ),
      // Trophy row.
      textEl(
        pos: const Offset(0.5, 0.3),
        size: const Size(0.82, 0.1),
        literal: '🏆  🥇  🏅',
        fontSize: 60,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Glowing shelf.
      shapeEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.72, 0.012),
        shape: ShapeKind.pill,
        gradient: [accent, const Color(0xFF8A6D1F)],
      ),
      // Tally grid (real counts).
      statGridEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.86, 0.22),
        columns: 3,
        tiles: const [
          ['12', 'PRs'],
          ['3', 'BADGES'],
          ['1', 'STREAK'],
        ],
        tileColor: const Color(0x14FFFFFF),
        valueColor: white,
        labelColor: muted,
        valueFontSize: 46,
        labelFontSize: 16,
        valueFont: CardFontIx.display,
      ),
      // Cabinet plaque.
      shapeEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.6, 0.06),
        shape: ShapeKind.pill,
        fill: accent.withValues(alpha: 0.16),
        stroke: accent,
        strokeWidth: 1.5,
      ),
      textEl(
        pos: const Offset(0.39, 0.8),
        size: const Size(0.3, 0.04),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.cond,
        fontSize: 20,
        color: white,
        align: TextAlign.right,
        letterSpacing: 1.5,
        allCaps: true,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.63, 0.8),
        size: const Size(0.26, 0.04),
        literal: 'HALL OF FAME',
        font: CardFontIx.cond,
        fontSize: 20,
        color: white,
        align: TextAlign.left,
        letterSpacing: 1.5,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.94), color: white),
    ],
  );
}
