/// Editable-card preset — **Raffle Stub**. A classic two-part cloakroom raffle
/// ticket: a wide volt ticket with a big repeated lucky NUMBER, a center
/// perforated tear (with punched notches) splitting the keep-stub from the
/// drop-stub, matching numbers on both halves, and a captioned barcode. Every
/// text layer editable; number / event / date / barcode caption bind live.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketRaffleDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const ink = Color(0xFF14160B);
  const muted = Color(0xB314160B);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketRaffle',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0F100A), Color(0xFF060704)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.28),
        size: const Size(0.84, 0.025),
        literal: 'ZEALOVA PRIZE DRAW',
        font: CardFontIx.mono,
        fontSize: 16,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      // The volt raffle ticket body.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.92, 0.28),
        shape: ShapeKind.rounded,
        fill: volt,
        cornerRadius: 14,
      ),
      // Drop-stub label (left half).
      textEl(
        pos: const Offset(0.27, 0.42),
        size: const Size(0.34, 0.022),
        literal: 'KEEP THIS HALF',
        font: CardFontIx.mono,
        fontSize: 13,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.27, 0.5),
        size: const Size(0.34, 0.07),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 56,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.27, 0.56),
        size: const Size(0.34, 0.02),
        literal: 'NO. 04821',
        font: CardFontIx.mono,
        fontSize: 14,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1.2,
      ),
      // Center perforation.
      perforationEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.01, 0.28),
        edge: PerforationEdge.left,
        color: const Color(0x6614160B),
        notchColor: const Color(0xFF0F100A),
        notchRadius: 16,
      ),
      // Keep-stub (right half) — matching number.
      textEl(
        pos: const Offset(0.73, 0.42),
        size: const Size(0.34, 0.022),
        literal: 'DROP IN THE BOX',
        font: CardFontIx.mono,
        fontSize: 13,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.73, 0.5),
        size: const Size(0.34, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 26,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 0.6,
        allCaps: true,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.73, 0.55),
        size: const Size(0.34, 0.022),
        literal: 'NO. 04821',
        font: CardFontIx.mono,
        fontSize: 14,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1.2,
      ),
      // Date line below the ticket.
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.84, 0.028),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.condMid,
        fontSize: 22,
        color: const Color(0xFFFFFFFF),
        align: TextAlign.center,
        letterSpacing: 1,
        allCaps: true,
      ),
      // Barcode footer.
      barcodeEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.7, 0.055),
        data: 'ZEALOVA-RAFFLE-04821',
        caption: 'DRAWN AT CLOSE · ZEALOVA',
        captionBinding: const DataBinding(BindingSource.socialHandle),
        barColor: const Color(0xFFFFFFFF),
        background: const Color(0xFF14160B),
        captionColor: const Color(0x99FFFFFF),
        captionFontSize: 14,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white70),
    ],
  );
}
