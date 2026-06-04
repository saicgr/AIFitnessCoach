/// Editable-card preset for the **Race Bib** collectible — a marathon race
/// number pinned to a white field: a red event banner ("PUSH DAY MARATHON
/// 2026"), the bib number (the hero stat) set enormous, a timing-chip barcode
/// strip, the athlete name + division, and four corner pin dots. Every text is
/// editable; the bib number + name bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleRaceBibDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const paper = Color(0xFFFFFFFF);
  const ink = Color(0xFF111111);
  const banner = Color(0xFFC0392B);
  const sub = Color(0xFF888888);
  const pin = Color(0x33000000);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleRaceBib',
    accent: accent,
    background: solidBg(paper),
    elements: [
      // Pin dots (four corners).
      shapeEl(
        pos: const Offset(0.12, 0.12),
        size: const Size(0.05, 0.05),
        shape: ShapeKind.circle,
        fill: pin,
      ),
      shapeEl(
        pos: const Offset(0.88, 0.12),
        size: const Size(0.05, 0.05),
        shape: ShapeKind.circle,
        fill: pin,
      ),
      shapeEl(
        pos: const Offset(0.12, 0.88),
        size: const Size(0.05, 0.05),
        shape: ShapeKind.circle,
        fill: pin,
      ),
      shapeEl(
        pos: const Offset(0.88, 0.88),
        size: const Size(0.05, 0.05),
        shape: ShapeKind.circle,
        fill: pin,
      ),
      // Event banner — bound title.
      textEl(
        pos: const Offset(0.5, 0.2),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.cond,
        fontSize: 22,
        color: banner,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.25),
        size: const Size(0.84, 0.03),
        literal: 'MARATHON 2026',
        font: CardFontIx.cond,
        fontSize: 18,
        color: banner,
        align: TextAlign.center,
        letterSpacing: 4,
        maxLines: 1,
      ),
      // Bib number (hero stat).
      textEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.92, 0.22),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 200,
        color: ink,
        align: TextAlign.center,
        lineHeight: 0.85,
        sizeMode: TextSizeMode.shrinkToFit,
        maxLines: 1,
      ),
      // Timing-chip barcode.
      barcodeEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.66, 0.06),
        data: 'BIB-TIMING-2026',
        showCaption: false,
        barColor: ink,
        background: const Color(0x00000000),
      ),
      // Name + division — bound name + literal division.
      textEl(
        pos: const Offset(0.4, 0.76),
        size: const Size(0.42, 0.04),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.cond,
        fontSize: 18,
        color: sub,
        align: TextAlign.right,
        letterSpacing: 1.5,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.66, 0.76),
        size: const Size(0.3, 0.04),
        literal: '· KG DIVISION',
        font: CardFontIx.cond,
        fontSize: 18,
        color: sub,
        align: TextAlign.left,
        letterSpacing: 1.5,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.92), color: ink),
    ],
  );
}
