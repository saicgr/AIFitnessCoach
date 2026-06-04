/// Editable-card preset — **Lottery / Scratch Ticket**. A glossy lottery card:
/// a metallic header, three "scratched" play panels revealing matched WIN
/// symbols, a volt JACKPOT prize line driven by the hero value, a perforated
/// claim-stub tear, and a captioned barcode for validation. Every text layer
/// editable; prize / date / barcode caption bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketScratchDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const ink = Color(0xFF14140A);
  const paper = Color(0xFF1A1C12);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketScratch',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF14160C), Color(0xFF070804)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Lottery card body.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.66),
        shape: ShapeKind.rounded,
        fill: paper,
        stroke: volt,
        strokeWidth: 1.5,
        cornerRadius: 22,
      ),
      // Metallic header band.
      shapeEl(
        pos: const Offset(0.5, 0.235),
        size: const Size(0.86, 0.07),
        shape: ShapeKind.rounded,
        fill: volt,
        cornerRadius: 22,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.265),
        size: const Size(0.86, 0.05),
        shape: ShapeKind.rect,
        fill: volt,
      ),
      textEl(
        pos: const Offset(0.5, 0.235),
        size: const Size(0.78, 0.04),
        literal: 'ZEALOVA INSTANT WIN',
        font: CardFontIx.display,
        fontSize: 34,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 1,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.32),
        size: const Size(0.78, 0.025),
        literal: 'SCRATCH TO REVEAL · MATCH 3 TO WIN',
        font: CardFontIx.mono,
        fontSize: 15,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      // Three scratch panels with matched symbols.
      shapeEl(
        pos: const Offset(0.27, 0.42),
        size: const Size(0.22, 0.12),
        shape: ShapeKind.rounded,
        fill: const Color(0x14D8FF3A),
        stroke: const Color(0x55D8FF3A),
        strokeWidth: 1.5,
        cornerRadius: 12,
      ),
      iconEl(
        pos: const Offset(0.27, 0.42),
        size: const Size(0.12, 0.07),
        emoji: '💪',
        color: volt,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.22, 0.12),
        shape: ShapeKind.rounded,
        fill: const Color(0x14D8FF3A),
        stroke: const Color(0x55D8FF3A),
        strokeWidth: 1.5,
        cornerRadius: 12,
      ),
      iconEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.12, 0.07),
        emoji: '💪',
        color: volt,
      ),
      shapeEl(
        pos: const Offset(0.73, 0.42),
        size: const Size(0.22, 0.12),
        shape: ShapeKind.rounded,
        fill: const Color(0x14D8FF3A),
        stroke: const Color(0x55D8FF3A),
        strokeWidth: 1.5,
        cornerRadius: 12,
      ),
      iconEl(
        pos: const Offset(0.73, 0.42),
        size: const Size(0.12, 0.07),
        emoji: '💪',
        color: volt,
      ),
      // WINNER banner.
      textEl(
        pos: const Offset(0.5, 0.535),
        size: const Size(0.78, 0.03),
        literal: 'WINNER!',
        font: CardFontIx.display,
        fontSize: 26,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      // Prize = hero value.
      textEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.82, 0.075),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 60,
        color: white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.645),
        size: const Size(0.78, 0.025),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.mono,
        fontSize: 16,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
        maxLines: 1,
      ),
      // Perforated claim stub.
      perforationEl(
        pos: const Offset(0.5, 0.69),
        size: const Size(0.86, 0.01),
        edge: PerforationEdge.bottom,
        color: const Color(0x66FFFFFF),
        notchColor: const Color(0xFF070804),
        notchRadius: 15,
      ),
      // Validation barcode.
      barcodeEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.68, 0.05),
        data: 'ZEALOVA-SCRATCH-WIN',
        caption: 'VALIDATE TO CLAIM · ZEALOVA',
        captionBinding: const DataBinding(BindingSource.periodLabel),
        barColor: const Color(0xFFFFFFFF),
        background: paper,
        captionColor: muted,
        captionFontSize: 13,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
