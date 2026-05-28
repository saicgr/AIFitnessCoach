/// F3.110 — Equipment preflight banner.
///
/// Shows in the T-30 pre-workout band: lists the equipment today's session
/// requires (e.g. "Barbell · DBs 35lb · Bench") so the user can verify
/// before walking into the gym. Self-collapses if no workout scheduled or
/// equipment list is empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/environment_equipment_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';

class EquipmentPreflightBanner extends ConsumerWidget {
  const EquipmentPreflightBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull?.todayWorkout;
    if (today == null) return const SizedBox.shrink();

    final hour = DateTime.now().hour;
    if (hour < 16 || hour >= 20) return const SizedBox.shrink();

    // Collect distinct equipment items required by today's exercises, then
    // surface the ones the user has NOT marked as owned in their gym
    // environment profile. If everything is owned (or nothing tagged),
    // the banner self-collapses — no point shouting "you have a barbell."
    final requiredRaw = <String>{};
    for (final ex in today.exercises) {
      final e = (ex.equipment ?? '').trim();
      if (e.isEmpty || e.toLowerCase() == 'none' || e.toLowerCase() == 'body only') {
        continue;
      }
      requiredRaw.add(e);
    }
    if (requiredRaw.isEmpty) return const SizedBox.shrink();

    final owned = ref
        .watch(environmentEquipmentProvider)
        .equipment
        .map((e) => e.toLowerCase().trim())
        .toSet();
    final equipment = owned.isEmpty
        ? requiredRaw.toList(growable: false)
        : requiredRaw
            .where((e) => !owned.contains(e.toLowerCase()))
            .toList(growable: false);
    if (equipment.isEmpty) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/workout/${today.id}', extra: today);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: c.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Equipment check',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in equipment)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
