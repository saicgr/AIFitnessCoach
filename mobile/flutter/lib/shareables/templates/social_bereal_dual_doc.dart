/// Social-era preset — **BeReal Dual**. The signature BeReal layout: a
/// full-bleed back-camera photo with the small black-framed front-camera inset
/// pinned to the top-left corner, plus the centred "⚡ BeReal. · post-workout"
/// timestamp pill. The inset binds to the secondary custom photo, the main
/// photo to the hero image; the timestamp pill text is editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc socialBerealDualDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'socialBerealDual',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      // Front-camera inset (top-left, black frame) — selfie / secondary photo.
      photoEl(
        pos: const Offset(0.22, 0.13),
        size: const Size(0.32, 0.2),
        binding: const DataBinding(BindingSource.customPhotoPathSecondary),
        mask: PhotoMask.rounded,
        cornerRadius: 14,
        frameColor: const Color(0xFF000000),
        frameWidth: 3,
      ),
      // BeReal timestamp pill (centred top).
      shapeEl(
        pos: const Offset(0.5, 0.045),
        size: const Size(0.56, 0.035),
        shape: ShapeKind.pill,
        fill: const Color(0x80000000),
      ),
      textEl(
        pos: const Offset(0.5, 0.045),
        size: const Size(0.56, 0.03),
        literal: '⚡ BeReal.  ·  post-workout',
        font: CardFontIx.condMid,
        fontSize: 16,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Bottom caption from the share title.
      scrimEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(1, 0.2),
        colors: const [Color(0x00000000), Color(0xB3000000)],
      ),
      textEl(
        pos: const Offset(0.5, 0.93),
        size: const Size(0.84, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.cond,
        fontSize: 28,
        color: white,
        align: TextAlign.center,
        maxLines: 2,
      ),
      watermarkEl(pos: const Offset(0.04, 0.04), color: white),
    ],
  );
}
