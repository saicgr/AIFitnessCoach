/// Editable-card preset — **Cinema Admission Ticket**. A movie stub: a marquee
/// header, the workout title as the "feature", a star rating row (your session
/// score), a SCREEN / SEAT / TIME field grid, a perforated tear separating the
/// admit-one stub, and a captioned barcode. Volt-lime accent. Every text layer
/// editable; feature / showtime / rating / barcode caption bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketCinemaDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  const panel = Color(0xFF16180D);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketCinema',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF13150B), Color(0xFF070804)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Ticket panel.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.64),
        shape: ShapeKind.rounded,
        fill: panel,
        stroke: const Color(0x33D8FF3A),
        strokeWidth: 1.2,
        cornerRadius: 22,
      ),
      // Marquee header band.
      shapeEl(
        pos: const Offset(0.5, 0.235),
        size: const Size(0.88, 0.06),
        shape: ShapeKind.rounded,
        fill: volt,
        cornerRadius: 22,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.26),
        size: const Size(0.88, 0.04),
        shape: ShapeKind.rect,
        fill: volt,
      ),
      textEl(
        pos: const Offset(0.5, 0.235),
        size: const Size(0.8, 0.03),
        literal: 'ZEALOVA CINEMA · NOW SHOWING',
        font: CardFontIx.condMid,
        fontSize: 20,
        color: const Color(0xFF16180D),
        align: TextAlign.center,
        letterSpacing: 1.6,
        allCaps: true,
      ),
      // Feature = workout title.
      textEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.8, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 56,
        color: white,
        align: TextAlign.center,
        letterSpacing: 0.5,
        allCaps: true,
        maxLines: 2,
        lineHeight: 0.95,
      ),
      // Star rating (your session score).
      ratingStarsEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.4, 0.045),
        rating: 4.5,
        filledColor: volt,
        emptyColor: const Color(0x33FFFFFF),
      ),
      textEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.8, 0.025),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 16,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1.2,
        allCaps: true,
        maxLines: 1,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.8, 0.003),
        style: DividerStyle.dotted,
        color: const Color(0x33FFFFFF),
        thickness: 2,
      ),
      // SCREEN / SEAT / TIME grid.
      statGridEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.8, 0.1),
        columns: 3,
        tiles: const [
          ['07', 'SCREEN'],
          ['H14', 'SEAT'],
          ['AM', 'TIME'],
        ],
        tileColor: const Color(0x14D8FF3A),
        valueColor: volt,
        labelColor: muted,
        valueFontSize: 32,
        labelFontSize: 13,
        valueFont: CardFontIx.display,
      ),
      // Showtime / date line.
      textEl(
        pos: const Offset(0.5, 0.645),
        size: const Size(0.8, 0.028),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.condMid,
        fontSize: 20,
        color: white,
        align: TextAlign.center,
        letterSpacing: 1.2,
        allCaps: true,
      ),
      // Perforated tear before the stub.
      perforationEl(
        pos: const Offset(0.5, 0.69),
        size: const Size(0.88, 0.01),
        edge: PerforationEdge.bottom,
        color: const Color(0x66FFFFFF),
        notchColor: const Color(0xFF070804),
        notchRadius: 15,
      ),
      // Admit-one barcode.
      barcodeEl(
        pos: const Offset(0.5, 0.745),
        size: const Size(0.7, 0.05),
        data: 'ZEALOVA-CINEMA-ADMIT',
        caption: 'ADMIT ONE · ZEALOVA',
        captionBinding: const DataBinding(BindingSource.socialHandle),
        barColor: const Color(0xFFFFFFFF),
        background: panel,
        captionColor: muted,
        captionFontSize: 14,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
