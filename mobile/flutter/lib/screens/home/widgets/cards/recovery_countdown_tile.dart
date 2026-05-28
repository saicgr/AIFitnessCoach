/// F3.112 — Recovery countdown tile.
///
/// Shows hours-until-fully-recovered for the most recent completed
/// session. Backend heuristic: >= 45 min workout = hard (36 h budget),
/// < 45 min = light (12 h budget); `hours_remaining = budget - elapsed`.
///
/// Self-collapses when:
///   * today's workout hasn't been completed yet (handled by ranker via
///     `todayWorkoutProvider`), OR
///   * the backend has no completed session on file, OR
///   * `hours_remaining` is 0 (fully recovered).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_pattern_providers.dart';
import '../../../../data/providers/today_workout_provider.dart';

class RecoveryCountdownTile extends ConsumerWidget {
  const RecoveryCountdownTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull;
    final completed = today?.completedToday ?? false;
    if (!completed) return const SizedBox.shrink();

    final async = ref.watch(recoveryHoursProvider);
    final data = async.asData?.value;
    // Self-collapse on no data / fully recovered / loading / error —
    // never render a fixed-24h heuristic that lies on every session.
    if (data == null || !data.hasData || data.hoursRemaining <= 0) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    final hours = data.hoursRemaining;
    final total = data.estimatedTotalRecoveryHours;
    final pct = total > 0
        ? ((total - hours) / total).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final isHard = total >= 36;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          // Circular progress for recovery percent.
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 4,
                    backgroundColor: c.cardBorder,
                    valueColor: AlwaysStoppedAnimation(c.accent),
                  ),
                ),
                Icon(Icons.bedtime_rounded, size: 20, color: c.accent),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hours}h until you\'re fully recovered',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHard
                      ? 'Hard session — full reset takes ~${total}h.'
                      : 'Light session — full reset takes ~${total}h.',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
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
