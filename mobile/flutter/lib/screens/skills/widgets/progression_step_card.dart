import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/skill_progression.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
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
    final tc = ThemeColors.of(context);
    final green = tc.success;

    final borderColor = isCurrent ? tc.accent : AppColors.cardBorder;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: tc.accent.withValues(alpha: 0.18),
                    blurRadius: 14,
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
                        style: ZType.disp(
                          16,
                          color: isUnlocked ? tc.textPrimary : tc.textMuted,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _DifficultyBadge(
                            level: step.difficultyLevel,
                            label: step.difficultyLabel,
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context).progressionStepCardCompleted.toUpperCase(),
                                  style: ZType.lbl(10, color: green, letterSpacing: 1),
                                ),
                              ],
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
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tc.surface,
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: tc.textMuted,
                    ),
                  )
                else if (isCurrent && onPractice != null)
                  ZealovaButton(
                    label: AppLocalizations.of(context).progressionStepCardPractice,
                    onTap: onPractice,
                    expand: false,
                    height: 40,
                  ),
              ],
            ),

            // Unlock criteria for current step
            if (isCurrent && step.unlockCriteria != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tc.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.hairlineStrong),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: tc.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.progressionStepCardGoal(step.unlockCriteriaText),
                        style: TextStyle(
                          color: tc.textSecondary,
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
                    color: tc.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      step.tips!,
                      style: TextStyle(
                        color: tc.textSecondary,
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
                AppLocalizations.of(context).progressionStepCardCompletePreviousStepTo,
                style: TextStyle(
                  color: tc.textMuted,
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Difficulty dots
        ...List.generate(5, (index) {
          final filled = index < (level / 2).ceil();
          return Container(
            width: 6,
            height: 6,
            margin: EdgeInsetsDirectional.only(end: index < 4 ? 2 : 6),
            decoration: BoxDecoration(
              color: filled ? color : color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          );
        }),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(10, color: color, letterSpacing: 1),
        ),
      ],
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
