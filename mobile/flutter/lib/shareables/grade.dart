/// Deterministic letter-grade mapping for share cards (F10 Meal grade).
///
/// The app already computes a meal **health / inflammation score** on a 1–10
/// scale (`Shareable.healthScore`, sourced from the nutrition analyzer). This
/// file is the single pure mapping from that score to a letter grade A+ … D-.
/// Zero AI, zero network — just arithmetic, so a meal-grade card is free to
/// render and re-render.
///
/// The cutoffs are intentionally generous-at-the-top (a "10/10 clean meal"
/// should read **A+**, a midfield "6" lands at **B-/C+**) and never reward a
/// genuinely poor meal with a passing grade. They are the only place the
/// score→grade contract lives; tests and card presets both call [letterGrade].
library;

import 'package:flutter/material.dart';

/// A letter grade plus the accent color that represents it. Greens for the
/// A/B band, amber for C, red for D — the universal report-card palette.
@immutable
class MealGrade {
  /// "A+", "A", "A-", "B+", … "D-".
  final String letter;

  /// A short qualitative label ("Excellent", "Solid", "Okay", "Heavy").
  final String label;

  /// The band color — used for the big-letter glyph + accent chrome. This is
  /// a *semantic* grade color (green→red), deliberately independent of the
  /// app's brand accent, because a grade's meaning is carried by its hue.
  final Color color;

  const MealGrade(this.letter, this.label, this.color);
}

/// Maps a 1–10 health score to a [MealGrade]. The score is clamped, so an
/// out-of-range value never throws.
///
/// Cutoffs (score → letter):
///   9.5–10 → A+   ·  8.5–9.4 → A   ·  8.0–8.4 → A-
///   7.5–7.9 → B+  ·  6.5–7.4 → B   ·  6.0–6.4 → B-
///   5.5–5.9 → C+  ·  4.5–5.4 → C   ·  4.0–4.4 → C-
///   3.0–3.9 → D+  ·  2.0–2.9 → D   ·  <2.0   → D-
MealGrade letterGrade(num score) {
  final s = score.toDouble().clamp(0.0, 10.0);

  const aColor = Color(0xFF22C55E); // green
  const bColor = Color(0xFF84CC16); // lime
  const cColor = Color(0xFFF59E0B); // amber
  const dColor = Color(0xFFEF4444); // red

  if (s >= 9.5) return const MealGrade('A+', 'Excellent', aColor);
  if (s >= 8.5) return const MealGrade('A', 'Excellent', aColor);
  if (s >= 8.0) return const MealGrade('A-', 'Great', aColor);
  if (s >= 7.5) return const MealGrade('B+', 'Solid', bColor);
  if (s >= 6.5) return const MealGrade('B', 'Solid', bColor);
  if (s >= 6.0) return const MealGrade('B-', 'Good', bColor);
  if (s >= 5.5) return const MealGrade('C+', 'Okay', cColor);
  if (s >= 4.5) return const MealGrade('C', 'Okay', cColor);
  if (s >= 4.0) return const MealGrade('C-', 'So-so', cColor);
  if (s >= 3.0) return const MealGrade('D+', 'Heavy', dColor);
  if (s >= 2.0) return const MealGrade('D', 'Heavy', dColor);
  return const MealGrade('D-', 'Indulgent', dColor);
}

/// Convenience — just the letter string for a score (used by Wrapped scenes
/// and stat tiles that only need the glyph).
String letterGradeString(num score) => letterGrade(score).letter;
