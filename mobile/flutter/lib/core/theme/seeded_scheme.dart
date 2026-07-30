import 'package:flutter/material.dart';

/// Memoised [ColorScheme.fromSeed].
///
/// Why this exists: seeding the whole scheme from the single accent (register
/// row 15) is the correct fix, but `ColorScheme.fromSeed` is NOT a cheap
/// constructor — it builds a full HCT tonal palette. Measured on this repo's
/// pinned Flutter (host machine, 500 warmed iterations):
///
///   ColorScheme.fromSeed(...)  ≈ 287 µs
///   ColorScheme.dark(...)      ≈   0.4 µs
///
/// `app.dart` rebuilds BOTH themes (`AppThemeLight.buildTheme` and
/// `AppTheme.buildDarkTheme`) inside its `build()`, so every root rebuild —
/// auth-status change, locale sync, accent change, gym-profile fetch landing —
/// paid ~0.6 ms on a Mac, several milliseconds on a mid-range phone, for a
/// value that is a pure function of (seed, brightness). Memoising removes that
/// cost without weakening the single-accent invariant: the seeded scheme is
/// still derived, never hand-written.
///
/// No eviction policy, and none is needed: the seed is always the resolved app
/// accent, which comes from the fixed `AccentColor` enum, so the key space is
/// bounded by construction (accents × 2 brightnesses). Deliberately NOT an
/// arbitrary max-entries cap.
ColorScheme seededScheme(Color seedColor, Brightness brightness) {
  final key = (seedColor.toARGB32(), brightness);
  final hit = _cache[key];
  if (hit != null) return hit;
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  _cache[key] = scheme;
  return scheme;
}

final Map<(int, Brightness), ColorScheme> _cache = {};
