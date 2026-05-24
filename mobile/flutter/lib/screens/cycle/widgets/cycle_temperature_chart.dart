/// The headline Oura-style interactive basal-body-temperature (BBT) chart.
///
/// Built on `fl_chart` `LineChart`, composed in layers (see the planning doc
/// "The headline temperature graph"):
///   1. Phase background bands (menstrual / follicular / fertile / luteal)
///   2. The BBT temperature line — real points as dots, true gaps for
///      missing days, a lighter dashed predicted continuation.
///   3. Markers & guide lines — the cover line, a vertical "today" line, an
///      ovulation marker (hollow = estimated, filled = thermally confirmed),
///      period-start flags.
///   4. An interactive drag-scrub crosshair with a rich floating callout +
///      a haptic tick on each day crossed.
///
/// Range control: This cycle / Last 3 cycles (ghost overlay) / All.
/// Before any BBT is logged the temperature layer is replaced by an
/// educational empty state while bands + markers still render.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/hormonal_health.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/charts/cycle_phase_chart_overlay.dart';
import '../cycle_visuals.dart';

/// One BBT reading projected onto the chart's day axis.
class CycleBbtSample {
  /// Calendar date of the reading (local-midnight).
  final DateTime date;

  /// Canonical-Celsius temperature.
  final double celsius;

  /// Cycle day on that date (1-based), or null when outside a known cycle.
  final int? cycleDay;

  /// Symptoms / mood logged that day, for the scrub callout.
  final List<String> symptoms;

  const CycleBbtSample({
    required this.date,
    required this.celsius,
    this.cycleDay,
    this.symptoms = const [],
  });
}

/// Selectable history range for the chart.
enum CycleChartRange { thisCycle, last3, all }

extension CycleChartRangeLabel on CycleChartRange {
  String get label {
    switch (this) {
      case CycleChartRange.thisCycle:
        return 'This cycle';
      case CycleChartRange.last3:
        return 'Last 3';
      case CycleChartRange.all:
        return 'All';
    }
  }
}

class CycleTemperatureChart extends StatefulWidget {
  /// All BBT samples available (any range); the widget windows them itself.
  final List<CycleBbtSample> samples;

  /// The current prediction — supplies phase bands, cover line, ovulation
  /// marker and period-start flags. May be null (renders the empty state).
  final CyclePrediction? prediction;

  /// Pink feature accent (chrome / CTAs).
  final Color accent;

  /// Whether to render temperatures in Fahrenheit (user default).
  final bool fahrenheit;

  /// Invoked when the user taps the scrub callout — opens that day's log.
  final void Function(CycleBbtSample sample)? onDayTap;

  /// Invoked from the callout's "Ask coach about this day" affordance.
  final void Function(CycleBbtSample sample)? onAskCoach;

  const CycleTemperatureChart({
    super.key,
    required this.samples,
    required this.prediction,
    required this.accent,
    required this.fahrenheit,
    this.onDayTap,
    this.onAskCoach,
  });

  @override
  State<CycleTemperatureChart> createState() => _CycleTemperatureChartState();
}

class _CycleTemperatureChartState extends State<CycleTemperatureChart> {
  CycleChartRange _range = CycleChartRange.thisCycle;

  /// Index of the day currently under the scrub crosshair, or null.
  int? _scrubIndex;

