import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/providers/sleep_detail_provider.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/services/api_client.dart';
import '../../data/services/health_goals_service.dart';
import '../../data/services/health_service.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/date_strip.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/trends/trend_chart.dart';
import 'widgets/sleep_coaching.dart';
import 'widgets/sleep_hypnogram.dart';
import 'widgets/sleep_score.dart';
import '../pillar/widgets/ask_coach_button.dart';

import '../../l10n/generated/app_localizations.dart';
/// Dedicated Sleep detail screen — route `/health/sleep`.
///
/// Reached by tapping the "Last Night's Sleep" card. A date strip scrubs
/// across the loaded nightly history; the body shows the selected night's
/// hypnogram, sleep score, efficiency / latency / debt / regularity, naps,
/// and below the fold the 7-night + 30-day charts, the monthly summary,
/// day-seeded coaching tips, and a sleep-goal setter.
///
/// Honest empty states throughout (plan edge cases B): a day with no data
/// shows a per-day empty state; today before the morning sync shows the
/// most-recent night; future days are unreachable (the date strip disables
/// them); no Health connection shows a connect prompt instead of the screen.
class SleepDetailScreen extends ConsumerStatefulWidget {
  const SleepDetailScreen({super.key});

  @override
  ConsumerState<SleepDetailScreen> createState() => _SleepDetailScreenState();
}

class _SleepDetailScreenState extends ConsumerState<SleepDetailScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final sync = ref.watch(healthSyncProvider);
    final historyAsync = ref.watch(sleepHistoryProvider);
    final goalsAsync = ref.watch(healthGoalsProvider);
    final goalMinutes =
        goalsAsync.valueOrNull?.sleepDurationGoalMinutes ?? 480;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(
                children: [
                  const GlassBackButton(),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).sleepDetailSleep,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Ask Coach — opens chat with this pillar prefilled.
                  AskCoachButton(
                    contextLabel: 'Sleep · last night',
                    statSnapshot: const {'pillar': 'sleep'},
                  ),
                ],
              ),
            ),
            if (!sync.isConnected)
              Expanded(child: _ConnectHealthEmpty(isDark: isDark))
            else
              Expanded(
                child: historyAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorEmpty(isDark: isDark),
                  data: (history) => _buildBody(
                    context,
                    isDark,
                    history,
                    goalMinutes,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    SleepHistory history,
    int goalMinutes,
  ) {
    // The night to display: the selected day's night, or — when today has
    // no data yet (pre-sync) and today is selected — the most-recent night
    // so the screen is never blank on first open (edge case 13).
    final now = DateTime.now();
    final isTodaySelected =
        _selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day;
    final night = history.nightFor(_selectedDate);
    final displayNight =
        night ?? (isTodaySelected ? history.latest : null);
    final showingFallback = night == null && displayNight != null;

    final debt = history.sleepDebtMinutes(goalMinutes);
    final regularity = history.regularityScore();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Date strip — capped to the real backfill window (edge case 15).
        DateStrip(
          selectedDate: _selectedDate,
          loggedDateKeys: history.trackedDateKeys,
          weeksBack: (kSleepHistoryDays / 7).ceil() + 1,
          onDaySelected: (d) => setState(() => _selectedDate = d),
        ),
        const SizedBox(height: 8),
        if (displayNight == null)
          _NoNightForDay(
            isDark: isDark,
            selectedDate: _selectedDate,
            history: history,
          )
        else ...[
          if (showingFallback)
            _InProgressNote(isDark: isDark, night: displayNight),
          _selectedNightCard(context, isDark, displayNight, goalMinutes,
              debt, regularity, history),
        ],
        const SizedBox(height: 12),
        _SevenNightChart(history: history, goalMinutes: goalMinutes, isDark: isDark),
        const SizedBox(height: 12),
        _ThirtyDayTrend(isDark: isDark),
        const SizedBox(height: 12),
        _DebtRegularityCard(
            debt: debt, regularity: regularity, isDark: isDark),
        const SizedBox(height: 12),
        _MonthlySummaryCard(history: history, isDark: isDark),
        const SizedBox(height: 12),
        if (displayNight != null)
          _CoachingCard(
            night: displayNight,
            goalMinutes: goalMinutes,
            debt: debt,
            regularity: regularity,
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        _SleepGoalCard(isDark: isDark),
        const SizedBox(height: 16),
        // Custom Trends — routes to the existing builder with Sleep
        // pre-selected via TrendMetric.pillarSleep. Lets users overlay
        // Sleep against other metrics (Train, Nourish, Move, weight, etc.).
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.auto_graph_rounded, size: 16),
            label: Text(AppLocalizations.of(context).statsRewardsCustomTrends),
            onPressed: () {
              try {
                context.push('/trends/custom',
                    extra: TrendMetric.pillarSleep);
              } catch (_) {
                context.push('/trends/custom');
              }
            },
          ),
        ),
      ],
    );
  }

  // ── Selected-night detail card ────────────────────────────────────────
  Widget _selectedNightCard(
    BuildContext context,
    bool isDark,
    DailySleep night,
    int goalMinutes,
    int debt,
    int? regularity,
    SleepHistory history,
  ) {
    final main = night.mainSleep;
    final total = night.totalAsleepMinutes;
    final score = computeSleepScore(
      asleepMinutes: total,
      goalMinutes: goalMinutes,
      efficiency: main.efficiency,
      deepMinutes: main.deepMinutes,
      remMinutes: main.remMinutes,
      midSleepMinutesFromMidnight: _midSleep(main),
      avgMidSleepMinutesFromMidnight: history.avgMidSleepMinutes(),
    );

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.bedtime_rounded,
            color: AppColors.purple,
            title: DateFormat('EEEE, MMM d').format(night.date),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          // Duration headline vs goal.
          _DurationHeadline(
            asleepMinutes: total,
            goalMinutes: goalMinutes,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          if (score != null) ...[
            SleepScoreRing(score: score, isDark: isDark),
            const SizedBox(height: 18),
          ],
          // Hypnogram (stage-proportion).
          SleepHypnogram(summary: main, isDark: isDark),
          const SizedBox(height: 14),
          // Efficiency + latency metric row.
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: AppLocalizations.of(context).sleepDetailEfficiency,
                  value: main.efficiency != null
                      ? '${(main.efficiency! * 100).round()}%'
                      : '–',
                  icon: Icons.speed_rounded,
                  color: AppColors.teal,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: AppLocalizations.of(context).sleepDetailFellAsleepIn,
                  value: main.latencyMinutes != null
                      ? '${main.latencyMinutes} min'
                      : '–',
                  icon: Icons.hourglass_bottom_rounded,
                  color: AppColors.cyan,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          // Naps — listed separately, added to the day total (edge case 3).
          if (night.naps.isNotEmpty) ...[
            const SizedBox(height: 14),
            _NapsSection(naps: night.naps, isDark: isDark),
          ],
        ],
      ),
    );
  }

  static int? _midSleep(SleepSummary s) {
    final bed = s.bedTime;
    final wake = s.wakeTime;
    if (bed == null || wake == null) return null;
    final mid = bed.add(
        Duration(minutes: wake.difference(bed).inMinutes ~/ 2));
    return mid.hour * 60 + mid.minute;
  }
}

