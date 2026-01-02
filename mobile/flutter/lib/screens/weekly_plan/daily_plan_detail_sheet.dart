import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers/weekly_plan_provider.dart';

/// Detailed view of a single day's plan
class DailyPlanDetailSheet extends ConsumerWidget {
  final DailyPlanEntry entry;

  const DailyPlanDetailSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                _buildHeader(context),

                // Workout Section (if training day)
                if (entry.dayType == DayType.training)
                  _buildWorkoutSection(context),

                // Nutrition Targets
                _buildNutritionSection(context),

                // Fasting Window
                if (entry.eatingWindowStart != null)
                  _buildFastingSection(context),

                // Meal Suggestions
                if (entry.mealSuggestions.isNotEmpty)
                  _buildMealSuggestionsSection(context, ref),

                // Coordination Notes
                if (entry.coordinationNotes.isNotEmpty)
                  _buildNotesSection(context),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: entry.dayType.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              entry.dayType.icon,
              color: entry.dayType.color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.dayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (entry.isToday) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'TODAY',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.dayType.displayName,
                  style: TextStyle(
                    color: entry.dayType.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Workout',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              if (entry.workoutCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.workoutFocus ?? 'Scheduled Workout',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (entry.workoutTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  entry.workoutTime!,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
                if (entry.workoutDurationMinutes != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.workoutDurationMinutes} min',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (!entry.workoutCompleted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to workout or start workout
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Nutrition Targets',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  context,
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: '${entry.calorieTarget}',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  context,
                  icon: Icons.egg_alt,
                  label: 'Protein',
                  value: '${entry.proteinTargetG.toInt()}g',
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  context,
                  icon: Icons.bakery_dining,
                  label: 'Carbs',
                  value: '${entry.carbsTargetG.toInt()}g',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  context,
                  icon: Icons.water_drop,
                  label: 'Fat',
                  value: '${entry.fatTargetG.toInt()}g',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastingSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Fasting Window',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Spacer(),
              if (entry.fastingProtocol != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    entry.fastingProtocol!,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeBlock(
                context,
                label: 'Eating Starts',
                time: entry.eatingWindowStart ?? '--:--',
                icon: Icons.restaurant,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.arrow_forward,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              _buildTimeBlock(
                context,
                label: 'Eating Ends',
                time: entry.eatingWindowEnd ?? '--:--',
                icon: Icons.no_food,
              ),
            ],
          ),
          if (entry.fastingDurationHours != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${entry.fastingDurationHours}h fast',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeBlock(
    BuildContext context, {
    required String label,
    required String time,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.orange),
        const SizedBox(height: 6),
        Text(
          time,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMealSuggestionsSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Meal Suggestions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  // Regenerate meals
                  final suggestions = await ref
                      .read(weeklyPlanProvider.notifier)
                      .regenerateMealSuggestions(entry);
                  if (suggestions != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meals regenerated!')),
                    );
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entry.mealSuggestions.map(
            (meal) => _buildMealCard(context, meal),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, MealSuggestion meal) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(meal.mealTypeIcon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                meal.mealTypeDisplay,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                meal.suggestedTime,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...meal.foods.map(
            (food) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${food.name} (${food.amount})',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${food.calories} cal',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (meal.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              meal.notes!,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMealMacroChip('${meal.totalCalories ?? 0} cal', Colors.orange),
              const SizedBox(width: 8),
              _buildMealMacroChip(
                  '${meal.totalProteinG?.toInt() ?? 0}g protein', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealMacroChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Notes & Warnings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entry.coordinationNotes.map(
            (note) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: note.severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: note.severityColor.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(note.severityIcon, color: note.severityColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.message,
                          style: TextStyle(
                            color: note.severityColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (note.suggestion != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            note.suggestion!,
                            style: TextStyle(
                              color: note.severityColor.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
