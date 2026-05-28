/// F3.34 — PMS prep card. Surfaces 3-5 days before next-period start so the
/// user can plan recovery / nutrition / training intensity. Collapses
/// outside that window or when prediction data is missing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/hormonal_health.dart';
import '../../../../data/providers/hormonal_health_provider.dart';
import '../../../../data/services/haptic_service.dart';

class PmsPrepCard extends ConsumerWidget {
  const PmsPrepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    bool tracks = false;
    try {
      tracks = ref.watch(hasHormonalTrackingProvider);
    } catch (_) {}
    if (!tracks) return const SizedBox.shrink();

    CyclePrediction? pred;
    try {
      pred = ref.watch(cyclePredictionProvider).valueOrNull;
    } catch (_) {}
    if (pred == null || !pred.predictionsAvailable) {
      return const SizedBox.shrink();
    }

    final days = pred.daysUntilNextPeriod;
    if (days == null || days < 1 || days > 5) {
      return const SizedBox.shrink();
    }
    // Only show in luteal phase (defensive — predictions sometimes label
    // the late-cycle window differently).
    if (pred.currentPhase != null && pred.currentPhase != CyclePhase.luteal) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/cycle');
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
                const Text('🌙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'PMS prep · $days day${days == 1 ? '' : 's'} out',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Tip(text: 'Lean toward lighter sessions and longer cooldowns.'),
            const SizedBox(height: 4),
            _Tip(text: 'Iron-rich meals + magnesium support cramps.'),
            const SizedBox(height: 4),
            _Tip(text: 'Sleep target +30 min for the next few nights.'),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, right: 6),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: c.textMuted,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
