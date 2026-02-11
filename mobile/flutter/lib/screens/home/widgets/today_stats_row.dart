import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Compact row of 3 stat pills: Goals, Calories, Water.
/// Displayed on the home screen beneath the hero section.
class TodayStatsRow extends ConsumerWidget {
  const TodayStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _GoalsPill(key: const ValueKey('goals_pill'))),
          const SizedBox(width: 8),
          Expanded(child: _CaloriesPill(key: const ValueKey('calories_pill'))),
          const SizedBox(width: 8),
          Expanded(child: _WaterPill(key: const ValueKey('water_pill'))),
        ],
      ),
    );
  }
}

// =============================================================================
// Pill 1 - Goals
// =============================================================================

class _GoalsPill extends ConsumerWidget {
  const _GoalsPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyGoals = ref.watch(dailyGoalsProvider);

    // Count the 4 main goals: login, weight, meal, workout
    int completed = 0;
    if (dailyGoals != null) {
      if (dailyGoals.loggedIn) completed++;
      if (dailyGoals.loggedWeight) completed++;
      if (dailyGoals.loggedMeal) completed++;
      if (dailyGoals.completedWorkout) completed++;
    }
    const int total = 4;

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/xp-goals');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$completed/$total',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'goals',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Pill 2 - Calories
// =============================================================================

class _CaloriesPill extends ConsumerWidget {
  const _CaloriesPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionState = ref.watch(nutritionProvider);
    final summary = nutritionState.todaySummary;

    final bool hasData = summary != null;
    final String calorieText =
        hasData ? _formatCalories(summary.totalCalories) : '--';
    final int proteinG = hasData ? summary.totalProteinG.round() : 0;
    final int fatG = hasData ? summary.totalFatG.round() : 0;
    final int carbsG = hasData ? summary.totalCarbsG.round() : 0;

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/nutrition');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$calorieText kcal',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          hasData
              ? _MacroDotsRow(
                  proteinG: proteinG,
                  fatG: fatG,
                  carbsG: carbsG,
                )
              : Text(
                  '-- macros',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
        ],
      ),
    );
  }

  /// Format calories with comma separator (e.g., 1,850)
  String _formatCalories(int calories) {
    if (calories >= 1000) {
      final thousands = calories ~/ 1000;
      final remainder = calories % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return calories.toString();
  }
}

/// Row of colored dots with macro gram values.
/// Yellow = protein, Red = fat, Green = carbs (standard nutrition colors).
class _MacroDotsRow extends StatelessWidget {
  final int proteinG;
  final int fatG;
  final int carbsG;

  const _MacroDotsRow({
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
  });

  // Standard nutrition macro colors
  static const Color _proteinColor = Color(0xFFEAB308); // Yellow
  static const Color _fatColor = Color(0xFFEF4444); // Red
  static const Color _carbsColor = Color(0xFF22C55E); // Green

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _macroDot(_proteinColor, '${proteinG}g'),
        _separator(context),
        _macroDot(_fatColor, '${fatG}g'),
        _separator(context),
        _macroDot(_carbsColor, '${carbsG}g'),
      ],
    );
  }

  Widget _macroDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _separator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        '\u00B7',
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
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

    final bool hasData = summary != null;
    final String waterText = hasData
        ? '${(summary.totalMl / 1000).toStringAsFixed(1)}L'
        : '--';

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/hydration');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            waterText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'water',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
