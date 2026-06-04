/// Editable-card preset for the **Comic Panel** template — a halftone comic-book
/// page: a bold black-bordered top panel with the user's photo, a yellow
/// caption box ("MEANWHILE, AT THE GYM…"), a speech bubble with the workout
/// title, a jagged volt "POW!" burst carrying the hero stat, and a bottom
/// narration strip. Comic-ink frames + halftone texture overlay.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosComicPanelDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF111111);
  const paper = Color(0xFFFDF6E3);
  const comicYellow = Color(0xFFFFD23F);
  return cardDoc(
    aspect: aspect,
    presetId: 'iosComicPanel',
    accent: accent,
    background: solidBg(paper),
    elements: [
      // Top photo panel with thick comic border.
      shapeEl(
        pos: const Offset(0.5, 0.3),
        size: const Size(0.92, 0.46),
        shape: ShapeKind.rounded,
        fill: ink,
        cornerRadius: 6,
      ),
      photoEl(
        pos: const Offset(0.5, 0.3),
        size: const Size(0.86, 0.42),
        binding: const DataBinding(BindingSource.heroImageUrl),
        mask: PhotoMask.rect,
        cornerRadius: 2,
      ),
      // Yellow caption box (top-left of panel).
      shapeEl(
        pos: const Offset(0.32, 0.13),
        size: const Size(0.5, 0.06),
        shape: ShapeKind.rounded,
        fill: comicYellow,
        stroke: ink,
        strokeWidth: 3,
        cornerRadius: 4,
      ),
      textEl(
        pos: const Offset(0.32, 0.13),
        size: const Size(0.46, 0.045),
        literal: 'MEANWHILE, AT THE GYM…',
        font: CardFontIx.display,
        fontSize: 22,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Speech bubble with the workout title.
      shapeEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.84, 0.13),
        shape: ShapeKind.rounded,
        fill: const Color(0xFFFFFFFF),
        stroke: ink,
        strokeWidth: 4,
        cornerRadius: 40,
      ),
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.74, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 44,
        color: ink,
        align: TextAlign.center,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // POW! burst (volt) with hero stat.
      shapeEl(
        pos: const Offset(0.78, 0.78),
        size: const Size(0.4, 0.2),
        shape: ShapeKind.circle,
        gradient: [accent, Color.lerp(accent, const Color(0xFFFF3D00), 0.4)!],
        stroke: ink,
        strokeWidth: 4,
        radial: true,
      ),
      textEl(
        pos: const Offset(0.78, 0.78),
        size: const Size(0.34, 0.12),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 56,
        color: ink,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Bottom narration strip.
      shapeEl(
        pos: const Offset(0.3, 0.9),
        size: const Size(0.52, 0.07),
        shape: ShapeKind.rounded,
        fill: comicYellow,
        stroke: ink,
        strokeWidth: 3,
        cornerRadius: 4,
      ),
      textEl(
        pos: const Offset(0.3, 0.9),
        size: const Size(0.48, 0.05),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.condMid,
        fontSize: 22,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.66, 0.95), color: ink),
    ],
  );
}
