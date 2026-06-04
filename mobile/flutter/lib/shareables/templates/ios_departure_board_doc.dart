/// Editable-card preset for the **Departure Board** template — an airport /
/// train split-flap departures board: a dark board with a yellow mono header
/// row (TIME · WORKOUT · STATUS), the workout title set as the "destination", a
/// volt "ON TIME / DEPARTED" status flap, and a repeater of the day's highlight
/// rows beneath like a flight manifest. Split-flap mono type throughout.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosDepartureBoardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const board = Color(0xFF0B0D10);
  const flap = Color(0xFF15181D);
  const amber = Color(0xFFFFC53D);
  const white = Color(0xFFFFFFFF);
  const white60 = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'iosDepartureBoard',
    accent: accent,
    background: solidBg(board),
    elements: [
      // Board bezel.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.94, 0.84),
        shape: ShapeKind.rounded,
        fill: flap,
        stroke: const Color(0x33000000),
        strokeWidth: 2,
        cornerRadius: 14,
      ),
      // Header bar.
      shapeEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.88, 0.06),
        shape: ShapeKind.rect,
        fill: const Color(0xFF000000),
      ),
      textEl(
        pos: const Offset(0.18, 0.16),
        size: const Size(0.22, 0.03),
        literal: 'TIME',
        font: CardFontIx.mono,
        fontSize: 18,
        color: amber,
        align: TextAlign.left,
        letterSpacing: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.4, 0.03),
        literal: 'WORKOUT',
        font: CardFontIx.mono,
        fontSize: 18,
        color: amber,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      textEl(
        pos: const Offset(0.84, 0.16),
        size: const Size(0.22, 0.03),
        literal: 'STATUS',
        font: CardFontIx.mono,
        fontSize: 18,
        color: amber,
        align: TextAlign.right,
        letterSpacing: 2,
      ),
      // Headline destination row.
      textEl(
        pos: const Offset(0.18, 0.27),
        size: const Size(0.22, 0.04),
        literal: '09:41',
        font: CardFontIx.mono,
        fontSize: 30,
        color: white,
        align: TextAlign.left,
      ),
      textEl(
        pos: const Offset(0.52, 0.27),
        size: const Size(0.46, 0.045),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.mono,
        fontSize: 30,
        color: white,
        align: TextAlign.left,
        maxLines: 1,
        allCaps: true,
      ),
      // Status flap (volt).
      shapeEl(
        pos: const Offset(0.84, 0.27),
        size: const Size(0.22, 0.045),
        shape: ShapeKind.rounded,
        fill: accent,
        cornerRadius: 4,
      ),
      textEl(
        pos: const Offset(0.84, 0.27),
        size: const Size(0.2, 0.03),
        literal: 'DEPARTED',
        font: CardFontIx.mono,
        fontSize: 15,
        color: const Color(0xFF111111),
        align: TextAlign.center,
        letterSpacing: 1,
      ),
      // Hero stat as a marquee line.
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 20,
        color: amber,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      // Manifest rows from highlights.
      repeaterEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.86, 0.42),
        maxItems: 5,
        fontSize: 24,
        textColor: white,
        showAmount: false,
        showCalories: false,
        rowSpacing: 10,
      ),
      // Footer.
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.86, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 16,
        color: white60,
        align: TextAlign.center,
        letterSpacing: 1.4,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: white60),
    ],
  );
}
