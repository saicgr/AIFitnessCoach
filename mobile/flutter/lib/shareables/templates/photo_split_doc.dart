/// Editable-card preset for the **PhotoSplit** template — a 50/50 layout
/// with the user's photo filling the top half and a solid dark data panel
/// below carrying the eyebrow, title, hero number and a 2×2 stat grid.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc photoSplitDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'photoSplit',
    accent: accent,
    background: solidBg(const Color(0xFF0B0F19)),
    elements: [
      // Top photo pane.
      photoEl(
        pos: const Offset(0.5, 0.23),
        size: const Size(1.0, 0.46),
        binding: const DataBinding(BindingSource.customPhotoPath),
        mask: PhotoMask.rect,
      ),
      scrimEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(1.0, 0.12),
        colors: const [Color(0x00000000), Color(0x80000000)],
      ),
      // Data panel.
      textEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 22,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 2.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.84, 0.07),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 42,
        align: TextAlign.center,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(0.84, 0.12),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 150,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // 2×2 stat grid backing.
      shapeEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.84, 0.16),
        shape: ShapeKind.rounded,
        fill: const Color(0x0DFFFFFF),
        stroke: accent.withValues(alpha: 0.25),
        strokeWidth: 1,
        cornerRadius: 12,
      ),
      chipsEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.8, 0.14),
        binding: const DataBinding(BindingSource.highlightLabel),
        layout: ChipLayout.wrap,
        maxItems: 4,
        fontSize: 18,
      ),
      watermarkEl(pos: const Offset(0.30, 0.96), color: Colors.white),
    ],
  );
}
