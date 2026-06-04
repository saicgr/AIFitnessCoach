import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/providers/week_start_provider.dart';
import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// CalendarHeatmap — GitHub-style 52-week × 7-day grid filled from
/// `data.subMetrics` (treated as activity counts), accent-tinted cells,
/// total + streak chips below. Year-in-review staple.
///
/// [weekStartsSunday] (B11) controls the first day of the week so the
/// day-of-week row labels honor the user's preference. Default false =
/// Monday-first, matching `weekStartsSundayProvider`'s default. Pass
/// `ref.watch(weekStartsSundayProvider)` from the catalog builder.
class CalendarHeatmapTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;
  final bool weekStartsSunday;

  const CalendarHeatmapTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
    this.weekStartsSunday = false,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    // First-day-of-week preference (B11). `WeekDisplayConfig` gives the
    // ordered single-letter day labels (Mon-first: M T W T F S S;
    // Sun-first: S M T W T F S) and the row rotation the painter applies so
    // the data's Monday-relative rows line up under the right label.
    final weekConfig = WeekDisplayConfig.from(weekStartsSunday);
    final hasRealData = _hasEnoughRealData(data);
    final values = hasRealData ? _values(data) : const <int>[];
    // "Active days" = days WITH activity, not the sum of intensity values.
    // Previously summed values which inflated the count by exercise reps —
    // user-facing "818 active days" headline looked completely fake because
    // it was summing all set counts, not counting unique active days.
    final activeDays = values.where((v) => v > 0).length;
    final streakValue = data.highlights
        .firstWhere(
          (h) => h.label.toUpperCase().contains('STREAK'),
          orElse: () => const ShareableMetric(label: '', value: ''),
        )
        .value;

    // Empty-state guard: if upstream adapter didn't fill subMetrics with
    // real activity data (most common on first-day users + on quick-workout
    // shareables that don't carry year-of-history), render a placeholder
    // rather than synthesizing fake fills via the previous deterministic-
    // pattern fallback. Per `feedback_no_silent_fallbacks.md`: never
    // silently fall back to degraded data — surface the empty state.
    if (!hasRealData) {
      return ShareableCanvas(
        aspect: data.aspect,
        accentColor: accent,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 56, color: accent.withValues(alpha: 0.7)),
                const SizedBox(height: 16),
                Text(
                  'Year-in-review unlocks at 30+ logged days',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22 * mul,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Keep showing up — your real heatmap will look way cooler than mock data ever could.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14 * mul,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final total = activeDays;

    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: accent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.periodLabel.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 13 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30 * mul,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sparse labels (every other row) so the column doesn't
                      // crowd, but ordered by the user's first-day-of-week.
                      for (final d in _sparseDayLabels(weekConfig.dayLabels))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.2),
                          child: SizedBox(
                            height: 11,
                            child: Text(
                              d,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 9 * mul,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 52 / 7,
                    child: CustomPaint(
                      painter: _HeatmapPainter(
                        values: values,
                        accent: accent,
                        // displayOrder maps display-row -> data-row so the
                        // Monday-relative intensity vector lines up under the
                        // preference-ordered day labels (B11).
                        displayOrder: weekConfig.displayOrder,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _legend('Less', accent.withValues(alpha: 0.18), mul),
                ...List.generate(4, (i) {
                  final t = (i + 1) / 4;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.25 + t * 0.55),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                _legend('More', accent, mul),
                const Spacer(),
                Text(
                  '$total active days',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12 * mul,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip('TOTAL', '$total', accent, mul),
                if (streakValue.isNotEmpty)
                  _chip('STREAK', streakValue, accent, mul),
                _chip('YEAR', '${DateTime.now().year}', accent, mul),
              ],
            ),
            const SizedBox(height: 22),
            if (showWatermark)
              AppWatermark(
                textColor: Colors.white,
                fontSize: 13 * mul,
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, Color color, double mul) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9 * mul,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _chip(String label, String value, Color accent, double mul) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9 * mul,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * mul,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the 7-row sparse day-label column: show the label on rows
  /// 0, 2, 4 (matching the original M / W / F cadence) and blank the rest so
  /// the column stays uncrowded. `labels` is already ordered by the user's
  /// first-day-of-week (e.g. [M,T,W,T,F,S,S] or [S,M,T,W,T,F,S]).
  List<String> _sparseDayLabels(List<String> labels) {
    return List.generate(
      7,
      (i) => (i.isEven && i < labels.length) ? labels[i] : '',
    );
  }

  /// Returns true only when the adapter provided real per-day data.
  /// Threshold: 30+ subMetric entries so we have enough signal for a
  /// believable visualization. Below that we render the empty-state in
  /// `build()` instead of synthesizing fake fills.
  bool _hasEnoughRealData(Shareable d) => d.subMetrics.length >= 30;

  /// Build a 52*7=364 cell intensity vector from sub-metrics. Only called
  /// after `_hasEnoughRealData` returns true, so we never fall back to the
  /// deterministic synthetic pattern (the source of the previous fake-
  /// looking "818 active days" heatmap).
  List<int> _values(Shareable d) {
    final n = 52 * 7;
    return List.generate(n, (i) {
      if (i < d.subMetrics.length) {
        return int.tryParse(d.subMetrics[i].value
                .replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
      }
      return 0;
    });
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<int> values;
  final Color accent;

  /// display-row index -> data-row index (Mon=0..Sun=6 in the source vector).
  /// Monday-first = [0..6]; Sunday-first = [6,0,1,2,3,4,5].
  final List<int> displayOrder;

  _HeatmapPainter({
    required this.values,
    required this.accent,
    this.displayOrder = const [0, 1, 2, 3, 4, 5, 6],
  });

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 52;
    const rows = 7;
    const gap = 2.0;
    final cellW = (size.width - gap * (cols - 1)) / cols;
    final cellH = (size.height - gap * (rows - 1)) / rows;
    final cell = math.min(cellW, cellH);
    final radius = Radius.circular(cell * 0.18);
    final paint = Paint();
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        // r is the DISPLAY row; map it to the source data row so Sunday-first
        // pulls Sunday (data row 6) to the top (B11).
        final dataRow = r < displayOrder.length ? displayOrder[r] : r;
        final idx = c * rows + dataRow;
        final v = idx < values.length ? values[idx] : 0;
        if (v == 0) {
          paint.color = Colors.white.withValues(alpha: 0.05);
        } else {
          final t = (v / 4).clamp(0.0, 1.0);
          paint.color = accent.withValues(alpha: 0.25 + t * 0.55);
        }
        final x = c * (cell + gap);
        final y = r * (cell + gap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cell, cell), radius),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      old.values != values ||
      old.accent != accent ||
      old.displayOrder != displayOrder;
}
