/// Editable-card preset for the **Leaderboard Snapshot** data template — a
/// ranked board with YOU highlighted: a "WEEKLY LEADERBOARD" header, a podium
/// row, then ranked entries (your row gets the volt rail + your real handle /
/// volume), capped with your rank line. Every row label is an editable layer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataLeaderboardDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const muted = Color(0x99FFFFFF);

  // One leaderboard row. [you] highlights the current user's entry.
  List<CardElement> row(String rank, String name, String value, double cy,
      {bool you = false}) {
    return [
      shapeEl(
        pos: Offset(0.5, cy),
        size: const Size(0.86, 0.085),
        shape: ShapeKind.rounded,
        fill: you ? const Color(0x16B8FF2F) : const Color(0x08FFFFFF),
        stroke: you ? volt : const Color(0x00000000),
        strokeWidth: you ? 1.4 : 0,
        cornerRadius: 12,
      ),
      textEl(
        pos: Offset(0.14, cy),
        size: const Size(0.12, 0.05),
        literal: rank,
        font: CardFontIx.display,
        fontSize: 32,
        color: you ? volt : muted,
        align: TextAlign.center,
      ),
      textEl(
        pos: Offset(0.46, cy),
        size: const Size(0.42, 0.05),
        literal: name,
        font: CardFontIx.cond,
        fontSize: 26,
        color: you ? Colors.white : const Color(0xCCFFFFFF),
        maxLines: 1,
      ),
      textEl(
        pos: Offset(0.84, cy),
        size: const Size(0.26, 0.05),
        literal: value,
        font: CardFontIx.mono,
        fontSize: 22,
        color: you ? volt : muted,
        align: TextAlign.right,
        maxLines: 1,
      ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'dataLeaderboard',
    accent: volt,
    background: gradientBg(
      [const Color(0xFF0C1118), const Color(0xFF06080C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.08),
        size: const Size(0.86, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: CardFontIx.cond,
        fontSize: 20,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.15),
        size: const Size(0.9, 0.055),
        literal: 'WEEKLY LEADERBOARD',
        font: CardFontIx.display,
        fontSize: 46,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      // Column header.
      textEl(
        pos: const Offset(0.84, 0.235),
        size: const Size(0.26, 0.025),
        literal: 'VOLUME KG',
        font: CardFontIx.mono,
        fontSize: 14,
        color: muted,
        align: TextAlign.right,
        letterSpacing: 1.5,
      ),
      // Ranked rows — the user (YOU) is highlighted with a real handle/volume.
      ...row('1', 'Marcus L.', '11,402', 0.33),
      ...row('2', 'Priya K.', '10,815', 0.43),
      ...row('3', 'YOU', '9,128', 0.53, you: true),
      ...row('4', 'Jordan T.', '8,640', 0.63),
      ...row('5', 'Sam R.', '8,012', 0.73),
      // Your handle on the highlighted row (bound, overlays the YOU label).
      textEl(
        pos: const Offset(0.46, 0.565),
        size: const Size(0.42, 0.03),
        binding: const DataBinding(BindingSource.socialHandle),
        font: CardFontIx.mono,
        fontSize: 15,
        color: volt,
        maxLines: 1,
      ),
      // Your rank line — the real hero string.
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.86, 0.04),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.cond,
        fontSize: 28,
        color: volt,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.925),
        size: const Size(0.86, 0.025),
        literal: 'TOP 3% THIS WEEK',
        font: CardFontIx.mono,
        fontSize: 14,
        color: muted,
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.96), color: const Color(0xFFFFFFFF)),
    ],
  );
}
