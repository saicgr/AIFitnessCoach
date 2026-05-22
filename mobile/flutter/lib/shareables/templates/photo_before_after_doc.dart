/// Editable-card preset for the **PhotoBeforeAfter** template — two stacked
/// photos (before / after) under bottom scrims, BEFORE/AFTER tags, and a
/// centered accent delta-stat pill straddling the divide.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc photoBeforeAfterDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'photoBeforeAfter',
    accent: accent,
    background: solidBg(const Color(0xFF000000)),
    elements: [
      // Top (before) photo.
      photoEl(
        pos: const Offset(0.5, 0.25),
        size: const Size(1.0, 0.5),
        binding: const DataBinding(BindingSource.customPhotoPath),
        mask: PhotoMask.rect,
      ),
      // Bottom (after) photo.
      photoEl(
        pos: const Offset(0.5, 0.75),
        size: const Size(1.0, 0.5),
        binding: const DataBinding(BindingSource.customPhotoPathSecondary),
        mask: PhotoMask.rect,
      ),
      scrimEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(1.0, 0.2),
        colors: const [Color(0x00000000), Color(0xB3000000)],
      ),
      scrimEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(1.0, 0.2),
        colors: const [Color(0x00000000), Color(0xB3000000)],
      ),
      textEl(
        pos: const Offset(0.16, 0.07),
        size: const Size(0.3, 0.04),
        literal: 'BEFORE',
        font: 1,
        fontSize: 24,
        letterSpacing: 2.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.16, 0.57),
        size: const Size(0.3, 0.04),
        literal: 'AFTER',
        font: 1,
        fontSize: 24,
        letterSpacing: 2.4,
        allCaps: true,
      ),
      // Center delta pill.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.5, 0.07),
        shape: ShapeKind.pill,
        fill: accent,
      ),
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.46, 0.06),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 44,
        color: const Color(0xFF000000),
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.30, 0.96), color: Colors.white),
    ],
  );
}
