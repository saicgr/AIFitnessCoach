/// Editable-card preset for the **Festival Wristband** collectible — a fabric
/// VIP access band stretched diagonally across a black field: a volt-to-cyan
/// woven strap (tilted) carrying "PUSH DAY ACCESS" and a mono "⚡ ZEALOVA ·
/// VOLUME · VIP" line, with a small barcode tab and a holder name. Every text
/// is editable; the access label + volume bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleWristbandDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const strapInk = Color(0xFF0B0B0B);
  const muted = Color(0x99FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleWristband',
    accent: accent,
    background: solidBg(const Color(0xFF0A0B0E)),
    elements: [
      // Woven strap.
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(1.12, 0.2),
        gradient: [accent, const Color(0xFF22D3EE)],
      ),
      // Access label — bound title + literal "ACCESS".
      textEl(
        pos: const Offset(0.42, 0.39),
        size: const Size(0.52, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 38,
        color: strapInk,
        align: TextAlign.right,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.74, 0.39),
        size: const Size(0.24, 0.05),
        literal: 'ACCESS',
        font: CardFontIx.display,
        fontSize: 38,
        color: strapInk,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Mono detail line — literal issuer + bound stat + VIP.
      textEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 15,
        color: strapInk,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.025),
        literal: '⚡ ZEALOVA · VIP',
        font: CardFontIx.mono,
        fontSize: 13,
        color: strapInk,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Barcode tab.
      barcodeEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.5, 0.06),
        data: 'BAND-VIP-2026',
        showCaption: false,
        barColor: const Color(0xFFFFFFFF),
        background: const Color(0x00000000),
      ),
      // Holder name — "HOLDER" label + bound name.
      textEl(
        pos: const Offset(0.4, 0.77),
        size: const Size(0.34, 0.035),
        literal: 'HOLDER ·',
        font: CardFontIx.cond,
        fontSize: 17,
        color: muted,
        align: TextAlign.right,
        letterSpacing: 2,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.66, 0.77),
        size: const Size(0.3, 0.035),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.cond,
        fontSize: 17,
        color: muted,
        align: TextAlign.left,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.94), color: muted),
    ],
  );
}
