part of 'workout_stats_section.dart';

/// 6. STRENGTH % + NEXT-PR ETA.
///
/// For the top muscle groups (by strength score) shows a strength-level badge,
/// the best estimated 1RM (kg → lbs), a weekly best-e1RM sparkline, and — when
/// the trend is genuinely rising — an honest projected ETA to the next plate.
///
/// The ETA is a plain least-squares projection over the real weekly best-e1RM
/// series ([strengthE1rmTrendProvider]). It is shown ONLY when there are >=3
/// data points, the slope is positive, and the projected date is within ~6
/// months. Otherwise no ETA is drawn — we never fabricate a trajectory
/// (`feedback_no_silent_fallbacks.md`). e1RM history comes from real logged
/// estimated-1RMs, so a flat or declining lifter simply sees no ETA.
class _StrengthEtaCard extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const _StrengthEtaCard({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscleScores = ref.watch(muscleScoresProvider);
    final scoresLoading = ref.watch(scoresLoadingProvider);
    final e1rmTrend = ref.watch(strengthE1rmTrendProvider).valueOrNull;

    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (muscleScores.isEmpty && scoresLoading) {
      return StatCardShell(
        isDark: isDark,
        child: const _CardSkeleton(height: 120),
      );
    }

    // Top 3 by strength score, only those with a usable score.
    final ranked = muscleScores.values
        .where((m) => m.strengthScore > 0)
        .toList()
      ..sort((a, b) => b.strengthScore.compareTo(a.strengthScore));
    final top = ranked.take(3).toList(growable: false);

    if (top.isEmpty) {
      return StatCardShell(
        isDark: isDark,
        child: Row(
          children: [
            Icon(Icons.bolt, size: 22, color: textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Log a few lifts to build your strength profile by muscle group.',
                style:
                    TextStyle(fontSize: 13, height: 1.35, color: textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return StatCardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Strength by muscle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...top.map((m) {
            final series = e1rmTrend?.forMuscle(m.muscleGroup)?.weeks;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _StrengthRow(
                data: m,
                series: series,
                isDark: isDark,
                accent: accent,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StrengthRow extends StatelessWidget {
  final StrengthScoreData data;

  /// Weekly best-e1RM points for this muscle (may be null when the trend
  /// endpoint has no data for it yet).
  final List<E1rmPoint>? series;
  final bool isDark;
  final Color accent;

  const _StrengthRow({
    required this.data,
    required this.series,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final e1rmLbs = data.bestEstimated1rmKg != null
        ? _kgToLbs(data.bestEstimated1rmKg!)
        : null;
    final levelColor = Color(data.levelColor);

    // Real points only, for the sparkline + projection.
    final points = (series ?? const <E1rmPoint>[])
        .where((p) => p.bestE1rmKg != null)
        .toList(growable: false);
    final sparkValues =
        points.map((p) => _kgToLbs(p.bestE1rmKg!)).toList(growable: false);
    final eta = _projectNextPr(points);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                data.muscleGroupDisplayName,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data.levelDisplayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: levelColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Est. 1RM value (or score when no 1RM yet).
            SizedBox(
              width: 92,
              child: Text(
                e1rmLbs != null
                    ? 'Est. 1RM\n${e1rmLbs.round()} lbs'
                    : 'Score\n${data.strengthScore}/100',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.25,
                  color: textMuted,
                ),
              ),
            ),
            // Sparkline of weekly best e1RM (only when there are >=2 points).
            if (sparkValues.length >= 2)
              Expanded(
                child: MiniSparkline(
                  values: sparkValues,
                  color: accent,
                  height: 30,
                ),
              )
            else
              const Spacer(),
            // Honest ETA chip when the trend is genuinely rising.
            if (eta != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.success : AppColorsLight.success)
                      .withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 12,
                        color:
                            isDark ? AppColors.success : AppColorsLight.success),
                    const SizedBox(width: 4),
                    Text(
                      eta.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.success
                            : AppColorsLight.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A projected next-PR estimate, or null when no honest projection exists.
class _PrEta {
  /// Whole weeks until the projected next plate.
  final int weeks;

  /// Projected target in lbs.
  final double targetLbs;

  const _PrEta(this.weeks, this.targetLbs);

  String get label => weeks <= 1
      ? 'Next PR ~1 wk'
      : 'Next PR ~$weeks wks';
}

/// Least-squares projection over the real weekly best-e1RM points. Returns null
/// unless there are >=3 points, the slope is positive, and the next plate is
/// within ~26 weeks — so a flat or declining lifter sees no (fabricated) ETA.
///
/// x is measured in real weeks between week-start dates (so skipped weeks don't
/// distort the slope), y is e1RM in kg. The increment is one 2.5 kg plate
/// (~5 lb), the smallest honest jump.
_PrEta? _projectNextPr(List<E1rmPoint> points) {
  if (points.length < 3) return null;

  final first = points.first.weekStart;
  final xs = <double>[];
  final ys = <double>[];
  for (final p in points) {
    if (p.bestE1rmKg == null) continue;
    xs.add(p.weekStart.difference(first).inDays / 7.0);
    ys.add(p.bestE1rmKg!);
  }
  if (xs.length < 3) return null;

  final n = xs.length;
  final meanX = xs.reduce((a, b) => a + b) / n;
  final meanY = ys.reduce((a, b) => a + b) / n;
  double num = 0;
  double den = 0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - meanX;
    num += dx * (ys[i] - meanY);
    den += dx * dx;
  }
  if (den == 0) return null;
  final slopeKgPerWeek = num / den; // kg gained per week
  if (slopeKgPerWeek <= 0.05) return null; // not meaningfully progressing

  const incrementKg = 2.5; // one small plate (~5 lb)
  final currentBest = ys.reduce((a, b) => a > b ? a : b);
  final weeksToNext = (incrementKg / slopeKgPerWeek).ceil();
  if (weeksToNext <= 0 || weeksToNext > 26) return null; // too far to be useful

  return _PrEta(weeksToNext, _kgToLbs(currentBest + incrementKg));
}
