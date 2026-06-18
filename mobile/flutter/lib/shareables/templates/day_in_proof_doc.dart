/// Editable-card preset for **F3 — "Day in Proof" cross-domain card**.
///
/// The one card only Zealova can make: a single 9:16 that proves a whole day
/// across BOTH domains — the day's PR (workout) + meal grade (nutrition) +
/// streak — plus one cached insight line. Deterministic assembly: every value
/// is baked into the doc as a literal from the share payload (the
/// `/share/day-in-proof` response, mapped through `DayInProofAdapter`). No AI
/// at render time; the line is fetched once upstream and travels on `caption`.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../grade.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dayInProofDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  final grade = letterGrade(data.healthScore ?? 6);

  // Stat tiles baked from the payload (deterministic). PR + grade + streak.
  final prValue = shareableHeroString(data);
  final prLabel = data.heroUnitSingular.isNotEmpty
      ? shareableHeroUnit(data).toUpperCase()
      : 'TODAY\'S PR';
  final streak = data.currentStreak ?? 0;

  final tiles = <List<String>>[
    [prValue == '—' ? '—' : prValue, prLabel],
    [grade.letter, 'MEAL GRADE'],
    ['$streak', 'DAY STREAK'],
    [data.healthScore != null ? '${data.healthScore}/10' : '—', 'NUTRITION'],
  ];

  return cardDoc(
    aspect: aspect,
    presetId: 'dayInProof',
    accent: accent,
    background: gradientBg(
      [
        Color.lerp(const Color(0xFF0A0B10), accent, 0.20)!,
        const Color(0xFF05060A),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.09),
        size: const Size(0.84, 0.04),
        literal: 'A DAY IN PROOF',
        font: CardFontIx.cond,
        fontSize: 30,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      // Date / period label.
      textEl(
        pos: const Offset(0.5, 0.15),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.periodLabel),
        fontSize: 38,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Cross-domain stat grid (PR + grade + streak + nutrition score).
      statGridEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.88, 0.36),
        tiles: tiles,
        columns: 2,
        valueColor: Colors.white,
        valueFont: CardFontIx.display,
        valueFontSize: 56,
      ),
      // The cached insight line (caption) — the human voice on the card.
      textEl(
        pos: const Offset(0.5, 0.72),
        size: const Size(0.86, 0.1),
        binding: const DataBinding(BindingSource.caption),
        font: CardFontIx.condMid,
        fontSize: 40,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 3,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      // User name.
      textEl(
        pos: const Offset(0.5, 0.88),
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
