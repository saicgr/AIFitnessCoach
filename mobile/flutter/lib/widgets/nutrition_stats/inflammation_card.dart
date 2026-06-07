import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/nutrition.dart';
import '../../data/providers/nutrition_stats_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../screens/nutrition/widgets/inflammation_chip.dart';

/// "Inflammation" card for the NUTRITION STATS section.
///
/// Two honest, real-data panels in one card:
///  1. TODAY — a calorie-weighted daily inflammation score (0-10) on a graded
///     horizontal meter, plus the foods driving it. Computed client-side from
///     today's logs (each [FoodLog] carries `inflammationScore`) so it updates
///     the instant a meal is logged — no extra network call.
///  2. THIS WEEK — a 7-day mini trend from [weeklyInflammationProvider] (rides
///     on the same weekly payload the calorie trend uses).
///
/// Never fabricates: foods with a null score (enrichment pending) are excluded
/// from the average rather than counted as 0, and an all-null day shows an
/// explicit "log more to see this" state instead of a fake "perfect" reading.
class InflammationCard extends ConsumerWidget {
  final String userId;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const InflammationCard({
    super.key,
    required this.userId,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Today's logs drive the daily meter — recomputes on every log.
    final todayLogs = ref.watch(
        dailyNutritionProvider(todayNutritionKey()).select((s) => s.logs));
    final scored = todayLogs.where((l) => l.inflammationScore != null).toList();

    double? dailyScore;
    final contributors = <String>[];
    if (scored.isNotEmpty) {
      final weight =
          scored.fold<double>(0, (s, l) => s + (l.totalCalories.toDouble()));
      if (weight > 0) {
        dailyScore = scored.fold<double>(
                0, (s, l) => s + l.inflammationScore! * l.totalCalories) /
            weight;
      } else {
        dailyScore =
            scored.fold<double>(0, (s, l) => s + l.inflammationScore!) /
                scored.length;
      }
      final ranked = [...scored]
        ..sort((a, b) => b.inflammationScore!.compareTo(a.inflammationScore!));
      final seen = <String>{};
      for (final l in ranked) {
        final name = _logName(l);
        if (name != null && seen.add(name)) contributors.add(name);
        if (contributors.length >= 3) break;
      }
    }

    final weekly = ref.watch(weeklyInflammationProvider(userId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Inflammation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              if (dailyScore != null)
                InflammationChip(
                  score: dailyScore.round(),
                  triggers: contributors,
                  compact: false,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (dailyScore == null)
            _emptyToday()
          else ...[
            _Meter(score: dailyScore, isDark: isDark),
            const SizedBox(height: 10),
            Text(
              _dailyLine(dailyScore, contributors),
              style: TextStyle(fontSize: 12.5, height: 1.35, color: textMuted),
            ),
            if (contributors.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: contributors
                    .map((c) => _ContributorChip(label: c, isDark: isDark))
                    .toList(),
              ),
            ],
          ],
          // 7-day trend.
          weekly.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 16),
              child: SkeletonBox(height: 56, radius: 10),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (w) {
              if (w == null || w.daysWithScore < 2) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _WeekTrend(
                  series: w.series,
                  weekAverage: w.weekAverage,
                  isDark: isDark,
                  textMuted: textMuted,
                  textSecondary: textSecondary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyToday() {
    return Row(
      children: [
        Icon(Icons.local_fire_department_outlined, size: 18, color: textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'No inflammation scores yet today. Log a meal and its '
            'anti-inflammatory rating shows up here.',
            style: TextStyle(fontSize: 13, height: 1.3, color: textMuted),
          ),
        ),
      ],
    );
  }

  static String? _logName(FoodLog l) {
    final q = l.userQuery?.trim();
    if (q != null && q.isNotEmpty) return q;
    if (l.foodItems.isNotEmpty) {
      final n = l.foodItems.first.name.trim();
      if (n.isNotEmpty) return n;
    }
    return null;
  }

  /// Human one-liner from the real score. Variant-free but data-substituted, no
  /// em dashes.
  static String _dailyLine(double score, List<String> contributors) {
    final label = inflammationLabel(score).toLowerCase();
    final rounded = score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1);
    if (score >= 7) {
      final driver = contributors.isNotEmpty ? ' ${contributors.first} is the main driver.' : '';
      return "Today sits at $rounded/10, $label.$driver";
    }
    if (score >= 4) {
      return "Today sits at $rounded/10, $label. A few swaps could bring it down.";
    }
    return "Today sits at $rounded/10, $label. Nice work keeping it low.";
  }
}

/// Graded 0-10 horizontal meter with a marker at [score].
class _Meter extends StatelessWidget {
  final double score;
  final bool isDark;
  const _Meter({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final frac = (score / 10).clamp(0.0, 1.0);
    final track = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: 14,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Track with the full green->amber->red gradient so the scale is
              // legible even before the marker.
              Container(
                height: 8,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(colors: [
                    AppColors.success.withValues(alpha: 0.55),
                    AppColors.orange.withValues(alpha: 0.55),
                    AppColors.error.withValues(alpha: 0.55),
                  ]),
                  color: track,
                ),
              ),
              // Marker.
              Positioned(
                left: (w * frac - 7).clamp(0.0, w - 14),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: inflammationColor(score),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContributorChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _ContributorChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.length > 24 ? '${label.substring(0, 24)}…' : label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: muted),
      ),
    );
  }
}

/// Compact 7-day inflammation bar trend. Bars graded by score; empty days
/// render as faint stubs so gaps are honest.
class _WeekTrend extends StatelessWidget {
  final List<({String date, double? score})> series;
  final double? weekAverage;
  final bool isDark;
  final Color textMuted;
  final Color textSecondary;

  const _WeekTrend({
    required this.series,
    required this.weekAverage,
    required this.isDark,
    required this.textMuted,
    required this.textSecondary,
  });

  String _dayLabel(String date) {
    try {
      final dt = DateTime.parse(date);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'This week',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const Spacer(),
            if (weekAverage != null)
              Text(
                'avg ${weekAverage!.toStringAsFixed(1)}/10',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: series.map((p) {
              final s = p.score;
              final frac = s == null ? 0.0 : (s / 10).clamp(0.0, 1.0);
              final barH = 6 + frac * 36;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: barH,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: s == null
                            ? textMuted.withValues(alpha: 0.12)
                            : inflammationColor(s).withValues(alpha: 0.85),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dayLabel(p.date),
                      style: TextStyle(fontSize: 9.5, color: textMuted),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
