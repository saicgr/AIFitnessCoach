/// Editable-card preset for the **Museum Label** template — a gallery wall: the
/// user's photo hung in a thin museum frame on a warm plaster wall, with a small
/// engraved-style "exhibit label" placard beneath it (artist = handle, title =
/// workout, medium/year line = hero stat + period, and a short description bound
/// to the caption). Quiet, editorial, serif. Volt accent on the catalog number.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosMuseumLabelDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF2A2622);
  const sub = Color(0xFF6B635A);
  const wall = Color(0xFFEDE6DA);
  const placard = Color(0xFFF7F2E9);
  return cardDoc(
    aspect: aspect,
    presetId: 'iosMuseumLabel',
    accent: accent,
    background: gradientBg(
      const [Color(0xFFF2ECE0), Color(0xFFE4DBCB)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Framed artwork.
      shapeEl(
        pos: const Offset(0.5, 0.36),
        size: const Size(0.66, 0.5),
        shape: ShapeKind.rect,
        fill: wall,
        stroke: const Color(0xFF3A332B),
        strokeWidth: 10,
      ),
      photoEl(
        pos: const Offset(0.5, 0.36),
        size: const Size(0.6, 0.44),
        binding: const DataBinding(BindingSource.heroImageUrl),
        mask: PhotoMask.rect,
        cornerRadius: 0,
      ),
      // Engraved placard.
      shapeEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.7, 0.26),
        shape: ShapeKind.rounded,
        fill: placard,
        stroke: const Color(0x1A000000),
        strokeWidth: 1,
        cornerRadius: 6,
      ),
      // Catalog number (volt).
      textEl(
        pos: const Offset(0.5, 0.65),
        size: const Size(0.6, 0.025),
        literal: 'NO. 2026 · PERMANENT COLLECTION',
        font: CardFontIx.mono,
        fontSize: 14,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 1.4,
      ),
      // Artist (handle).
      textEl(
        pos: const Offset(0.5, 0.7),
        size: const Size(0.62, 0.03),
        binding: const DataBinding(BindingSource.socialHandle),
        literal: '@you',
        font: CardFontIx.serif,
        fontSize: 26,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Title (workout), italicized look via serif.
      textEl(
        pos: const Offset(0.5, 0.745),
        size: const Size(0.62, 0.035),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.serif,
        fontSize: 30,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Medium / year line.
      textEl(
        pos: const Offset(0.5, 0.785),
        size: const Size(0.62, 0.025),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 18,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 1,
        allCaps: true,
      ),
      // Description / caption.
      textEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.62, 0.04),
        binding: const DataBinding(BindingSource.caption),
        literal: 'Sweat on canvas, dedication in every rep.',
        font: CardFontIx.serif,
        fontSize: 16,
        color: sub,
        align: TextAlign.center,
        maxLines: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: sub),
    ],
  );
}
