/// The semantic state ramp: **supports · neutral · strains**.
///
/// The one rule this file exists to enforce: *colour encodes valence, never
/// position*. "2% above your 30-day baseline" is green for steps and amber for
/// resting heart rate, because the question a tinted deviation answers is
/// "does this reading support or strain the goal?", not "is the number bigger
/// than the baseline?". Every private `delta >= 0 ? success : warning` ternary
/// scattered around the app got that backwards for at least one metric.
///
/// Three pieces:
///
///  1. [GoodDirection] — the *declaration*. A metric states which way is
///     better (`higher`, `lower`) or that it refuses to judge (`neutral`).
///     Weight and calories are `neutral` by product decision: a cut and a bulk
///     flip the meaning, so we show the number and let the user judge.
///  2. [SemanticState] — the *resolution*. `valence + sign of deviation` →
///     supports / neutral / strains, via [SemanticState.resolve]. There is no
///     other constructor path in the app, and [SemanticState.resolve] has no
///     default for `valence` — you cannot tint a deviation without saying
///     which way is good for that metric.
///  3. [DeviationLine] — the *render*. A coloured dot plus the deviation
///     sentence. The label is required and always drawn, so colour is never
///     the sole carrier of meaning (WCAG 1.4.1).
///
/// Colour comes from [AppColors.stateSupports] / [AppColors.stateStrains] /
/// [AppColors.stateNeutral], never from `success`/`warning`/`error` (those are
/// event outcomes — "saved", "quota low" — and using the alert palette for an
/// ordinary Tuesday made every ordinary Tuesday look like an alarm).
library;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Which way is "good" for a metric. `lower` = a decrease is an improvement
/// (resting HR, body fat); `higher` = an increase is (steps, HRV, sleep);
/// `neutral` = we don't judge (body weight, calories eaten, a user-defined
/// metric with no stated direction).
///
/// Lives here rather than in `stat_trend.dart` (which re-exports it for its
/// existing callers) because it is the app's single valence vocabulary — the
/// trend chips, the vitals screen and the deviation lines all speak it.
enum GoodDirection { higher, lower, neutral }

/// The three rungs of the state ramp. The only way to obtain one from a
/// measurement is [SemanticState.resolve], which forces the caller to declare
/// the metric's [GoodDirection].
enum SemanticState {
  /// This reading moves the metric toward its goal.
  supports,

  /// No judgment: the metric has no goal direction, or the deviation is
  /// inside the noise floor.
  neutral,

  /// This reading moves the metric away from its goal.
  strains;

  /// Resolves a deviation into a ramp rung.
  ///
  /// [deviation] is the signed distance from the baseline in *any* unit —
  /// percent, absolute, z-score — because only its sign is read. [epsilon] is
  /// the noise floor in that same unit; anything inside it reads [neutral]
  /// ("on your baseline") rather than fabricating a direction from rounding
  /// dust.
  ///
  /// [valence] has no default on purpose. A caller that hasn't decided which
  /// way is good for its metric must say `GoodDirection.neutral` out loud.
  static SemanticState resolve({
    required GoodDirection valence,
    required double deviation,
    double epsilon = 0.0,
  }) {
    if (valence == GoodDirection.neutral) return SemanticState.neutral;
    if (deviation.isNaN || deviation.abs() <= epsilon) {
      return SemanticState.neutral;
    }
    final above = deviation > 0;
    final good = valence == GoodDirection.higher ? above : !above;
    return good ? SemanticState.supports : SemanticState.strains;
  }

  /// The ramp colour for this rung, resolved against the active theme.
  Color color(BuildContext context) =>
      colorFor(Theme.of(context).brightness == Brightness.dark);

  /// Theme-independent form, for painters and tests that already know the
  /// brightness.
  Color colorFor(bool isDark) {
    switch (this) {
      case SemanticState.supports:
        return isDark ? AppColors.stateSupports : AppColorsLight.stateSupports;
      case SemanticState.strains:
        return isDark ? AppColors.stateStrains : AppColorsLight.stateStrains;
      case SemanticState.neutral:
        return isDark ? AppColors.stateNeutral : AppColorsLight.stateNeutral;
    }
  }
}

