/// Editable-card preset for the **Watch Face** collectible — a smartwatch face
/// on pure black: a rounded-square watch body, a big "9:41" Anton time, an
/// Apple-style activity-rings trio at the bottom, a "VOLUME ✓" complication at
/// the top in volt-lime, and a title complication. Every text is editable; the
/// complication + title bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleWatchFaceDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleWatchFace',
    accent: accent,
    background: solidBg(const Color(0xFF000000)),
    elements: [
      // Watch body.
      shapeEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.74, 0.6),
        fill: const Color(0xFF0A0B0E),
        stroke: const Color(0xFF1C1C20),
        strokeWidth: 4,
        cornerRadius: 88,
      ),
      // Top complication (volume ✓) — bound stat + check glyph.
      textEl(
        pos: const Offset(0.46, 0.28),
        size: const Size(0.4, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 18,
        color: accent,
        align: TextAlign.right,
        letterSpacing: 1.5,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.62, 0.28),
        size: const Size(0.08, 0.03),
        literal: '✓',
        font: CardFontIx.cond,
        fontSize: 18,
        color: accent,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Time.
      textEl(
        pos: const Offset(0.5, 0.43),
        size: const Size(0.6, 0.12),
        literal: '9:41',
        font: CardFontIx.display,
        fontSize: 96,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Title complication.
      textEl(
        pos: const Offset(0.5, 0.53),
        size: const Size(0.6, 0.035),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.cond,
        fontSize: 22,
        color: const Color(0xCCFFFFFF),
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      // Activity rings trio.
      ringTrioEl(
        pos: const Offset(0.5, 0.63),
        size: const Size(0.16, 0.13),
        outer: 0.85,
        middle: 0.72,
        inner: 0.6,
      ),
      // Date complication below the watch.
      textEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.82, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 18,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: white),
    ],
  );
}
