/// Editable-card preset for **F15 — Before / After Slider**.
///
/// A side-by-side reveal: the BEFORE photo fills the left half, the AFTER photo
/// the right, split by a vertical divider with a draggable circular handle. The
/// handle + divider are ordinary card elements, so in the editor the user drags
/// them left/right to set the reveal split (the "slider" affordance), and the
/// captured PNG bakes that split. Works for progress photos
/// (`customPhotoPath` / `customPhotoPathSecondary`) or a food plate
/// before/after — both use the same two photo bindings.
///
/// Deterministic: no AI, no network — just two already-attached photos.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc beforeAfterSliderDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;

  // Food shares carry their photos in foodImageUrls; progress shares use the
  // custom-photo slots. Bind each half to the right source so the card is
  // populated for either kind.
  final isFood = data.kind == ShareableKind.foodLog ||
      data.kind == ShareableKind.nutrition;
  final beforeBinding = isFood
      ? const DataBinding(BindingSource.foodImageUrl, index: 0)
      : const DataBinding(BindingSource.customPhotoPath);
  final afterBinding = isFood
      ? const DataBinding(BindingSource.foodImageUrl, index: 1)
      : const DataBinding(BindingSource.customPhotoPathSecondary);

  return cardDoc(
    aspect: aspect,
    presetId: 'beforeAfterSlider',
    accent: accent,
    background: solidBg(const Color(0xFF000000)),
    elements: [
      // BEFORE — left half.
      photoEl(
        pos: const Offset(0.25, 0.5),
        size: const Size(0.5, 1.0),
        binding: beforeBinding,
        mask: PhotoMask.rect,
      ),
      // AFTER — right half.
      photoEl(
        pos: const Offset(0.75, 0.5),
        size: const Size(0.5, 1.0),
        binding: afterBinding,
        mask: PhotoMask.rect,
      ),
      // Vertical divider line (drag horizontally to set the split).
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.012, 1.0),
        shape: ShapeKind.rect,
        fill: Colors.white,
      ),
      // Circular drag handle straddling the divider.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.14, 0.08),
        shape: ShapeKind.circle,
        fill: Colors.white,
      ),
      iconEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.1, 0.05),
        emoji: '⇆',
        color: const Color(0xFF111111),
      ),
      // Top scrim for tag legibility.
      scrimEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(1.0, 0.16),
        colors: const [Color(0xB3000000), Color(0x00000000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      textEl(
        pos: const Offset(0.16, 0.06),
        size: const Size(0.3, 0.04),
        literal: 'BEFORE',
        font: CardFontIx.cond,
        fontSize: 26,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.84, 0.06),
        size: const Size(0.3, 0.04),
        literal: 'AFTER',
        font: CardFontIx.cond,
        fontSize: 26,
        color: accent,
        align: TextAlign.right,
        letterSpacing: 3,
        allCaps: true,
      ),
      // Bottom scrim + caption.
      scrimEl(
        pos: const Offset(0.5, 0.92),
        size: const Size(1.0, 0.16),
        colors: const [Color(0x00000000), Color(0xCC000000)],
      ),
      textEl(
        pos: const Offset(0.5, 0.92),
        size: const Size(0.9, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.cond,
        fontSize: 38,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.30, 0.97), color: Colors.white),
    ],
  );
}
