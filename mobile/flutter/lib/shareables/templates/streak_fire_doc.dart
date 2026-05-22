/// Editable-card preset for the **Streak Fire** template — radial orange/red
/// glow, a flame icon, the big streak number and a "DAY STREAK" tag, with two
/// supporting highlight stats beneath.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc streakFireDoc(Shareable data, ShareableAspect aspect) {
  return cardDoc(
    aspect: aspect,
    presetId: 'streakFire',
    accent: const Color(0xFFFB923C),
    background: gradientBg(
      const [Color(0xFF7C2D12), Color(0xFFB45309), Color(0xFF1F1411)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Radial warm glow behind the flame.
      shapeEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(1.0, 0.56),
        shape: ShapeKind.circle,
        fill: const Color(0x8CFB923C),
        gradient: const [Color(0x8CFB923C), Color(0x00FB923C)],
        radial: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.84, 0.04),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 26,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      iconEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.24, 0.13),
        emoji: '🔥',
      ),
      textEl(
        pos: const Offset(0.5, 0.55),
        size: const Size(0.9, 0.22),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 240,
        align: TextAlign.center,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.84, 0.04),
        literal: 'DAY STREAK',
        font: 1,
        fontSize: 32,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      textEl(
        pos: const Offset(0.32, 0.83),
        size: const Size(0.34, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 1),
        font: 1,
        fontSize: 44,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.32, 0.87),
        size: const Size(0.34, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 1),
        font: 1,
        fontSize: 20,
        color: Colors.white70,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.68, 0.83),
        size: const Size(0.34, 0.05),
        binding: const DataBinding(BindingSource.highlightValue, index: 2),
        font: 1,
        fontSize: 44,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.68, 0.87),
        size: const Size(0.34, 0.03),
        binding: const DataBinding(BindingSource.highlightLabel, index: 2),
        font: 1,
        fontSize: 20,
        color: Colors.white70,
        align: TextAlign.center,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.32, 0.94), color: Colors.white),
    ],
  );
}
