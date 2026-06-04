/// Editable-card preset for the **Tournament Bracket** data/meme template —
/// your session's exercises seeded into a knockout bracket: each "matchup" is a
/// row with an accent-left rule and a ✓ for the lifts you completed, converging
/// on a champion line that reads the hero volume. Every row label is editable.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc dataBracketDoc(Shareable data, ShareableAspect aspect) {
  const volt = Color(0xFFB8FF2F);
  const ink = Color(0xFF0D1117);

  // One bracket matchup row: accent left-rule when "won" (completed).
  List<CardElement> matchup(String name, bool won, double cy) {
    final railColor = won ? volt : const Color(0xFF333A44);
    return [
      shapeEl(
        pos: Offset(0.5, cy),
        size: const Size(0.84, 0.075),
        shape: ShapeKind.rounded,
        fill: const Color(0x08FFFFFF),
        cornerRadius: 8,
      ),
      shapeEl(
        pos: Offset(0.10, cy),
        size: const Size(0.012, 0.075),
        shape: ShapeKind.rect,
        fill: railColor,
      ),
      textEl(
        pos: Offset(0.40, cy),
        size: const Size(0.58, 0.05),
        literal: name,
        font: CardFontIx.cond,
        fontSize: 28,
        color: won ? Colors.white : const Color(0x80FFFFFF),
        maxLines: 1,
      ),
      textEl(
        pos: Offset(0.86, cy),
        size: const Size(0.1, 0.05),
        literal: won ? '✓' : '',
        font: CardFontIx.cond,
        fontSize: 30,
        color: volt,
        align: TextAlign.center,
      ),
    ];
  }

  return cardDoc(
    aspect: aspect,
    presetId: 'dataBracket',
    accent: volt,
    background: gradientBg(
      [ink, const Color(0xFF06080C)],
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
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 3,
        allCaps: true,
      ),
      textEl(
        pos: const Offset(0.5, 0.155),
        size: const Size(0.86, 0.06),
        binding: const DataBinding(BindingSource.title),
        font: CardFontIx.display,
        fontSize: 52,
        color: Colors.white,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.225),
        size: const Size(0.7, 0.025),
        literal: 'KNOCKOUT · FINAL',
        font: CardFontIx.mono,
        fontSize: 15,
        color: volt,
        align: TextAlign.center,
        letterSpacing: 3,
      ),
      ...matchup('Bench Press', true, 0.36),
      ...matchup('Cable Row', false, 0.46),
      ...matchup('Chest Fly', true, 0.56),
      ...matchup('Overhead Press', true, 0.66),
      ...matchup('Pull Up', false, 0.76),
      // Champion line — hero volume crowns the bracket.
      textEl(
        pos: const Offset(0.5, 0.88),
        size: const Size(0.86, 0.05),
        binding: const DataBinding(BindingSource.heroString),
        font: CardFontIx.display,
        fontSize: 36,
        color: volt,
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.925),
        size: const Size(0.86, 0.025),
        literal: '🏆 SESSION CHAMPION',
        font: CardFontIx.mono,
        fontSize: 14,
        color: const Color(0x99FFFFFF),
        align: TextAlign.center,
        letterSpacing: 2,
      ),
      watermarkEl(pos: const Offset(0.3, 0.96), color: const Color(0xFFFFFFFF)),
    ],
  );
}
