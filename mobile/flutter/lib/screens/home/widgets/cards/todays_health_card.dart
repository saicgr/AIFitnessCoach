import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers/neat_provider.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../data/services/health_service.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Composite "Today's Health" card matching the level of polish competitors
/// (GymBeat, FitOn) ship: a hero steps progress block with the gap-to-goal
/// readout, then a 3-up row of metric tiles for active calories, average
/// heart rate, and the day's heart-rate range.
///
/// Reads from the existing `dailyActivityProvider` — no new data plumbing.
/// Hidden when Health Connect / HealthKit isn't connected (the standalone
/// `DailyStepsTile` shows the connect CTA in that case so we don't
/// duplicate it here).
class TodaysHealthCard extends ConsumerStatefulWidget {
  const TodaysHealthCard({
    super.key,
    this.onRefresh,
    this.isRefreshing = false,
  });

  /// When non-null, an inline refresh affordance is rendered in the card
  /// header (left of the settings cog). The host owns the refresh state and
  /// passes `isRefreshing: true` to swap the icon for a spinner.
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  @override
  ConsumerState<TodaysHealthCard> createState() => _TodaysHealthCardState();
}

class _TodaysHealthCardState extends ConsumerState<TodaysHealthCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sync = ref.read(healthSyncProvider);
      if (sync.isConnected) {
        ref.read(dailyActivityProvider.notifier).loadTodayActivity();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final sync = ref.watch(healthSyncProvider);
    // Permission denied / not connected: show a "Connect Health" CTA card
    // instead of zeros. Empty zero-state was misleading — users thought
    // their watch wasn't syncing when really they'd never granted
    // permissions. Edge case: if permissions were revoked mid-session, the
    // sync state notifier flips `isConnected` to false and we re-render
    // the same CTA, which is the correct recovery path.
    if (!sync.isConnected) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.favorite_rounded,
                      color: AppColors.success, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).todaysHealthCardConnectHealth,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).todaysHealthCardSyncStepsHeartRate,
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticService.light();
                    ref.read(healthSyncProvider.notifier).connect();
                  },
                  child: Text(AppLocalizations.of(context).unifiedHomeWidgetsConnect),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activity = ref.watch(dailyActivityProvider).today;
    final stepGoal = ref.watch(stepGoalProvider);
    final steps = activity?.steps ?? 0;
    final progress = stepGoal == 0 ? 0.0 : (steps / stepGoal).clamp(0.0, 1.0);
    final remaining = (stepGoal - steps).clamp(0, stepGoal);

    final activeCal = activity?.caloriesBurned.round();
    final avgHr = activity?.avgHeartRate;
    final minHr = activity?.minHeartRate;
    final maxHr = activity?.maxHeartRate;
    final restingHr = activity?.restingHeartRate;
    final hasHrRange = minHr != null && maxHr != null && maxHr > minHr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header
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
                    child: Icon(Icons.favorite_rounded,
                        color: AppColors.success, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context).todaysHealthCardTodaySHealth,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onRefresh != null) ...[
                    if (widget.isRefreshing)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: textMuted,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          HapticService.light();
                          widget.onRefresh!();
                        },
                        child: Icon(Icons.refresh,
                            size: 18, color: textMuted),
                      ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      context.push('/settings');
                    },
                    child: Icon(Icons.settings_outlined,
                        size: 18, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Body — tapping it opens the Combined Health hub
              // (`/health/combined`): recovery, per-metric history, goal
              // setting, activity streak. The header's cog / refresh keep
              // their own taps; only the body below routes to the hub.
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  context.push('/health/combined');
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Hero: steps + progress + gap-to-goal
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatSteps(steps),
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            height: 1.0,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'steps',
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Icon(Icons.chevron_right_rounded,
                              size: 20, color: textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      remaining > 0
                          ? '${_formatSteps(remaining)} to go of ${_formatSteps(stepGoal)}'
                          : 'Goal hit — ${_formatSteps(steps - stepGoal)} over target',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: cardBorder.withValues(alpha: 0.4),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ─── Metric tiles in a 2×2 grid (4 equal-width slots).
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: AppColors.orange,
                            value: activeCal != null ? '$activeCal' : '—',
                            unit: 'cal',
                            label: AppLocalizations.of(context).todaysHealthCardActiveEnergy,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            icon: Icons.favorite_rounded,
                            iconColor: AppColors.error,
                            value: avgHr != null ? '$avgHr' : '—',
                            unit: 'bpm',
                            label: AppLocalizations.of(context).workoutDayDetailAvgHr,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            icon: Icons.show_chart_rounded,
                            iconColor: AppColors.purple,
                            value: hasHrRange ? '$minHr–$maxHr' : '—',
                            unit: 'bpm',
                            label: AppLocalizations.of(context).todaysHealthCardHrRange,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            icon: Icons.bedtime_outlined,
                            iconColor: AppColors.teal,
                            value: restingHr != null ? '$restingHr' : '—',
                            unit: 'bpm',
                            label: AppLocalizations.of(context).todaysHealthCardRestingHr,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSteps(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;
  final bool isDark;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
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
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
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
