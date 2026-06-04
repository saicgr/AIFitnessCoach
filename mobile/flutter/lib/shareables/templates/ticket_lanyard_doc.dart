/// Editable-card preset — **Festival / Conference Lanyard**. A laminated badge
/// hanging from a neck strap: a volt lanyard strap up top feeding into a clip,
/// then a glossy ID card with the holder name, role chips, an entry statGrid,
/// and a captioned barcode at the bottom of the card for scanning at the gate.
/// Every text layer editable; name / role / date / barcode caption bind live.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc ticketLanyardDoc(Shareable s, ShareableAspect aspect) {
  final accent = s.accentColor;
  const volt = Color(0xFFD8FF3A);
  const card = Color(0xFF14160C);
  const white = Color(0xFFFFFFFF);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'ticketLanyard',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0E0F09), Color(0xFF050603)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Lanyard strap (two diagonals into a clip).
      shapeEl(
        pos: const Offset(0.4, 0.13),
        size: const Size(0.04, 0.18),
        shape: ShapeKind.rect,
        fill: volt,
      ),
      shapeEl(
        pos: const Offset(0.6, 0.13),
        size: const Size(0.04, 0.18),
        shape: ShapeKind.rect,
        fill: volt,
      ),
      // Clip.
      shapeEl(
        pos: const Offset(0.5, 0.205),
        size: const Size(0.1, 0.03),
        shape: ShapeKind.rounded,
        fill: const Color(0xFF8A8A8A),
        cornerRadius: 4,
      ),
      // Badge card.
      shapeEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.74, 0.62),
        shape: ShapeKind.rounded,
        fill: card,
        stroke: const Color(0x33D8FF3A),
        strokeWidth: 1.2,
        cornerRadius: 22,
      ),
      // Volt top stripe on the card.
      shapeEl(
        pos: const Offset(0.5, 0.275),
        size: const Size(0.74, 0.06),
        shape: ShapeKind.rounded,
        fill: volt,
        cornerRadius: 22,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.295),
        size: const Size(0.74, 0.04),
        shape: ShapeKind.rect,
        fill: volt,
      ),
      textEl(
        pos: const Offset(0.5, 0.275),
        size: const Size(0.66, 0.03),
        literal: 'ZEALOVA SUMMIT 2026',
        font: CardFontIx.condMid,
        fontSize: 22,
        color: const Color(0xFF14160C),
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      // Avatar circle + holder.
      shapeEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.18, 0.1),
        shape: ShapeKind.circle,
        fill: const Color(0x14D8FF3A),
        stroke: volt,
        strokeWidth: 2,
      ),
      iconEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.1, 0.05),
        emoji: '🏋️',
        color: volt,
      ),
      textEl(
        pos: const Offset(0.5, 0.49),
        size: const Size(0.66, 0.045),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.display,
        fontSize: 40,
        color: white,
        align: TextAlign.center,
        allCaps: true,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.53),
        size: const Size(0.66, 0.025),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.mono,
        fontSize: 16,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
        maxLines: 1,
      ),
      // Role chips.
      chipsEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.66, 0.05),
        literalItems: const ['ATHLETE', 'SPEAKER', 'ALL-ACCESS'],
        layout: ChipLayout.wrap,
        maxItems: 3,
        chipColor: const Color(0x1FFFFFFF),
        textColor: white,
        fontSize: 17,
        spacing: 8,
      ),
      // Entry grid.
      statGridEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.66, 0.08),
        columns: 2,
        tiles: const [
          ['HALL A', 'ACCESS'],
          ['VIP', 'ZONE'],
        ],
        tileColor: const Color(0x14FFFFFF),
        valueColor: white,
        labelColor: muted,
        valueFontSize: 22,
        labelFontSize: 12,
        valueFont: CardFontIx.condMid,
      ),
      // Barcode at the bottom of the badge.
      barcodeEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.62, 0.05),
        data: 'ZEALOVA-LANYARD',
        caption: 'SCAN TO ENTER',
        captionBinding: const DataBinding(BindingSource.periodLabel),
        barColor: const Color(0xFFFFFFFF),
        background: card,
        captionColor: muted,
        captionFontSize: 14,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: muted),
    ],
  );
}
