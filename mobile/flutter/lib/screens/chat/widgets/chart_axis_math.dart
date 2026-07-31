import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pure axis-scaling math for [GenericBlocksRenderer]'s charts, split into its
/// own file so it's directly unit-testable — a widget test can't reliably
/// assert on fl_chart's internal text-wrapping behavior.
///
/// E2E register #132(b): a coach-chat chart's y-axis rendered as a garbled,
/// wrapped "334.5" / "8" tick. Root cause was three compounding bugs, all
/// fixed here:
///  1. [yBounds] padded the data range by a flat 12% and returned the raw
///     fractional result untouched when the backend sent no `y_max` (e.g.
///     `334.58333333333337`) — the padded bound is now snapped OUTWARD to a
///     "nice" round number (Heckbert's 1/2/5×10ⁿ graph-label algorithm) so
///     the ticks it produces are round too.
///  2. [formatAxisValue] printed that fractional value near-verbatim (a raw
///     `double.toString()` can carry a dozen digits of floating-point noise)
///     — now capped at 2 decimals.
///  3. The chart's `reservedSize` was a fixed 32px, too narrow for a wide
///     label at font-size 9 — [axisReservedSize] now measures the actual
///     widest formatted tick via [TextPainter] instead of guessing.

/// "Nice numbers for graph labels" step-size (Heckbert) — snaps [raw] to the
/// nearest value in the 1/2/5×10ⁿ family every charting library uses so an
/// axis interval is always a round number. [roundUp] picks the smallest nice
/// value ≥ raw (used for choosing a tick STEP so ~4-5 ticks fit the range);
/// the false branch instead rounds to the CLOSEST nice value.
@visibleForTesting
double niceStep(double raw, {required bool roundUp}) {
  if (raw <= 0) return 1;
  final exponent = (math.log(raw) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  final fraction = raw / magnitude;
  double niceFraction;
  if (roundUp) {
    if (fraction <= 1) {
      niceFraction = 1;
    } else if (fraction <= 2) {
      niceFraction = 2;
    } else if (fraction <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
  } else {
    if (fraction < 1.5) {
      niceFraction = 1;
    } else if (fraction < 3) {
      niceFraction = 2;
    } else if (fraction < 7) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
  }
  return niceFraction * magnitude;
}

/// Render a JSON num/str axis value for display, capped at 2 decimals.
///
/// Non-integer values are capped at 2 decimals. A raw `double.toString()` can
/// carry a dozen digits of floating-point noise (e.g. an axis tick built from
/// `(hi - lo) * 0.12` padding math, or repeated interval addition) — that's
/// both meaningless to a user and, at chart-label sizes, wide enough to force
/// a wrap.
String formatAxisValue(Object? v) {
  if (v is num) {
    if (v == v.roundToDouble() && v.abs() < 1e15) {
      return v.toInt().toString();
    }
    final rounded = double.parse(v.toStringAsFixed(2));
    if (rounded == rounded.roundToDouble() && rounded.abs() < 1e15) {
      return rounded.toInt().toString();
    }
    return rounded.toString();
  }
  return v?.toString() ?? '';
}

/// y bounds + tick step, with headroom when not explicitly provided.
///
/// The padded bound is snapped OUTWARD to a nice round number (never inward —
/// an explicit [yMin]/[yMax] is a floor/ceiling, snapping only ever widens
/// it), and the tick step is returned alongside so callers can hand fl_chart
/// an explicit `interval` instead of letting it invent its own (which need
/// not land on a round number either).
(double, double, double) yBounds(
    List<double> points, double? yMin, double? yMax) {
  var lo = points.reduce((a, b) => a < b ? a : b);
  var hi = points.reduce((a, b) => a > b ? a : b);
  if (lo == hi) {
    // Flat series — pad so the line/bar is visible.
    lo = lo - 1;
    hi = hi + 1;
  } else {
    final pad = (hi - lo) * 0.12;
    lo -= pad;
    hi += pad;
  }
  var resolvedLo = yMin ?? lo;
  var resolvedHi = yMax ?? hi;
  if (resolvedLo == resolvedHi) {
    resolvedLo -= 1;
    resolvedHi += 1;
  }
  // Aim for ~4-5 ticks; the step itself is snapped to a nice value so the
  // ticks it produces (resolvedLo/Hi rounded to multiples of it) are too.
  final step = niceStep((resolvedHi - resolvedLo) / 4, roundUp: true);
  final niceLo = (resolvedLo / step).floor() * step;
  final niceHi = (resolvedHi / step).ceil() * step;
  return (niceLo, niceHi, step);
}

/// Left-axis reserved width, sized to fit the WIDEST formatted tick label at
/// this text's font size. A fixed 32px was exactly what turned a wide label
/// into a wrapped two-line mess — this measures the actual text instead of
/// guessing, so a future wide label (a big calorie total, a negative delta)
/// can never repeat the bug.
double axisReservedSize(double lo, double hi, {double fontSize = 9}) {
  final widest = [lo, hi]
      .map(formatAxisValue)
      .reduce((a, b) => a.length >= b.length ? a : b);
  final painter = TextPainter(
    text: TextSpan(text: widest, style: TextStyle(fontSize: fontSize)),
    textDirection: TextDirection.ltr,
  )..layout();
  // +6 matches the label's own `EdgeInsets.only(right: 6)`; +4 slack so
  // digits never brush the plot area. Clamped so a single stray huge number
  // can't blow out the chart's layout either.
  return (painter.width + 10).clamp(28.0, 56.0);
}
