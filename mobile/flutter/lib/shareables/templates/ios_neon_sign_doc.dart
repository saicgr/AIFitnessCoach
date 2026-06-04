/// Editable-card preset for the **Neon Sign** template — a glowing tube-neon
/// sign on a dark brick-toned wall: a volt-accent neon-glow workout title, a
/// secondary cyan/pink glow hero line, an "OPEN 24/7" style tag, and a thin
/// neon underline rule. Uses element glow effects to fake the tube bloom.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosNeonSignDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const neonPink = Color(0xFFFF2D95);
  const neonCyan = Color(0xFF22D3EE);

  return cardDoc(
    aspect: aspect,
    presetId: 'iosNeonSign',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF120D18), Color(0xFF080510)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Soft wall vignette bloom.
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(1.1, 0.7),
        shape: ShapeKind.circle,
        fill: const Color(0x00000000),
        gradient: const [Color(0x22FF2D95), Color(0x00000000)],
        radial: true,
      ),
      // Eyebrow neon tag.
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.04),
        literal: 'OPEN 24 / 7',
        font: CardFontIx.cond,
        fontSize: 28,
        color: neonCyan,
        align: TextAlign.center,
        letterSpacing: 6,
      ),
      // Main neon title with volt glow.
      _glowText(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.92, 0.22),
        binding: const DataBinding(BindingSource.title),
        fontSize: 96,
        color: accent,
        glow: accent,
      ),
      // Neon underline rule.
      shapeEl(
        pos: const Offset(0.5, 0.56),
        size: const Size(0.6, 0.006),
        shape: ShapeKind.pill,
        fill: neonPink,
      ),
      // Hero stat in pink neon.
      _glowText(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.86, 0.12),
        binding: const DataBinding(BindingSource.heroString),
        fontSize: 72,
        color: neonPink,
        glow: neonPink,
      ),
      // Period label, cyan neon, smaller.
      _glowText(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.84, 0.05),
        binding: const DataBinding(BindingSource.periodLabel),
        fontSize: 30,
        color: neonCyan,
        glow: neonCyan,
        allCaps: true,
        letterSpacing: 3,
        font: CardFontIx.cond,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: const Color(0x99FFFFFF)),
    ],
  );
}

/// A neon-glow text element — bright core + soft same-hue glow halo.
CardElement _glowText({
  required Offset pos,
  required Size size,
  DataBinding binding = DataBinding.none,
  String literal = '',
  required double fontSize,
  required Color color,
  required Color glow,
  bool allCaps = false,
  double letterSpacing = 1,
  int font = CardFontIx.display,
}) =>
    CardElement(
      id: CardDoc.newId(),
      type: CardElementType.text,
      transform: ElementTransform(position: pos, size: size),
      effects: ElementEffects(
        glow: ShadowSpec(color: glow.withValues(alpha: 0.85), blur: 36),
      ),
      props: TextProps(
        literal: literal,
        binding: binding,
        fontIndex: font,
        fontSize: fontSize,
        color: color,
        align: TextAlign.center,
        letterSpacing: letterSpacing,
        allCaps: allCaps,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
    );
