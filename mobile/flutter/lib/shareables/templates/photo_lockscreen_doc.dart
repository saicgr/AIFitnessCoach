/// Editable-card preset for the **PhotoLockscreen** template — user photo
/// as a wallpaper, a big light-weight clock, a date line, and a frosted
/// glass widget card pinned near the bottom with the workout summary.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc photoLockscreenDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'photoLockscreen',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.customPhotoPath),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: const [Color(0x33000000), Color(0x00000000), Color(0x66000000)],
        stops: const [0.0, 0.45, 1.0],
      ),
      // Date line above the clock.
      textEl(
        pos: const Offset(0.5, 0.2),
        size: const Size(0.84, 0.04),
        literal: 'Today',
        fontSize: 32,
        align: TextAlign.center,
        letterSpacing: 0.4,
      ),
      // Big clock face.
      textEl(
        pos: const Offset(0.5, 0.3),
        size: const Size(0.9, 0.16),
        literal: '9:41',
        font: 2,
        fontSize: 280,
        align: TextAlign.center,
        letterSpacing: -8,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Frosted widget card.
      shapeEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.86, 0.18),
        shape: ShapeKind.rounded,
        fill: const Color(0x52000000),
        stroke: const Color(0x33FFFFFF),
        strokeWidth: 1.5,
        cornerRadius: 28,
      ),
      textEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(0.7, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 22,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 1.6,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.74, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 36,
        align: TextAlign.center,
        maxLines: 1,
      ),
      chipsEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.74, 0.05),
        binding: const DataBinding(BindingSource.foodItemName),
        layout: ChipLayout.row,
        maxItems: 3,
        fontSize: 18,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white),
    ],
  );
}
