/// Editable-card preset for the **Billboard** template — a roadside highway
/// billboard: a giant photo panel mounted on two steel support posts against a
/// dusk-sky gradient, with an oversized ad headline (workout title), a volt
/// "call-to-action" strap, the hero stat as the big claim, and a small brand
/// plate in the corner. Reads like an out-of-home ad for the user's grind.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosBillboardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  const steel = Color(0xFF3A3F47);
  return cardDoc(
    aspect: aspect,
    presetId: 'iosBillboard',
    accent: accent,
    background: gradientBg(
      const [Color(0xFFF9A35C), Color(0xFFB45D8E), Color(0xFF2A2152)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.45, 1.0],
    ),
    elements: [
      // Support posts.
      shapeEl(
        pos: const Offset(0.32, 0.75),
        size: const Size(0.035, 0.42),
        shape: ShapeKind.rect,
        fill: steel,
      ),
      shapeEl(
        pos: const Offset(0.68, 0.75),
        size: const Size(0.035, 0.42),
        shape: ShapeKind.rect,
        fill: steel,
      ),
      // Billboard frame.
      shapeEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.94, 0.56),
        shape: ShapeKind.rounded,
        fill: const Color(0xFF14171D),
        stroke: steel,
        strokeWidth: 8,
        cornerRadius: 10,
      ),
      // Photo panel.
      photoEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.88, 0.5),
        binding: const DataBinding(BindingSource.heroImageUrl),
        mask: PhotoMask.rect,
        cornerRadius: 4,
      ),
      scrimEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.88, 0.5),
        colors: const [Color(0x00000000), Color(0xCC000000)],
      ),
      // Headline (title).
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.82, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 84,
        color: white,
        align: TextAlign.center,
        letterSpacing: -1,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(color: Color(0x99000000), blur: 18),
      ),
      // Volt CTA strap.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.5, 0.07),
        shape: ShapeKind.rounded,
        fill: accent,
        cornerRadius: 8,
      ),
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.46, 0.045),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 40,
        color: const Color(0xFF111111),
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Brand plate (corner).
      textEl(
        pos: const Offset(0.5, 0.92),
        size: const Size(0.7, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 20,
        color: white70,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.3, 0.96), color: white70),
    ],
  );
}
