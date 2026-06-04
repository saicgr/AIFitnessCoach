/// Editable-card preset for the **Rx Prescription Label** data/meme template —
/// your workout dispensed like a pharmacy label on white paper: a "⚡ ZEALOVA
/// PHARMACY" header rule, monospaced PATIENT / Rx / SIG / QTY fields, a "side
/// effects: gains, confidence" footer, and a barcode. Every field editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataRxLabelDoc(Shareable data, ShareableAspect aspect) {
  const paper = Color(0xFFFFFFFF);
  const inkLine = Color(0xFF111111);
  return cardDoc(
    aspect: aspect,
    presetId: 'dataRxLabel',
    accent: const Color(0xFFB8FF2F),
    background: solidBg(paper),
    elements: [
      // Pharmacy header.
      textEl(
        pos: const Offset(0.5, 0.09),
        size: const Size(0.86, 0.035),
        literal: '⚡ ZEALOVA PHARMACY',
        font: CardFontIx.mono,
        fontSize: 24,
        color: inkLine,
        align: TextAlign.center,
        letterSpacing: 1.5,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.125),
        size: const Size(0.86, 0.003),
        color: inkLine,
      ),
      // Patient label + bound display name (two layers — label is editable).
      textEl(
        pos: const Offset(0.225, 0.20),
        size: const Size(0.3, 0.03),
        literal: 'PATIENT:',
        font: CardFontIx.mono,
        fontSize: 22,
        color: const Color(0xFF666666),
        align: TextAlign.left,
      ),
      textEl(
        pos: const Offset(0.62, 0.20),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.mono,
        fontSize: 22,
        color: inkLine,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Rx — the workout title.
      textEl(
        pos: const Offset(0.5, 0.27),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 44,
        color: inkLine,
        align: TextAlign.left,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.225),
        size: const Size(0.86, 0.025),
        literal: 'Rx',
        font: CardFontIx.mono,
        fontSize: 18,
        color: const Color(0xFF666666),
        align: TextAlign.left,
      ),
      // SIG / directions.
      textEl(
        pos: const Offset(0.5, 0.39),
        size: const Size(0.86, 0.12),
        literal: 'SIG: Take 1 session daily.\nDo not skip leg day.\nRefills: ∞',
        font: CardFontIx.mono,
        fontSize: 22,
        color: inkLine,
        align: TextAlign.left,
        lineHeight: 1.6,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.49),
        size: const Size(0.86, 0.003),
        color: const Color(0x33111111),
      ),
      // QTY label + the real volume.
      textEl(
        pos: const Offset(0.17, 0.55),
        size: const Size(0.18, 0.035),
        literal: 'QTY:',
        font: CardFontIx.mono,
        fontSize: 24,
        color: const Color(0xFF666666),
        align: TextAlign.left,
      ),
      textEl(
        pos: const Offset(0.6, 0.55),
        size: const Size(0.56, 0.035),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.mono,
        fontSize: 24,
        color: inkLine,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // FILLED label + the period.
      textEl(
        pos: const Offset(0.19, 0.595),
        size: const Size(0.22, 0.025),
        literal: 'FILLED:',
        font: CardFontIx.mono,
        fontSize: 16,
        color: const Color(0xFF666666),
        align: TextAlign.left,
      ),
      textEl(
        pos: const Offset(0.62, 0.595),
        size: const Size(0.5, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.mono,
        fontSize: 16,
        color: const Color(0xFF333333),
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Barcode + side-effects footer.
      barcodeEl(
        pos: const Offset(0.5, 0.74),
        size: const Size(0.86, 0.16),
        data: 'ZEALOVA-RX-2026',
        caption: 'ZEALOVA · Rx · 2026',
        captionBinding: const DataBinding(BindingSource.title),
      ),
      dividerEl(
        pos: const Offset(0.5, 0.85),
        size: const Size(0.86, 0.003),
        color: inkLine,
      ),
      textEl(
        pos: const Offset(0.5, 0.89),
        size: const Size(0.86, 0.03),
        literal: 'SIDE EFFECTS: gains, confidence, sweat',
        font: CardFontIx.mono,
        fontSize: 16,
        color: const Color(0xFF333333),
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: inkLine),
    ],
  );
}
