/// Editable-card preset — **Gym Receipt (with TOTAL)**. A thermal-receipt slip:
/// ZEALOVA store header, a date/cashier line, exercise line items rendered by
/// the repeater between dashed rules, a bold SUBTOTAL/TOTAL block ending in the
/// hero value, then a perforated tear-off bottom and a captioned barcode like a
/// real till receipt. Volt-lime header accent. Every text layer editable; store
/// line / items / total / barcode caption bind to live workout data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketGymReceiptDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const ink = Color(0xFF161616);
  const paper = Color(0xFFF8F6EE);
  const sub = Color(0xFF5A5A5A);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketGymReceipt',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0E0F0A), Color(0xFF181A12), Color(0xFF0E0F0A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Receipt slip.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.78),
        shape: ShapeKind.rounded,
        fill: paper,
        cornerRadius: 4,
      ),
      // Volt store header band.
      shapeEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.78, 0.045),
        shape: ShapeKind.rect,
        fill: volt,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.7, 0.03),
        literal: 'ZEALOVA GYM CO.',
        font: CardFontIx.display,
        fontSize: 26,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 1.2,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.205),
        size: const Size(0.7, 0.025),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.mono,
        fontSize: 18,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 1,
        allCaps: true,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.24),
        size: const Size(0.7, 0.02),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 15,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 0.8,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(0.7, 0.018),
        literal: 'CASHIER: COACH   REG #01',
        font: CardFontIx.mono,
        fontSize: 13,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 0.6,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.305),
        size: const Size(0.7, 0.003),
        style: DividerStyle.dashed,
        color: const Color(0x80161616),
        thickness: 1,
      ),
      // Exercise line items (qty × name … reps/volume), receipt-style.
      repeaterEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.7, 0.26),
        maxItems: 7,
        fontSize: 19,
        textColor: ink,
        exerciseMode: true,
        showAmount: true,
        showCalories: false,
        showImage: false,
        rowSpacing: 7,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.61),
        size: const Size(0.7, 0.003),
        style: DividerStyle.dashed,
        color: const Color(0x80161616),
        thickness: 1,
      ),
      // Subtotal row.
      textEl(
        pos: const Offset(0.32, 0.645),
        size: const Size(0.32, 0.025),
        literal: 'SUBTOTAL',
        font: CardFontIx.mono,
        fontSize: 18,
        color: sub,
        letterSpacing: 0.8,
      ),
      textEl(
        pos: const Offset(0.68, 0.645),
        size: const Size(0.34, 0.025),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 18,
        color: sub,
        align: TextAlign.right,
      ),
      // TOTAL row (bold, big).
      textEl(
        pos: const Offset(0.32, 0.69),
        size: const Size(0.32, 0.04),
        literal: 'TOTAL',
        font: CardFontIx.display,
        fontSize: 34,
        color: ink,
        letterSpacing: 1,
      ),
      textEl(
        pos: const Offset(0.68, 0.69),
        size: const Size(0.4, 0.05),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 40,
        color: ink,
        align: TextAlign.right,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.73),
        size: const Size(0.7, 0.02),
        literal: '*** PAID IN FULL · NO REFUNDS ON GAINS ***',
        font: CardFontIx.mono,
        fontSize: 13,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 0.6,
      ),
      // Perforated tear-off bottom.
      perforationEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.78, 0.01),
        edge: PerforationEdge.bottom,
        color: const Color(0x66161616),
        notchColor: const Color(0xFF0E0F0A),
        notchRadius: 14,
      ),
      // Barcode footer.
      barcodeEl(
        pos: const Offset(0.5, 0.81),
        size: const Size(0.64, 0.05),
        data: 'ZEALOVA-RECEIPT',
        caption: 'THANK YOU · ZEALOVA',
        captionBinding: const DataBinding(BindingSource.socialHandle),
        barColor: ink,
        background: paper,
        captionColor: sub,
        captionFontSize: 14,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white70),
    ],
  );
}
