/// F3.61 — Sunday weekly digest tile.
///
/// End-of-week recap tile that surfaces in the PageView Sunday evenings.
/// Tap routes to the profile stats tab where the full digest renders.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/weekly_plan.dart';
import '../../../../data/providers/weekly_plan_provider.dart';
import '../../../../data/services/haptic_service.dart';

class WeeklyDigestTile extends ConsumerWidget {
  final bool show;
  final int? workoutsCompleted;
  final int? workoutsPlanned;
  final String? topMuscleGroup;

  const WeeklyDigestTile({
    super.key,
    this.show = true,
    this.workoutsCompleted,
    this.workoutsPlanned,
    this.topMuscleGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    // Compute the week's completed/planned counts from the live weekly plan
    // when the caller doesn't override. Constructor values win for previews.
    int resolvedCompleted = workoutsCompleted ?? 0;
    int resolvedPlanned = workoutsPlanned ?? 0;
    if (workoutsCompleted == null || workoutsPlanned == null) {
      final plan = ref.watch(weeklyPlanProvider).currentPlan;
      if (plan != null) {
        final training =
            plan.dailyEntries.where((e) => e.dayType == DayType.training);
        resolvedPlanned = workoutsPlanned ?? training.length;
        resolvedCompleted =
            workoutsCompleted ?? training.where((e) => e.workoutCompleted).length;
      }
    }
    // TODO(backend): GET /api/v1/workouts/weekly-digest — top muscle group is
    // not currently surfaced by any provider; passed in by the ranker when known.

    final ratio = resolvedPlanned > 0
        ? (resolvedCompleted / resolvedPlanned).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/profile?tab=stats&source=weekly_digest');
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
            children: [
              Row(
                children: [
                  Text('📊', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'YOUR WEEK',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: c.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 18, color: c.textMuted),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                resolvedPlanned > 0
                    ? '$resolvedCompleted of $resolvedPlanned workouts'
                    : 'Recap your week',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: c.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                ),
              ),
              if (topMuscleGroup != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Most-worked: $topMuscleGroup',
                  style: TextStyle(
                      fontSize: 12, color: c.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
