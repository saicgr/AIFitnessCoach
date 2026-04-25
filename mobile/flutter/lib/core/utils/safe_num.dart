/// Finite-number helpers used across progress / percentage widgets.
///
/// `.toInt()` on a Dart `double` throws `UnsupportedError("Infinity or NaN
/// toInt")` when the value is non-finite. `.clamp` does NOT coerce NaN —
/// a NaN input yields a NaN output. Both surfaced as fatal crashes in
/// production (Sentry cluster on PLG110 post-workout-completion, April
/// 2026) where a zero-divisor progress calculation escaped into widget
/// text.
///
/// Prefer these helpers to writing the guard inline — they make intent
/// visible at call sites and give us one place to add logging if we ever
/// want to surface "NaN reached the UI" to Sentry.
library;

/// Convert a percentage-shaped double to its integer representation.
/// Returns [fallback] when the input is NaN, ±Infinity, or anything the
/// runtime rejects. Always clamps to 0..100 to keep UI labels sane.
int safePercent(double value, {int fallback = 0}) {
  if (!value.isFinite) return fallback;
  if (value < 0) return 0;
  if (value > 100) return 100;
  return value.toInt();
}

/// Convert an arbitrary double to int, returning [fallback] when the
/// value is non-finite. Does NOT clamp — use [safePercent] for
/// percentage displays.
int safeToInt(double value, {int fallback = 0}) {
  if (!value.isFinite) return fallback;
  return value.toInt();
}

/// Coerce a non-finite double to [fallback] (default 0.0). Use when
/// passing to APIs that assume finite input (LinearProgressIndicator's
/// value, tween targets, etc.).
double safeDouble(double value, {double fallback = 0.0}) {
  if (!value.isFinite) return fallback;
  return value;
}

/// Finite-and-clamped fraction helper: always returns 0.0..1.0.
/// Common idiom for progress bars that compute `current / total`.
double safeFraction(double value) {
  if (!value.isFinite) return 0.0;
  if (value < 0) return 0.0;
  if (value > 1) return 1.0;
  return value;
}
