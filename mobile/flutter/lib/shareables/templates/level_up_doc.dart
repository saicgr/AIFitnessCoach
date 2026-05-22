/// Editable-card preset for the **Level Up** template — an RPG XP card:
/// LEVEL UP eyebrow + title, a gold sweep-gradient tier badge with the hero
/// value inside, and up to three highlight rows.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc levelUpDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const gold = Color(0xFFFCD34D);
  return cardDoc(
    aspect: aspect,
    presetId: 'levelUp',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF1E1B4B), Color(0xFF6D28D9), Color(0xFF0F0F1F)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.04),
        literal: 'LEVEL UP',
        font: 1,
        fontSize: 26,
        color: gold,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.86, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 44,
        align: TextAlign.center,
        letterSpacing: 1.6,
        allCaps: true,
        maxLines: 2,
      ),
      // XP ring — gold rim disc.
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.42, 0.24),
        shape: ShapeKind.circle,
        gradient: const [gold, Color(0xFFFB923C), gold],
      ),
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.36, 0.205),
        shape: ShapeKind.circle,
        fill: const Color(0xFF1E1B4B),
      ),
      textEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.32, 0.14),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 120,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Highlight rows.
      for (var i = 0; i < 3; i++) ...[
        textEl(
          pos: Offset(0.16, 0.66 + i * 0.08),
          size: const Size(0.5, 0.05),
          binding: DataBinding(BindingSource.highlightLabel, index: i),
          font: 1,
          fontSize: 22,
          color: Colors.white70,
          letterSpacing: 1.4,
          allCaps: true,
        ),
        textEl(
          pos: Offset(0.84, 0.66 + i * 0.08),
          size: const Size(0.36, 0.05),
          binding: DataBinding(BindingSource.highlightValue, index: i),
          font: 1,
          fontSize: 28,
          align: TextAlign.right,
        ),
      ],
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white),
    ],
  );
}
