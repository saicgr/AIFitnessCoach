/// Editable-card preset for the **Holo Card** collectible — a "1 of 1" holo
/// trading card: a saturated holographic rim (layered shape gradients), a dark
/// interior, the hero exercise illustration with an iridescent overlay sheen,
/// and a foil nameplate reading "NAME ✦ HOLO" with the rank + serial number.
/// Every text is editable; name / stat / serial bind to live data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleHoloCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const white = Color(0xFFFFFFFF);
  const interior = Color(0xFF0C0C12);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleHoloCard',
    accent: accent,
    background: solidBg(const Color(0xFF07070A)),
    elements: [
      // Holographic rim — layered iridescent gradient.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.88),
        gradient: const [
          Color(0xFFFF4DD2),
          Color(0xFF4DFFD2),
          Color(0xFF4D7CFF),
          Color(0xFFFFD24D),
          Color(0xFFFF4DD2),
        ],
        cornerRadius: 16,
      ),
      // Diagonal sheen highlight.
      scrimEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.88),
        colors: const [Color(0x4DFFFFFF), Color(0x00FFFFFF), Color(0x4D000000)],
        stops: const [0.0, 0.42, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      // Dark interior.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.81, 0.83),
        fill: interior,
        stroke: const Color(0x4DFFFFFF),
        strokeWidth: 1,
        cornerRadius: 11,
      ),
      // Hero illustration.
      photoEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.7, 0.5),
        binding: const DataBinding(BindingSource.heroImageUrl),
        cornerRadius: 8,
      ),
      // Iridescent overlay on the art.
      scrimEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.7, 0.5),
        colors: const [Color(0x66FFFFFF), Color(0x00FFFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      // Foil nameplate — bound name + holo mark.
      textEl(
        pos: const Offset(0.4, 0.78),
        size: const Size(0.5, 0.05),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.display,
        fontSize: 34,
        color: white,
        align: TextAlign.right,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.74, 0.78),
        size: const Size(0.24, 0.05),
        literal: '✦ HOLO',
        font: CardFontIx.display,
        fontSize: 34,
        color: white,
        align: TextAlign.left,
        maxLines: 1,
      ),
      // Rank · serial.
      textEl(
        pos: const Offset(0.4, 0.84),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.rank),
        font: CardFontIx.cond,
        fontSize: 17,
        color: accent,
        align: TextAlign.right,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.7, 0.84),
        size: const Size(0.28, 0.03),
        literal: '· 1 / 1',
        font: CardFontIx.cond,
        fontSize: 17,
        color: accent,
        align: TextAlign.left,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: white),
    ],
  );
}
