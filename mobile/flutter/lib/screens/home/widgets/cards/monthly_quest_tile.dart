/// F3.50 — Monthly quest tile. A bigger, calendar-month-scoped goal
/// (e.g. "20 workouts this month") with progress bar. Reads
/// workoutHistoryProvider best-effort; static label fallback otherwise.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';

class MonthlyQuestTile extends ConsumerWidget {
  const MonthlyQuestTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final now = DateTime.now();
    final monthName = _monthName(now.month);
    // TODO(backend): GET /api/v1/quests/monthly — server-defined target + reward.
    // Until then, static 20-workouts target with client-side completion count
    // derived from workoutsProvider.
    const target = 20;
    int completed = 0;
    try {
      final workoutsAsync = ref.watch(workoutsProvider);
      final list = workoutsAsync.asData?.value ?? const [];
      final monthStart = DateTime(now.year, now.month, 1);
      for (final w in list) {
        final iso = w.completedAt;
        if (iso == null) continue;
        final dt = DateTime.tryParse(iso);
        if (dt == null) continue;
        if (!dt.isBefore(monthStart) && dt.isBefore(DateTime(now.year, now.month + 1, 1))) {
          completed++;
        }
      }
    } catch (_) {}
    final progress = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/profile?tab=stats');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$monthName quest · $target workouts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$completed/$target',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: c.cardBorder.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation<Color>(c.accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ends ${_endOfMonthLabel(now)}',
              style: TextStyle(
                fontSize: 11,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[m - 1];
  }

  String _endOfMonthLabel(DateTime now) {
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return '${_monthName(now.month).substring(0, 3)} $lastDay';
  }
}
