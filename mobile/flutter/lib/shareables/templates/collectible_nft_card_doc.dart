/// Editable-card preset for the **NFT** collectible — a crypto-art mint card:
/// a near-black canvas with the hero illustration full-bleed under a
/// purple/cyan iridescent overlay, an Anton "TITLE #SERIAL" plate, and a mono
/// "0xCHE…225 · minted on you" wallet line in volt-lime. Every text is
/// editable; the title, serial + wallet bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleNftCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const canvas = Color(0xFF0B0B12);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleNftCard',
    accent: accent,
    background: solidBg(canvas),
    elements: [
      // Art window.
      photoEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.88, 0.66),
        binding: const DataBinding(BindingSource.heroImageUrl),
        cornerRadius: 10,
      ),
      // Iridescent overlay.
      scrimEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.88, 0.66),
        colors: const [Color(0x667C3AED), Color(0x00000000), Color(0x5922D3EE)],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      // Legibility scrim under the plate.
      scrimEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(1, 0.28),
        colors: const [Color(0x00000000), Color(0xE6000000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      // Title #serial plate — bound title + literal serial.
      textEl(
        pos: const Offset(0.42, 0.83),
        size: const Size(0.6, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 40,
        color: white,
        align: TextAlign.right,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.78, 0.83),
        size: const Size(0.18, 0.05),
        literal: '#1',
        font: CardFontIx.display,
        fontSize: 40,
        color: white,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Wallet / mint line — literal wallet + bound stat.
      textEl(
        pos: const Offset(0.5, 0.89),
        size: const Size(0.88, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 15,
        color: accent,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.93),
        size: const Size(0.88, 0.025),
        literal: '0xCHE…225 · minted on you',
        font: CardFontIx.mono,
        fontSize: 13,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.97), color: white),
    ],
  );
}
