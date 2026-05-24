import 'package:flutter/material.dart';

import '../../data/models/hormonal_health.dart';

/// A reusable, chart-agnostic overlay that shades menstrual / follicular /
/// fertile / luteal cycle-phase **columns** behind any time-series chart, plus
/// a compact tappable legend.
///
/// Why a `Positioned.fill` `CustomPaint` and not `fl_chart`'s native
/// `RangeAnnotation`: the consumer charts in Zealova are a mix of
/// `LineChart`, `BarChart` and bespoke painters, and several do not even use
/// an `x` axis expressed in epoch-days. A pure paint layer keyed off the
/// chart's visible *date* range drops cleanly behind ALL of them with one
/// API — the caller wraps its chart in a [Stack] and inserts
/// [CyclePhaseChartOverlay] as the first (lowest) child. (MacroFactor 1.1,
/// 1.8, 1.18.)
///
/// The overlay is a **clean no-op** when cycle tracking is not in use: pass a
/// null [prediction] (or one with no `lastPeriodStart`) and nothing paints.
/// Callers should additionally gate the whole [Stack] on
/// `hasHormonalTrackingProvider` so the legend never appears for users who do
/// not track a cycle.
///
/// Phase columns are derived deterministically from the [CyclePrediction]
/// (the same prediction the Cycle screen renders) by walking back/forward in
/// whole cycles from `lastPeriodStart`, so the overlay covers history *and*
/// the near future without needing a separate per-row phase tag.
class CyclePhaseChartOverlay extends StatelessWidget {
  /// The cycle prediction driving the phase boundaries. When null the overlay
  /// paints nothing (no-op for users without cycle tracking).
  final CyclePrediction? prediction;

  /// First date visible on the chart's x-axis (inclusive).
  final DateTime rangeStart;

  /// Last date visible on the chart's x-axis (inclusive).
  final DateTime rangeEnd;

  /// Left inset of the plotting area inside the chart widget, in logical
  /// pixels. Charts reserve space for their y-axis labels; pass that width so
  /// the shaded columns line up with the data, not the axis gutter.
  final double leftPadding;

  /// Right inset of the plotting area.
  final double rightPadding;

  /// Top inset of the plotting area (space above the bars/line).
  final double topPadding;

  /// Bottom inset of the plotting area (space reserved for x-axis labels).
  final double bottomPadding;

  /// Opacity applied to every phase band. Kept low so the chart data stays
  /// the visual focus.
  final double bandOpacity;

  /// When non-null AND `Theme.of(context).brightness == Brightness.dark`, this
  /// value is used in place of [bandOpacity]. Dark surfaces eat low-alpha
  /// fills — callers can bump to ~0.20 for legibility without affecting light
  /// theme.
  final double? darkModeBandOpacity;

  /// When true, paint ONLY menstrual phase bands (drop follicular / fertile /
  /// luteal). Used by long-range trend charts (≥1Y) where four phase bands
  /// per cycle compresses into visual mush; the menstrual-only mode keeps the
  /// overlay legible as a "period markers backdrop".
  final bool coarse;

  /// Optional per-user cycle length (days). When provided, [canRender] uses it
  /// to gate a stale prediction: if `lastPeriodStart` is older than
  /// `2 * avgCycleLength`, no overlay is drawn (no logs in >2 cycles).
  final int? avgCycleLength;

  const CyclePhaseChartOverlay({
    super.key,
    required this.prediction,
    required this.rangeStart,
    required this.rangeEnd,
    this.leftPadding = 0,
    this.rightPadding = 0,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.bandOpacity = 0.13,
    this.darkModeBandOpacity,
    this.coarse = false,
    this.avgCycleLength,
  });

  /// True when a meaningful overlay can be drawn for [prediction].
  ///
  /// Also no-ops when [prediction.lastPeriodStart] is older than
  /// `2 * avgCycleLength` days (i.e. the user has not logged a period in more
  /// than two cycles). Without this gate, [_buildBands] would happily tile
  /// fictional phase bands into the present off a long-stale anchor.
  static bool canRender(
    CyclePrediction? prediction, {
    int? avgCycleLength,
  }) {
    if (prediction == null || prediction.lastPeriodStart == null) return false;
    final cycleLen = (avgCycleLength != null && avgCycleLength >= 21)
        ? avgCycleLength
        : 28;
    final today = DateTime.now();
    final daysSince = today.difference(prediction.lastPeriodStart!).inDays;
    if (daysSince > 2 * cycleLen) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!canRender(prediction, avgCycleLength: avgCycleLength)) {
      return const SizedBox.shrink();
    }

    final bands = _buildBands(prediction!, rangeStart, rangeEnd,
        coarse: coarse);
    if (bands.isEmpty) return const SizedBox.shrink();

