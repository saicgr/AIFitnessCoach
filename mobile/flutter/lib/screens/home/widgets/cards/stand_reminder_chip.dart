/// F3.22 — Stand reminder chip.
///
/// Apple-Watch-style "stand for at least 1 min per waking hour" chip. Shows
/// today's count of stand hours and the goal. Collapses when no data.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/haptic_service.dart';

// TODO(backend): GET /api/v1/health/stand-hours/today — Apple-Watch-style
// "stand hours" is HealthKit `appleStandHour` on iOS (per-hour stand event)
// and has no Health Connect equivalent on Android. The `health` Dart package
// does not currently expose APPLE_STAND_HOUR, and `DailyActivity` has no
// `standHours` column, so the chip stays collapsed until either an HK bridge
// or a backend per-hour sedentary breakdown is added.
final standReminderSignalProvider = Provider.autoDispose<int?>((ref) => null);

class StandReminderChip extends ConsumerWidget {
  /// Stand hours achieved today.
  final int? hoursAchieved;

  /// Goal stand hours (typically 12).
  final int goal;

  /// Optional tap handler — typically logs a quick stand minute via the
  /// hourly-stand nudge action.
  final VoidCallback? onLogStand;

  const StandReminderChip({
    super.key,
    this.hoursAchieved,
    this.goal = 12,
    this.onLogStand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = hoursAchieved ?? ref.watch(standReminderSignalProvider);
    if (h == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final pct = (h / goal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onLogStand?.call();
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
                Icon(Icons.accessibility_new, size: 16, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  'Stand hours',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '$h / $goal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: c.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(c.accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Move once per waking hour',
              style: TextStyle(fontSize: 11.5, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
