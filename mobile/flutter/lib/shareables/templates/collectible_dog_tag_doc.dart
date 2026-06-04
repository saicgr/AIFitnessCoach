/// Editable-card preset for the **Dog Tag** collectible — a military-style
/// embossed ID tag on a dark olive field: a rounded olive plate with a
/// ball-chain hole, monospace stamped lines (NAME, split + blood type, lifetime
/// volume, a "NO QUIT · NO SKIP" creed), and an "ISSUED BY ⚡ ZEALOVA" footer.
/// Every text is editable; the name + volume bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleDogTagDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const field = Color(0xFF14160F);
  const plate = Color(0xFF3A3F2E);
  const plateBorder = Color(0xFF5A6147);
  const stamp = Color(0xFFCDD3BD);
  const muted = Color(0xFF8A8F7C);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleDogTag',
    accent: accent,
    background: solidBg(field),
    elements: [
      // Ball-chain hole.
      shapeEl(
        pos: const Offset(0.5, 0.17),
        size: const Size(0.07, 0.07),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        stroke: plateBorder,
        strokeWidth: 3,
      ),
      // Olive plate.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.7, 0.5),
        fill: plate,
        stroke: plateBorder,
        strokeWidth: 1.5,
        cornerRadius: 28,
      ),
      // Name (stamped).
      textEl(
        pos: const Offset(0.5, 0.36),
        size: const Size(0.6, 0.05),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.mono,
        fontSize: 28,
        color: stamp,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Split (bound) on the left, blood type literal on the right.
      textEl(
        pos: const Offset(0.42, 0.44),
        size: const Size(0.42, 0.035),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.mono,
        fontSize: 18,
        color: stamp,
        align: TextAlign.right,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.65, 0.44),
        size: const Size(0.12, 0.035),
        literal: '· O+',
        font: CardFontIx.mono,
        fontSize: 18,
        color: stamp,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Lifetime volume.
      textEl(
        pos: const Offset(0.5, 0.51),
        size: const Size(0.6, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 22,
        color: accent,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Creed.
      textEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.6, 0.035),
        literal: 'NO QUIT · NO SKIP',
        font: CardFontIx.mono,
        fontSize: 16,
        color: stamp,
        align: TextAlign.center,
        letterSpacing: 1.5,
        maxLines: 1,
      ),
      // Issuer footer.
      textEl(
        pos: const Offset(0.5, 0.7),
        size: const Size(0.8, 0.03),
        literal: 'ISSUED BY ⚡ ZEALOVA',
        font: CardFontIx.cond,
        fontSize: 16,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 3,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: muted),
    ],
  );
}
