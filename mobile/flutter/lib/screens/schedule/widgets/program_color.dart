import 'package:flutter/material.dart';

/// Deterministic per-program accent colors.
///
/// The schedule is a MERGED multi-program calendar — HYROX, a 5K builder, a
/// mobility flow, plus the always-on AI program can all share a week. To keep
/// them visually distinct WITHOUT a new DB field, every program is hashed to a
/// fixed slot in [palette] off its assignment id (stable across launches), so a
/// given program is always the same color on its chip, day-card, Manage row and
/// filter swatch. The AI program is reserved the cyan [ai] color.
///
/// Mirrors the v9 mockup palette in
/// `docs/planning/program-schedule-2026-06/mockups.html`.
class ProgramColors {
  ProgramColors._();

  /// Distinct accents assigned by hash. Order is fixed — do not reorder, or
  /// existing programs would silently re-color.
  static const List<Color> palette = [
    Color(0xFFE8772A), // orange
    Color(0xFF5B9BFF), // blue
    Color(0xFF37C7A4), // teal
    Color(0xFF9B6CFF), // purple
    Color(0xFFE2574B), // red
    Color(0xFF8FCF45), // green
    Color(0xFFF2B13C), // amber
    Color(0xFFE45B9B), // magenta
  ];

  /// The always-on AI program lane (ghost cards, AI chip/swatch).
  static const Color ai = Color(0xFF39C2E0);

  /// Custom user events (non-program schedule items).
  static const Color custom = Color(0xFF8FCF45);

  /// Stable color for a program key (the assignment id, falling back to its
  /// name). Empty / null keys get the first palette slot.
  static Color forKey(String? key) {
    if (key == null || key.trim().isEmpty) return palette.first;
    var h = 0;
    for (final c in key.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return palette[h % palette.length];
  }

  /// Dark, photo-forward gradient base derived from [accent]. Used when there's
  /// no real cover art — never blank (per the mockup "auto color" fallback).
  static LinearGradient cardGradient(Color accent) {
    final base = Color.alphaBlend(Colors.black.withValues(alpha: 0.60), accent);
    final dark = Color.alphaBlend(Colors.black.withValues(alpha: 0.86), accent);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [base, dark],
    );
  }

  /// Soft accent glow overlaid on the top-right of a card, mirroring the
  /// radial highlight in the mockup `.ph` layers.
  static RadialGradient cardGlow(Color accent) {
    return RadialGradient(
      center: const Alignment(0.7, -0.8),
      radius: 1.1,
      colors: [accent.withValues(alpha: 0.42), Colors.transparent],
    );
  }
}
