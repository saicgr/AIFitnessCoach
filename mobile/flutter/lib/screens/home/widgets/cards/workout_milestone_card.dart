/// F3.64 — Workout milestone card (e.g. 100th workout, 1k sets).
///
/// Renders when a numeric milestone is hit. Pure presentation; the
/// SubCardRanker decides eligibility based on history.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_pattern_providers.dart';
import '../../../../data/services/haptic_service.dart';

/// F3.64 — Workout milestone celebration card.
///
/// Two modes:
///   1. **Self-driven** (no params): watches [workoutMilestoneProvider]
///      and renders only when a milestone was crossed in the last 7 days.
///   2. **Ranker-driven** (label/body provided): forces render — used by
///      the home SubCardRanker for canned celebrations.
class WorkoutMilestoneCard extends ConsumerWidget {
  final bool show;

  /// When `null`, the card consults the backend provider and decides
  /// itself whether to render (only when `just_crossed != null`).
  final String? milestoneLabel;
  final String? body;
  final String? shareDeepLink;

  const WorkoutMilestoneCard({
    super.key,
    this.show = true,
    this.milestoneLabel,
    this.body,
    this.shareDeepLink,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();

    // Self-driven mode: derive label/body from backend.
    final isSelfDriven = milestoneLabel == null && body == null;
    String resolvedLabel;
    String resolvedBody;
    if (isSelfDriven) {
      final async = ref.watch(workoutMilestoneProvider);
      final data = async.asData?.value;
      // Render only when the backend reports a milestone crossed in the
      // last 7 days. Otherwise self-collapse — never leak loading/error
      // states onto the home screen.
      if (data == null || data.justCrossed == null) {
        return const SizedBox.shrink();
      }
      resolvedLabel = '${data.justCrossed} workouts';
      resolvedBody = 'You showed up — over and over. Share it?';
    } else {
      resolvedLabel = milestoneLabel ?? '100 workouts';
      resolvedBody = body ?? 'You showed up — over and over. Share it?';
    }

    final c = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events,
                  color: c.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedLabel,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    resolvedBody,
                    style: TextStyle(
                        fontSize: 12,
                        color: c.textSecondary,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                HapticService.light();
                context.push(shareDeepLink ?? '/profile?tab=stats');
              },
              style: TextButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.accentContrast,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Share',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
