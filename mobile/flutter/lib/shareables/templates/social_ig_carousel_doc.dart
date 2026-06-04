/// Social-era preset — **Instagram Carousel Slide**. A full-bleed photo with
/// the "1 / 3" slide counter top-right, dot page indicators mid-card, a bottom
/// scrim, and a handle + "swipe →" caption. The slide counter, dots, handle and
/// caption are editable; the photo binds to the share's hero image.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialIgCarouselDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialIgCarousel',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(1, 0.4),
        colors: const [Color(0x00000000), Color(0xCC000000)],
      ),
      // Slide counter pill.
      shapeEl(
        pos: const Offset(0.88, 0.05),
        size: const Size(0.16, 0.035),
        shape: ShapeKind.pill,
        fill: const Color(0x80000000),
      ),
      textEl(
        pos: const Offset(0.88, 0.05),
        size: const Size(0.16, 0.03),
        literal: '1 / 3',
        font: CardFontIx.condMid,
        fontSize: 16,
        color: white,
        align: TextAlign.center,
      ),
      // Page dots (active first).
      shapeEl(
        pos: const Offset(0.47, 0.62),
        size: const Size(0.018, 0.011),
        shape: ShapeKind.circle,
        fill: white,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.018, 0.011),
        shape: ShapeKind.circle,
        fill: const Color(0x66FFFFFF),
      ),
      shapeEl(
        pos: const Offset(0.53, 0.62),
        size: const Size(0.018, 0.011),
        shape: ShapeKind.circle,
        fill: const Color(0x66FFFFFF),
      ),
      // Accent rule above caption.
      shapeEl(
        pos: const Offset(0.12, 0.85),
        size: const Size(0.1, 0.005),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      // Swipe affordance.
      textEl(
        pos: const Offset(0.12, 0.875),
        size: const Size(0.5, 0.03),
        literal: 'swipe →',
        font: CardFontIx.cond,
        fontSize: 20,
        color: accent,
      ),
      // Handle.
      textEl(
        pos: const Offset(0.5, 0.905),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.socialHandle),
        font: CardFontIx.cond,
        fontSize: 24,
        color: white,
        maxLines: 1,
      ),
      // Caption.
      textEl(
        pos: const Offset(0.5, 0.94),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 22,
        color: white70,
        maxLines: 2,
      ),
      watermarkEl(pos: const Offset(0.04, 0.04), color: white70),
    ],
  );
}
