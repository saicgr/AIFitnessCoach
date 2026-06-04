/// Editable-card preset for the **Movie Poster** template — a one-sheet film
/// poster: a full-bleed dramatic photo under a heavy bottom scrim, a billing
/// block "credits" eyebrow, a towering condensed title, a tagline, a star
/// rating, and a bottom credits crawl + release-date line. Volt accent on the
/// title underline + rating.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosMoviePosterDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'iosMoviePoster',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x33000000), Color(0x00000000), Color(0xE6000000)],
        stops: const [0.0, 0.4, 1.0],
      ),
      // Billing-block eyebrow (top).
      textEl(
        pos: const Offset(0.5, 0.07),
        size: const Size(0.92, 0.025),
        literal: 'ZEALOVA PICTURES PRESENTS',
        font: CardFontIx.cond,
        fontSize: 16,
        color: white70,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      // Star rating.
      ratingStarsEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.34, 0.05),
        rating: 5,
        filledColor: accent,
      ),
      // Tagline.
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.serif,
        fontSize: 28,
        color: white70,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Towering title.
      textEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.94, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 110,
        color: white,
        align: TextAlign.center,
        letterSpacing: -1,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Accent underline.
      shapeEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.36, 0.006),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      // Credits crawl (condensed micro caps).
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.9, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 16,
        color: white70,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: white70),
    ],
  );
}
