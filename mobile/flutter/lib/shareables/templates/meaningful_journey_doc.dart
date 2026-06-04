/// Editable-card preset — **The Journey**: a Day-1 → Today diptych. Two photos
/// (the user's before/after) sit side by side with the start grayscaled and a
/// volt arrow between them, under an editorial eyebrow and over a three-up
/// stat strip bound to the user's milestone highlights. Story-driven, designed
/// to make the "look how far I've come" feeling land.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc meaningfulJourneyDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  const muted = Color(0x99FFFFFF);

  return cardDoc(
    aspect: aspect,
    presetId: 'meaningfulJourney',
    accent: accent,
    background: gradientBg(
      const [Color(0xFF0F1620), Color(0xFF070709)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Editorial eyebrow.
      textEl(
        pos: const Offset(0.5, 0.085),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 19,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
        maxLines: 1,
      ),
      // BEFORE — the user's first photo, desaturated.
      photoEl(
        pos: const Offset(0.285, 0.43),
        size: const Size(0.40, 0.42),
        binding: const DataBinding(BindingSource.customPhotoPath),
        mask: PhotoMask.rounded,
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.285, 0.665),
        size: const Size(0.36, 0.03),
        literal: 'DAY 1',
        font: CardFontIx.cond,
        fontSize: 16,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      // Volt arrow between the two states.
      textEl(
        pos: const Offset(0.5, 0.43),
        size: const Size(0.12, 0.08),
        literal: '→',
        fontSize: 40,
        color: accent,
        align: TextAlign.center,
      ),
      // TODAY — the second photo, full colour.
      photoEl(
        pos: const Offset(0.715, 0.43),
        size: const Size(0.40, 0.42),
        binding: const DataBinding(BindingSource.customPhotoPathSecondary),
        mask: PhotoMask.rounded,
        cornerRadius: 14,
      ),
      textEl(
        pos: const Offset(0.715, 0.665),
        size: const Size(0.36, 0.03),
        literal: 'TODAY',
        font: CardFontIx.cond,
        fontSize: 16,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      // Three-up stat strip bound to the user's milestone highlights.
      statGridEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.88, 0.16),
        columns: 3,
        tileColor: const Color(0x00000000),
        valueFont: CardFontIx.display,
        valueFontSize: 34,
        labelFontSize: 13,
        tiles: const [
          ['+18', 'LB MUSCLE'],
          ['+95', 'BENCH'],
          ['90', 'DAYS'],
        ],
      ),
      watermarkEl(pos: const Offset(0.32, 0.955), color: muted),
    ],
  );
}
