import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/providers/neat_provider.dart';
import '../../../../data/providers/xp_provider.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../data/services/health_service.dart';

/// Focused steps card — today's step count vs a 10,000-step daily goal with a
/// progress ring.
///
/// **Data source:** reads from the `dailyActivityProvider`, which calls
/// `HealthService.getTodaySteps()` under the hood. That method uses the
/// `health` Flutter plugin (v11) which is the canonical bridge to:
///   - **iOS**: Apple HealthKit (native step counter / pedometer / paired
///     Apple Watch).
///   - **Android**: Health Connect — which aggregates step data from any
///     registered provider including Samsung Health, Google Fit, Fitbit,
///     Garmin, Xiaomi Mi Fitness, etc. If Health Connect isn't installed,
///     data reads fall back to whatever the OEM's default step counter
///     exposes.
///
/// If the user hasn't granted health permissions / connected a source yet,
/// the card shows a "Connect" CTA that deep-links to Settings → Health Sync
/// where they can authorise. Otherwise it renders the live step count.
class DailyStepsTile extends ConsumerStatefulWidget {
  const DailyStepsTile({super.key});

  @override
  ConsumerState<DailyStepsTile> createState() => _DailyStepsTileState();
}

class _DailyStepsTileState extends ConsumerState<DailyStepsTile> {
  @override
  void initState() {
    super.initState();
    // Kick a refresh once the widget mounts so newly-enabled permissions
    // populate the card without a manual pull-to-refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sync = ref.read(healthSyncProvider);
      if (sync.isConnected) {
        ref.read(dailyActivityProvider.notifier).loadTodayActivity();
      }
    });
  }

  Future<void> _connect() async {
    HapticService.light();
    // Route to Settings where the Health Sync section handles permission
    // requests + provider selection (HealthKit / Health Connect).
    context.push('/settings');
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
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    final syncState = ref.watch(healthSyncProvider);
    final activityState = ref.watch(dailyActivityProvider);

    if (!syncState.isConnected) {
      return _buildConnectCard(
        context,
        isDark: isDark,
        elevated: elevated,
        textPrimary: textPrimary,
        textMuted: textMuted,
        cardBorder: cardBorder,
        accent: accent,
      );
    }

    final steps = activityState.today?.steps ?? 0;
    final isFromHealth = activityState.today?.isFromHealthConnect ?? false;

    // Goal comes from the NEAT provider — sourced from the user's backend
    // profile (coach-set or manually adjusted in Settings). Falls back to
    // 10,000 if no goal is configured yet.
    final dailyGoal = ref.watch(stepGoalProvider);
    final progress = dailyGoal > 0
        ? (steps / dailyGoal).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final goalHit = dailyGoal > 0 && steps >= dailyGoal;

    // Fire-once-per-day: when the user crosses the step goal, ask the XP
    // notifier to award XP and emit a coach-banner event. `markStepsGoalHit`
    // is idempotent — repeated calls after the flag is set are no-ops.
    final dailyGoals = ref.watch(dailyGoalsProvider);
    if (goalHit && dailyGoals != null && !dailyGoals.hitStepsGoal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(xpProvider.notifier).markStepsGoalHit(steps);
      });
    }
    final progressColor = goalHit ? AppColors.success : accent;
    final sourceLabel = Platform.isIOS
        ? 'Apple Health'
        : 'Health Connect';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: cardBorder,
                    valueColor: AlwaysStoppedAnimation(progressColor),
                  ),
                ),
                Icon(
                  Icons.directions_walk_rounded,
                  color: progressColor,
                  size: 22,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'STEPS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: textMuted,
                      ),
                    ),
                    if (isFromHealth) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified_rounded,
                          size: 11, color: accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatCount(steps),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${_formatCount(dailyGoal)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  goalHit
                      ? 'Daily goal reached 🎉 · via $sourceLabel'
                      : '${_formatCount(dailyGoal - steps)} to go · via $sourceLabel',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: goalHit ? AppColors.success : textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectCard(
    BuildContext context, {
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
    required Color accent,
  }) {
    final sourceLabel = Platform.isIOS ? 'Apple Health' : 'Health Connect';
    final detail = Platform.isIOS
        ? 'Pulls steps from the iPhone pedometer or a paired Apple Watch.'
        : 'Pulls steps from Google Fit, Samsung Health, Fitbit, or any provider registered with Health Connect.';

    return GestureDetector(
      onTap: _connect,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.directions_walk_rounded,
                  color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Connect $sourceLabel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble()
          ? '${k.toInt()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return n.toString();
  }
}
