/// Editable-card preset for the **Passport** template — REDESIGNED: navy cover
/// with an Anton "PASSPORT" masthead, a clean interior page that now carries a
/// real passport-style PHOTO (the user's shot) beside data fields (nationality
/// ZEALOVA, athlete name, workout, date), a rotated-feel red ENTERED stamp, and
/// a gold footer rule. Fixes the old version's clipped "ZEALOVA" overflow.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc passportDoc(Shareable data, ShareableAspect aspect) {
  const navy = Color(0xFF15275C);
  const gold = Color(0xFFFBBF24);
  const red = Color(0xFFE0322E);
  const ink = Color(0xFF1A1A1A);
  const sub = Color(0xFF6B7280);
  return cardDoc(
    aspect: aspect,
    presetId: 'passport',
    accent: data.accentColor,
    background: gradientBg(
      const [Color(0xFF1B306E), navy],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      iconEl(
        pos: const Offset(0.14, 0.075),
        size: const Size(0.1, 0.05),
        emoji: '🌐',
        color: gold,
      ),
      textEl(
        pos: const Offset(0.5, 0.085),
        size: const Size(0.92, 0.05),
        literal: 'PASSPORT',
        font: CardFontIx.display,
        fontSize: 50,
        color: gold,
        align: TextAlign.center,
        letterSpacing: 8,
      ),
      // Interior page.
      shapeEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.86, 0.62),
        shape: ShapeKind.rounded,
        fill: const Color(0xFFF7F5EF),
        cornerRadius: 12,
      ),
      // Passport photo (the user's shot).
      photoEl(
        pos: const Offset(0.275, 0.42),
        size: const Size(0.26, 0.20),
        binding: const DataBinding(BindingSource.heroImageUrl),
        cornerRadius: 6,
        frameColor: navy,
        frameWidth: 2,
      ),
      // Fields, right of the photo.
      textEl(
        pos: const Offset(0.66, 0.345),
        size: const Size(0.4, 0.02),
        literal: 'NATIONALITY',
        font: CardFontIx.cond,
        fontSize: 15,
        color: sub,
        letterSpacing: 1.6,
      ),
      textEl(
        pos: const Offset(0.66, 0.39),
        size: const Size(0.42, 0.045),
        literal: 'ZEALOVA',
        font: CardFontIx.display,
        fontSize: 38,
        color: navy,
      ),
      textEl(
        pos: const Offset(0.66, 0.45),
        size: const Size(0.42, 0.02),
        literal: 'ATHLETE',
        font: CardFontIx.cond,
        fontSize: 15,
        color: sub,
        letterSpacing: 1.6,
      ),
      textEl(
        pos: const Offset(0.66, 0.49),
        size: const Size(0.42, 0.035),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.condMid,
        fontSize: 27,
        color: ink,
        maxLines: 1,
      ),
      // Workout + date row, full width below the photo.
      textEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.72, 0.02),
        literal: 'WORKOUT',
        font: CardFontIx.cond,
        fontSize: 15,
        color: sub,
        letterSpacing: 1.6,
      ),
      textEl(
        pos: const Offset(0.5, 0.645),
        size: const Size(0.72, 0.035),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 26,
        color: ink,
        maxLines: 1,
      ),
      // ENTERED stamp.
      shapeEl(
        pos: const Offset(0.66, 0.74),
        size: const Size(0.28, 0.06),
        shape: ShapeKind.rounded,
        fill: const Color(0x00000000),
        stroke: red,
        strokeWidth: 2.5,
        cornerRadius: 5,
      ),
      textEl(
        pos: const Offset(0.66, 0.74),
        size: const Size(0.26, 0.03),
        literal: 'ENTERED',
        font: CardFontIx.cond,
        fontSize: 24,
        color: red,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      textEl(
        pos: const Offset(0.34, 0.74),
        size: const Size(0.28, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 18,
        color: sub,
        align: TextAlign.center,
        allCaps: true,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.86, 0.004),
        color: gold,
        thickness: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: const Color(0x99FFFFFF)),
    ],
  );
}
