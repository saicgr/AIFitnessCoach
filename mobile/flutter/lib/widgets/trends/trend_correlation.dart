import 'dart:math' as math;

/// Pure, testable statistics helpers for the Trends engine.
///
/// Kept dependency-free (no Flutter imports) so the maths can be unit-tested
/// in isolation and reused by both [TrendChart] and the Custom Trends builder.

/// A single point on a metric's time series.
///
/// [date] is the (local) day the value was recorded; [value] is the metric
/// value already converted to its display unit.
class TrendPoint {
  final DateTime date;
  final double value;

  const TrendPoint({required this.date, required this.value});
}

/// MacroFactor-style exponentially-weighted moving average ("trend weight").
///
/// MacroFactor describes its weight trend as a moving average that "cares"
/// about a long history but weights recent data more heavily. We implement
/// that with a standard EWMA recurrence:
///
///   trend[0] = raw[0]
///   trend[i] = alpha * raw[i] + (1 - alpha) * trend[i-1]
///
/// A lower [alpha] (≈0.1) smooths harder and reacts slower; a higher alpha
/// reacts faster. 0.25 is a good default for daily-ish body-weight data — it
/// damps day-to-day water-weight noise without lagging real trends.
List<double> computeEwma(List<double> values, {double alpha = 0.25}) {
  if (values.isEmpty) return const [];
  final out = <double>[values.first];
  for (var i = 1; i < values.length; i++) {
    out.add(alpha * values[i] + (1 - alpha) * out[i - 1]);
  }
  return out;
}

/// EWMA over [TrendPoint]s, preserving each point's date.
List<TrendPoint> ewmaPoints(List<TrendPoint> points, {double alpha = 0.25}) {
  if (points.isEmpty) return const [];
  final smoothed = computeEwma(
    points.map((p) => p.value).toList(growable: false),
    alpha: alpha,
  );
  return [
    for (var i = 0; i < points.length; i++)
      TrendPoint(date: points[i].date, value: smoothed[i]),
  ];
}

/// Result of a Pearson correlation between two metric series.
class CorrelationResult {
  /// Pearson's r in [-1, 1]. Null when there were too few overlapping points.
  final double? r;

  /// Number of date-aligned paired points used in the computation.
  final int pairedPoints;

  /// True when [pairedPoints] met the minimum required for a meaningful r.
  bool get hasEnoughData => r != null;

  const CorrelationResult({required this.r, required this.pairedPoints});

  /// Plain-English strength bucket: 'strong', 'moderate', 'weak', 'none'.
  String get strengthLabel {
    final v = r;
    if (v == null) return 'none';
    final a = v.abs();
    if (a >= 0.7) return 'strong';
    if (a >= 0.4) return 'moderate';
    if (a >= 0.2) return 'weak';
    return 'none';
  }

  /// One-line plain-English interpretation for the correlation chip.
  String interpretation(String metricA, String metricB) {
    final v = r;
    if (v == null) {
      return '$metricA and $metricB need more days logged on the same '
          'dates before a correlation can be measured.';
    }
    final dir = v > 0 ? 'positive' : (v < 0 ? 'negative' : 'flat');
    switch (strengthLabel) {
      case 'strong':
        return v > 0
            ? '$metricA and $metricB rise and fall closely together.'
            : 'When $metricA goes up, $metricB tends to go down.';
      case 'moderate':
        return v > 0
            ? '$metricA and $metricB tend to move together.'
            : '$metricA and $metricB tend to move in opposite directions.';
      case 'weak':
        return 'A slight $dir link between $metricA and $metricB.';
      default:
        return 'No clear relationship between $metricA and $metricB.';
    }
  }
}

/// Minimum number of date-aligned paired points required before a Pearson
/// correlation is reported. Below this the chip shows "not enough data".
const int kMinCorrelationPairs = 5;

/// Computes Pearson's r between two series after aligning them by calendar day.
///
/// Both series are first collapsed to one value per day (mean of same-day
/// points), then the intersection of days present in BOTH series is used as
/// the paired sample. Returns a null `r` when fewer than [kMinCorrelationPairs]
/// days overlap, or when either side has zero variance (a flat line).
CorrelationResult pearsonCorrelation(
  List<TrendPoint> seriesA,
  List<TrendPoint> seriesB,
) {
  final dailyA = _collapseToDaily(seriesA);
  final dailyB = _collapseToDaily(seriesB);

  final sharedDays = dailyA.keys.where(dailyB.containsKey).toList();
  final n = sharedDays.length;
  if (n < kMinCorrelationPairs) {
    return CorrelationResult(r: null, pairedPoints: n);
  }

  final xs = [for (final d in sharedDays) dailyA[d]!];
  final ys = [for (final d in sharedDays) dailyB[d]!];

  final meanX = xs.reduce((a, b) => a + b) / n;
  final meanY = ys.reduce((a, b) => a + b) / n;

  var cov = 0.0;
  var varX = 0.0;
  var varY = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - meanX;
    final dy = ys[i] - meanY;
    cov += dx * dy;
    varX += dx * dx;
    varY += dy * dy;
  }

  // A flat series has zero variance — Pearson's r is undefined there.
  if (varX <= 0 || varY <= 0) {
    return CorrelationResult(r: null, pairedPoints: n);
  }

  final r = cov / (math.sqrt(varX) * math.sqrt(varY));
  // Clamp to guard against floating-point overshoot past ±1.
  return CorrelationResult(r: r.clamp(-1.0, 1.0), pairedPoints: n);
}

/// Min/max normalises a series into a shared 0–100 index, preserving dates.
///
/// Research (multi-series chart UX): more than ~3 raw-scale lines on one axis
/// is unreadable — values with wildly different magnitudes (e.g. kg vs kcal)
/// flatten each other. Normalising every overlay to a common 0–100 index keeps
/// SHAPE (the thing a trend reader cares about) while making one axis legible.
/// A flat series maps to a constant 50 (its shape carries no information).
List<TrendPoint> normalizeToIndex(List<TrendPoint> points) {
  if (points.isEmpty) return const [];
  final values = points.map((p) => p.value).toList(growable: false);
  final lo = values.reduce(math.min);
  final hi = values.reduce(math.max);
  final span = hi - lo;
  return [
    for (final p in points)
      TrendPoint(
        date: p.date,
        value: span == 0 ? 50.0 : ((p.value - lo) / span) * 100.0,
      ),
  ];
}

/// Collapses a series to one value per calendar day (mean of same-day points).
Map<DateTime, double> _collapseToDaily(List<TrendPoint> series) {
  final sums = <DateTime, double>{};
  final counts = <DateTime, int>{};
  for (final p in series) {
    final day = DateTime(p.date.year, p.date.month, p.date.day);
    sums[day] = (sums[day] ?? 0) + p.value;
    counts[day] = (counts[day] ?? 0) + 1;
  }
  return {
    for (final e in sums.entries) e.key: e.value / counts[e.key]!,
  };
}
