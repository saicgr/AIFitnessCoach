/// F3.48 — Daily quest deck. Surfaces today's 3 small quests (log a meal,
/// hit water target, complete workout). Static deck for now — designed to
/// be swapped in for a server-driven quest list when that endpoint ships.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/repositories/hydration_repository.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';

class DailyQuestDeck extends ConsumerWidget {
  const DailyQuestDeck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    // Best-effort completion checks.
    bool mealLogged = false;
    bool hydrationHit = false;
    bool workoutDone = false;
    try {
      final n = ref.watch(dailyNutritionProvider(todayNutritionKey()));
      final today = DateTime.now();
      mealLogged = n.logs.any((l) {
        final d = l.loggedAt.isUtc ? l.loggedAt.toLocal() : l.loggedAt;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      });
    } catch (_) {}
    try {
      final h = ref.watch(hydrationProvider);
      final goal = h.dailyGoalMl > 0 ? h.dailyGoalMl : 2000;
      hydrationHit = (h.todaySummary?.totalMl ?? 0) >= goal;
    } catch (_) {}
    try {
      workoutDone = ref.watch(todayWorkoutProvider).valueOrNull?.completedToday ?? false;
    } catch (_) {}

    final quests = <_Quest>[
      _Quest(
          icon: '🍽️',
          label: 'Log any meal',
          done: mealLogged,
          route: '/nutrition'),
      _Quest(
          icon: '💧',
          label: 'Hit water goal',
          done: hydrationHit,
          route: '/nutrition'),
      _Quest(
          icon: '🏋️',
          label: 'Finish today\'s workout',
          done: workoutDone,
          route: '/workouts'),
    ];
    final completed = quests.where((q) => q.done).length;

    return Container(
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
              Text(
                'Daily quests',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$completed / ${quests.length}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final q in quests) ...[
            _QuestRow(
              quest: q,
              onTap: () {
                HapticService.light();
                context.push(q.route);
              },
            ),
            if (q != quests.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _Quest {
  final String icon;
  final String label;
  final bool done;
  final String route;
  _Quest({
    required this.icon,
    required this.label,
    required this.done,
    required this.route,
  });
}

class _QuestRow extends StatelessWidget {
  final _Quest quest;
  final VoidCallback onTap;
  const _QuestRow({required this.quest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Text(quest.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                quest.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: quest.done ? c.textMuted : c.textPrimary,
                  decoration:
                      quest.done ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
            Icon(
              quest.done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 18,
              color: quest.done ? c.accent : c.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
