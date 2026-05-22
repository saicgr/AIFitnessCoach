/// Editable-card preset for the **Meal Streak** food template — a logging
/// streak celebration: a glowing flame, a "Day N logged" hero, a mini week
/// dots row, and today's meal title.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealStreakDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const flame = Color(0xFFFB923C);

  // Seven mini week dots, last two filled with the accent.
  List<CardElement> weekDots() {
    final dots = <CardElement>[];
    for (var i = 0; i < 7; i++) {
      final cx = 0.22 + i * 0.093;
      final lit = i >= 5;
      dots.add(shapeEl(
        pos: Offset(cx, 0.74),
        size: const Size(0.06, 0.034),
        shape: ShapeKind.circle,
        fill: lit ? accent : const Color(0x1FFFFFFF),
        stroke: lit ? null : const Color(0x33FFFFFF),
        strokeWidth: lit ? 0 : 1.5,
      ));
    }
    return dots;
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'mealStreak',
    accent: accent,
    background: gradientBg(
      [
        Color.lerp(const Color(0xFF1A0E06), accent, 0.22)!,
        const Color(0xFF080604),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.11),
        size: const Size(0.86, 0.04),
        literal: 'NUTRITION STREAK',
        font: 5,
        fontSize: 22,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // Glow disc behind the flame.
      shapeEl(
        pos: const Offset(0.5, 0.34),
        size: const Size(0.62, 0.34),
        shape: ShapeKind.circle,
        gradient: const [Color(0x66FB923C), Color(0x00FB923C)],
        radial: true,
      ),
      iconEl(
        pos: const Offset(0.5, 0.32),
        size: const Size(0.42, 0.22),
        emoji: '🔥',
      ),
      textEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.9, 0.1),
        binding: const DataBinding(BindingSource.heroString),
        font: 1,
        fontSize: 96,
        color: Colors.white,
        align: TextAlign.center,
      ),
      textEl(
        pos: const Offset(0.5, 0.62),
        size: const Size(0.86, 0.045),
        literal: 'DAYS LOGGED IN A ROW',
        font: 5,
        fontSize: 20,
        color: flame,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      ...weekDots(),
      textEl(
        pos: const Offset(0.5, 0.84),
        size: const Size(0.84, 0.05),
        binding: const DataBinding(BindingSource.title),
        fontSize: 38,
        align: TextAlign.center,
        maxLines: 2,
      ),
      textEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 2,
        fontSize: 22,
        color: Colors.white60,
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white70),
    ],
  );
}
