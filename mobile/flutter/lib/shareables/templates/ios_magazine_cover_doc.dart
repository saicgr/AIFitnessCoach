/// Editable-card preset for the **Magazine Cover** template — a glossy
/// fitness-magazine cover: full-bleed photo, a giant condensed masthead across
/// the top, a barcode + issue line bottom-left, and a rail of cover-line teasers
/// down the right edge bound to the share's highlights. Volt accent on the
/// cover star line.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc iosMagazineCoverDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const white70 = Color(0xB3FFFFFF);
  return cardDoc(
    aspect: aspect,
    presetId: 'iosMagazineCover',
    accent: accent,
    background: photoBg(
      binding: const DataBinding(BindingSource.heroImageUrl),
    ),
    elements: [
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(1, 1),
        colors: const [Color(0x73000000), Color(0x1A000000), Color(0x99000000)],
        stops: const [0.0, 0.4, 1.0],
      ),
      // Masthead.
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.94, 0.09),
        literal: 'ZEALOVA',
        font: CardFontIx.display,
        fontSize: 150,
        color: white,
        align: TextAlign.center,
        letterSpacing: -2,
        sizeMode: TextSizeMode.shrinkToFit,
        shadow: const ShadowSpec(color: Color(0x80000000), blur: 20),
      ),
      // Issue line under masthead.
      textEl(
        pos: const Offset(0.5, 0.17),
        size: const Size(0.9, 0.025),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 18,
        color: white70,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      // Cover star headline.
      textEl(
        pos: const Offset(0.05, 0.68),
        size: const Size(0.62, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 64,
        color: accent,
        align: TextAlign.left,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Cover deck.
      textEl(
        pos: const Offset(0.05, 0.76),
        size: const Size(0.62, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.condMid,
        fontSize: 26,
        color: white,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Cover-line rail (right edge).
      chipsEl(
        pos: const Offset(0.82, 0.45),
        size: const Size(0.3, 0.42),
        binding: const DataBinding(BindingSource.highlightLabel),
        layout: ChipLayout.column,
        maxItems: 4,
        chipColor: const Color(0x00000000),
        textColor: white,
        fontSize: 22,
      ),
      // Barcode + watermark footer.
      barcodeEl(
        pos: const Offset(0.16, 0.94),
        size: const Size(0.22, 0.07),
        captionBinding: const DataBinding(BindingSource.periodLabel),
        caption: 'ZEALOVA · 2026',
        barColor: const Color(0xFFFFFFFF),
        background: const Color(0x00000000),
        captionColor: white70,
        captionFontSize: 13,
      ),
      watermarkEl(pos: const Offset(0.62, 0.94), color: white70),
    ],
  );
}
