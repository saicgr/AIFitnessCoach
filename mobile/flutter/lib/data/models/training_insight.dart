/// Training-trend AI insight — the coach line atop the Stats-tab training
/// section. Backed by `GET /api/v1/coach/daily-insight?source=workout_stats`.
///
/// The backend assembles a real training-trend snapshot (volume deltas,
/// push/pull split, ACWR state, recent PR count, current streak), runs it
/// through Gemini with a ground-truth number guardrail, and falls back to a
/// deterministic line derived from the same real snapshot when Gemini is
/// unavailable / over the cost cap / fails validation. `isFallback` flags the
/// deterministic path so the UI can show a subtle indicator. Hand-written.
library;

import 'package:flutter/foundation.dart';

@immutable
class TrainingInsight {
  /// Short headline (<= 8 words) naming the most notable trend.
  final String headline;

  /// 1 to 2 sentence interpretation with one concrete next move.
  final String body;

  /// True when the backend served the deterministic fallback rather than a
  /// fresh Gemini generation (delivery == "deterministic_fallback").
  final bool isFallback;

  const TrainingInsight({
    required this.headline,
    required this.body,
    this.isFallback = false,
  });

  factory TrainingInsight.fromJson(Map<String, dynamic> json) {
    return TrainingInsight(
      headline: (json['headline'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      isFallback: (json['delivery'] as String?) == 'deterministic_fallback',
    );
  }
}
