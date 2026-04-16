import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/providers/consistency_provider.dart';
import '../../../data/providers/habit_provider.dart';
import '../../../data/providers/recovery_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/repositories/sauna_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/health_service.dart';
import '../../nutrition/widgets/calories_burned_sheet.dart';
import 'edit_tracking_sheet.dart';

/// Compact single-row tracking strip: Goals, Calories+Macros, Water, Burned.
class TodayStatsRow extends ConsumerWidget {
  const TodayStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pills = ref.watch(trackingPillsProvider);

    final pillWidgets = <Widget>[];

    if (pills.showGoals) pillWidgets.add(const _GoalsPill(key: ValueKey('goals_pill')));
    if (pills.showNutrition) pillWidgets.add(const _NutritionPill(key: ValueKey('nutrition_pill')));
    if (pills.showBurned) pillWidgets.add(const _BurnedPill(key: ValueKey('burned_pill')));
    if (pills.showSteps) pillWidgets.add(const _StepsPill(key: ValueKey('steps_pill')));
    if (pills.showSleep) pillWidgets.add(const _SleepPill(key: ValueKey('sleep_pill')));
    if (pills.showStreak) pillWidgets.add(const _StreakPill(key: ValueKey('streak_pill')));
    if (pills.showHabits) pillWidgets.add(const _HabitsPill(key: ValueKey('habits_pill')));

    if (pillWidgets.isEmpty) return const SizedBox.shrink();

    // Use Expanded row for <=4 pills, scrollable row for 5+
    if (pillWidgets.length <= 4) {
      final children = <Widget>[];
      for (int i = 0; i < pillWidgets.length; i++) {
        if (i > 0) children.add(const SizedBox(width: 6));
        // Nutrition pill gets double width for calories + macros + water
        final flex = (pillWidgets[i].key == const ValueKey('nutrition_pill')) ? 2 : 1;
        children.add(Expanded(flex: flex, child: pillWidgets[i]));
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: children),
      );
    }

    // Scrollable for 5+ pills
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 68,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: pillWidgets.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => SizedBox(
            width: MediaQuery.of(context).size.width * 0.22,
            child: pillWidgets[i],
          ),
        ),
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: completed > 0 ? doneColor : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _goalDot('L', loggedIn, doneColor, mutedColor),
                const SizedBox(width: 2),
                _goalDot('W', loggedWeight, doneColor, mutedColor),
                const SizedBox(width: 2),
                _goalDot('M', loggedMeal, doneColor, mutedColor),
                const SizedBox(width: 2),
                _goalDot('T', completedWorkout, doneColor, mutedColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalDot(String letter, bool done, Color doneColor, Color mutedColor) {
    return Tooltip(
      message: _tooltipFor(letter),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: done ? doneColor : mutedColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 7,
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
// Pill 2 - Nutrition (Calories + Macros + Water combined)
// =============================================================================

class _NutritionPill extends ConsumerWidget {
  const _NutritionPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionState = ref.watch(nutritionProvider);
    final summary = nutritionState.todaySummary;
    final hydrationState = ref.watch(hydrationProvider);
    final waterSummary = hydrationState.todaySummary;
    final goalMl = hydrationState.dailyGoalMl;

    final bool hasNutrition = summary != null;
    final String calorieText =
        hasNutrition ? _formatCalories(summary.totalCalories) : '--';
    final int proteinG = hasNutrition ? summary.totalProteinG.round() : 0;
    final int carbsG = hasNutrition ? summary.totalCarbsG.round() : 0;
    final int fatG = hasNutrition ? summary.totalFatG.round() : 0;

    final double currentL = waterSummary != null ? waterSummary.totalMl / 1000 : 0;
    final double goalL = goalMl / 1000;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final waterColor = currentL >= goalL
        ? const Color(0xFF3B82F6)
        : const Color(0xFF60A5FA);

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/nutrition');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Calories + Water
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  calorieText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF6B35),
                  ),
                ),
                Text(
                  ' kcal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.water_drop, size: 13, color: waterColor),
                const SizedBox(width: 2),
                Text(
                  '${currentL.toStringAsFixed(1)}L',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: waterColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          // Row 2: Macros spanning full width with colors
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              maxLines: 1,
              text: TextSpan(
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                children: [
                  TextSpan(text: 'P:${proteinG}g', style: TextStyle(color: isDark ? AppColors.macroProtein : AppColorsLight.macroProtein)),
                  const TextSpan(text: '  '),
                  TextSpan(text: 'C:${carbsG}g', style: TextStyle(color: isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs)),
                  const TextSpan(text: '  '),
                  TextSpan(text: 'F:${fatG}g', style: TextStyle(color: isDark ? AppColors.macroFat : AppColorsLight.macroFat)),
                ],
              ),
            ),
          ),
        ],
      ),
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
    final int healthBurned = activity?.caloriesBurned.round() ?? 0;

    // Include sauna calories in burned total
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;
    final saunaAsync = userId != null ? ref.watch(dailySaunaProvider(userId)) : null;
    final saunaCal = saunaAsync?.valueOrNull?.totalCalories ?? 0;
    final burned = healthBurned + saunaCal;

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        if ((connected && healthBurned > 0) || saunaCal > 0) {
          showCaloriesBurnedSheet(context, burned.toDouble());
        } else {
          context.push('/stats');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            connected || saunaCal > 0 ? '$burned' : '--',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: (connected && healthBurned > 0) || saunaCal > 0
                  ? const Color(0xFFFF6B35)
                  : Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.local_fire_department,
            size: 14,
            color: (connected && healthBurned > 0) || saunaCal > 0
                ? const Color(0xFFFF6B35)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Pill 5 - Steps
// =============================================================================

class _StepsPill extends ConsumerWidget {
  const _StepsPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(dailyActivityProvider);
    final syncState = ref.watch(healthSyncProvider);
    final activity = activityState.today;

    final bool connected = syncState.isConnected;
    final int steps = activity?.steps ?? 0;

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            connected ? _formatSteps(steps) : '--',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: connected && steps > 0
                  ? const Color(0xFF8B5CF6)
                  : Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.directions_walk,
            size: 14,
            color: connected && steps > 0
                ? const Color(0xFF8B5CF6)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      final k = steps / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return steps.toString();
  }
}

