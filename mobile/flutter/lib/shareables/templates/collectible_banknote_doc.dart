/// Editable-card preset for the **Banknote** collectible — a "Bank of Gains"
/// currency note: an engraved green field, a white inner frame, the
/// denomination (the hero stat) set large in the two opposite corners like a
/// bill, a central muscle motif, an issuer line and a serial barcode. Every
/// text is editable; the denomination + serial bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleBanknoteDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const noteInk = Color(0xFFEAFFF2);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleBanknote',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF1F5C3D), Color(0xFF2E7D52)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    elements: [
      // White inner frame.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.9, 0.9),
        fill: const Color(0x00000000),
        stroke: const Color(0x66FFFFFF),
        strokeWidth: 2,
        cornerRadius: 6,
      ),
      // Top-left denomination.
      textEl(
        pos: const Offset(0.28, 0.18),
        size: const Size(0.4, 0.06),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 56,
        color: noteInk,
        maxLines: 1,
      ),
      // Issuer label (top-right).
      textEl(
        pos: const Offset(0.74, 0.16),
        size: const Size(0.4, 0.03),
        literal: 'BANK OF GAINS',
        font: CardFontIx.cond,
        fontSize: 16,
        color: noteInk,
        align: TextAlign.right,
        letterSpacing: 2,
        maxLines: 1,
      ),
      // Central motif.
      iconEl(
        pos: const Offset(0.5, 0.44),
        size: const Size(0.3, 0.16),
        emoji: '💪',
        color: const Color(0x99EAFFF2),
      ),
      // Engraved title strip.
      textEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.82, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.cond,
        fontSize: 24,
        color: noteInk,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      // Holder line (bottom-left) — bound name above a literal motto.
      textEl(
        pos: const Offset(0.3, 0.75),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.cond,
        fontSize: 16,
        color: noteInk,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.3, 0.79),
        size: const Size(0.5, 0.025),
        literal: 'NON-NEGOTIABLE',
        font: CardFontIx.cond,
        fontSize: 13,
        color: noteInk,
        letterSpacing: 1.5,
        maxLines: 1,
      ),
      // Bottom-right denomination (mirrored corner).
      textEl(
        pos: const Offset(0.72, 0.79),
        size: const Size(0.4, 0.06),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 56,
        color: noteInk,
        align: TextAlign.right,
        maxLines: 1,
      ),
      // Serial barcode strip.
      barcodeEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.6, 0.05),
        data: 'GAINS-NOTE-2026',
        captionBinding: const DataBinding(BindingSource.socialHandle),
        caption: 'SERIAL · ZEALOVA',
        barColor: noteInk,
        background: const Color(0x00000000),
        captionColor: noteInk,
        captionFontSize: 13,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: noteInk),
    ],
  );
}
