/// Social-era preset — **Pinterest Pin**. A tall, photo-forward pin: full-bleed
/// image, the red "Save" button pinned top-right, a bottom scrim, and a bold
/// pin title + a small descriptor line. Save label, title and descriptor are
/// editable; the image binds to the share's hero photo.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialPinterestPinDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  const pinRed = Color(0xFFE60023);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialPinterestPin',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      // Save button.
      shapeEl(
        pos: const Offset(0.86, 0.05),
        size: const Size(0.22, 0.045),
        shape: ShapeKind.pill,
        fill: pinRed,
      ),
      textEl(
        pos: const Offset(0.86, 0.05),
        size: const Size(0.22, 0.035),
        literal: 'Save',
        font: CardFontIx.cond,
        fontSize: 22,
        color: white,
        align: TextAlign.center,
      ),
      // Bottom scrim + title block.
      scrimEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(1, 0.36),
        colors: const [Color(0x00000000), Color(0xD9000000)],
      ),
      textEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.86, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 48,
        color: white,
        align: TextAlign.center,
        lineHeight: 1.0,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.93),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.condMid,
        fontSize: 20,
        color: white70,
        align: TextAlign.center,
        allCaps: true,
        letterSpacing: 1.5,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.04, 0.04), color: white70),
    ],
  );
}
