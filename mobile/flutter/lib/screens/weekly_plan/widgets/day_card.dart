import 'package:flutter/material.dart';
import '../../../data/models/weekly_plan.dart';

/// Card widget for a single day in the weekly plan
class DayCard extends StatelessWidget {
  final DailyPlanEntry entry;
  final VoidCallback onTap;

  const DayCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isToday = entry.isToday;

    return Card(
      elevation: isToday ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isToday
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day header row
              Row(
                children: [
                  // Day type icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: entry.dayType.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      entry.dayType.icon,
                      color: entry.dayType.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Day name and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              entry.dayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          entry.dayType.displayName,
                          style: TextStyle(
                            color: entry.dayType.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Completion indicators
                  if (entry.dayType == DayType.training) ...[
                    _buildCompletionIndicator(
                      context,
                      isCompleted: entry.workoutCompleted,
                      icon: Icons.fitness_center,
                      color: Colors.green,
                    ),
                  ],
                  if (entry.eatingWindowStart != null) ...[
                    const SizedBox(width: 6),
                    _buildCompletionIndicator(
                      context,
                      isCompleted: entry.fastingCompleted,
                      icon: Icons.timer,
                      color: Colors.orange,
                    ),
                  ],
                  const SizedBox(width: 6),
                  _buildCompletionIndicator(
                    context,
                    isCompleted: entry.nutritionLogged,
                    icon: Icons.restaurant,
                    color: Colors.blue,
                  ),

                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              // Divider
              if (entry.dayType == DayType.training ||
                  entry.mealSuggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 12),
              ],

              // Training day info
              if (entry.dayType == DayType.training) ...[
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.workoutFocus ?? 'Workout',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (entry.workoutTime != null)
                      Text(
                        entry.workoutTime!,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Nutrition targets row
              Row(
                children: [
                  _buildMacroChip(
                    context,
                    icon: Icons.local_fire_department,
                    value: '${entry.calorieTarget}',
                    label: 'cal',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildMacroChip(
                    context,
                    icon: Icons.egg_alt,
                    value: '${entry.proteinTargetG.toInt()}g',
                    label: 'protein',
                    color: Colors.red,
                  ),
                  const Spacer(),
                  if (entry.eatingWindowDisplay != null)
                    Text(
                      entry.eatingWindowDisplay!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),

              // Warnings
              if (entry.hasWarnings) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${entry.coordinationNotes.length} note(s)',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionIndicator(
    BuildContext context, {
    required bool isCompleted,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isCompleted ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isCompleted ? Icons.check : icon,
        size: 14,
        color: isCompleted ? color : Colors.grey,
      ),
    );
  }

  Widget _buildMacroChip(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
