/// Editable-card preset — **Before / After**: a clean two-photo diptych. The
/// user's first photo (desaturated, BEFORE) and second photo (full colour,
/// AFTER) fill the frame side by side with a thin volt seam between them, a
/// black caption bar with a "TRANSFORMATION" label, and the period span beneath.
/// Two distinct photoEl layers, both editable / swappable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulBeforeAfterDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const muted = Color(0x99FFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulBeforeAfter',
    accent: accent,
    background: solidBg(const Color(0xFF050506)),
    elements: [
      // BEFORE photo — left half.
      photoEl(
        pos: const Offset(0.2495, 0.44),
        size: const Size(0.495, 0.78),
        binding: const DataBinding(BindingSource.customPhotoPath),
        mask: PhotoMask.rect,
        cornerRadius: 0,
      ),
      // AFTER photo — right half.
      photoEl(
        pos: const Offset(0.7505, 0.44),
        size: const Size(0.495, 0.78),
        binding: const DataBinding(BindingSource.customPhotoPathSecondary),
        mask: PhotoMask.rect,
        cornerRadius: 0,
      ),
      // Volt seam between the two photos.
      shapeEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.006, 0.78),
        shape: ShapeKind.rect,
        fill: accent,
        cornerRadius: 0,
      ),
      // BEFORE / AFTER chip labels.
      textEl(
        pos: const Offset(0.12, 0.08),
        size: const Size(0.22, 0.03),
        literal: 'BEFORE',
        font: CardFontIx.cond,
        fontSize: 16,
        color: const Color(0xFFFFFFFF),
        align: TextAlign.left,
        letterSpacing: 3,
        shadow: const ShadowSpec(
          color: Color(0xAA000000),
          blur: 10,
          offset: Offset(0, 2),
        ),
      ),
      textEl(
        pos: const Offset(0.88, 0.08),
        size: const Size(0.22, 0.03),
        literal: 'AFTER',
        font: CardFontIx.cond,
        fontSize: 16,
        color: accent,
        align: TextAlign.right,
        letterSpacing: 3,
        shadow: const ShadowSpec(
          color: Color(0xAA000000),
          blur: 10,
          offset: Offset(0, 2),
        ),
      ),
      // Black caption bar.
      textEl(
        pos: const Offset(0.5, 0.89),
        size: const Size(0.86, 0.05),
        literal: 'TRANSFORMATION',
        font: CardFontIx.display,
        fontSize: 34,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 1,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.93),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 15,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.965), color: muted),
    ],
  );
}
