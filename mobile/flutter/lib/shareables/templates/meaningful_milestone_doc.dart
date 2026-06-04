/// Editable-card preset — **Lifetime Milestone**: a quiet, reverent odometer.
/// A vignette-radial dark field, a "LIFETIME · SINCE …" eyebrow, the enormous
/// lifetime-volume number in Anton volt, a "POUNDS LIFTED" caption, and a
/// hand-set Fraunces italic coda ("one rep at a time."). Built to feel earned,
/// not flashy.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulMilestoneDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const muted = Color(0x99FFFFFF);
  const white = Color(0xFFFFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulMilestone',
    accent: accent,
    background: CardBackground(
      kind: CardBackgroundKind.linearGradient,
      colors: const [Color(0xFF161616), Color(0xFF000000)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Radial vignette to focus the centre.
      shapeEl(
        pos: const Offset(0.5, 0.35),
        size: const Size(1.3, 1.0),
        shape: ShapeKind.circle,
        gradient: const [Color(0x33222222), Color(0x00000000)],
        radial: true,
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 18,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 5,
        allCaps: true,
        maxLines: 1,
      ),
      // The enormous lifetime-volume number.
      textEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.94, 0.18),
        binding: const DataBinding(BindingSource.lifetimeVolume),
        font: CardFontIx.display,
        fontSize: 110,
        color: accent,
        align: TextAlign.center,
        lineHeight: 0.85,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Caption.
      textEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.84, 0.04),
        literal: 'POUNDS LIFTED',
        font: CardFontIx.cond,
        fontSize: 24,
        color: white,
        align: TextAlign.center,
        letterSpacing: 6,
        allCaps: true,
        maxLines: 1,
      ),
      // Fraunces italic coda.
      textEl(
        pos: const Offset(0.5, 0.65),
        size: const Size(0.78, 0.05),
        literal: 'one rep at a time.',
        font: CardFontIx.serif,
        fontSize: 26,
        color: muted,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: muted),
    ],
  );
}
