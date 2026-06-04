/// Editable-card preset — **Event / Stadium Ticket**. A floodlit-arena look:
/// the workout title as the headline act, a SECTION / ROW / SEAT field grid, a
/// big admit-one block, a top perforated tear (with notches) splitting the
/// admission stub, and a captioned barcode. Volt-lime accent. Every text layer
/// editable; act / date / seat info / barcode caption bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketEventDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  const panel = Color(0xFF15180E);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketEvent',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF14180C), Color(0xFF080A05)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Ticket panel.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.66),
        shape: ShapeKind.rounded,
        fill: panel,
        stroke: const Color(0x33D8FF3A),
        strokeWidth: 1.2,
        cornerRadius: 22,
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.235),
        size: const Size(0.74, 0.025),
        literal: 'LIVE · ONE NIGHT ONLY',
        font: CardFontIx.mono,
        fontSize: 16,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      // Headline act = workout title.
      textEl(
        pos: const Offset(0.5, 0.31),
        size: const Size(0.78, 0.09),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 62,
        color: white,
        align: TextAlign.center,
        letterSpacing: 0.5,
        allCaps: true,
        maxLines: 2,
        lineHeight: 0.95,
      ),
      // Venue / date line.
      textEl(
        pos: const Offset(0.5, 0.385),
        size: const Size(0.74, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.condMid,
        fontSize: 22,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.43),
        size: const Size(0.74, 0.003),
        style: DividerStyle.dotted,
        color: const Color(0x33FFFFFF),
        thickness: 2,
      ),
      // SECTION / ROW / SEAT.
      statGridEl(
        pos: const Offset(0.5, 0.515),
        size: const Size(0.78, 0.1),
        columns: 3,
        tiles: const [
          ['FLOOR', 'SECTION'],
          ['1', 'ROW'],
          ['A', 'SEAT'],
        ],
        tileColor: const Color(0x14D8FF3A),
        valueColor: volt,
        labelColor: muted,
        valueFontSize: 34,
        labelFontSize: 14,
        valueFont: CardFontIx.display,
      ),
      // Admit one strip.
      shapeEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.78, 0.05),
        shape: ShapeKind.pill,
        fill: volt,
      ),
      textEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.78, 0.03),
        literal: 'ADMIT ONE — UNLIMITED SETS',
        font: CardFontIx.condMid,
        fontSize: 22,
        color: const Color(0xFF12140C),
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      // Perforated tear above the stub.
      perforationEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.88, 0.01),
        edge: PerforationEdge.top,
        color: const Color(0x66FFFFFF),
        notchColor: const Color(0xFF080A05),
        notchRadius: 16,
      ),
      // Barcode + caption (the act subtitle = hero string).
      barcodeEl(
        pos: const Offset(0.5, 0.73),
        size: const Size(0.74, 0.06),
        data: 'ZEALOVA-EVENT-TICKET',
        caption: 'ZEALOVA ARENA',
        captionBinding: const DataBinding(BindingSource.heroString),
        barColor: const Color(0xFFFFFFFF),
        background: panel,
        captionColor: muted,
        captionFontSize: 16,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
