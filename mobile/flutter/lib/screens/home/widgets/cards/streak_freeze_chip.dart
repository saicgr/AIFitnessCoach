/// F3.47 / B9 — Banked streak-freeze chip. Surfaces how many freeze tokens the
/// user has available plus the cadence toward their next AUTO-EARNED freeze
/// (one per 10 weeks of activity). Tapping opens the streak timeframe sheet.
///
/// Refreshed UI (B9):
///   * Reads the live `/xp/freeze-status` (auto-earns server-side) instead of
///     just the cached balance — so the count is always current.
///   * When the status reports `justEarnedFreeze`, fires the freeze-earned
///     celebration once.
///   * Shows a thin "next free freeze" progress bar so the reward feels earned.
///   * Falls back to the cached `xpFreezesAvailableProvider` balance while the
///     network status is loading, so the chip never flickers empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/streak_freeze_provider.dart';
import '../../../../data/providers/xp_provider.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../widgets/freeze_earned_dialog.dart';
import '../../../../widgets/streak_timeframe_sheet.dart';

class StreakFreezeChip extends ConsumerStatefulWidget {
  const StreakFreezeChip({super.key});

  @override
  ConsumerState<StreakFreezeChip> createState() => _StreakFreezeChipState();
}

class _StreakFreezeChipState extends ConsumerState<StreakFreezeChip> {
  bool _celebrated = false;

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    // Cached balance as a non-flickering fallback.
    int cachedBalance = 0;
    try {
      cachedBalance = ref.watch(xpFreezesAvailableProvider);
    } catch (_) {
      cachedBalance = 0;
    }

    final statusAsync = ref.watch(streakFreezeStatusProvider);

    // Fire the freeze-earned celebration exactly once when the status reports
    // a freeze was just auto-earned.
    statusAsync.whenData((status) {
      if (status.justEarnedFreeze && !_celebrated) {
        _celebrated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showFreezeEarnedDialog(
            context,
            freezesAvailable: status.freezesAvailable,
            currentStreak: status.currentStreak,
          );
        });
      }
    });

    final status = statusAsync.asData?.value;
    final freezes = status?.freezesAvailable ?? cachedBalance;
    if (freezes <= 0) return const SizedBox.shrink();

    final progress = status?.progressToNextFreeze ?? 0.0;
    final untilNext = status?.streakUntilNextFreeze;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        showStreakTimeframeSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧊', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$freezes streak freeze${freezes == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      untilNext != null && untilNext > 0
                          ? '$untilNext days to your next free one'
                          : 'Protects a missed day.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: c.textSecondary.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
