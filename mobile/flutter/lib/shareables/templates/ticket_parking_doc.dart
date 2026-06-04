/// Editable-card preset — **Parking Ticket**. A garage parking stub: a bright
/// volt header, big IN/OUT time fields, a rate / level / total field grid, a
/// perforated detach line near the bottom, and a captioned barcode the
/// attendant scans on exit. The "amount due" reads from the hero value. Every
/// text layer editable; lot / date / total / barcode caption bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketParkingDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const ink = Color(0xFF14140C);
  const paper = Color(0xFFFBFAF4);
  const sub = Color(0x9914140C);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketParking',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0F100A), Color(0xFF060704)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Parking stub.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.7, 0.74),
        shape: ShapeKind.rounded,
        fill: paper,
        cornerRadius: 8,
      ),
      // Volt header.
      shapeEl(
        pos: const Offset(0.5, 0.205),
        size: const Size(0.7, 0.09),
        shape: ShapeKind.rounded,
        fill: volt,
        cornerRadius: 8,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.235),
        size: const Size(0.7, 0.05),
        shape: ShapeKind.rect,
        fill: volt,
      ),
      textEl(
        pos: const Offset(0.5, 0.19),
        size: const Size(0.62, 0.03),
        literal: 'ZEALOVA PARK',
        font: CardFontIx.display,
        fontSize: 28,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 1.2,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.225),
        size: const Size(0.62, 0.02),
        literal: 'PARKING TICKET · KEEP WITH YOU',
        font: CardFontIx.mono,
        fontSize: 13,
        color: const Color(0xCC14140C),
        align: TextAlign.center,
        letterSpacing: 1,
        allCaps: true,
      ),
      // IN / OUT big fields.
      textEl(
        pos: const Offset(0.28, 0.32),
        size: const Size(0.3, 0.02),
        literal: 'TIME IN',
        font: CardFontIx.mono,
        fontSize: 14,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 1.4,
      ),
      textEl(
        pos: const Offset(0.28, 0.36),
        size: const Size(0.32, 0.04),
        literal: '06:51',
        font: CardFontIx.display,
        fontSize: 40,
        color: ink,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.72, 0.32),
        size: const Size(0.3, 0.02),
        literal: 'TIME OUT',
        font: CardFontIx.mono,
        fontSize: 14,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 1.4,
      ),
      textEl(
        pos: const Offset(0.72, 0.36),
        size: const Size(0.32, 0.04),
        literal: '07:39',
        font: CardFontIx.display,
        fontSize: 40,
        color: ink,
        align: TextAlign.center,
      ),
      // Session / date line.
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.62, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.condMid,
        fontSize: 20,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 0.8,
        allCaps: true,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.455),
        size: const Size(0.62, 0.003),
        style: DividerStyle.dotted,
        color: const Color(0x6614140C),
        thickness: 2,
      ),
      // Level / rate / duration grid.
      statGridEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.62, 0.1),
        columns: 3,
        tiles: const [
          ['L3', 'LEVEL'],
          ['B12', 'BAY'],
          ['MAX', 'EFFORT'],
        ],
        tileColor: const Color(0x1414140C),
        valueColor: ink,
        labelColor: sub,
        valueFontSize: 30,
        labelFontSize: 13,
        valueFont: CardFontIx.condMid,
      ),
      // Amount due (the workout's hero value).
      textEl(
        pos: const Offset(0.32, 0.63),
        size: const Size(0.3, 0.03),
        literal: 'AMOUNT DUE',
        font: CardFontIx.mono,
        fontSize: 16,
        color: sub,
        letterSpacing: 0.8,
      ),
      textEl(
        pos: const Offset(0.68, 0.63),
        size: const Size(0.38, 0.045),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 34,
        color: ink,
        align: TextAlign.right,
        maxLines: 1,
      ),
      // Perforated detach.
      perforationEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.7, 0.01),
        edge: PerforationEdge.bottom,
        color: const Color(0x6614140C),
        notchColor: const Color(0xFF0F100A),
        notchRadius: 13,
      ),
      // Barcode footer.
      barcodeEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.58, 0.05),
        data: 'ZEALOVA-PARK-EXIT',
        caption: 'SCAN AT EXIT · ZEALOVA',
        captionBinding: const DataBinding(BindingSource.heroString),
        barColor: ink,
        background: paper,
        captionColor: sub,
        captionFontSize: 13,
      ),
      watermarkEl(pos: const Offset(0.3, 0.93), color: Colors.white70),
    ],
  );
}
