/// F3.27 — Bedtime window tile.
///
/// Suggests the optimal bedtime window for hitting the user's sleep target
/// before their wake alarm. Collapses when window not configured.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_signals_providers.dart';

/// Bedtime window derived from `GET /api/v1/users/me/sleep-target`.
///
/// Window opens 90 min before the derived bedtime and closes at the bedtime
/// itself; the upstream signal fires when `now >= bedtime - 90min`.
/// Self-collapses when wake alarm / target sleep are not configured.
final bedtimeWindowSignalProvider = Provider.autoDispose<
    ({String? windowStart, String? windowEnd, int? minutesUntilWindow})>((ref) {
  final target = ref.watch(sleepTargetProvider).valueOrNull;
  final bed = target?.derivedBedtimeLocalTime;
  if (bed == null) {
    return (windowStart: null, windowEnd: null, minutesUntilWindow: null);
  }
  // Window starts 90 min BEFORE bedtime; ends at bedtime.
  final now = DateTime.now();
  final minsUntilBed = minutesUntilLocal(bed, now);
  if (minsUntilBed == null) {
    return (windowStart: null, windowEnd: null, minutesUntilWindow: null);
  }
  // Window start = bedtime - 90 min.
  final parts = bed.split(':');
  final bedH = int.tryParse(parts[0]) ?? 22;
  final bedM = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final start = DateTime(now.year, now.month, now.day, bedH, bedM)
      .subtract(const Duration(minutes: 90));
  final startHHmm =
      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
  return (
    windowStart: startHHmm,
    windowEnd: bed,
    minutesUntilWindow: minsUntilBed - 0, // 0 when at bedtime; -90 mid-window
  );
});

class BedtimeWindowTile extends ConsumerWidget {
  /// "Start" of optimal bedtime (e.g. 22:30) — 24h "HH:mm".
  final String? windowStart;

  /// "End" of optimal bedtime — 24h "HH:mm".
  final String? windowEnd;

  /// Minutes remaining until window opens; negative = inside the window.
  final int? minutesUntilWindow;

  const BedtimeWindowTile({
    super.key,
    this.windowStart,
    this.windowEnd,
    this.minutesUntilWindow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(bedtimeWindowSignalProvider);
    final s = windowStart ?? signal.windowStart;
    final e = windowEnd ?? signal.windowEnd;
    if (s == null || e == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final mins = minutesUntilWindow ?? signal.minutesUntilWindow;

    String subtitle;
    if (mins == null) {
      subtitle = 'Tonight';
    } else if (mins <= 0 && mins > -90) {
      subtitle = 'Window is open now';
    } else if (mins > 0 && mins <= 180) {
      subtitle = 'Starts in ${mins}m';
    } else {
      subtitle = 'Tonight';
    }

    return Container(
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
              Icon(Icons.bedtime_outlined, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text(
                'Bedtime window',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$s – $e',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
