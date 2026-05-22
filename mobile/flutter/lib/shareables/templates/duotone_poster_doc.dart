/// Editable-card preset — **Duotone Poster**: the meal photo treated as a
/// single dark-tint duotone (photo under a heavy scrim), one giant macro
/// number overlapping the image edge, a thin baseline divider and a sparse
/// caption.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc duotonePosterDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  // The duotone shadow tone — a deep accent-tinted ink.
  final shadow = Color.lerp(const Color(0xFF0B0B12), accent, 0.34)!;

  return cardDoc(
    aspect: aspect,
    presetId: 'duotonePoster',
    accent: accent,
    background: photoBg(),
    elements: [
      // Heavy duotone scrim — collapses the photo to one dark tint.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1.0, 1.0),
        colors: [
          shadow.withValues(alpha: 0.92),
          shadow.withValues(alpha: 0.62),
          shadow.withValues(alpha: 0.96),
        ],
        stops: const [0.0, 0.45, 1.0],
      ),
      // Eyebrow — sparse.
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.82, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 5,
        fontSize: 22,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 5,
        allCaps: true,
        maxLines: 1,
      ),
      // Giant macro number overlapping the image edge (runs past the bottom).
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(1.1, 0.5),
        binding: const DataBinding(BindingSource.calories),
        font: 1,
        fontSize: 320,
        color: const Color(0xFFF7F5F0),
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Thin baseline divider.
      dividerEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.7, 0.004),
        color: const Color(0x66FFFFFF),
        thickness: 2,
      ),
      // Sparse caption — the meal name.
      textEl(
        pos: const Offset(0.5, 0.91),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 2,
        fontSize: 28,
        color: const Color(0xFFE9E6DE),
        align: TextAlign.center,
        letterSpacing: 1,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      watermarkEl(pos: const Offset(0.3, 0.96), color: Colors.white70),
    ],
  );
}
