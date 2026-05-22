/// Editable-card preset for the **Boarding Pass** template — airline pass
/// aesthetic: a cream paper panel with a FROM/TO route, info fields, a
/// perforated divider splitting a stub, and a barcode strip.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc boardingPassDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF1A1A1A);
  return cardDoc(
    aspect: aspect,
    presetId: 'boardingPass',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF111014), Color(0xFF050507)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Cream paper pass body.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.34),
        shape: ShapeKind.rounded,
        fill: const Color(0xFFF6F1E2),
        cornerRadius: 18,
      ),
      // Airline masthead.
      textEl(
        pos: const Offset(0.3, 0.37),
        size: const Size(0.46, 0.04),
        literal: 'ZEALOVA AIRLINES',
        font: 3,
        fontSize: 26,
        color: ink,
        letterSpacing: 2,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.66, 0.37),
        size: const Size(0.3, 0.03),
        literal: 'BOARDING PASS',
        font: 0,
        fontSize: 18,
        color: const Color(0x991A1A1A),
        align: TextAlign.right,
        letterSpacing: 1.6,
        allCaps: true,
      ),
      // FROM / TO route.
      textEl(
        pos: const Offset(0.22, 0.43),
        size: const Size(0.2, 0.06),
        literal: 'LAST',
        font: 8,
        fontSize: 56,
        color: ink,
      ),
      iconEl(
        pos: const Offset(0.42, 0.43),
        size: const Size(0.08, 0.04),
        emoji: '✈️',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.62, 0.43),
        size: const Size(0.2, 0.06),
        literal: 'NEXT',
        font: 8,
        fontSize: 56,
        color: ink,
      ),
      textEl(
        pos: const Offset(0.42, 0.49),
        size: const Size(0.7, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 30,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 1,
        allCaps: true,
        maxLines: 1,
      ),
      // Info field — flight number from hero value.
      textEl(
        pos: const Offset(0.42, 0.55),
        size: const Size(0.7, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: 4,
        fontSize: 28,
        color: ink,
        align: TextAlign.center,
      ),
      // Perforation divider.
      dividerEl(
        pos: const Offset(0.71, 0.5),
        size: const Size(0.003, 0.32),
        style: DividerStyle.perforated,
        color: const Color(0x8C1A1A1A),
        thickness: 2,
      ),
      // Barcode strip.
      shapeEl(
        pos: const Offset(0.42, 0.6),
        size: const Size(0.62, 0.025),
        shape: ShapeKind.rect,
        fill: ink,
      ),
      textEl(
        pos: const Offset(0.42, 0.64),
        size: const Size(0.62, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: 0,
        fontSize: 18,
        color: const Color(0xB31A1A1A),
        letterSpacing: 1.4,
        allCaps: true,
      ),
      // Stub.
      textEl(
        pos: const Offset(0.86, 0.4),
        size: const Size(0.22, 0.03),
        literal: 'PASS',
        font: 8,
        fontSize: 22,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 2.4,
      ),
      textEl(
        pos: const Offset(0.86, 0.6),
        size: const Size(0.22, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 0,
        fontSize: 18,
        color: const Color(0x991A1A1A),
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.3, 0.9), color: Colors.white70),
    ],
  );
}