    // Bump opacity in dark mode if the caller provided a value — low-alpha
    // fills wash out on dark surfaces.
    final effectiveOpacity = (darkModeBandOpacity != null &&
            Theme.of(context).brightness == Brightness.dark)
        ? darkModeBandOpacity!
        : bandOpacity;

    return Positioned.fill(
      child: IgnorePointer(
        // The overlay is purely decorative — never intercept the chart's
        // own touch/scrub gestures.
        child: CustomPaint(
          painter: _PhaseBandPainter(
            bands: bands,
            rangeStart: _dateOnly(rangeStart),
            rangeEnd: _dateOnly(rangeEnd),
            leftPadding: leftPadding,
            rightPadding: rightPadding,
            topPadding: topPadding,
            bottomPadding: bottomPadding,
            bandOpacity: effectiveOpacity,
          ),
        ),
      ),
    );
  }

  /// Compact legend showing the four phase swatches. Render this next to /
  /// below the chart so the shaded columns are interpretable. Each swatch is
  /// tappable and surfaces a one-line phase description.
  static Widget legend(
    BuildContext context, {
    bool isDark = true,
    bool compact = false,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final phase in CyclePhase.values)
          _LegendChip(phase: phase, isDark: isDark, compact: compact),
      ],
    );
  }

  // ── Phase-band derivation ─────────────────────────────────────────────

  /// Walks whole cycles backward and forward from `lastPeriodStart` to tile
  /// the [rangeStart]..[rangeEnd] window with phase segments. Each cycle is
  /// split menstrual → follicular → ovulation(fertile) → luteal using the
  /// prediction's period length / ovulation offsets.
  static List<_PhaseBand> _buildBands(
    CyclePrediction p,
    DateTime rangeStart,
    DateTime rangeEnd, {
    bool coarse = false,
  }) {
    final anchor = _dateOnly(p.lastPeriodStart!);
    final start = _dateOnly(rangeStart);
    final end = _dateOnly(rangeEnd);
    if (!end.isAfter(start)) return const [];

    // Cycle / period geometry. Fall back to clinically typical values when a
    // field is missing so the overlay still renders for low-data users.
    final cycleLen = _avgCycleLength(p);
    final periodLen = _avgPeriodLength(p);
    final lutealLen = _lutealLength(p, cycleLen);

    final bands = <_PhaseBand>[];

    // Find the cycle index covering [start]. Cycle k begins at
    // anchor + k*cycleLen (k may be negative for history).
    final daysFromAnchor = start.difference(anchor).inDays;
    int k = (daysFromAnchor / cycleLen).floor() - 1;

    // Tile forward until we pass [end]. Capped to avoid pathological loops on
    // an absurd range.
    var guard = 0;
    while (guard++ < 400) {
      final cycleStart = anchor.add(Duration(days: (k * cycleLen).round()));
      final cycleEnd = cycleStart.add(Duration(days: cycleLen));
      if (cycleStart.isAfter(end)) break;

      if (!cycleEnd.isBefore(start)) {
        // Phase boundaries within this cycle.
        final menstrualEnd = cycleStart.add(Duration(days: periodLen));
        // Ovulation ≈ cycleEnd - lutealLen; fertile window = ovulation ± a
        // few days. Keep it a compact 4-day shaded band centred on ovulation.
        final ovulation = cycleEnd.subtract(Duration(days: lutealLen));
        final fertileStart = ovulation.subtract(const Duration(days: 2));
        final fertileEnd = ovulation.add(const Duration(days: 2));

        _addBand(bands, CyclePhase.menstrual, cycleStart, menstrualEnd,
            start, end);
        // Coarse mode (≥1Y ranges): only menstrual bands. Four bands per
        // cycle compress to unreadable mush on wide ranges; the menstrual-
        // only mode keeps the overlay legible as period markers.
        if (!coarse) {
          _addBand(bands, CyclePhase.follicular, menstrualEnd, fertileStart,
              start, end);
          _addBand(bands, CyclePhase.ovulation, fertileStart, fertileEnd,
              start, end);
          _addBand(bands, CyclePhase.luteal, fertileEnd, cycleEnd, start, end);
        }
      }
      k++;
    }
    return bands;
  }

  static void _addBand(
    List<_PhaseBand> out,
    CyclePhase phase,
    DateTime segStart,
    DateTime segEnd,
    DateTime clampStart,
    DateTime clampEnd,
  ) {
    if (!segEnd.isAfter(segStart)) return;
    final s = segStart.isBefore(clampStart) ? clampStart : segStart;
    final e = segEnd.isAfter(clampEnd) ? clampEnd : segEnd;
    if (!e.isAfter(s)) return;
    out.add(_PhaseBand(phase: phase, start: s, end: e));
  }

  static int _avgCycleLength(CyclePrediction p) {
    final v = p.stats.avgCycleLength;
    if (v != null && v >= 21 && v <= 60) return v.round();
    return 28;
  }

  static int _avgPeriodLength(CyclePrediction p) {
    final v = p.stats.avgPeriodLength;
    if (v != null && v >= 2 && v <= 12) return v.round();
    return 5;
  }

  static int _lutealLength(CyclePrediction p, int cycleLen) {
    // Prefer a value implied by the prediction's own ovulation estimate.
    final ov = p.ovulationDate;
    final next = p.nextPeriodDate;
    if (ov != null && next != null) {
      final diff = next.difference(ov).inDays;
      if (diff >= 9 && diff <= 17) return diff;
    }
    // Luteal phase is near-constant ~14d; never longer than the cycle.
    return cycleLen > 16 ? 14 : (cycleLen ~/ 2);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// One contiguous shaded segment of a single phase.
class _PhaseBand {
  final CyclePhase phase;
  final DateTime start;
  final DateTime end;

  const _PhaseBand({
    required this.phase,
    required this.start,
    required this.end,
  });
}

/// Maps a [CyclePhase] to its overlay swatch color. Mirrors the hex codes on
/// [CyclePhaseExtension.color] so the overlay, the Cycle screen ribbon and
/// the legend all agree.
Color cyclePhaseOverlayColor(CyclePhase phase) {
  switch (phase) {
    case CyclePhase.menstrual:
      return const Color(0xFFE57373); // red
    case CyclePhase.follicular:
      return const Color(0xFF81C784); // green
    case CyclePhase.ovulation:
      return const Color(0xFFFFD54F); // amber — most saturated, draws the eye
    case CyclePhase.luteal:
      return const Color(0xFF64B5F6); // blue
  }
}

String _phaseShortLabel(CyclePhase phase) {
  switch (phase) {
    case CyclePhase.menstrual:
      return 'Period';
    case CyclePhase.follicular:
      return 'Follicular';
    case CyclePhase.ovulation:
      return 'Fertile';
    case CyclePhase.luteal:
      return 'Luteal';
  }
}

class _PhaseBandPainter extends CustomPainter {
  final List<_PhaseBand> bands;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double leftPadding;
  final double rightPadding;
  final double topPadding;
  final double bottomPadding;
  final double bandOpacity;

  _PhaseBandPainter({
    required this.bands,
    required this.rangeStart,
    required this.rangeEnd,
    required this.leftPadding,
    required this.rightPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.bandOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalDays = rangeEnd.difference(rangeStart).inDays;
    if (totalDays <= 0) return;

    final plotWidth = size.width - leftPadding - rightPadding;
    final plotHeight = size.height - topPadding - bottomPadding;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    final pxPerDay = plotWidth / totalDays;

    for (final band in bands) {
      final startDay = band.start.difference(rangeStart).inDays;
      final endDay = band.end.difference(rangeStart).inDays;
      final left =
          (leftPadding + startDay * pxPerDay).clamp(leftPadding, size.width);
      final right =
          (leftPadding + endDay * pxPerDay).clamp(leftPadding, size.width);
      if (right <= left) continue;

      final paint = Paint()
        ..color = cyclePhaseOverlayColor(band.phase).withValues(
          // The fertile/ovulation band is slightly more saturated so the eye
          // lands on it, matching the headline temperature chart.
          alpha: band.phase == CyclePhase.ovulation
              ? bandOpacity + 0.06
              : bandOpacity,
        )
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(left, topPadding, right, topPadding + plotHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PhaseBandPainter old) {
    return old.bands.length != bands.length ||
        old.rangeStart != rangeStart ||
        old.rangeEnd != rangeEnd ||
        old.leftPadding != leftPadding ||
        old.rightPadding != rightPadding ||
        old.topPadding != topPadding ||
        old.bottomPadding != bottomPadding ||
        old.bandOpacity != bandOpacity;
  }
}

/// A single tappable legend swatch + label.
class _LegendChip extends StatelessWidget {
  final CyclePhase phase;
  final bool isDark;
  final bool compact;

  const _LegendChip({
    required this.phase,
    required this.isDark,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = cyclePhaseOverlayColor(phase);
    final textColor = isDark ? Colors.white70 : Colors.black54;
    final swatch = compact ? 8.0 : 10.0;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        // A lightweight phase explainer — keeps the overlay self-documenting
        // without depending on the full Cycle screen.
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(phase.displayName),
            content: Text(phase.description),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: swatch,
              height: swatch,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _phaseShortLabel(phase),
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
