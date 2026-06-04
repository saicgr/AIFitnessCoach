/// Editable-card preset — **Event Wristband**. A festival/VIP fabric wristband
/// stretched across the canvas: a long volt band with woven texture stripes,
/// the holder name printed on it, ACCESS-ALL-AREAS chips, the perforated
/// adhesive closure tab with notches at one end, and a tiny barcode tag dangling
/// off the band. Every text layer editable; name / tier / date / barcode caption
/// bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketWristbandDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const ink = Color(0xFF14160B);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketWristband',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF101208), Color(0xFF060704)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.18),
        size: const Size(0.8, 0.025),
        literal: 'ZEALOVA FEST · ALL ACCESS',
        font: CardFontIx.mono,
        fontSize: 16,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      // The main wristband (volt fabric band).
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.94, 0.16),
        shape: ShapeKind.rounded,
        fill: volt,
        cornerRadius: 10,
      ),
      // Woven dashed stripe on the band.
      dividerEl(
        pos: const Offset(0.5, 0.39),
        size: const Size(0.86, 0.004),
        style: DividerStyle.dashed,
        color: const Color(0x4014160B),
        thickness: 2,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.86, 0.004),
        style: DividerStyle.dashed,
        color: const Color(0x4014160B),
        thickness: 2,
      ),
      // Holder name printed on the band.
      textEl(
        pos: const Offset(0.46, 0.42),
        size: const Size(0.78, 0.06),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.display,
        fontSize: 46,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 1,
        allCaps: true,
        maxLines: 1,
      ),
      // Perforated adhesive closure tab (right end).
      perforationEl(
        pos: const Offset(0.9, 0.42),
        size: const Size(0.01, 0.16),
        edge: PerforationEdge.left,
        color: const Color(0x6614160B),
        notchColor: const Color(0xFF101208),
        notchRadius: 12,
      ),
      // Access chips.
      chipsEl(
        pos: const Offset(0.5, 0.59),
        size: const Size(0.84, 0.07),
        literalItems: const ['FLOOR', 'BACKSTAGE', 'VIP', 'PR LOUNGE'],
        layout: ChipLayout.wrap,
        maxItems: 4,
        chipColor: const Color(0x1FD8FF3A),
        textColor: volt,
        fontSize: 20,
        spacing: 10,
      ),
      // Tier / date line.
      textEl(
        pos: const Offset(0.5, 0.67),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 24,
        color: white,
        align: TextAlign.center,
        letterSpacing: 1,
        allCaps: true,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(0.84, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 16,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      // Dangling barcode tag.
      barcodeEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.5, 0.055),
        data: 'ZEALOVA-WRISTBAND',
        caption: 'NON-TRANSFERABLE',
        captionBinding: const DataBinding(BindingSource.heroString),
        barColor: const Color(0xFFFFFFFF),
        background: const Color(0xFF14160B),
        captionColor: muted,
        captionFontSize: 14,
      ),
      watermarkEl(pos: const Offset(0.3, 0.94), color: muted),
    ],
  );
}
