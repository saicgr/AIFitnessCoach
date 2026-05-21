import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/providers/combined_health_provider.dart';
import '../../data/providers/recovery_provider.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/services/api_client.dart';
import '../../data/services/health_goals_service.dart';
import '../../data/services/health_service.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/date_strip.dart';
import '../../widgets/glass_back_button.dart';
import 'widgets/metric_history_card.dart';

/// Combined Health hub — route `/health/combined`.
///
/// Reached by tapping the "Today's Health" card body. A date strip scrubs
/// the loaded daily-activity history; the body shows the recovery hero, then
/// per-metric history sections (steps / active calories / heart rate / sleep
/// / water), step + active-minute goal setting, and the activity streak.
///
/// Honest empty states throughout (plan edge case C): each section renders
/// its own per-day / per-metric empty state, so the hub still renders even
/// when only some metrics have data (case 17); no Health connection shows a
/// connect prompt instead of the hub.
class CombinedHealthScreen extends ConsumerStatefulWidget {
  const CombinedHealthScreen({super.key});

  @override
  ConsumerState<CombinedHealthScreen> createState() =>
      _CombinedHealthScreenState();
}

class _CombinedHealthScreenState extends ConsumerState<CombinedHealthScreen> {
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
    final historyAsync = ref.watch(combinedHealthHistoryProvider);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(
                children: [
                  const GlassBackButton(),
                  const SizedBox(width: 12),
                  Text(
                    'Health',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
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
                  error: (_, __) => _ErrorEmpty(isDark: isDark),
                  data: (history) =>
                      _buildBody(context, isDark, history),
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
    CombinedHealthHistory history,
  ) {
    final day = history.dayFor(_selectedDate);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        DateStrip(
          selectedDate: _selectedDate,
          loggedDateKeys: history.trackedDateKeys,
          weeksBack: (kCombinedHealthDays / 7).ceil() + 1,
          onDaySelected: (d) => setState(() => _selectedDate = d),
        ),
        const SizedBox(height: 8),
        // ── Recovery hero
        _RecoveryHero(isDark: isDark),
        const SizedBox(height: 12),
        // ── Activity streak
        _ActivityStreakCard(history: history, isDark: isDark),
        const SizedBox(height: 12),
        // ── Per-metric sections
        MetricHistoryCard(
          title: 'Steps',
          icon: Icons.directions_walk_rounded,
          color: AppColors.success,
          valueText: day != null && day.steps > 0
              ? '${_grouped(day.steps)} steps'
              : null,
          metric: TrendMetric.steps,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        MetricHistoryCard(
          title: 'Active Energy',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.orange,
          valueText: day != null && day.caloriesBurned > 0
              ? '${day.caloriesBurned.round()} cal'
              : null,
          metric: TrendMetric.activeCalories,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        MetricHistoryCard(
          title: 'Resting Heart Rate',
          icon: Icons.favorite_rounded,
          color: AppColors.error,
          valueText: day?.restingHeartRate != null
              ? '${day!.restingHeartRate} bpm'
              : null,
          subtitleText: _hrRangeLine(day),
          metric: TrendMetric.restingHeartRate,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        MetricHistoryCard(
          title: 'Sleep',
          icon: Icons.bedtime_rounded,
          color: AppColors.purple,
          valueText: day?.sleepMinutes != null && day!.sleepMinutes! > 0
              ? '${day.sleepMinutes! ~/ 60}h ${day.sleepMinutes! % 60}m'
              : null,
          metric: TrendMetric.sleepHours,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        // Water has no trend metric source — value only, no fabricated chart.
        MetricHistoryCard(
          title: 'Water',
          icon: Icons.water_drop_rounded,
          color: AppColors.cyan,
          valueText: day?.waterMl != null && day!.waterMl! > 0
              ? '${day.waterMl} ml'
              : null,
          metric: null,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        // ── Goal setting
        _ActivityGoalsCard(isDark: isDark),
      ],
    );
  }

  /// Resting + avg/min/max HR breakdown line for the HR section subtitle.
  String? _hrRangeLine(DailyActivity? day) {
    if (day == null) return null;
    final parts = <String>[];
    if (day.avgHeartRate != null) parts.add('avg ${day.avgHeartRate}');
    if (day.minHeartRate != null && day.maxHeartRate != null) {
      parts.add('range ${day.minHeartRate}-${day.maxHeartRate}');
    }
    return parts.isEmpty ? null : '${parts.join(' · ')} bpm';
  }

  static String _grouped(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Recovery hero ──────────────────────────────────────────────────────────
class _RecoveryHero extends ConsumerWidget {
  final bool isDark;
  const _RecoveryHero({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final recoveryAsync = ref.watch(recoveryProvider);

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: recoveryAsync.when(
        loading: () => const SizedBox(
          height: 70,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => _row(
          textPrimary,
          textMuted,
          null,
          'Recovery unavailable right now.',
        ),
        data: (recovery) {
          // Recovery is computed even from a single input (edge case 19);
          // a null result means no inputs at all → honest empty line.
          if (recovery == null) {
            return _row(
              textPrimary,
              textMuted,
              null,
              'Recovery needs a resting heart rate or a tracked night.',
            );
          }
          return _row(
            textPrimary,
            textMuted,
            recovery.score,
            '${recovery.label} recovery'
            '${recovery.restingHR != null ? ' · resting HR ${recovery.restingHR}' : ''}',
          );
        },
      ),
    );
  }

  Widget _row(
    Color textPrimary,
    Color textMuted,
    int? score,
    String caption,
  ) {
    final color = score == null
        ? textMuted
        : (score >= 80
            ? AppColors.success
            : score >= 60
                ? AppColors.teal
                : score >= 40
                    ? AppColors.warning
                    : AppColors.error);
    return Row(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: score == null ? 0 : score / 100,
                  strokeWidth: 7,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                score?.toString() ?? '–',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recovery',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Activity streak ────────────────────────────────────────────────────────
class _ActivityStreakCard extends ConsumerWidget {
  final CombinedHealthHistory history;
  final bool isDark;
  const _ActivityStreakCard({required this.history, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final goalsAsync = ref.watch(healthGoalsProvider);
    final stepGoal = goalsAsync.valueOrNull?.stepGoal ?? 10000;
    final streak = history.activityStreak(stepGoal);

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.local_fire_department_rounded,
                color: AppColors.orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity streak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                Text(
                  streak == 0
                      ? 'Hit your step goal to start a streak.'
                      : streak == 1
                          ? '1 day at or above your step goal.'
                          : '$streak days in a row at or above your step goal.',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: streak > 0 ? AppColors.orange : textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step + active-minute goal setting ──────────────────────────────────────
class _ActivityGoalsCard extends ConsumerStatefulWidget {
  final bool isDark;
  const _ActivityGoalsCard({required this.isDark});

  @override
  ConsumerState<_ActivityGoalsCard> createState() =>
      _ActivityGoalsCardState();
}

class _ActivityGoalsCardState extends ConsumerState<_ActivityGoalsCard> {
  bool _saving = false;

  static const List<int> _stepOptions = [
    5000, 7500, 10000, 12500, 15000, 20000
  ];
  static const List<int> _activeOptions = [15, 20, 30, 45, 60, 90];

  Future<void> _save({int? stepGoal, int? activeMinutesGoal}) async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticService.selection();
    try {
      final service = ref.read(healthGoalsServiceProvider);
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId != null) {
        await service.updateGoals(
          userId,
          stepGoal: stepGoal,
          activeMinutesGoal: activeMinutesGoal,
        );
        ref.invalidate(healthGoalsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save goal.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final goalsAsync = ref.watch(healthGoalsProvider);
    final goals = goalsAsync.valueOrNull ?? HealthGoals.defaults;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.flag_rounded,
                    color: AppColors.success, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Daily goals',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Step goal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _stepOptions)
                _GoalChip(
                  label: _grouped(s),
                  selected: s == goals.stepGoal,
                  isDark: isDark,
                  onTap: _saving ? null : () => _save(stepGoal: s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Active minutes goal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _activeOptions)
                _GoalChip(
                  label: '$m min',
                  selected: m == goals.activeMinutesGoal,
                  isDark: isDark,
                  onTap: _saving ? null : () => _save(activeMinutesGoal: m),
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
                Text('Saving…',
                    style: TextStyle(fontSize: 11, color: textMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _grouped(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
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

// ── Empty / error states ───────────────────────────────────────────────────
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
            Icon(Icons.favorite_outline_rounded, size: 48, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'Connect Health to see your activity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Steps, heart rate, sleep and more sync from Health Connect '
              'on Android and the Health app on iOS.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                HapticService.light();
                ref.read(healthSyncProvider.notifier).connect();
              },
              child: const Text('Connect Health'),
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
              'Could not load your health data. Pull back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
