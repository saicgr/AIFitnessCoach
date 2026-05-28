/// F3.29 — Sleep latency tile.
///
/// Minutes from bed-in to first sleep stage last night. Healthy range is
/// roughly 10–20 min — < 5 may signal sleep debt; > 30 may signal stress or
/// late caffeine. Collapses when no data.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/recovery_provider.dart';

/// Last night's sleep latency in minutes, pulled from the real
/// `sleepProvider` (HealthKit / Health Connect bridge in
/// `health_service_ui.dart` — `_SleepSessionAgg.latencyMinutes`). Null until
/// at least one staged sleep session lands, which keeps the tile collapsed.
final sleepLatencySignalProvider = Provider.autoDispose<int?>((ref) {
  final async = ref.watch(sleepProvider);
  return async.maybeWhen(
    data: (summary) => summary?.latencyMinutes,
    orElse: () => null,
  );
});

class SleepLatencyTile extends ConsumerWidget {
  /// Minutes-to-sleep last night. Null → collapsed.
  final int? latencyMinutes;

  const SleepLatencyTile({super.key, this.latencyMinutes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lat = latencyMinutes ?? ref.watch(sleepLatencySignalProvider);
    if (lat == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    final String label;
    final Color labelColor;
    if (lat < 5) {
      label = 'Possibly sleep-deprived';
      labelColor = c.warning;
    } else if (lat <= 20) {
      label = 'Healthy';
      labelColor = c.success;
    } else if (lat <= 30) {
      label = 'A bit elevated';
      labelColor = c.warning;
    } else {
      label = 'High — check caffeine, stress';
      labelColor = c.error;
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
              Icon(Icons.nights_stay_outlined, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text(
                'Sleep latency',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$lat',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'min to sleep',
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