  /// Last day index a haptic tick fired for (so we tick once per day).
  int? _lastTickIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    final windowed = _windowedSamples();
    final hasData = windowed.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat_rounded,
                  size: 18, color: widget.accent),
              const SizedBox(width: 8),
              Text(
                'Basal temperature',
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _RangeControl(
                range: _range,
                accent: widget.accent,
                fg: fg,
                onChanged: (r) {
                  HapticService.selection();
                  setState(() {
                    _range = r;
                    _scrubIndex = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasData)
            _EmptyChartShell(
              fg: fg,
              accent: widget.accent,
              prediction: widget.prediction,
              isDark: isDark,
            )
          else
            _buildChart(context, windowed, fg, isDark),
          const SizedBox(height: 10),
          _Legend(fg: fg),
        ],
      ),
    );
  }

  // ── Sample windowing ──────────────────────────────────────────────────

  List<CycleBbtSample> _windowedSamples() {
    final all = [...widget.samples]..sort((a, b) => a.date.compareTo(b.date));
    if (all.isEmpty) return const [];
    switch (_range) {
      case CycleChartRange.all:
        return all;
      case CycleChartRange.last3:
        // ~3 cycles ≈ 90 days back from the newest sample.
        final cutoff =
            all.last.date.subtract(const Duration(days: 90));
        return all.where((s) => !s.date.isBefore(cutoff)).toList();
      case CycleChartRange.thisCycle:
        final lastStart = widget.prediction?.lastPeriodStart;
        if (lastStart == null) {
          final cutoff =
              all.last.date.subtract(const Duration(days: 35));
          return all.where((s) => !s.date.isBefore(cutoff)).toList();
        }
        return all.where((s) => !s.date.isBefore(lastStart)).toList();
    }
  }

  // ── Chart ─────────────────────────────────────────────────────────────

  Widget _buildChart(
    BuildContext context,
    List<CycleBbtSample> samples,
    Color fg,
    bool isDark,
  ) {
    final f = widget.fahrenheit;

    // Build spots; missing days are true gaps (fl_chart breaks the line when
    // a spot is absent — we only add spots for days with a reading).
    final firstDate = samples.first.date;
    double xFor(DateTime d) =>
        d.difference(firstDate).inDays.toDouble();

    final spots = <FlSpot>[];
    for (final s in samples) {
      spots.add(FlSpot(xFor(s.date), CycleTemp.display(s.celsius, fahrenheit: f)));
    }

    // Y bounds from the data with margin, clamped to plausible BBT band.
    final temps = spots.map((s) => s.y).toList();
    var yMin = temps.reduce((a, b) => a < b ? a : b);
    var yMax = temps.reduce((a, b) => a > b ? a : b);
    final cover = widget.prediction?.coverLineCelsius;
    if (cover != null) {
      final c = CycleTemp.display(cover, fahrenheit: f);
      yMin = yMin < c ? yMin : c;
      yMax = yMax > c ? yMax : c;
    }
    final pad = (yMax - yMin).clamp(0.4, 4.0) * 0.25;
    yMin -= pad;
    yMax += pad;

    final maxX = spots.last.x;
    final minX = spots.first.x;
    final span = (maxX - minX).clamp(1.0, double.infinity);

    // Phase background bands.
    final bands = _phaseBands(firstDate, minX, maxX, isDark);

    // Guide lines: cover line + today line.
    final hLines = <HorizontalLine>[];
    if (cover != null) {
      hLines.add(HorizontalLine(
        y: CycleTemp.display(cover, fahrenheit: f),
        color: CyclePhaseColors.luteal,
        strokeWidth: 1.4,
        dashArray: [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          style: TextStyle(
            color: CyclePhaseColors.luteal,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
          labelResolver: (_) => 'Cover line',
        ),
      ));
    }
    final vLines = <VerticalLine>[];
    final today = CycleDates.dateOnly(DateTime.now());
    final todayX = xFor(today);
    if (todayX >= minX && todayX <= maxX) {
      vLines.add(VerticalLine(
        x: todayX,
        color: widget.accent.withValues(alpha: 0.8),
        strokeWidth: 1.4,
        label: VerticalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          style: TextStyle(
            color: widget.accent,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
          labelResolver: (_) => 'Today',
        ),
      ));
    }
    // Ovulation marker line.
    final ovu = widget.prediction?.ovulationDate;
    if (ovu != null) {
      final ox = xFor(CycleDates.dateOnly(ovu));
      if (ox >= minX && ox <= maxX) {
        final confirmed = widget.prediction?.isOvulationConfirmed ?? false;
        vLines.add(VerticalLine(
          x: ox,
          color: CyclePhaseColors.ovulation
              .withValues(alpha: confirmed ? 0.95 : 0.5),
          strokeWidth: confirmed ? 2.0 : 1.2,
          dashArray: confirmed ? null : [4, 4],
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.bottomRight,
            style: TextStyle(
              color: CyclePhaseColors.ovulation,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
            labelResolver: (_) =>
                confirmed ? 'Ovulation ✓' : 'Ovulation ~',
          ),
        ));
      }
    }
    // Scrub crosshair.
    if (_scrubIndex != null &&
        _scrubIndex! >= 0 &&
        _scrubIndex! < samples.length) {
      vLines.add(VerticalLine(
        x: spots[_scrubIndex!].x,
        color: fg.withValues(alpha: 0.45),
        strokeWidth: 1.0,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scrub callout (above the chart so it never clips).
        SizedBox(
          height: 78,
          child: _scrubIndex != null &&
                  _scrubIndex! >= 0 &&
                  _scrubIndex! < samples.length
              ? _ScrubCallout(
                  sample: samples[_scrubIndex!],
                  prediction: widget.prediction,
                  fahrenheit: f,
                  accent: widget.accent,
                  fg: fg,
                  isDark: isDark,
                  onTap: () => widget.onDayTap?.call(samples[_scrubIndex!]),
                  onAskCoach: widget.onAskCoach == null
                      ? null
                      : () => widget.onAskCoach!(samples[_scrubIndex!]),
                )
              : Center(
                  child: Text(
                    'Drag across the chart to inspect any day',
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 200,
          child: RepaintBoundary(
            child: GestureDetector(
              onHorizontalDragStart: (d) =>
                  _onScrub(d.localPosition, samples, minX, span),
              onHorizontalDragUpdate: (d) =>
                  _onScrub(d.localPosition, samples, minX, span),
              onHorizontalDragEnd: (_) {
                _lastTickIndex = null;
              },
              onTapUp: (d) => _onScrub(d.localPosition, samples, minX, span),
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: yMin,
                  maxY: yMax,
                  lineTouchData: const LineTouchData(enabled: false),
                  rangeAnnotations:
                      RangeAnnotations(verticalRangeAnnotations: bands),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: hLines,
                    verticalLines: vLines,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        ((yMax - yMin) / 4).clamp(0.05, double.infinity),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: fg.withValues(alpha: 0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: ((yMax - yMin) / 4)
                            .clamp(0.05, double.infinity),
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toStringAsFixed(f ? 1 : 2),
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.4),
                              fontSize: 9,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: (span / 5).clamp(1.0, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final d = firstDate
                              .add(Duration(days: value.round()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              CycleDates.medium(d),
                              style: TextStyle(
                                color: fg.withValues(alpha: 0.4),
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.28,
                      preventCurveOverShooting: true,
                      color: widget.accent,
                      barWidth: 2.6,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, pct, bar, idx) {
                          final isScrub = _scrubIndex == idx;
                          return FlDotCirclePainter(
                            radius: isScrub ? 5 : 3,
                            color: widget.accent,
                            strokeWidth: isScrub ? 2.4 : 1.4,
                            strokeColor: isDark
                                ? Colors.black
                                : Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: widget.accent.withValues(alpha: 0.10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 420.ms).slideY(
              begin: 0.08,
              end: 0,
              duration: 420.ms,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }

  /// Build the four phase background bands for the visible window.
  List<VerticalRangeAnnotation> _phaseBands(
    DateTime firstDate,
    double minX,
    double maxX,
    bool isDark,
  ) {
    final p = widget.prediction;
    if (p == null || p.lastPeriodStart == null) return const [];
    double xFor(DateTime d) =>
        CycleDates.dateOnly(d).difference(firstDate).inDays.toDouble();

    final bands = <VerticalRangeAnnotation>[];
    void band(DateTime start, DateTime end, Color color, double alpha) {
      final x1 = xFor(start).clamp(minX, maxX);
      final x2 = xFor(end).clamp(minX, maxX);
      if (x2 <= x1) return;
      bands.add(VerticalRangeAnnotation(
        x1: x1,
        x2: x2,
        color: color.withValues(alpha: alpha),
      ));
    }

    final lastStart = p.lastPeriodStart!;
    final periodLen = p.stats.avgPeriodLength?.round() ?? 5;
    final periodEnd = lastStart.add(Duration(days: periodLen - 1));
    band(lastStart, periodEnd, CyclePhaseColors.menstrual, 0.16);

    final fStart = p.fertileWindowStart;
    final fEnd = p.fertileWindowEnd;
    if (fStart != null && fEnd != null) {
      band(periodEnd, fStart, CyclePhaseColors.follicular, 0.10);
      // Fertile window is the most saturated so the eye lands there.
      band(fStart, fEnd, CyclePhaseColors.ovulation, 0.22);
      final next = p.nextPeriodDate;
      if (next != null) {
        band(fEnd, next, CyclePhaseColors.luteal, 0.12);
      }
    }
    return bands;
  }

  /// Resolve the nearest day index from a horizontal scrub position and fire
  /// a haptic tick when the day under the finger changes.
  void _onScrub(
    Offset local,
    List<CycleBbtSample> samples,
    double minX,
    double span,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    // The chart occupies the full card width minus the left axis (~38px).
    final width = box.size.width - 32; // card horizontal padding
    const leftAxis = 38.0;
    final plotWidth = (width - leftAxis).clamp(1.0, double.infinity);
    final dx = (local.dx - leftAxis).clamp(0.0, plotWidth);
    final frac = dx / plotWidth;
    final targetX = minX + frac * span;

    // Nearest sample by x.
    int nearest = 0;
    double best = double.infinity;
    final firstDate = samples.first.date;
    for (var i = 0; i < samples.length; i++) {
      final x = samples[i].date.difference(firstDate).inDays.toDouble();
      final dist = (x - targetX).abs();
      if (dist < best) {
        best = dist;
        nearest = i;
      }
    }
    if (nearest != _lastTickIndex) {
      HapticService.selection();
      _lastTickIndex = nearest;
    }
    if (nearest != _scrubIndex) {
      setState(() => _scrubIndex = nearest);
    }
  }
}

// ── Range control ────────────────────────────────────────────────────────

class _RangeControl extends StatelessWidget {
  final CycleChartRange range;
  final Color accent;
  final Color fg;
  final ValueChanged<CycleChartRange> onChanged;

  const _RangeControl({
    required this.range,
    required this.accent,
    required this.fg,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: CycleChartRange.values.map((r) {
          final selected = r == range;
          return GestureDetector(
            onTap: () => onChanged(r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                r.label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : fg.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Scrub callout ────────────────────────────────────────────────────────

class _ScrubCallout extends StatelessWidget {
  final CycleBbtSample sample;
  final CyclePrediction? prediction;
  final bool fahrenheit;
  final Color accent;
  final Color fg;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onAskCoach;

  const _ScrubCallout({
    required this.sample,
    required this.prediction,
    required this.fahrenheit,
    required this.accent,
    required this.fg,
    required this.isDark,
    this.onTap,
    this.onAskCoach,
  });

  @override
  Widget build(BuildContext context) {
    final phase = prediction == null
        ? null
        : cyclePhaseForDate(prediction!, sample.date);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CyclePhaseColors.of(phase)
              .withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(CyclePhaseColors.emoji(phase),
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${CycleDates.withWeekday(sample.date)}'
                    '${sample.cycleDay != null ? ' · Day ${sample.cycleDay}' : ''}',
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${CycleTemp.format(sample.celsius, fahrenheit: fahrenheit)}'
                    '${phase != null ? ' · ${phase.displayName}' : ''}'
                    '${sample.symptoms.isNotEmpty ? ' · ${sample.symptoms.take(2).join(', ')}' : ''}',
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onAskCoach != null)
              GestureDetector(
                onTap: onAskCoach,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 12, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        'Ask',
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Legend ───────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final Color fg;
  const _Legend({required this.fg});

  @override
  Widget build(BuildContext context) {
    Widget chip(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: fg.withValues(alpha: 0.55), fontSize: 10)),
          ],
        );
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        chip(CyclePhaseColors.menstrual, 'Menstrual'),
        chip(CyclePhaseColors.follicular, 'Follicular'),
        chip(CyclePhaseColors.ovulation, 'Fertile'),
        chip(CyclePhaseColors.luteal, 'Luteal'),
      ],
    );
  }
}

// ── Empty chart shell (Oura-style — phase bands + baseline + overlay) ───

/// When no BBT samples exist, we still render the chart chrome (phase-band
/// background + faint baseline) and overlay a compact educational message
/// + CTA on top. This avoids the "come back later" placeholder feel; the
/// user sees an empty-but-real chart they understand how to fill.
class _EmptyChartShell extends StatelessWidget {
  final Color fg;
  final Color accent;
  final CyclePrediction? prediction;
  final bool isDark;

  const _EmptyChartShell({
    required this.fg,
    required this.accent,
    required this.prediction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Anchor the overlay to a 35-day window ending today so phase bands
    // align with the visible chart even though we have no temperature data.
    final today = CycleDates.dateOnly(DateTime.now());
    final rangeStart = today.subtract(const Duration(days: 28));
    final rangeEnd = today.add(const Duration(days: 6));

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          // Phase-band background — no-ops cleanly when prediction is null
          // or has no anchor.
          if (CyclePhaseChartOverlay.canRender(prediction))
            CyclePhaseChartOverlay(
              prediction: prediction,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
              bandOpacity: isDark ? 0.18 : 0.12,
            ),
          // Faint baseline across the vertical center.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BaselinePainter(
                  color: fg.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          // Educational overlay — slightly smaller than the original
          // placeholder so the shell behind it stays visible.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thermostat_rounded,
                      size: 26, color: accent.withValues(alpha: 0.85)),
                  const SizedBox(height: 6),
                  Text(
                    'Log basal temperature to fill this chart',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Take it first thing each morning. After ovulation it '
                    'rises ~0.5°F — a few readings confirm the shift.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.6),
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 360.ms);
  }
}

/// Faint horizontal baseline through the vertical center of the chart shell.
class _BaselinePainter extends CustomPainter {
  final Color color;
  const _BaselinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    // Dashed line.
    const dash = 6.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_BaselinePainter old) => old.color != color;
}
