/// Editable-card preset for the **Gift Card** collectible — a glossy
/// volt-to-cyan gift card: the brand wordmark top-left, a "GIFT OF GAINS"
/// eyebrow, the loaded balance (the hero stat) set large, a magnetic stripe, a
/// barcode + "no expiry · self-redeemable daily" mono footer. Every text is
/// editable; the balance + serial bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleGiftCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const ink = Color(0xFF0B0B0B);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleGiftCard',
    accent: accent,
    background: gradientBg(
      [accent, const Color(0xFF22D3EE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    elements: [
      // Glossy sheen.
      scrimEl(
        pos: const Offset(0.5, 0.32),
        size: const Size(1, 0.6),
        colors: const [Color(0x33FFFFFF), Color(0x00FFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      // Brand wordmark.
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.82, 0.06),
        literal: 'ZEALOVA',
        font: CardFontIx.display,
        fontSize: 48,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.82, 0.03),
        literal: 'GIFT OF GAINS',
        font: CardFontIx.cond,
        fontSize: 18,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 4,
        maxLines: 1,
      ),
      // Balance (hero stat).
      textEl(
        pos: const Offset(0.5, 0.49),
        size: const Size(0.9, 0.1),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 96,
        color: ink,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
        maxLines: 1,
      ),
      // Title sub-line.
      textEl(
        pos: const Offset(0.5, 0.59),
        size: const Size(0.82, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 24,
        color: ink,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Magnetic stripe.
      shapeEl(
        pos: const Offset(0.5, 0.71),
        size: const Size(1, 0.07),
        fill: const Color(0xCC000000),
      ),
      // Holder line — "FOR" label + bound name.
      textEl(
        pos: const Offset(0.36, 0.8),
        size: const Size(0.16, 0.03),
        literal: 'FOR',
        font: CardFontIx.cond,
        fontSize: 17,
        color: ink,
        align: TextAlign.right,
        letterSpacing: 2,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.6, 0.8),
        size: const Size(0.42, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.cond,
        fontSize: 17,
        color: ink,
        align: TextAlign.left,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      // Barcode footer.
      barcodeEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.7, 0.06),
        data: 'ZEALOVA-GIFT-2026',
        caption: 'no expiry · self-redeemable daily',
        barColor: ink,
        background: const Color(0x00000000),
        captionColor: ink,
        captionFontSize: 13,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: ink),
    ],
  );
}
