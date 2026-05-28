/// F3.36 — One-tap period symptom log tile. Shows during menstrual phase
/// so the user can drop a flow / symptom marker for the day. Tapping
/// routes to the cycle screen logger.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/hormonal_health.dart';
import '../../../../data/providers/hormonal_health_provider.dart';
import '../../../../data/services/haptic_service.dart';

class PeriodSymptomLogTile extends ConsumerWidget {
  const PeriodSymptomLogTile({super.key});

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
    if (pred == null) return const SizedBox.shrink();
    final inPeriod = pred.inPeriod || pred.currentPhase == CyclePhase.menstrual;
    if (!inPeriod) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/cycle?tab=log');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            const Text('🩸', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Log today\'s symptoms',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Flow, cramps, mood — a few taps.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
