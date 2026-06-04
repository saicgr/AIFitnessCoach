/// Editable-card preset for the **Imagined by AI** template — a full-bleed
/// hero photo pushed through a saturated purple→cyan diffusion gradient, an
/// "✦ imagined by zealova ai" provenance chip, and an Anton "PUSH DAY · DREAMT"
/// title bound to the workout title. Mimics an AI-generated art post.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc aiImaginedDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'aiImagined',
    accent: accent,
    background: photoBg(binding: const DataBinding(BindingSource.heroImageUrl)),
    elements: [
      // Diffusion-style color wash (purple → clear → cyan).
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [
          Color(0x667C3AED),
          Color(0x00000000),
          Color(0x4D22D3EE),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      // Bottom legibility scrim.
      scrimEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(1, 0.4),
        colors: const [Color(0x00000000), Color(0xCC000000)],
      ),
      // Provenance chip.
      shapeEl(
        pos: const Offset(0.28, 0.08),
        size: const Size(0.46, 0.05),
        shape: ShapeKind.rounded,
        fill: const Color(0x80000000),
        cornerRadius: 10,
      ),
      textEl(
        pos: const Offset(0.28, 0.08),
        size: const Size(0.46, 0.04),
        literal: '✦ imagined by zealova ai',
        font: CardFontIx.cond,
        fontSize: 18,
        color: white,
        align: TextAlign.center,
      ),
      // Big dreamt title — binds to workout title.
      textEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.88, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 56,
        color: white,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.955), color: const Color(0xCCFFFFFF)),
    ],
  );
}
