/// Editable-card preset for the **Now Playing** template — Spotify-style
/// "Now Working Out" card: blurred album-art backdrop, square cover, track
/// title, artist line, a progress bar, and transport-control glyphs.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc nowPlayingDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'nowPlaying',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
      blurred: true,
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x8C000000), Color(0x8C000000)],
      ),
      textEl(
        pos: const Offset(0.5, 0.07),
        size: const Size(0.86, 0.03),
        literal: 'NOW WORKING OUT',
        font: 1,
        fontSize: 22,
        color: white,
        align: TextAlign.center,
        letterSpacing: 2.4,
      ),
      photoEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.78, 0.44),
        binding: const DataBinding(BindingSource.heroImageUrl),
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.86, 0.09),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 60,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.05,
        letterSpacing: -0.5,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.69),
        size: const Size(0.86, 0.035),
        literal: 'Zealova',
        fontSize: 28,
        color: Colors.white70,
        align: TextAlign.center,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.86, 0.006),
        shape: ShapeKind.pill,
        fill: const Color(0x33FFFFFF),
      ),
      shapeEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.86, 0.006),
        shape: ShapeKind.pill,
        gradient: [accent, accent],
      ),
      textEl(
        pos: const Offset(0.5, 0.81),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        fontSize: 26,
        color: Colors.white70,
        align: TextAlign.center,
      ),
      iconEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.16, 0.08),
        emoji: '⏸️',
        color: white,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: white),
    ],
  );
}
