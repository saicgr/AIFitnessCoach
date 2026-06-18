/// Editable-card presets for **F6 — "Add Yours" native prompt cards**.
///
/// Instagram's "Add Yours" sticker drives a chain reaction: one user posts a
/// prompt, everyone who sees it adds their own. These presets bake the prompt
/// look into the share card ("Add your heaviest lift" / "Add your meal") so the
/// poster's own stat sits below a tappable-looking prompt header. Deterministic
/// (no AI) — the prompt is literal copy + the share's existing hero/photo.
///
/// Two builders: [addYoursWorkoutDoc] (heaviest lift / today's workout) and
/// [addYoursFoodDoc] (your meal) — registered for the workout + food kinds so
/// the user explicitly gets food parity.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

/// The shared "Add Yours" prompt header — a pill with a + glyph and prompt copy.
List<CardElement> _addYoursHeader(Color accent, String prompt) => [
      // Prompt pill background.
      shapeEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.78, 0.1),
        shape: ShapeKind.pill,
        fill: Colors.white,
      ),
      // The camera/＋ glyph chip.
      shapeEl(
        pos: const Offset(0.2, 0.16),
        size: const Size(0.12, 0.07),
        shape: ShapeKind.circle,
        fill: accent,
      ),
      iconEl(
        pos: const Offset(0.2, 0.16),
        size: const Size(0.08, 0.045),
        emoji: '➕',
        color: Colors.white,
      ),
      textEl(
        pos: const Offset(0.56, 0.16),
        size: const Size(0.5, 0.06),
        literal: prompt,
        font: CardFontIx.cond,
        fontSize: 30,
        color: const Color(0xFF111111),
        align: TextAlign.left,
        maxLines: 2,
      ),
    ];

/// Workout "Add Yours" — "Add your heaviest lift" over the hero number.
CardDoc addYoursWorkoutDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  return cardDoc(
    aspect: aspect,
    presetId: 'addYoursWorkout',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF06080F), accent, 0.2)!,
      const Color(0xFF04050A),
    ]),
    elements: [
      ..._addYoursHeader(accent, 'Add your heaviest lift'),
      // Big hero stat.
      textEl(
        pos: const Offset(0.5, 0.46),
        size: const Size(0.9, 0.22),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 220,
        color: accent,
        align: TextAlign.center,
        maxLines: 1,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.6),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        fontSize: 40,
        align: TextAlign.center,
        maxLines: 2,
      ),
      // Three stat tiles from highlights.
      statGridEl(
        pos: const Offset(0.5, 0.8),
        size: const Size(0.86, 0.16),
        columns: 3,
        tiles: [
          for (var i = 0; i < 3 && i < data.highlights.length; i++)
            [data.highlights[i].value, data.highlights[i].label],
        ],
        valueFontSize: 36,
        labelFontSize: 14,
        valueFont: CardFontIx.cond,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white70),
    ],
  );
}

/// Food "Add Yours" — "Add your meal" over the meal photo + macros.
CardDoc addYoursFoodDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  final hasPhoto =
      data.foodImageUrls != null && data.foodImageUrls!.isNotEmpty;
  return cardDoc(
    aspect: aspect,
    presetId: 'addYoursFood',
    accent: accent,
    background: gradientBg([
      Color.lerp(const Color(0xFF0A0B10), accent, 0.18)!,
      const Color(0xFF050608),
    ]),
    elements: [
      ..._addYoursHeader(accent, 'Add your meal'),
      if (hasPhoto)
        photoEl(
          pos: const Offset(0.5, 0.46),
          size: const Size(0.72, 0.4),
          binding: const DataBinding(BindingSource.foodImageUrl, index: 0),
          mask: PhotoMask.rounded,
          cornerRadius: 36,
        ),
      textEl(
        pos: Offset(0.5, hasPhoto ? 0.72 : 0.46),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.title),
        fontSize: 42,
        align: TextAlign.center,
        maxLines: 2,
      ),
      // Macro pill row.
      chartEl(
        pos: Offset(0.5, hasPhoto ? 0.85 : 0.7),
        size: const Size(0.86, 0.1),
        style: MacroVizStyle.pills,
      ),
      watermarkEl(pos: const Offset(0.30, 0.95), color: Colors.white70),
    ],
  );
}
