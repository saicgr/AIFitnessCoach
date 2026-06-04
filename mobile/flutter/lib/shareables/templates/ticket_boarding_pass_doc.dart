/// Editable-card preset — **Boarding Pass (Ticket)**. A volt-lime airline pass:
/// dark fuselage backdrop, a glassy pass body with a FROM→TO route built from
/// the workout, a perforated stub tear on the right edge with punched notches,
/// a field statGrid (gate / seat / volume / PRs) and a prominent barcode strip
/// captioned with the user's handle. Every text layer is editable; route, date,
/// stats and barcode caption bind to live workout data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketBoardingPassDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const ink = Color(0xFF12140C);
  const paper = Color(0xFFF7F4E9);
  const sub = Color(0x99121400);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketBoardingPass',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF101307), Color(0xFF05060A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Pass body (paper).
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.42),
        shape: ShapeKind.rounded,
        fill: paper,
        cornerRadius: 20,
      ),
      // Volt header band.
      shapeEl(
        pos: const Offset(0.5, 0.325),
        size: const Size(0.88, 0.07),
        shape: ShapeKind.rounded,
        fill: volt,
        cornerRadius: 20,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.355),
        size: const Size(0.88, 0.04),
        shape: ShapeKind.rect,
        fill: volt,
      ),
      textEl(
        pos: const Offset(0.3, 0.325),
        size: const Size(0.46, 0.04),
        literal: 'ZEALOVA AIRLINES',
        font: CardFontIx.display,
        fontSize: 26,
        color: ink,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.68, 0.325),
        size: const Size(0.3, 0.03),
        literal: 'BOARDING PASS',
        font: CardFontIx.mono,
        fontSize: 16,
        color: const Color(0xCC12140C),
        align: TextAlign.right,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      // FROM → TO route.
      textEl(
        pos: const Offset(0.2, 0.41),
        size: const Size(0.24, 0.06),
        literal: 'REST',
        font: CardFontIx.display,
        fontSize: 50,
        color: ink,
        align: TextAlign.center,
      ),
      iconEl(
        pos: const Offset(0.42, 0.41),
        size: const Size(0.08, 0.035),
        emoji: '✈️',
        color: accent,
      ),
      textEl(
        pos: const Offset(0.64, 0.41),
        size: const Size(0.24, 0.06),
        literal: 'GAINS',
        font: CardFontIx.display,
        fontSize: 50,
        color: ink,
        align: TextAlign.center,
      ),
      // Flight = workout title.
      textEl(
        pos: const Offset(0.42, 0.47),
        size: const Size(0.7, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 30,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 0.6,
        allCaps: true,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.42, 0.512),
        size: const Size(0.7, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 16,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 1.2,
        allCaps: true,
      ),
      // Field grid — gate / seat / volume / PRs.
      statGridEl(
        pos: const Offset(0.42, 0.6),
        size: const Size(0.7, 0.1),
        columns: 4,
        tiles: const [
          ['A12', 'GATE'],
          ['1A', 'SEAT'],
          ['ON', 'TIME'],
          ['100%', 'EFFORT'],
        ],
        tileColor: const Color(0x140F1300),
        valueColor: ink,
        labelColor: sub,
        valueFontSize: 26,
        labelFontSize: 13,
        valueFont: CardFontIx.condMid,
      ),
      // Perforated stub tear with punched notches.
      perforationEl(
        pos: const Offset(0.745, 0.5),
        size: const Size(0.01, 0.42),
        edge: PerforationEdge.left,
        color: const Color(0x6612140C),
        notchColor: const Color(0xFF101307),
        notchRadius: 18,
      ),
      // Stub vertical label.
      textEl(
        pos: const Offset(0.86, 0.36),
        size: const Size(0.22, 0.03),
        literal: 'BOARD NOW',
        font: CardFontIx.condMid,
        fontSize: 18,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 1.4,
      ),
      textEl(
        pos: const Offset(0.86, 0.41),
        size: const Size(0.22, 0.05),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 30,
        color: accent,
        align: TextAlign.center,
        maxLines: 2,
      ),
      // Barcode strip + caption (handle).
      barcodeEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.74, 0.05),
        data: 'ZEALOVA-BOARDING',
        caption: '@you · ZEALOVA',
        captionBinding: const DataBinding(BindingSource.socialHandle),
        barColor: ink,
        background: paper,
        captionColor: sub,
        captionFontSize: 16,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white70),
    ],
  );
}
