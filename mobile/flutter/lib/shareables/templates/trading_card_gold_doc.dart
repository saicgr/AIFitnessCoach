/// Editable-card preset for the **Trading Card Gold** template — a gold-foil
/// border around a dark-navy interior, a "★ RARE" rarity pill, the hero
/// exercise illustration, the cardholder name and key stat rows.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc tradingCardGoldDoc(Shareable data, ShareableAspect aspect) {
  const gold = Color(0xFFFBBF24);
  const navy = Color(0xFF1E293B);
  return cardDoc(
    aspect: aspect,
    presetId: 'tradingCardGold',
    accent: gold,
    background: solidBg(const Color(0xFF0B1020)),
    elements: [
      // Gold-foil border.
      shapeEl(
        pos: const Offset(0.5, 0.47),
        size: const Size(0.82, 0.82),
        gradient: const [gold, Color(0xFFEAB308), Color(0xFFCA8A04)],
        stroke: const Color(0xFF422006),
        strokeWidth: 3,
        cornerRadius: 18,
      ),
      // Navy interior panel.
      shapeEl(
        pos: const Offset(0.5, 0.47),
        size: const Size(0.74, 0.74),
        fill: navy,
        cornerRadius: 12,
      ),
      textEl(
        pos: const Offset(0.32, 0.14),
        size: const Size(0.4, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 28,
        color: gold,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.66, 0.14),
        size: const Size(0.26, 0.04),
        literal: '★ RARE',
        font: 1,
        fontSize: 24,
        color: gold,
        align: TextAlign.right,
      ),
      // Hero exercise illustration.
      photoEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.66, 0.34),
        binding: const DataBinding(BindingSource.heroImageUrl),
        cornerRadius: 8,
      ),
      textEl(
        pos: const Offset(0.5, 0.61),
        size: const Size(0.66, 0.06),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: 1,
        fontSize: 52,
        align: TextAlign.center,
        maxLines: 1,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.66, 0.004),
        color: const Color(0x66FBBF24),
        thickness: 1.5,
      ),
      for (var i = 0; i < 3; i++) ...[
        textEl(
          pos: Offset(0.34, 0.71 + i * 0.05),
          size: const Size(0.36, 0.04),
          binding: DataBinding(BindingSource.highlightLabel, index: i),
          font: 0,
          fontSize: 22,
          color: gold,
          letterSpacing: 0.6,
          allCaps: true,
          maxLines: 1,
        ),
        textEl(
          pos: Offset(0.66, 0.71 + i * 0.05),
          size: const Size(0.26, 0.04),
          binding: DataBinding(BindingSource.highlightValue, index: i),
          font: 1,
          fontSize: 26,
          align: TextAlign.right,
        ),
      ],
      watermarkEl(pos: const Offset(0.32, 0.93), color: Colors.white60),
    ],
  );
}