// ════════════════════════════════════════════════════════════════════════
// Shared card scaffolding
// ════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool isDark;
  const _CardHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DurationHeadline extends StatelessWidget {
  final int asleepMinutes;
  final int goalMinutes;
  final bool isDark;
  const _DurationHeadline({
    required this.asleepMinutes,
    required this.goalMinutes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final h = asleepMinutes ~/ 60;
    final m = asleepMinutes % 60;
    final goalH = goalMinutes ~/ 60;
    final goalM = goalMinutes % 60;
    final diff = asleepMinutes - goalMinutes;
    final String goalLine;
    if (diff >= -15 && diff <= 15) {
      goalLine = 'On your ${goalH}h${goalM == 0 ? '' : ' ${goalM}m'} goal';
    } else if (diff < 0) {
      goalLine =
          '${(-diff) ~/ 60}h ${(-diff) % 60}m under your ${goalH}h goal';
    } else {
      goalLine = '${diff ~/ 60}h ${diff % 60}m over your ${goalH}h goal';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${h}h',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                height: 1.0,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${m}m',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                height: 1.0,
                letterSpacing: -1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          goalLine,
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final tileBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);
    final tileBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tileBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Naps section ─────────────────────────────────────────────────────────
class _NapsSection extends StatelessWidget {
  final List<SleepSummary> naps;
  final bool isDark;
  const _NapsSection({required this.naps, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final fmt = DateFormat('HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          naps.length == 1 ? AppLocalizations.of(context).sleepDetailNap : '${naps.length} naps',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 6),
        for (final nap in naps)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_outlined,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  _fmtDur(nap.totalMinutes),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (nap.bedTime != null && nap.wakeTime != null)
                  Text(
                    '${fmt.format(nap.bedTime!)} – ${fmt.format(nap.wakeTime!)}',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _fmtDur(int m) {
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${m % 60}m';
  }
}

// ── 7-night bar chart ──────────────────────────────────────────────────────
class _SevenNightChart extends StatelessWidget {
  final SleepHistory history;
  final int goalMinutes;
  final bool isDark;
  const _SevenNightChart({
    required this.history,
    required this.goalMinutes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Last 7 calendar days ending today, oldest → newest.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final values = [
      for (final d in days) history.nightFor(d)?.totalAsleepMinutes ?? 0,
    ];
    final maxVal = [
      goalMinutes,
      ...values,
    ].reduce((a, b) => a > b ? a : b).toDouble();
    final anyData = values.any((v) => v > 0);

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.bar_chart_rounded,
            color: AppColors.cyan,
            title: AppLocalizations.of(context).sleepDetailLast7Nights,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          if (!anyData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppLocalizations.of(context).sleepDetailNoSleepTrackedIn,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: _DayBar(
                        date: days[i],
                        minutes: values[i],
                        maxMinutes: maxVal,
                        goalMinutes: goalMinutes,
                        isDark: isDark,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final DateTime date;
  final int minutes;
  final double maxMinutes;
  final int goalMinutes;
  final bool isDark;
  const _DayBar({
    required this.date,
    required this.minutes,
    required this.maxMinutes,
    required this.goalMinutes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final track = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final frac = maxMinutes > 0 ? (minutes / maxMinutes).clamp(0.0, 1.0) : 0.0;
    final hitGoal = minutes >= goalMinutes;
    final barColor = minutes == 0
        ? track
        : (hitGoal ? AppColors.success : AppColors.purple);
    final hours = minutes > 0
        ? (minutes / 60).toStringAsFixed(1)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            hours,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: track,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: c.maxHeight * frac,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 5),
          Text(
            DateFormat('E').format(date)[0],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 30-day trend (TrendChart + the sleep_minutes metric) ──────────────────
class _ThirtyDayTrend extends ConsumerWidget {
  final bool isDark;
  const _ThirtyDayTrend({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final seriesAsync = ref.watch(
      trendSeriesProvider(
        const TrendSeriesKey(TrendMetric.sleepHours, TrendRange.d30),
      ),
    );

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.show_chart_rounded,
            color: AppColors.purple,
            title: AppLocalizations.of(context).sleepDetail30DayTrend,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          seriesAsync.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text(
              AppLocalizations.of(context).sleepDetailTrendUnavailable,
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            data: (series) {
              if (series.points.length < 2) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    AppLocalizations.of(context).sleepDetailTwoOrMoreSynced,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                );
              }
              return TrendChart(
                height: 180,
                accent: AppColors.purple,
                primary: TrendChartSeries(
                  label: AppLocalizations.of(context).sleepDetailSleep,
                  unit: series.unit,
                  points: series.points,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Sleep debt + regularity ────────────────────────────────────────────────
class _DebtRegularityCard extends StatelessWidget {
  final int debt;
  final int? regularity;
  final bool isDark;
  const _DebtRegularityCard({
    required this.debt,
    required this.regularity,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.balance_rounded,
            color: AppColors.teal,
            title: AppLocalizations.of(context).sleepDetailDebtRegularity,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: AppLocalizations.of(context).sleepDetailSleepDebt14d,
                  value: debt <= 0
                      ? 'None'
                      : '${debt ~/ 60}h ${debt % 60}m',
                  icon: Icons.trending_down_rounded,
                  color: debt > 120 ? AppColors.warning : AppColors.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: AppLocalizations.of(context).sleepDetailRegularity,
                  value: regularity != null ? '$regularity / 100' : '–',
                  icon: Icons.event_repeat_rounded,
                  color: AppColors.cyan,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Monthly summary (≥14 nights) ──────────────────────────────────────────
class _MonthlySummaryCard extends StatelessWidget {
  final SleepHistory history;
  final bool isDark;
  const _MonthlySummaryCard({required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final summary = history.monthlySummary();
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.calendar_month_rounded,
            color: AppColors.cyan,
            title: AppLocalizations.of(context).sleepDetailMonthlySummary,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          if (summary == null)
            Text(
              'Your monthly summary unlocks after 14 tracked nights — '
              'keep syncing and it will appear here.',
              style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: AppLocalizations.of(context).sleepDetailAvgNight,
                    value:
                        '${summary.avgAsleepMinutes ~/ 60}h ${summary.avgAsleepMinutes % 60}m',
                    icon: Icons.nightlight_round,
                    color: AppColors.purple,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetric(
                    label: AppLocalizations.of(context).sleepDetailBestNight,
                    value:
                        '${summary.bestAsleepMinutes ~/ 60}h ${summary.bestAsleepMinutes % 60}m',
                    icon: Icons.star_rounded,
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: AppLocalizations.of(context).sleepDetailShortestNight,
                    value:
                        '${summary.worstAsleepMinutes ~/ 60}h ${summary.worstAsleepMinutes % 60}m',
                    icon: Icons.trending_down_rounded,
                    color: AppColors.warning,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetric(
                    label: AppLocalizations.of(context).sleepDetailNightsWithNaps,
                    value: '${summary.napNightCount}',
                    icon: Icons.wb_sunny_outlined,
                    color: AppColors.cyan,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Across ${summary.nightCount} tracked nights.',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Coaching tips ──────────────────────────────────────────────────────────
class _CoachingCard extends StatelessWidget {
  final DailySleep night;
  final int goalMinutes;
  final int debt;
  final int? regularity;
  final bool isDark;
  const _CoachingCard({
    required this.night,
    required this.goalMinutes,
    required this.debt,
    required this.regularity,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final daySeed = night.date.difference(DateTime(2020)).inDays;
    final tips = sleepCoachingTips(
      asleepMinutes: night.totalAsleepMinutes,
      goalMinutes: goalMinutes,
      efficiency: night.mainSleep.efficiency,
      latencyMinutes: night.mainSleep.latencyMinutes,
      regularityScore: regularity,
      sleepDebtMinutes: debt,
      daySeed: daySeed,
    );
    if (tips.isEmpty) return const SizedBox.shrink();

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.lightbulb_outline_rounded,
            color: AppColors.warning,
            title: AppLocalizations.of(context).sleepDetailCoachingTips,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < tips.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: AppColors.warning),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tips[i].title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tips[i].body,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sleep-goal setter ──────────────────────────────────────────────────────
class _SleepGoalCard extends ConsumerStatefulWidget {
  final bool isDark;
  const _SleepGoalCard({required this.isDark});

  @override
  ConsumerState<_SleepGoalCard> createState() => _SleepGoalCardState();
}

class _SleepGoalCardState extends ConsumerState<_SleepGoalCard> {
  bool _saving = false;

  /// Sleep-goal options in minutes — 6h to 9h30 in 30-min steps.
  static const List<int> _options = [
    360, 390, 420, 450, 480, 510, 540, 570
  ];

  Future<void> _save(int minutes) async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticService.selection();
    try {
      final apiClient = ref.read(healthGoalsServiceProvider);
      final userId =
          await ref.read(apiClientProvider).getUserId();
      if (userId != null) {
        await apiClient.updateGoals(userId,
            sleepDurationGoalMinutes: minutes);
        ref.invalidate(healthGoalsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).sleepDetailCouldNotSaveSleep)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final goalsAsync = ref.watch(healthGoalsProvider);
    final current =
        goalsAsync.valueOrNull?.sleepDurationGoalMinutes ?? 480;

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.flag_rounded,
            color: AppColors.success,
            title: AppLocalizations.of(context).sleepDetailSleepGoal,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          Text(
            'Your nightly sleep target. The Sleep Foundation recommends '
            '7-9 hours for most adults.',
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _options)
                _GoalChip(
                  label: '${m ~/ 60}h${m % 60 == 0 ? '' : ' ${m % 60}m'}',
                  selected: m == current,
                  isDark: isDark,
                  onTap: _saving ? null : () => _save(m),
                ),
            ],
          ),
          if (_saving) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).sleepDetailSaving,
                    style: TextStyle(fontSize: 11, color: textMuted)),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Current: ${current ~/ 60}h${current % 60 == 0 ? '' : ' ${current % 60}m'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback? onTap;
  const _GoalChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.success.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.success : border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.success : textPrimary,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Empty / fallback states
// ════════════════════════════════════════════════════════════════════════

class _NoNightForDay extends StatelessWidget {
  final bool isDark;
  final DateTime selectedDate;
  final SleepHistory history;
  const _NoNightForDay({
    required this.isDark,
    required this.selectedDate,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final latest = history.latest;
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bedtime_off_outlined, size: 32, color: textMuted),
          const SizedBox(height: 10),
          Text(
            'No sleep tracked for ${DateFormat('EEEE, MMM d').format(selectedDate)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            latest != null
                ? 'Your most recent tracked night was '
                    '${DateFormat('EEEE, MMM d').format(latest.date)}.'
                : 'No nights have been tracked yet.',
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _InProgressNote extends StatelessWidget {
  final bool isDark;
  final DailySleep night;
  const _InProgressNote({required this.isDark, required this.night});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.sync_rounded, size: 14, color: textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Today hasn't synced yet — showing your most recent night "
              '(${DateFormat('MMM d').format(night.date)}).',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectHealthEmpty extends ConsumerWidget {
  final bool isDark;
  const _ConnectHealthEmpty({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bedtime_outlined, size: 48, color: textMuted),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).sleepDetailConnectHealthToSee,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sleep data syncs from Health Connect on Android and the '
              'Health app on iOS. Once connected, your nights appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                HapticService.light();
                ref.read(healthSyncProvider.notifier).connect();
              },
              child: Text(AppLocalizations.of(context).todaysHealthCardConnectHealth),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorEmpty extends StatelessWidget {
  final bool isDark;
  const _ErrorEmpty({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: textMuted),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).sleepDetailCouldNotLoadSleep,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
