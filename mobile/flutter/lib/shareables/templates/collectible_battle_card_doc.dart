/// Editable-card preset for the **Battle Card** collectible — a Pokémon-style
/// trading card: a gold-foil rim around a cream interior, the athlete name +
/// "HP" hero stat at the top, the hero exercise illustration in a bordered
/// window, and an "attack move" line that quotes the headline lift. Every text
/// is editable; the HP and damage values bind to real session data.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc collectibleBattleCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const gold = Color(0xFFF5D042);
  const goldDeep = Color(0xFFB8860B);
  const rimInk = Color(0xFF6B5210);
  const cream = Color(0xFFFFFCEB);
  const ink = Color(0xFF111111);
  const sub = Color(0xFF555555);
  const danger = Color(0xFFC0392B);
  return cardDoc(
    aspect: aspect,
    presetId: 'collectibleBattleCard',
    accent: accent,
    background: solidBg(const Color(0xFF0B0B0F)),
    elements: [
      // Gold-foil rim.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.84, 0.86),
        gradient: const [gold, goldDeep],
        stroke: rimInk,
        strokeWidth: 2,
        cornerRadius: 18,
      ),
      // Cream interior.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.78, 0.8),
        fill: cream,
        cornerRadius: 11,
      ),
      // Name + HP header row.
      textEl(
        pos: const Offset(0.36, 0.18),
        size: const Size(0.4, 0.05),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.display,
        fontSize: 34,
        color: ink,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.51, 0.18),
        size: const Size(0.1, 0.04),
        literal: 'HP',
        font: CardFontIx.display,
        fontSize: 20,
        color: danger,
        align: TextAlign.right,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.66, 0.18),
        size: const Size(0.22, 0.05),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 30,
        color: danger,
        align: TextAlign.right,
        maxLines: 1,
      ),
      // Hero illustration window.
      photoEl(
        pos: const Offset(0.5, 0.45),
        size: const Size(0.68, 0.4),
        binding: const DataBinding(BindingSource.heroImageUrl),
        cornerRadius: 6,
        frameColor: rimInk,
        frameWidth: 2,
      ),
      // Attack divider.
      dividerEl(
        pos: const Offset(0.5, 0.69),
        size: const Size(0.68, 0.003),
        color: const Color(0xFFC9B870),
        thickness: 1.5,
      ),
      // Attack move (⚡ glyph + bound title).
      iconEl(
        pos: const Offset(0.22, 0.74),
        size: const Size(0.06, 0.035),
        emoji: '⚡',
      ),
      textEl(
        pos: const Offset(0.54, 0.74),
        size: const Size(0.56, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 26,
        color: ink,
        maxLines: 1,
      ),
      // Flavor line — quotes the headline lift.
      textEl(
        pos: const Offset(0.5, 0.79),
        size: const Size(0.68, 0.035),
        literal: 'Hits hard. Opponent flees the gym.',
        font: CardFontIx.cond,
        fontSize: 18,
        color: sub,
        maxLines: 2,
      ),
      // Rarity stamp.
      textEl(
        pos: const Offset(0.5, 0.85),
        size: const Size(0.68, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 15,
        color: goldDeep,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.32, 0.95), color: const Color(0xFFB8860B)),
    ],
  );
}