/// Per-metric valence declarations, keyed by the metric's string id.
///
/// This is the lookup for the metrics that live *outside* the `TrendMetric`
/// enum — vitals signals, Today Score and its pillars, ring ids. `TrendMetric`
/// already carries its own `goodDirection`; this table does not duplicate it,
/// it covers the gap the scout found (HRV, respiratory rate, skin temperature,
/// stress, the score composites).
///
/// Anything not listed is [GoodDirection.neutral]: an unknown metric gets a
/// factual number and no judgment, never a guessed tint.
abstract final class MetricValence {
  /// Canonical declarations. Keys are lower-snake; [forKey] normalises.
  static const Map<String, GoodDirection> declarations = {
    // ── Above baseline is better ──────────────────────────────────────────
    'today_score': GoodDirection.higher,
    'score': GoodDirection.higher,
    'readiness': GoodDirection.higher,
    'readiness_score': GoodDirection.higher,
    'recovery': GoodDirection.higher,
    'steps': GoodDirection.higher,
    'move': GoodDirection.higher,
    'active_calories': GoodDirection.higher,
    'active_energy': GoodDirection.higher,
    'hrv': GoodDirection.higher,
    'heart_rate_variability': GoodDirection.higher,
    'sleep': GoodDirection.higher,
    'sleep_hours': GoodDirection.higher,
    'sleep_duration': GoodDirection.higher,
    'sleep_score': GoodDirection.higher,
    'vo2max': GoodDirection.higher,
    'vo2_max': GoodDirection.higher,
    'spo2': GoodDirection.higher,
    'blood_oxygen': GoodDirection.higher,
    'water': GoodDirection.higher,
    'hydration': GoodDirection.higher,
    'protein': GoodDirection.higher,
    'train': GoodDirection.higher,
    'nourish': GoodDirection.higher,
    'heart_health': GoodDirection.higher,
    'lean_mass': GoodDirection.higher,

    // ── Above baseline is worse ───────────────────────────────────────────
    'resting_heart_rate': GoodDirection.lower,
    'resting_hr': GoodDirection.lower,
    'rhr': GoodDirection.lower,
    'heart_rate': GoodDirection.lower,
    'respiratory_rate': GoodDirection.lower,
    'stress': GoodDirection.lower,
    'stress_score': GoodDirection.lower,
    'skin_temp': GoodDirection.lower,
    'skin_temperature': GoodDirection.lower,
    'body_fat': GoodDirection.lower,
    'waist': GoodDirection.lower,
    'hips': GoodDirection.lower,

    // ── Explicitly no judgment ────────────────────────────────────────────
    // Weight and calories are goal-dependent: a cut and a bulk flip which
    // direction is the win, and we don't ask the user to declare one. They are
    // listed rather than left to the default so the decision is visible here
    // instead of looking like an oversight.
    'weight': GoodDirection.neutral,
    'body_weight': GoodDirection.neutral,
    'calories': GoodDirection.neutral,
    'calories_eaten': GoodDirection.neutral,
    'bmi': GoodDirection.neutral,
  };

  /// The declared valence for [key], or [GoodDirection.neutral] when the
  /// metric hasn't declared one. Accepts `camelCase`, `snake_case` or
  /// space-separated ids.
  static GoodDirection forKey(String key) {
    final normalised = key
        .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
    return declarations[normalised] ?? GoodDirection.neutral;
  }

  /// Maps the backend `VitalSignal.direction` vocabulary
  /// (`high_bad` | `low_bad` | `either`) onto the ramp's valence. `either`
  /// means "both tails are a concern", which no single direction expresses —
  /// callers handle it as an out-of-range strain, so it maps to neutral here.
  static GoodDirection fromBackendDirection(String direction) {
    switch (direction) {
      case 'high_bad':
        return GoodDirection.lower;
      case 'low_bad':
        return GoodDirection.higher;
      default:
        return GoodDirection.neutral;
    }
  }
}

/// A deviation-from-baseline line: a ramp-coloured dot followed by the
/// sentence that says what the colour means ("12% below your 30-day
/// baseline").
///
/// The colour is derived, never passed: give it the metric's [valence] and the
/// signed [deviation] and it picks the rung. The [label] is required, so the
/// tint always ships glued to its text (WCAG 1.4.1 — colour is never the sole
/// encoding).
class DeviationLine extends StatelessWidget {
  /// Which way is good for THIS metric. No default — see [SemanticState.resolve].
  final GoodDirection valence;

  /// Signed distance from the baseline, in whatever unit [label] describes.
  /// Only the sign and the magnitude-vs-[epsilon] comparison are read.
  final double deviation;

  /// The sentence the colour is reinforcing, e.g. "12% below your 30-day
  /// baseline". Never omit it to save space — shorten it ("on baseline").
  final String label;

  /// Noise floor, in [deviation]'s unit. Inside it the line reads neutral.
  final double epsilon;

  final double fontSize;
  final double dotSize;
  final int maxLines;
  final TextAlign textAlign;

  /// Optional base style for the label — lets a surface with its own type
  /// ladder (the Home metric tiles' condensed uppercase sub-line) keep its
  /// family, weight and tracking. The ramp colour is still applied on top and
  /// can never be overridden: colour stays derived from valence.
  final TextStyle? textStyle;

  const DeviationLine({
    super.key,
    required this.valence,
    required this.deviation,
    required this.label,
    this.epsilon = 0.0,
    this.fontSize = 11.5,
    this.dotSize = 6,
    this.maxLines = 2,
    this.textAlign = TextAlign.start,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final state = SemanticState.resolve(
      valence: valence,
      deviation: deviation,
      epsilon: epsilon,
    );
    final color = state.color(context);
    final base = textStyle ??
        TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1.3,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Optically centres the dot on the first line of the label.
          padding:
              EdgeInsetsDirectional.only(top: (base.fontSize ?? fontSize) * 0.42),
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        SizedBox(width: dotSize),
        Flexible(
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: base.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
