/// Editable-card preset for the **Meal Achievement** food template — a
/// game-style horizontal unlock banner: a trophy icon chip on the left, an
/// "PROTEIN GOAL UNLOCKED" headline + subtext on the right, a confetti
/// scatter, all on a dark glossy background.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc mealAchievementDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const gold = Color(0xFFF5C542);

  // A single confetti dot.
  CardElement confetti(double x, double y, double s, Color c) => shapeEl(
        pos: Offset(x, y),
        size: Size(s, s),
        shape: ShapeKind.rounded,
        fill: c,
        cornerRadius: 4,
      );

  return cardDoc(
    aspect: aspect,
    presetId: 'mealAchievement',
    accent: accent,
    background: gradientBg(
      [
        Color.lerp(const Color(0xFF14161F), accent, 0.22)!,
        const Color(0xFF070810),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    elements: [
      // Confetti scatter behind the banner.
      confetti(0.16, 0.2, 0.035, gold),
      confetti(0.84, 0.22, 0.03, accent),
      confetti(0.28, 0.78, 0.04, const Color(0xFF06B6D4)),
      confetti(0.72, 0.82, 0.032, const Color(0xFFA855F7)),
      confetti(0.9, 0.55, 0.026, gold),
      confetti(0.08, 0.6, 0.03, const Color(0xFF22C55E)),
      // Glossy banner card.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.88, 0.42),
        shape: ShapeKind.rounded,
        gradient: const [Color(0xFF20232E), Color(0xFF12141C)],
        stroke: gold.withValues(alpha: 0.5),
        strokeWidth: 2,
        cornerRadius: 28,
      ),
      shapeEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.84, 0.1),
        shape: ShapeKind.rounded,
        fill: const Color(0x14FFFFFF),
        cornerRadius: 20,
      ),
      // Trophy icon chip on the left.
      shapeEl(
        pos: const Offset(0.27, 0.5),
        size: const Size(0.22, 0.22),
        shape: ShapeKind.circle,
        gradient: const [Color(0xFFF7D873), Color(0xFFC8941F)],
      ),
      iconEl(
        pos: const Offset(0.27, 0.5),
        size: const Size(0.12, 0.09),
        emoji: '🏆',
      ),
      // Headline + subtext on the right.
      textEl(
        pos: const Offset(0.63, 0.42),
        size: const Size(0.46, 0.04),
        literal: 'ACHIEVEMENT UNLOCKED',
        font: 5,
        fontSize: 18,
        color: gold,
        align: TextAlign.left,
        letterSpacing: 2,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.63, 0.5),
        size: const Size(0.46, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: 1,
        fontSize: 40,
        color: Colors.white,
        align: TextAlign.left,
        maxLines: 2,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.63, 0.6),
        size: const Size(0.46, 0.04),
        binding: const DataBinding(BindingSource.calories),
        font: 0,
        fontSize: 22,
        color: Colors.white70,
        align: TextAlign.left,
        maxLines: 1,
      ),
      watermarkEl(pos: const Offset(0.3, 0.92), color: Colors.white70),
    ],
  );
}
