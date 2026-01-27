import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/week_comparison_provider.dart';
import '../../../../data/services/haptic_service.dart';

/// A card showing what exercises changed this week compared to last week.
/// Provides transparency into weekly exercise variation.
class WeekChangesCard extends ConsumerWidget {
  const WeekChangesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonState = ref.watch(weekComparisonProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Don't show if loading or error
    if (comparisonState.isLoading) {
      return const SizedBox.shrink();
    }

    final comparison = comparisonState.comparison;
    if (comparison == null) {
      return const SizedBox.shrink();
    }

    // Don't show if there are no exercises to compare (first week)
    if (comparison.totalPrevious == 0 && comparison.totalCurrent == 0) {
      return const SizedBox.shrink();
    }

    // Show card only if there are changes or it's the first week
    final hasChanges = comparison.hasChanges;
    final isFirstWeek = comparison.totalPrevious == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasChanges
                ? AppColors.cyan.withOpacity(0.3)
                : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticService.light();
              _showDetailsSheet(context, comparison, isDark);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasChanges
                              ? AppColors.cyan.withOpacity(0.15)
                              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          hasChanges ? Icons.autorenew : Icons.check_circle_outline,
                          color: hasChanges ? AppColors.cyan : AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFirstWeek ? 'Your First Week' : "This Week's Changes",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              comparisonState.summaryText,
                              style: TextStyle(
                                fontSize: 13,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: textMuted,
                        size: 20,
                      ),
                    ],
                  ),

                  // Show preview of new exercises if any
                  if (hasChanges && comparison.newExercises.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: comparison.newExercises.take(3).map((exercise) {
                        return Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: textMuted.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: textMuted.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fiber_new,
                                size: 14,
                                color: textPrimary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  exercise,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    if (comparison.newExercises.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+${comparison.newExercises.length - 3} more new exercises',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, comparison, bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.compare_arrows,
                          color: AppColors.cyan,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Week Comparison',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Summary stats
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                label: 'This Week',
                                value: '${comparison.totalCurrent}',
                                icon: Icons.fitness_center,
                                color: AppColors.cyan,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatBox(
                                label: 'Last Week',
                                value: '${comparison.totalPrevious}',
                                icon: Icons.history,
                                color: AppColors.purple,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),

                        // New exercises section
                        if (comparison.newExercises.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _SectionHeader(
                            title: 'New This Week',
                            count: comparison.newExercises.length,
                            color: AppColors.cyan,
                            icon: Icons.add_circle_outline,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          ...comparison.newExercises.map<Widget>((exercise) {
                            return _ExerciseListItem(
                              name: exercise,
                              icon: Icons.fiber_new,
                              color: AppColors.cyan,
                              isDark: isDark,
                            );
                          }),
                        ],

                        // Removed exercises section
                        if (comparison.removedExercises.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _SectionHeader(
                            title: 'Rotated Out',
                            count: comparison.removedExercises.length,
                            color: AppColors.orange,
                            icon: Icons.remove_circle_outline,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          ...comparison.removedExercises.map<Widget>((exercise) {
                            return _ExerciseListItem(
                              name: exercise,
                              icon: Icons.swap_horiz,
                              color: AppColors.orange,
                              isDark: isDark,
                            );
                          }),
                        ],

                        // Kept exercises section
                        if (comparison.keptExercises.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _SectionHeader(
                            title: 'Consistent',
                            count: comparison.keptExercises.length,
                            color: AppColors.success,
                            icon: Icons.check_circle_outline,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          ...comparison.keptExercises.map<Widget>((exercise) {
                            return _ExerciseListItem(
                              name: exercise,
                              icon: Icons.check,
                              color: AppColors.success,
                              isDark: isDark,
                            );
                          }),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseListItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _ExerciseListItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
