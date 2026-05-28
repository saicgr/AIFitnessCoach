/// F3.80 — Jet-lag adjust card.
///
/// Detected via device timezone change ≥3h within the last 48h. Suggests a
/// recovery-first session, hydration emphasis, and a bedtime nudge anchored
/// to the new local timezone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_insights_v2_provider.dart';
import '../../../../data/services/haptic_service.dart';

class JetLagSignal {
  final int hoursShifted; // signed
  final String newTimezoneLabel;
  final int daysSinceShift;
  const JetLagSignal({
    required this.hoursShifted,
    required this.newTimezoneLabel,
    required this.daysSinceShift,
  });
}

/// Backed by `GET /api/v1/insights/jet-lag`. Persists the current device tz
/// server-side and returns a shift when the user's last-seen tz differs and
/// the change happened in the last 7 days. Null until the API responds or if
/// the API reports no shift.
final jetLagSignalProvider = Provider.autoDispose<JetLagSignal?>((ref) {
  final asyncRes = ref.watch(jetLagApiProvider);
  return asyncRes.maybeWhen(
    data: (api) {
      if (!api.hasShift) return null;
      return JetLagSignal(
        hoursShifted: api.shiftedHours!,
        newTimezoneLabel: api.currentTz ?? '',
        daysSinceShift: api.daysSinceShift ?? 0,
      );
    },
    orElse: () => null,
  );
});

class JetLagAdjustCard extends ConsumerWidget {
  const JetLagAdjustCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    JetLagSignal? signal;
    try {
      signal = ref.watch(jetLagSignalProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (signal == null ||
        signal.hoursShifted.abs() < 3 ||
        signal.daysSinceShift > 4) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    final eastward = signal.hoursShifted > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.flight_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Adjusting for ${signal.hoursShifted.abs()}h ${eastward ? "east" : "west"}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            "You're in ${signal.newTimezoneLabel}. For the next ${5 - signal.daysSinceShift} days, expect lower output. Today: lighter load, +500ml water, bedtime anchored to local clock.",
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('/workout/today');
            },
            child: Text(
              "See today's adjusted plan →",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
