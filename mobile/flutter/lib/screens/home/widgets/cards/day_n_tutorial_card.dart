/// F3.86 — Day-N tutorial card.
///
/// Teaches one feature per day during the first ~10 days of usage. Surfaces
/// progressively (day 2 → chat, day 3 → recipes, day 5 → progress, etc.)
/// and self-disables after the tutorial track completes or the user has
/// already touched the feature.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/haptic_service.dart';

class DayNTutorialStep {
  final int dayN;
  final String headline;
  final String body;
  final String ctaLabel;
  final String route;
  const DayNTutorialStep({
    required this.dayN,
    required this.headline,
    required this.body,
    required this.ctaLabel,
    required this.route,
  });
}

/// Static tutorial track keyed by day-since-signup. Day index is derived
/// from the auth user's `created_at` timestamp. Returns null after day 10
/// or when the user record is missing a creation date.
// TODO(backend): GET /api/v1/users/me/tutorial-progress to also gate steps
// the user has already completed (chat opened, recipe saved, etc.).
const _tutorialTrack = <int, DayNTutorialStep>{
  2: DayNTutorialStep(
    dayN: 2,
    headline: 'Meet your AI Coach',
    body:
        'Ask anything — workout swaps, sore knee, what to eat tonight. The Coach pulls from your plan and history.',
    ctaLabel: 'Open chat',
    route: '/chat',
  ),
  3: DayNTutorialStep(
    dayN: 3,
    headline: 'Snap a meal to log it',
    body:
        'Tap the camera in Nutrition. One photo → portions + macros, no typing.',
    ctaLabel: 'Try food scan',
    route: '/nutrition',
  ),
  4: DayNTutorialStep(
    dayN: 4,
    headline: 'Browse recipes built for your goal',
    body:
        'Recipes auto-filtered by your macros, allergies, and what you cooked last.',
    ctaLabel: 'See recipes',
    route: '/recipes',
  ),
  5: DayNTutorialStep(
    dayN: 5,
    headline: 'Track your progress',
    body:
        'Weight, photos, measurements — all in one place. The trend matters more than any single day.',
    ctaLabel: 'Open progress',
    route: '/progress',
  ),
  7: DayNTutorialStep(
    dayN: 7,
    headline: 'Week 1 done — check your insights',
    body:
        'Patterns the app spotted in your training, sleep, and food. Worth a 60-second skim.',
    ctaLabel: 'View insights',
    route: '/insights',
  ),
  10: DayNTutorialStep(
    dayN: 10,
    headline: 'Customize your home',
    body:
        'Hide cards you ignore, pin the ones you live in. Settings → Home layout.',
    ctaLabel: 'Customize',
    route: '/settings',
  ),
};

final dayNTutorialStepProvider =
    Provider.autoDispose<DayNTutorialStep?>((ref) {
  try {
    final user = ref.watch(authStateProvider).user;
    final createdRaw = user?.createdAt;
    if (createdRaw == null || createdRaw.isEmpty) return null;
    final created = DateTime.tryParse(createdRaw);
    if (created == null) return null;
    final dayIndex = DateTime.now().difference(created).inDays + 1;
    return _tutorialTrack[dayIndex];
  } catch (_) {
    return null;
  }
});

class DayNTutorialCard extends ConsumerWidget {
  const DayNTutorialCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DayNTutorialStep? step;
    try {
      step = ref.watch(dayNTutorialStepProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (step == null) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Day ${step.dayN}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                step.headline,
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
            step.body,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticService.light();
                  context.push(step!.route);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  step.ctaLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
