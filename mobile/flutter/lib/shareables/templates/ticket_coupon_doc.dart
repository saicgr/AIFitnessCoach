/// Editable-card preset — **Coupon**. A clip-out money-saver: a dashed coupon
/// border, a giant volt "% OFF"-style hero value framed as the offer, a fine-
/// print terms line, a perforated CLIP-HERE tear on the left with scissor cue,
/// expiry from the date, and a captioned barcode to redeem. Every text layer
/// editable; offer / title / expiry / barcode caption bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketCouponDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const ink = Color(0xFF14150C);
  const paper = Color(0xFFFBFAF2);
  const sub = Color(0x9914150C);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketCoupon',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF101108), Color(0xFF060704)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Coupon body.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.5),
        shape: ShapeKind.rounded,
        fill: paper,
        cornerRadius: 16,
      ),
      // Inset dashed coupon border.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.82, 0.44),
        shape: ShapeKind.rounded,
        fill: const Color(0x00000000),
        stroke: const Color(0x6614150C),
        strokeWidth: 2,
        cornerRadius: 12,
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.33),
        size: const Size(0.72, 0.025),
        literal: 'ZEALOVA REWARDS · LIMITED',
        font: CardFontIx.mono,
        fontSize: 15,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      // Giant offer hero value.
      textEl(
        pos: const Offset(0.5, 0.43),
        size: const Size(0.82, 0.1),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 78,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Offer subtitle (the workout title).
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.035),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 26,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 0.8,
        allCaps: true,
        maxLines: 1,
      ),
      // Highlight underline.
      shapeEl(
        pos: const Offset(0.5, 0.535),
        size: const Size(0.4, 0.012),
        shape: ShapeKind.pill,
        fill: volt,
      ),
      // Terms / expiry.
      textEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.74, 0.022),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 15,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 1,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.605),
        size: const Size(0.74, 0.02),
        literal: 'NO CHEAT DAYS · ONE PER ATHLETE',
        font: CardFontIx.mono,
        fontSize: 12,
        color: sub,
        align: TextAlign.center,
        letterSpacing: 0.6,
      ),
      // CLIP-HERE perforation on the left.
      perforationEl(
        pos: const Offset(0.1, 0.5),
        size: const Size(0.01, 0.44),
        edge: PerforationEdge.left,
        color: const Color(0x6614150C),
        notchColor: const Color(0xFF101108),
        notchRadius: 12,
      ),
      iconEl(
        pos: const Offset(0.1, 0.3),
        size: const Size(0.05, 0.025),
        emoji: '✂️',
        color: paper,
      ),
      // Redeem barcode.
      barcodeEl(
        pos: const Offset(0.5, 0.665),
        size: const Size(0.62, 0.045),
        data: 'ZEALOVA-COUPON',
        caption: 'REDEEM CODE · ZEALOVA',
        captionBinding: const DataBinding(BindingSource.socialHandle),
        barColor: ink,
        background: paper,
        captionColor: sub,
        captionFontSize: 13,
      ),
      watermarkEl(pos: const Offset(0.3, 0.92), color: Colors.white70),
    ],
  );
}
