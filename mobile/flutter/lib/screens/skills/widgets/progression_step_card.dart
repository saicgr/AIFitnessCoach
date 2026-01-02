import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/skill_progression.dart';

/// Card displaying a single progression step
class ProgressionStepCard extends StatelessWidget {
  final ProgressionStep step;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isCompleted;
  final VoidCallback? onPractice;
  final VoidCallback? onTap;

  const ProgressionStepCard({
    super.key,
    required this.step,
    this.isUnlocked = false,
    this.isCurrent = false,
    this.isCompleted = false,
    this.onPractice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final green = isDark ? AppColors.green : AppColorsLight.green;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final borderColor = isCompleted
        ? green.withOpacity(0.4)
        : isCurrent
            ? cyan
            : cardBorder;

    final bgColor = isCompleted
        ? green.withOpacity(0.05)
        : isCurrent
            ? cyan.withOpacity(0.05)
            : elevated;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: cyan.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Exercise name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.exerciseName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isUnlocked
                                  ? null
                                  : textMuted,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _DifficultyBadge(
                            level: step.difficultyLevel,
                            label: step.difficultyLabel,
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Lock icon or practice button
                if (!isUnlocked)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: textMuted.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 18,
                      color: textMuted,
                    ),
                  )
                else if (isCurrent && onPractice != null)
                  FilledButton.icon(
                    onPressed: onPractice,
                    icon: const Icon(Icons.fitness_center_rounded, size: 18),
                    label: const Text('Practice'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cyan,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
              ],
            ),

            // Unlock criteria for current step
            if (isCurrent && step.unlockCriteria != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cyan.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: cyan,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Goal: ${step.unlockCriteriaText}',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Tips preview for unlocked steps
            if (isUnlocked &&
                !isCompleted &&
                step.tips != null &&
                step.tips!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 14,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      step.tips!,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Locked state message
            if (!isUnlocked) ...[
              const SizedBox(height: 12),
              Text(
                'Complete previous step to unlock',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final int level;
  final String label;

  const _DifficultyBadge({
    required this.level,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getDifficultyColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Difficulty dots
          ...List.generate(5, (index) {
            final filled = index < (level / 2).ceil();
            return Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(right: index < 4 ? 2 : 6),
              decoration: BoxDecoration(
                color: filled ? color : color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            );
          }),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(int level) {
    if (level <= 2) return AppColors.green;
    if (level <= 4) return AppColors.teal;
    if (level <= 6) return AppColors.orange;
    if (level <= 8) return AppColors.coral;
    return AppColors.purple;
  }
}
