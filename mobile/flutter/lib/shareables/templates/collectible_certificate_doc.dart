/// Editable-card preset for the **Certificate** collectible — a parchment
/// "Certificate of Achievement" with a double-rule border (accent outer +
/// hairline gold inner), a serif "ACHIEVEMENT" masthead, an "awarded to NAME"
/// line, an italic citation that quotes the title + hero stat, a medal glyph
/// and a signature rule. Every text is editable; name / stat bind to data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleCertificateDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const parchment = Color(0xFFF7F3E8);
  const ink = Color(0xFF2A2A2A);
  const goldHair = Color(0xFFC9B870);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleCertificate',
    accent: accent,
    background: solidBg(parchment),
    elements: [
      // Outer accent border.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.92, 0.92),
        fill: const Color(0x00000000),
        stroke: accent,
        strokeWidth: 3,
        cornerRadius: 2,
      ),
      // Inner gold hairline.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.86),
        fill: const Color(0x00000000),
        stroke: goldHair,
        strokeWidth: 1,
        cornerRadius: 2,
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(0.74, 0.03),
        literal: 'CERTIFICATE OF',
        font: CardFontIx.cond,
        fontSize: 18,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 6,
      ),
      // Serif masthead.
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.82, 0.07),
        literal: 'ACHIEVEMENT',
        font: CardFontIx.serif,
        fontSize: 58,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Awarded-to label.
      textEl(
        pos: const Offset(0.5, 0.43),
        size: const Size(0.78, 0.025),
        literal: 'awarded to',
        font: CardFontIx.cond,
        fontSize: 16,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Recipient name.
      textEl(
        pos: const Offset(0.5, 0.48),
        size: const Size(0.78, 0.04),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.serif,
        fontSize: 30,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // "for" lead-in.
      textEl(
        pos: const Offset(0.5, 0.54),
        size: const Size(0.74, 0.025),
        literal: 'for',
        font: CardFontIx.cond,
        fontSize: 16,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Italic citation.
      textEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.74, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.serif,
        fontSize: 24,
        color: ink,
        align: TextAlign.center,
        lineHeight: 1.3,
        maxLines: 2,
      ),
      // Hero stat callout.
      textEl(
        pos: const Offset(0.5, 0.64),
        size: const Size(0.74, 0.05),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 40,
        color: accent,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Medal seal.
      iconEl(
        pos: const Offset(0.5, 0.73),
        size: const Size(0.16, 0.07),
        emoji: '🏅',
      ),
      // Signature rule.
      dividerEl(
        pos: const Offset(0.5, 0.82),
        size: const Size(0.4, 0.003),
        color: ink,
        thickness: 1.2,
      ),
      textEl(
        pos: const Offset(0.5, 0.85),
        size: const Size(0.5, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 15,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.94), color: ink),
    ],
  );
}
