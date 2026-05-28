/// F3.83 — Weigh-in day chip.
///
/// Compact chip-style tile that surfaces on the user's chosen weigh-in
/// weekday (defaults to Monday). One-tap → /weight log entry. Collapses if
/// today doesn't match the weigh-in cadence or a weight was already logged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_insights_v2_provider.dart';
import '../../../../data/services/haptic_service.dart';

class WeighInDaySignal {
  /// 1 = Monday … 7 = Sunday (matches DateTime.weekday).
  final int weighInWeekday;
  final bool alreadyLoggedToday;
  const WeighInDaySignal({
    required this.weighInWeekday,
    required this.alreadyLoggedToday,
  });
}

/// Backed by `GET /api/v1/insights/weigh-in-day-pref`. Falls back to Monday
/// when no pref is persisted (matches the API contract: `weekday: null`).
/// `alreadyLoggedToday` is derived from `last_weigh_in_at`.
final weighInDaySignalProvider = Provider.autoDispose<WeighInDaySignal?>((ref) {
  final async = ref.watch(weighInDayPrefApiProvider);
  return async.maybeWhen(
    data: (api) => WeighInDaySignal(
      weighInWeekday: api.dartWeekday ?? DateTime.monday,
      alreadyLoggedToday: api.loggedToday,
    ),
    orElse: () => null,
  );
});

class WeighInDayChip extends ConsumerWidget {
  const WeighInDayChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WeighInDaySignal? signal;
    try {
      signal = ref.watch(weighInDaySignalProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (signal == null || signal.alreadyLoggedToday) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now();
    if (now.weekday != signal.weighInWeekday) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/weight/log');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.monitor_weight_rounded, size: 18, color: c.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weigh-in day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Same time, same conditions — keeps the trend honest.',
                      style: TextStyle(fontSize: 11.5, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
