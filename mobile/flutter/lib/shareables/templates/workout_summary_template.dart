import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// Apple Watch–style workout summary card.
///
/// Renders a near-black canvas with a top metadata block (workout title +
/// activity-type pill, optional time range + location) and a 2-column grid
/// of stat cells below. Each stat's numeric value is colored by metric type
/// to mirror the Watch summary aesthetic (heart rate red-pink, calories
/// orange, pace green, distance coral, duration white, elevation tan).
///
/// Color routing is deliberately label-driven — we don't need adapters to
/// pre-set [ShareableMetric.accent] for the common cases. Adapters can
/// override per-cell color by populating `metric.accent` and the template
/// will respect it.
class WorkoutSummaryTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WorkoutSummaryTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  // Apple Watch color palette — matched to the reference screenshot.
  // Kept module-private so adapters can't accidentally diverge; if you
  // need a new color, add a label here, don't hardcode in adapters.
  static const Color _heartRate = Color(0xFFFF375F);
  static const Color _caloriesOrange = Color(0xFFFF6B00);
  static const Color _distance = Color(0xFFFF375F);
  static const Color _pace = Color(0xFF30D158);
  static const Color _elevation = Color(0xFFAC8E68);
  static const Color _duration = Colors.white;
  static const Color _defaultValueColor = Colors.white;

  /// Pure black-ish background — matches Apple Watch summary screenshot.
  /// We override the canvas's accent-tinted gradient because the Watch
  /// look is intentionally flat/dark, not gradient-tinted.
  static const List<Color> _watchBackground = [
    Color(0xFF0A0A0A),
    Color(0xFF111111),
    Color(0xFF0A0A0A),
  ];

  /// Heuristic: pick a value color from the metric's label. Case-
  /// insensitive substring match so "Avg. Heart Rate", "Heart Rate",
  /// "HR avg" all map to the same red-pink. Adapters can override by
  /// setting `metric.accent` directly — that always wins.
  Color _colorForMetric(ShareableMetric m) {
    if (m.accent != null) return m.accent!;
    final l = m.label.toLowerCase();
    if (l.contains('heart') || l.contains('hr') || l.contains('bpm')) {
      return _heartRate;
    }
    if (l.contains('calorie') || l.contains('cal') || l.contains('kcal') ||
        l.contains('energy')) {
      return _caloriesOrange;
    }
    if (l.contains('pace') || l.contains('speed') || l.contains('tempo')) {
      return _pace;
    }
    if (l.contains('distance') || l.contains('miles') || l.contains('km') ||
        l.contains('mi')) {
      return _distance;
    }
    if (l.contains('elevation') || l.contains('elev') || l.contains('climb') ||
        l.contains('gain')) {
      return _elevation;
    }
    if (l.contains('time') || l.contains('duration')) {
      return _duration;
    }
    return _defaultValueColor;
  }

  @override
  Widget build(BuildContext context) {
    final aspect = data.aspect;
    final mul = aspect.bodyFontMultiplier;

    // Filter to populated highlights only — we never render placeholder
    // bars (per the Shareable contract). Cap at 8 so the grid stays at
    // most 4 rows × 2 cols on story aspect.
    final metrics = data.highlights
        .where((h) => h.isPopulated)
        .take(8)
        .toList();

    // Pull optional secondary metadata from subMetrics — adapters can
    // attach a "TIME" entry (value = "12:54 PM - 2:04 PM") and a
    // "LOCATION" entry (value = "Los Angeles") if available. Both are
    // optional — missing fields just suppress the row.
    String? timeRange;
    String? location;
    for (final m in data.subMetrics) {
      final l = m.label.toLowerCase();
      if (timeRange == null && (l.contains('time range') || l == 'time')) {
        timeRange = m.value;
      } else if (location == null && l.contains('location')) {
        location = m.value;
      }
    }

    // Activity-type pill: use periodLabel as the secondary chip when it
    // looks like a workout type (short, not a date range). Falls back to
    // a generic "WORKOUT" tag when periodLabel reads like a date.
    final pill = _activityPillText(data);

    return ShareableCanvas(
      aspect: aspect,
      accentColor: data.accentColor,
      backgroundOverride: _watchBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 56, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: workout title ────────────────────────────────
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 34 * mul,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            // ─── Activity-type pill ───────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Text(
                pill,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11 * mul,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (timeRange != null) ...[
              Text(
                timeRange,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 14 * mul,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (location != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_location_alt_outlined,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13 * mul,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 28),
            // ─── Stats grid ───────────────────────────────────────────
            Expanded(
              child: metrics.isEmpty
                  ? const SizedBox.shrink()
                  : _StatsGrid(
                      metrics: metrics,
                      colorOf: _colorForMetric,
                      fontMultiplier: mul,
                    ),
            ),
            const SizedBox(height: 12),
            // ─── Watermark ────────────────────────────────────────────
            if (showWatermark)
              Align(
                alignment: Alignment.centerLeft,
                child: AppWatermark(textColor: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  /// Pick a short label for the activity pill. Heuristic only: if the
  /// `periodLabel` looks like a date (contains digits), bias to the
  /// `kind`-derived fallback ("WORKOUT") so we don't render a date inside
  /// what should be an activity-type tag.
  String _activityPillText(Shareable data) {
    final candidate = data.periodLabel.trim();
    if (candidate.isEmpty || RegExp(r'\d').hasMatch(candidate)) {
      // Date-like → fall back to a kind-derived label.
      switch (data.kind) {
        case ShareableKind.workoutComplete:
          return 'WORKOUT';
        case ShareableKind.weeklyProgress:
        case ShareableKind.weeklySummary:
          return 'WEEK';
        case ShareableKind.statsOverview:
          return 'SESSION';
        default:
          return 'ACTIVITY';
      }
    }
    return candidate.toUpperCase();
  }
}

/// 2-column stats grid. Cells render label + colored value; if [unit]
/// can be split off (last token, all-caps short suffix) we lay it out
/// inline at a smaller weight so the value reads like the Watch
/// "240CAL" / "22'49\"/MI" treatment.
class _StatsGrid extends StatelessWidget {
  final List<ShareableMetric> metrics;
  final Color Function(ShareableMetric) colorOf;
  final double fontMultiplier;

  const _StatsGrid({
    required this.metrics,
    required this.colorOf,
    required this.fontMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    // 2 columns. Build pairs row-wise so an odd count still lays out
    // cleanly (single cell on the last row).
    final rows = <Widget>[];
    for (int i = 0; i < metrics.length; i += 2) {
      final left = metrics[i];
      final right = i + 1 < metrics.length ? metrics[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Cell(
                  metric: left,
                  color: colorOf(left),
                  fontMultiplier: fontMultiplier,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _Cell(
                        metric: right,
                        color: colorOf(right),
                        fontMultiplier: fontMultiplier,
                      ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

class _Cell extends StatelessWidget {
  final ShareableMetric metric;
  final Color color;
  final double fontMultiplier;

  const _Cell({
    required this.metric,
    required this.color,
    required this.fontMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    final value = metric.value.trim().isEmpty ? '—' : metric.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12 * fontMultiplier,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 30 * fontMultiplier,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
