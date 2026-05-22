/// Editable-card preset — **Candy Heart**: a pastel rounded card with short
/// stacked all-caps phrases ("EAT MORE", "140G", "GOOD JOB") set like the
/// printed phrases on a candy conversation-heart, and a tiny circular meal
/// photo tucked below.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc candyHeartDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  // A soft pastel ground tinted toward the accent — sweet, not loud.
  final ground = Color.lerp(const Color(0xFFFFF1F4), accent, 0.14)!;
  final ink = Color.lerp(const Color(0xFF7A2E3C), accent, 0.30)!;

  return cardDoc(
    aspect: aspect,
    presetId: 'candyHeart',
    accent: accent,
    background: solidBg(ground),
    elements: [
      // Inner rounded "candy" panel — a slightly deeper pastel.
      shapeEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.84, 0.74),
        shape: ShapeKind.rounded,
        fill: Color.lerp(ground, Colors.white, 0.55)!,
        cornerRadius: 72,
      ),
      // Top stacked phrase — the meal label, candy-heart style.
      textEl(
        pos: const Offset(0.5, 0.26),
        size: const Size(0.7, 0.07),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 7,
        fontSize: 40,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
        maxLines: 1,
      ),
      // Big middle phrase — the protein figure.
      textEl(
        pos: const Offset(0.5, 0.4),
        size: const Size(0.78, 0.12),
        binding: const DataBinding(BindingSource.proteinG),
        font: 1,
        fontSize: 92,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 1,
        allCaps: true,
        maxLines: 1,
      ),
      // Cheery sign-off phrase.
      textEl(
        pos: const Offset(0.5, 0.51),
        size: const Size(0.7, 0.06),
        literal: 'GOOD JOB',
        font: 7,
        fontSize: 38,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
        maxLines: 1,
      ),
      // Tiny circular meal photo below the phrases.
      photoEl(
        pos: const Offset(0.5, 0.68),
        size: const Size(0.26, 0.146),
        mask: PhotoMask.circle,
        frameColor: Colors.white,
        frameWidth: 8,
      ),
      watermarkEl(
        pos: const Offset(0.34, 0.92),
        color: ink.withValues(alpha: 0.6),
        iconSize: 16,
        fontSize: 11,
      ),
    ],
  );
}
