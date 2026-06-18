/// Editable-card preset for **F12 — Zealova Score + percentile**.
///
/// A composite 0–100 score in a big radial ring with a "stronger than X% of
/// athletes" percentile line and the viewer's tier badge — all sourced
/// **deterministically** from the existing Discover leaderboard percentile
/// (see `adapters/zealova_score_adapter.dart`). Zero AI, zero new backend.
///
/// The score arrives as `data.heroValue`, the tier as `data.rank`, and the
/// percentile travels on `data.subMetrics` (label 'PERCENTILE'); the preset
/// bakes the percentile line as literal text at build time.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc zealovaScoreCardDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;

  // Deterministic reads off the payload — no AI.
  final score = (data.heroValue ?? 0).round().clamp(0, 100);
  String pct = '';
  for (final m in data.subMetrics) {
    if (m.label == 'PERCENTILE') pct = m.value;
  }
  final strongerLine =
      pct.isEmpty ? 'Top of your league' : 'Stronger than $pct% of athletes';
  final tier = data.rank ?? 'Athlete';

  return cardDoc(
    aspect: aspect,
    presetId: 'zealovaScore',
    accent: accent,
    background: gradientBg(
      [
        const Color(0xFF06080C),
        Color.lerp(const Color(0xFF06080C), accent, 0.18)!,
        const Color(0xFF020305),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      // Eyebrow.
      textEl(
        pos: const Offset(0.5, 0.11),
        size: const Size(0.84, 0.04),
        literal: 'ZEALOVA SCORE',
        font: CardFontIx.cond,
        fontSize: 28,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
      ),
      // Period.
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.84, 0.035),
        binding: const DataBinding(BindingSource.periodLabel),
        fontSize: 22,
        color: const Color(0x80FFFFFF),
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      // The big score ring — fill fraction = score / 100.
      ringStatEl(
        pos: const Offset(0.5, 0.42),
        size: const Size(0.68, 0.34),
        progress: (score / 100).clamp(0.0, 1.0),
        centerValue: '$score',
        label: 'OUT OF 100',
        ringColor: accent,
        trackColor: const Color(0x1AFFFFFF),
        centerFontSize: 150,
        labelFontSize: 22,
        font: CardFontIx.display,
      ),
      // Percentile line.
      textEl(
        pos: const Offset(0.5, 0.66),
        size: const Size(0.88, 0.06),
        literal: strongerLine,
        font: CardFontIx.condMid,
        fontSize: 40,
        align: TextAlign.center,
        maxLines: 2,
      ),
      // Tier pill.
      shapeEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.42, 0.06),
        shape: ShapeKind.pill,
        fill: accent.withValues(alpha: 0.16),
        stroke: accent,
        strokeWidth: 1.5,
      ),
      textEl(
        pos: const Offset(0.5, 0.76),
        size: const Size(0.4, 0.045),
        literal: tier.toUpperCase(),
        font: CardFontIx.cond,
        fontSize: 28,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      // Three stat tiles (tier / rank / stronger-than).
      statGridEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.86, 0.1),
        columns: 3,
        tiles: [
          [data.rank ?? '—', 'TIER'],
          [
            data.highlights.isNotEmpty &&
                    data.highlights.length > 1
                ? data.highlights[1].value
                : '—',
            'RANK'
          ],
          [pct.isEmpty ? '—' : '$pct%', 'TOP %'],
        ],
        valueFontSize: 34,
        labelFontSize: 14,
        valueFont: CardFontIx.cond,
      ),
      // Handle / name.
      textEl(
        pos: const Offset(0.5, 0.95),
        size: const Size(0.84, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        fontSize: 22,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 2,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.72, 0.97), color: Colors.white70),
    ],
  );
}