// =============================================================================
// Pill 6 - Sleep
// =============================================================================

class _SleepPill extends ConsumerWidget {
  const _SleepPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepAsync = ref.watch(sleepProvider);
    final syncState = ref.watch(healthSyncProvider);
    final connected = syncState.isConnected;

    final sleep = sleepAsync.valueOrNull;
    final int totalMin = sleep?.totalMinutes ?? 0;
    final int hours = totalMin ~/ 60;
    final int mins = totalMin % 60;

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            connected && totalMin > 0 ? '${hours}h${mins > 0 ? ' ${mins}m' : ''}' : '--',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: connected && totalMin > 0
                  ? const Color(0xFF6366F1)
                  : Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.bedtime_outlined,
            size: 14,
            color: connected && totalMin > 0
                ? const Color(0xFF6366F1)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Pill 7 - Workout Streak
// =============================================================================

class _StreakPill extends ConsumerWidget {
  const _StreakPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consistencyState = ref.watch(consistencyProvider);
    final streak = consistencyState.currentStreak;
    final isActive = consistencyState.isStreakActive;

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isActive && streak > 0
                  ? const Color(0xFFF59E0B)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.bolt_outlined,
            size: 14,
            color: isActive && streak > 0
                ? const Color(0xFFF59E0B)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Pill 8 - Habits
// =============================================================================

class _HabitsPill extends ConsumerWidget {
  const _HabitsPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return _StatPillContainer(
        onTap: () {},
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('--', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Icon(Icons.check_circle_outline, size: 14),
          ],
        ),
      );
    }

    final habitsState = ref.watch(habitsProvider(userId));
    final completed = habitsState.completedToday;
    final total = habitsState.totalHabits;
    final allDone = habitsState.allCompleted;

    return _StatPillContainer(
      onTap: () {
        HapticService.light();
        context.push('/habits');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            total > 0 ? '$completed/$total' : '--',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: completed > 0
                  ? const Color(0xFF10B981)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            allDone ? Icons.check_circle : Icons.check_circle_outline,
            size: 14,
            color: allDone
                ? const Color(0xFF10B981)
                : (completed > 0
                    ? const Color(0xFF10B981).withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.onSurfaceVariant),
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
    final textColor = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DefaultTextStyle(
          style: TextStyle(color: textColor),
          child: child,
        ),
      ),
    );
  }
}
