import 'package:flutter/material.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/timeline_entry.dart';

/// A compact strip of the selected day's headline totals, drawn as small
/// labeled pills under the trend rail. Only non-zero metrics are shown, so an
/// empty/early day shows nothing rather than a row of zeros. Wraps on narrow
/// screens (iPhone SE) instead of overflowing.
class TimelineTotalsStrip extends StatelessWidget {
  final TimelineSummary summary;
  final ThemeColors c;

  /// Real sleep minutes for the selected day, sourced from Health Connect
  /// (`sleepHistoryProvider`) rather than `summary.sleepMinutes` — the backend
  /// aggregator has no sleep table, so the summary value is unreliable. Null
  /// (or 0) hides the sleep pill.
  final int? sleepMinutes;

  const TimelineTotalsStrip({
    super.key,
    required this.summary,
    required this.c,
    this.sleepMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[];

    void add(String text, Color tint) =>
        pills.add(_Pill(text: text, tint: tint, c: c));

    final calIn = summary.caloriesEaten;
    final calOut = summary.caloriesBurned;
    final net = summary.caloriesNet;

    if (calIn > 0) add('${_thousands(calIn)} in', c.success);
    if (calOut > 0) add('${_thousands(calOut)} out', c.warning);
    // Net only adds signal when there's both an intake and a burn.
    if (calIn > 0 && calOut > 0) {
      add('${net >= 0 ? '+' : ''}${_thousands(net)} net',
          net <= 0 ? c.success : c.textSecondary);
    }
    if (summary.waterMl > 0) {
      final goal = summary.waterGoalMl;
      add(
        goal > 0
            ? '${(summary.waterMl / 1000).toStringAsFixed(1)}/${(goal / 1000).toStringAsFixed(1)}L'
            : '${(summary.waterMl / 1000).toStringAsFixed(1)}L',
        c.info,
      );
    }
    final sleepM = (sleepMinutes ?? 0) > 0 ? sleepMinutes! : summary.sleepMinutes;
    if (sleepM > 0) add('${_duration(sleepM)} sleep', c.cyan);

    if (pills.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: pills,
    );
  }

  static String _duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String _thousands(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${v < 0 ? '-' : ''}$buf';
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color tint;
  final ThemeColors c;
  const _Pill({required this.text, required this.tint, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
