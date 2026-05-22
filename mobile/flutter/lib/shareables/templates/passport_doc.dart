/// Editable-card preset for the **Passport** template — navy cover with gold
/// PASSPORT lettering, a white interior page carrying the stamp number, app
/// name, workout title + red ENTERED stamp, and a gold footer line.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc passportDoc(Shareable data, ShareableAspect aspect) {
  const navy = Color(0xFF1E3A8A);
  const gold = Color(0xFFFBBF24);
  const red = Color(0xFFEF4444);
  return cardDoc(
    aspect: aspect,
    presetId: 'passport',
    accent: data.accentColor,
    background: solidBg(navy),
    elements: [
      iconEl(
        pos: const Offset(0.16, 0.08),
        size: const Size(0.12, 0.06),
        emoji: '🌍',
      ),
      textEl(
        pos: const Offset(0.72, 0.08),
        size: const Size(0.44, 0.05),
        literal: 'PASSPORT',
        font: 1,
        fontSize: 44,
        color: gold,
        align: TextAlign.right,
        letterSpacing: 4,
      ),
      // White interior page.
      shapeEl(
        pos: const Offset(0.5, 0.47),
        size: const Size(0.84, 0.5),
        shape: ShapeKind.rounded,
        fill: const Color(0xFFFFFFFF),
        cornerRadius: 8,
      ),
      textEl(
        pos: const Offset(0.32, 0.3),
        size: const Size(0.46, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 24,
        color: Colors.black54,
        letterSpacing: 2,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.32, 0.37),
        size: const Size(0.6, 0.06),
        literal: 'ZEALOVA',
        font: 1,
        fontSize: 64,
        color: navy,
      ),
      textEl(
        pos: const Offset(0.32, 0.43),
        size: const Size(0.6, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: 1,
        fontSize: 22,
        color: Colors.black54,
        letterSpacing: 1.5,
      ),
      textEl(
        pos: const Offset(0.32, 0.49),
        size: const Size(0.6, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 28,
        color: Colors.black87,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.32, 0.55),
        size: const Size(0.6, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        fontSize: 24,
        color: Colors.black54,
      ),
      shapeEl(
        pos: const Offset(0.27, 0.62),
        size: const Size(0.26, 0.05),
        shape: ShapeKind.rounded,
        fill: const Color(0x00000000),
        stroke: red,
        strokeWidth: 2,
        cornerRadius: 4,
      ),
      textEl(
        pos: const Offset(0.27, 0.62),
        size: const Size(0.24, 0.03),
        literal: 'ENTERED',
        font: 1,
        fontSize: 26,
        color: red,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.86),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 24,
        color: gold,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: Colors.white60),
    ],
  );
}
