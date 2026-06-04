/// Editable-card preset for the **Gold Medal** collectible — a 1st-place medal
/// on a dark spotlight: an accent ribbon dropping into a radial-gold disc
/// stamped "1", a "GOLD" division line, the event title, and the hero stat in
/// mono beneath. Every text is editable; the title + stat bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleMedalDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  const medalInk = Color(0xFF5A4A00);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleMedal',
    accent: accent,
    background: CardBackground(
      kind: CardBackgroundKind.linearGradient,
      colors: const [Color(0xFF1A1A1A), Color(0xFF000000)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Spotlight glow.
      shapeEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.9, 0.6),
        shape: ShapeKind.circle,
        gradient: [accent.withValues(alpha: 0.25), const Color(0x00000000)],
        radial: true,
      ),
      // Ribbon.
      shapeEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(0.07, 0.18),
        gradient: [accent, const Color(0xFF22D3EE)],
        cornerRadius: 2,
      ),
      // Medal disc.
      shapeEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.38, 0.38),
        shape: ShapeKind.circle,
        gradient: const [Color(0xFFFFD700), Color(0xFFB8860B)],
        radial: true,
        stroke: const Color(0x66FFFFFF),
        strokeWidth: 2,
      ),
      // Rank "1".
      textEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.3, 0.16),
        literal: '1',
        font: CardFontIx.display,
        fontSize: 110,
        color: medalInk,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Division line — bound title + "GOLD".
      textEl(
        pos: const Offset(0.4, 0.68),
        size: const Size(0.5, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 38,
        color: white,
        align: TextAlign.right,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.72, 0.68),
        size: const Size(0.24, 0.04),
        literal: '· GOLD',
        font: CardFontIx.display,
        fontSize: 38,
        color: white,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Hero stat.
      textEl(
        pos: const Offset(0.5, 0.75),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 20,
        color: muted,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Period stamp.
      textEl(
        pos: const Offset(0.5, 0.81),
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
      watermarkEl(pos: const Offset(0.32, 0.94), color: white),
    ],
  );
}
