/// Editable-card preset for the **AI Grid** template — a Midjourney-style 2×2
/// variation grid of the hero photo (four reframed tiles), a "✦ zealova ai ·
/// 4 variations" caption, and the workout title strap. The four photo tiles are
/// editable layers (swap any tile's image in the editor).
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiGridDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  const hero = DataBinding(BindingSource.heroImageUrl);

  // 2×2 tile centers + size in fractional space.
  const tileSize = Size(0.4, 0.22);
  const tiles = <Offset>[
    Offset(0.29, 0.32),
    Offset(0.71, 0.32),
    Offset(0.29, 0.56),
    Offset(0.71, 0.56),
  ];

  return cardDoc(
    aspect: aspect,
    presetId: 'aiGrid',
    accent: accent,
    background: solidBg(const Color(0xFF0A0A0A)),
    elements: [
      // Header.
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.03),
        literal: '✦ zealova ai · 4 variations',
        font: CardFontIx.mono,
        fontSize: 20,
        color: muted,
        align: TextAlign.center,
      ),
      // The four variation tiles.
      for (var i = 0; i < tiles.length; i++)
        photoEl(
          pos: tiles[i],
          size: tileSize,
          binding: hero,
          cornerRadius: 8,
        ),
      // Title strap.
      textEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.84, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 48,
        color: white,
        allCaps: true,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: muted),
    ],
  );
}
