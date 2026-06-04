/// Editable-card preset for the **Now Playing** template — REDESIGNED as a
/// faithful iOS "now playing" media widget: blurred photo backdrop, a single
/// glassmorphic control card with square album art, track title + stats
/// subtitle, a real scrubber with time labels, and a monochrome transport row
/// (◀◀ ❚❚ ▶▶) — replacing the old portrait-poster + lone ⏸️ emoji.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc nowPlayingDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  const white54 = Color(0x8AFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'nowPlaying',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
      blurred: true,
    ),
    elements: [
      // Darken the blurred backdrop so the glass card pops.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0xB3000000), Color(0xCC000000)],
      ),
      // Glassmorphic control card.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.30),
        shape: ShapeKind.rounded,
        fill: const Color(0x66121216),
        stroke: const Color(0x33FFFFFF),
        strokeWidth: 1.2,
        cornerRadius: 28,
      ),
      // Square album art (the user's photo).
      photoEl(
        pos: const Offset(0.215, 0.435),
        size: const Size(0.15, 0.12),
        binding: const DataBinding(BindingSource.heroImageUrl),
        cornerRadius: 10,
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.605, 0.388),
        size: const Size(0.5, 0.02),
        literal: 'NOW WORKING OUT',
        font: CardFontIx.cond,
        fontSize: 15,
        color: accent,
        letterSpacing: 2.2,
      ),
      // Track title.
      textEl(
        pos: const Offset(0.605, 0.432),
        size: const Size(0.5, 0.045),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 30,
        color: white,
        maxLines: 1,
      ),
      // Stats subtitle (volume · calories).
      textEl(
        pos: const Offset(0.605, 0.474),
        size: const Size(0.5, 0.025),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 18,
        color: white70,
      ),
      // Scrubber track + accent fill.
      shapeEl(
        pos: const Offset(0.5, 0.555),
        size: const Size(0.74, 0.006),
        shape: ShapeKind.pill,
        fill: const Color(0x33FFFFFF),
      ),
      shapeEl(
        pos: const Offset(0.345, 0.555),
        size: const Size(0.43, 0.006),
        shape: ShapeKind.pill,
        gradient: [accent, accent],
      ),
      textEl(
        pos: const Offset(0.18, 0.585),
        size: const Size(0.16, 0.02),
        literal: '6:51',
        font: CardFontIx.mono,
        fontSize: 14,
        color: white54,
      ),
      textEl(
        pos: const Offset(0.82, 0.585),
        size: const Size(0.16, 0.02),
        literal: '48:00',
        font: CardFontIx.mono,
        fontSize: 14,
        color: white54,
        align: TextAlign.right,
      ),
      // Monochrome transport row (crisp glyphs, not a colour emoji).
      textEl(
        pos: const Offset(0.5, 0.625),
        size: const Size(0.62, 0.04),
        literal: '⏮     ❚❚     ⏭',
        fontSize: 24,
        color: white,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: white70),
    ],
  );
}
