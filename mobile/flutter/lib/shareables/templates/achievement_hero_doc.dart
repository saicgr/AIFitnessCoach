/// Editable-card preset for the **Achievement Hero** template — purple-violet
/// gradient, a halo'd trophy badge, a giant achievement count, a "latest"
/// chip and two key-stat pills.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc achievementHeroDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'achievementHero',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF2D1B69), Color(0xFF1A0E3D), Color(0xFF0D0721)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 1,
        fontSize: 24,
        color: Colors.white70,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.15),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 44,
        align: TextAlign.center,
        letterSpacing: 1.6,
        allCaps: true,
        maxLines: 1,
      ),
      // Glow halo behind the trophy badge.
      shapeEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.5, 0.28),
        shape: ShapeKind.circle,
        gradient: const [Color(0x8CFFB35B), Color(0x33FF6B35), Color(0x00FF6B35)],
        radial: true,
      ),
      badgeEl(
        pos: const Offset(0.5, 0.38),
        size: const Size(0.3, 0.17),
        gradient: const [Color(0xFFFFB35B), Color(0xFFFF6B35)],
        label: 'TROPHY',
        valueLiteral: '🏆',
      ),
      textEl(
        pos: const Offset(0.5, 0.58),
        size: const Size(0.9, 0.16),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 200,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.8, 0.04),
        literal: 'ACHIEVEMENTS',
        font: 1,
        fontSize: 26,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.75),
        size: const Size(0.6, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 0),
        font: 0,
        fontSize: 26,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.27, 0.86),
        size: const Size(0.4, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 1),
        font: 1,
        fontSize: 32,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.73, 0.86),
        size: const Size(0.4, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 2),
        font: 1,
        fontSize: 32,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.95), color: Colors.white),
    ],
  );
}
