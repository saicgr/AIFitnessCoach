/// First-time / minimal-data setup card — replaces the broken-looking empty
/// rings row when the user has 0-1 applicable score contributors.
///
/// Plan §11. Renders a 4-step checklist (workout plan / nutrition targets /
/// Health Connect / first sleep night) each deep-linking to its setup
/// surface. Steps auto-tick as the user completes them; once `>1` pillars
/// apply the parent `TodayScoreCard` switches back to the ring row.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/providers/sleep_detail_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/health_service.dart' show healthSyncProvider;
import '../../../widgets/health_connect_sheet.dart';

class TodayScoreSetupCard extends ConsumerWidget {
  const TodayScoreSetupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    // Derive completion per step. Each is independent so a user who has e.g.
    // connected Health but not yet built a plan sees the right partial state.
    final hasPlan = ref.watch(workoutsProvider).maybeWhen(
          data: (workouts) => workouts.isNotEmpty,
          orElse: () => false,
        );
    final hasNutrition =
        ref.watch(nutritionPreferencesProvider).currentCalorieTarget > 0;
    final healthConnected = ref.watch(healthSyncProvider).isConnected;
    final hasFirstSleep = ref.watch(sleepHistoryProvider).maybeWhen(
          data: (h) => h.nights.isNotEmpty,
          orElse: () => false,
        );

    final steps = <_SetupStep>[
      _SetupStep(
        label: 'Add a workout plan',
        done: hasPlan,
        onTap: () => context.push('/workout/build'),
      ),
      _SetupStep(
        label: 'Set nutrition targets',
        done: hasNutrition,
        onTap: () => context.push('/nutrition-settings'),
      ),
      _SetupStep(
        label: 'Connect Health',
        done: healthConnected,
        onTap: () => showHealthConnectSheet(context, ref),
      ),
      _SetupStep(
        label: 'Track your first sleep',
        done: hasFirstSleep,
        // Auto-completes once a night syncs. Tapping just nudges health-connect
        // if not yet linked; otherwise a no-op friendly tooltip would be
        // overkill — silently route to the sheet so the user has somewhere to
        // go if they're stuck.
        onTap: () => healthConnected
            ? null
            : showHealthConnectSheet(context, ref),
      ),
    ];

    final firstIncomplete = steps.indexWhere((s) => !s.done);
    final completedCount = steps.where((s) => s.done).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'GET STARTED · $completedCount/${steps.length}',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            firstIncomplete == -1
                ? "You're all set"
                : 'Unlock your day score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          for (final step in steps) _SetupRow(step: step, c: c),
          if (firstIncomplete != -1) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: steps[firstIncomplete].onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.accentContrast,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text('Continue: ${steps[firstIncomplete].label}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetupStep {
  final String label;
  final bool done;
  // Nullable so the "track first sleep" row can be a no-op once it's already
  // ticked.
  final VoidCallback? onTap;
  _SetupStep({required this.label, required this.done, required this.onTap});
}

class _SetupRow extends StatelessWidget {
  final _SetupStep step;
  final ThemeColors c;
  const _SetupRow({required this.step, required this.c});

  @override
  Widget build(BuildContext context) {
    final iconBg = step.done
        ? const Color(0xFF3FA66B).withValues(alpha: 0.18)
        : c.cardBorder.withValues(alpha: 0.6);
    final iconColor =
        step.done ? const Color(0xFF3FA66B) : c.textMuted;

    return InkWell(
      onTap: step.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.done ? Icons.check_rounded : Icons.circle_outlined,
                size: 14,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                step.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: step.done ? FontWeight.w500 : FontWeight.w700,
                  color: step.done ? c.textMuted : c.textPrimary,
                  decoration:
                      step.done ? TextDecoration.lineThrough : null,
                  decorationColor: c.textMuted,
                ),
              ),
            ),
            if (step.onTap != null && !step.done)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
