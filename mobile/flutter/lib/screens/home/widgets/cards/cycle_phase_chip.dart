/// F3.32 — Compact cycle-phase chip showing the user's current cycle phase
/// + day-of-cycle. Reads [cyclePredictionProvider]; collapses if the user
/// doesn't track menstrual cycles or predictions are unavailable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/hormonal_health.dart';
import '../../../../data/providers/hormonal_health_provider.dart';
import '../../../../data/services/haptic_service.dart';

class CyclePhaseChip extends ConsumerWidget {
  const CyclePhaseChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    final tracks = _safeBool(() => ref.watch(hasHormonalTrackingProvider));
    if (!tracks) return const SizedBox.shrink();

    final pred = _safeRead<CyclePrediction?>(
      () => ref.watch(cyclePredictionProvider).valueOrNull,
    );
    if (pred == null || !pred.predictionsAvailable) {
      return const SizedBox.shrink();
    }
    final phase = pred.currentPhase;
    final day = pred.currentCycleDay;
    if (phase == null || day == null) return const SizedBox.shrink();

    final label = _phaseLabel(phase);
    final emoji = _phaseEmoji(phase);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/cycle');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Day $day of cycle',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(CyclePhase p) {
    switch (p) {
      case CyclePhase.menstrual:
        return 'Menstrual phase';
      case CyclePhase.follicular:
        return 'Follicular phase';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal phase';
    }
  }

  String _phaseEmoji(CyclePhase p) {
    switch (p) {
      case CyclePhase.menstrual:
        return '🩸';
      case CyclePhase.follicular:
        return '🌱';
      case CyclePhase.ovulation:
        return '🌸';
      case CyclePhase.luteal:
        return '🌙';
    }
  }
}

bool _safeBool(bool Function() fn) {
  try {
    return fn();
  } catch (_) {
    return false;
  }
}

T? _safeRead<T>(T? Function() fn) {
  try {
    return fn();
  } catch (_) {
    return null;
  }
}
