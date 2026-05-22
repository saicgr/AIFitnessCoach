/// Editable-card preset for the **PhotoQuote** template — user photo
/// full-bleed under a heavy scrim, a quote-mark glyph, a centered serif
/// italic quote, an accent rule and an all-caps attribution line.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc photoQuoteDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'photoQuote',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.customPhotoPath),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: const [Color(0x99000000), Color(0xCC000000)],
      ),
      iconEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.16, 0.08),
        emoji: '“',
        color: accent,
      ),
      // Centered serif italic quote.
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.82, 0.26),
        binding: const DataBinding(BindingSource.caption),
        font: 9,
        fontSize: 56,
        align: TextAlign.center,
        lineHeight: 1.25,
        maxLines: 5,
      ),
      // Accent rule under the quote.
      shapeEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.16, 0.004),
        shape: ShapeKind.rect,
        fill: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.72),
        size: const Size(0.7, 0.04),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: 1,
        fontSize: 24,
        color: const Color(0xD9FFFFFF),
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white),
    ],
  );
}
