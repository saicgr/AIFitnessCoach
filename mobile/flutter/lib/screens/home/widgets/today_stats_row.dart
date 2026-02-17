import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/health_service.dart';

/// Compact single-row tracking strip: Goals, Calories+Macros, Water, Burned.
class TodayStatsRow extends ConsumerWidget {
  const TodayStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _GoalsPill(key: const ValueKey('goals_pill'))),
          const SizedBox(width: 6),
          Expanded(flex: 2, child: _CaloriesPill(key: const ValueKey('calories_pill'))),
          const SizedBox(width: 6),
          Expanded(child: _WaterPill(key: const ValueKey('water_pill'))),
          const SizedBox(width: 6),
          Expanded(child: _BurnedPill(key: const ValueKey('burned_pill'))),
        ],
      ),
    );
  }
}

// =============================================================================
// Pill 1 - Goals (with mini indicators)
// =============================================================================

class _GoalsPill extends ConsumerWidget {
  const _GoalsPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyGoals = ref.watch(dailyGoalsProvider);

    final bool loggedIn = dailyGoals?.loggedIn ?? false;
    final bool loggedWeight = dailyGoals?.loggedWeight ?? false;
    final bool loggedMeal = dailyGoals?.loggedMeal ?? false;
    final bool completedWorkout = dailyGoals?.completedWorkout ?? false;

    int completed = 0;
    if (loggedIn) completed++;
    if (loggedWeight) completed++;
    if (loggedMeal) completed++;
    if (completedWorkout) completed++;

    final doneColor = const Color(0xFF22C55E);
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3);

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/xp-goals');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$completed/4',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _goalDot('L', loggedIn, doneColor, mutedColor),
              const SizedBox(width: 3),
              _goalDot('W', loggedWeight, doneColor, mutedColor),
              const SizedBox(width: 3),
              _goalDot('M', loggedMeal, doneColor, mutedColor),
              const SizedBox(width: 3),
              _goalDot('T', completedWorkout, doneColor, mutedColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalDot(String letter, bool done, Color doneColor, Color mutedColor) {
    return Tooltip(
      message: _tooltipFor(letter),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: done ? doneColor : mutedColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: done ? Colors.white : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }

  String _tooltipFor(String letter) {
    switch (letter) {
      case 'L': return 'Login';
      case 'W': return 'Log Weight';
      case 'M': return 'Log Meal';
      case 'T': return 'Train';
      default: return '';
    }
  }
}

// =============================================================================
// Pill 2 - Calories + Labeled Macros
// =============================================================================

class _CaloriesPill extends ConsumerWidget {
  const _CaloriesPill({super.key});

  static const Color _proteinColor = Color(0xFFEAB308);
  static const Color _carbsColor = Color(0xFF22C55E);
  static const Color _fatColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionState = ref.watch(nutritionProvider);
    final summary = nutritionState.todaySummary;

    final bool hasData = summary != null;
    final String calorieText =
        hasData ? _formatCalories(summary.totalCalories) : '--';
    final int proteinG = hasData ? summary.totalProteinG.round() : 0;
    final int carbsG = hasData ? summary.totalCarbsG.round() : 0;
    final int fatG = hasData ? summary.totalFatG.round() : 0;

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/nutrition');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$calorieText kcal',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _macroLabel('P', proteinG, _proteinColor),
              const SizedBox(width: 6),
              _macroLabel('C', carbsG, _carbsColor),
              const SizedBox(width: 6),
              _macroLabel('F', fatG, _fatColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroLabel(String letter, int grams, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$letter:',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          '${grams}g',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  String _formatCalories(int calories) {
    if (calories >= 1000) {
      final thousands = calories ~/ 1000;
      final remainder = calories % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return calories.toString();
  }
}

// =============================================================================
// Pill 3 - Water
// =============================================================================

class _WaterPill extends ConsumerWidget {
  const _WaterPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydrationState = ref.watch(hydrationProvider);
    final summary = hydrationState.todaySummary;
    final goalMl = hydrationState.dailyGoalMl;

    final bool hasData = summary != null;
    final double currentL = hasData ? summary.totalMl / 1000 : 0;
    final double goalL = goalMl / 1000;

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/hydration');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: currentL.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '/${goalL.toStringAsFixed(1)}L',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.water_drop_outlined,
            size: 14,
            color: currentL >= goalL
                ? const Color(0xFF3B82F6)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Pill 4 - Calories Burned
// =============================================================================

class _BurnedPill extends ConsumerWidget {
  const _BurnedPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(dailyActivityProvider);
    final syncState = ref.watch(healthSyncProvider);
    final activity = activityState.today;

    final bool connected = syncState.isConnected;
    final int burned = activity?.caloriesBurned.round() ?? 0;

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            connected ? '$burned' : '--',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.local_fire_department,
            size: 14,
            color: connected && burned > 0
                ? const Color(0xFFFF6B35)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared pill container
// =============================================================================

class _StatPillContainer extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _StatPillContainer({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
