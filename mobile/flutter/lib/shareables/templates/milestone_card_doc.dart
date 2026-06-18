/// Editable-card preset for **F7 — Milestone auto-cards**.
///
/// A celebratory "you just hit X" card surfaced the instant a milestone fires —
/// workout (100th workout, first 1RM, 30-day streak) **and** food (protein-goal
/// streak, first week logged). Deterministic: the milestone label + value come
/// from the share payload (`title` / `heroString` / a milestone highlight), no
/// AI. One builder serves both kinds; the eyebrow adapts via `mealLabel` for
/// food shares and falls back to a generic "MILESTONE".
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc milestoneCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  final isFood = data.kind == ShareableKind.foodLog ||
      data.kind == ShareableKind.nutrition;
  final hasPhoto = isFood &&
      data.foodImageUrls != null &&
      data.foodImageUrls!.isNotEmpty;

  return cardDoc(
    aspect: aspect,
    presetId: 'milestone',
    accent: accent,
    background: gradientBg(
      [
        accent,
        Color.lerp(accent, Colors.black, 0.5)!,
        const Color(0xFF050308),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Burst rays behind the trophy (decorative).
      iconEl(
        pos: const Offset(0.5, 0.3),
        size: const Size(0.6, 0.3),
        emoji: '🎉',
        color: Colors.white,
      ),
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.12),
        size: const Size(0.84, 0.04),
        binding: isFood
            ? const DataBinding(BindingSource.mealLabel)
            : DataBinding.none,
        literal: 'MILESTONE UNLOCKED',
        font: CardFontIx.cond,
        fontSize: 28,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      // Trophy / medal glyph.
      iconEl(
        pos: const Offset(0.5, 0.3),
        size: const Size(0.3, 0.16),
        emoji: '🏆',
        color: Colors.white,
      ),
      if (hasPhoto)
        photoEl(
          pos: const Offset(0.5, 0.3),
          size: const Size(0.32, 0.18),
          binding: const DataBinding(BindingSource.foodImageUrl, index: 0),
          mask: PhotoMask.circle,
          frameColor: Colors.white,
          frameWidth: 5,
        ),
      // The big milestone value.
      textEl(
        pos: const Offset(0.5, 0.52),
        size: const Size(0.92, 0.18),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 220,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // Milestone title.
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.88, 0.08),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.condMid,
        fontSize: 48,
        align: TextAlign.center,
        maxLines: 2,
      ),
      // Subtitle from the first highlight (e.g. "30-day streak").
      if (data.highlights.isNotEmpty)
        textEl(
          pos: const Offset(0.5, 0.8),
          size: const Size(0.84, 0.04),
          binding: const DataBinding(BindingSource.highlightLabel, index: 0),
          fontSize: 26,
          color: Colors.white,
          align: TextAlign.center,
          letterSpacing: 2,
          allCaps: true,
        ),
      textEl(
        pos: const Offset(0.5, 0.9),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: CardFontIx.cond,
        fontSize: 28,
        color: Colors.white,
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.62, 0.95), color: Colors.white),
    ],
  );
}
