/// Editable-card preset for the **License Plate** collectible — a US-style
/// embossed vanity plate: a white-to-grey plate with an inset blue keyline, a
/// "⚡ ZEALOVA STATE" top legend, the title set in big condensed plate type
/// (the "registration"), and a "9128 KG · EST 2026" bottom legend. Every text
/// is editable; the plate text + legend bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleLicensePlateDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const stateBlue = Color(0xFF1B4DB0);
  const sub = Color(0xFF555555);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleLicensePlate',
    accent: accent,
    background: solidBg(const Color(0xFF1A1D24)),
    elements: [
      // Plate body.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.42),
        gradient: const [Color(0xFFFDFDFD), Color(0xFFE9E9E9)],
        stroke: const Color(0xFF888888),
        strokeWidth: 2,
        cornerRadius: 16,
      ),
      // Inset blue keyline.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.34),
        fill: const Color(0x00000000),
        stroke: stateBlue,
        strokeWidth: 3,
        cornerRadius: 10,
      ),
      // Top legend.
      textEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.74, 0.03),
        literal: '⚡ ZEALOVA STATE',
        font: CardFontIx.cond,
        fontSize: 18,
        color: stateBlue,
        align: TextAlign.center,
        letterSpacing: 4,
        maxLines: 1,
      ),
      // Plate registration (title).
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.74, 0.1),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 76,
        color: stateBlue,
        align: TextAlign.center,
        letterSpacing: 6,
        sizeMode: TextSizeMode.shrinkToFit,
        allCaps: true,
        maxLines: 1,
      ),
      // Bottom legend — bound stat + literal "EST 2026".
      textEl(
        pos: const Offset(0.4, 0.6),
        size: const Size(0.42, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 16,
        color: sub,
        align: TextAlign.right,
        letterSpacing: 4,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.65, 0.6),
        size: const Size(0.24, 0.03),
        literal: '· EST 2026',
        font: CardFontIx.cond,
        fontSize: 16,
        color: sub,
        align: TextAlign.left,
        letterSpacing: 4,
        maxLines: 1,
      ),
      // Holder line below the plate.
      textEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.cond,
        fontSize: 20,
        color: const Color(0xCCFFFFFF),
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.92), color: const Color(0xCCFFFFFF)),
    ],
  );
}
