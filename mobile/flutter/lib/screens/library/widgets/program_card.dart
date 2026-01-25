import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/branded_program.dart';
import 'info_badge.dart';
import 'coming_soon_overlay.dart';
import '../components/program_detail_sheet.dart';
import '../components/coming_soon_bottom_sheet.dart';

/// Card widget displaying program info in a list format
class ProgramCard extends StatelessWidget {
  final BrandedProgram program;
  final bool showComingSoon;

  const ProgramCard({
    super.key,
    required this.program,
    this.showComingSoon = true, // Default to true - show all as coming soon
  });

  Color _getCategoryColor(String? category, bool isDark) {
    switch (category?.toLowerCase()) {
      case 'celebrity workout':
        return isDark ? AppColors.purple : AppColorsLight.purple;
      case 'goal-based':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'sport training':
        return isDark ? AppColors.success : AppColorsLight.success;
      default:
        return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'celebrity workout':
        return Icons.star;
      case 'goal-based':
        return Icons.track_changes;
      case 'sport training':
        return Icons.sports;
      default:
        return Icons.fitness_center;
    }
  }

  void _handleProgramTap(BuildContext context) {
    if (showComingSoon) {
      // Show coming soon modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ComingSoonBottomSheet(program: program),
      );
    } else {
      // Show program detail sheet (normal behavior)
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ProgramDetailSheet(program: program),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final categoryColor = _getCategoryColor(program.category, isDark);

    return GestureDetector(
      onTap: () => _handleProgramTap(context),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border:
                  isDark ? null : Border.all(color: AppColorsLight.cardBorder),
            ),
            child: Row(
              children: [
                // Category icon area
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(program.category),
                      size: 32,
                      color: categoryColor,
                    ),
                  ),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Program name
                        Text(
                          program.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Category & Difficulty badges
                        Row(
                          children: [
                            InfoBadge(
                              icon: _getCategoryIcon(program.category),
                              text: program.category ?? 'Program',
                              color: categoryColor,
                            ),
                            if (program.difficultyLevel != null) ...[
                              const SizedBox(width: 8),
                              InfoBadge(
                                icon: Icons.signal_cellular_alt,
                                text: DifficultyUtils.getDisplayName(program.difficultyLevel!),
                                color: DifficultyUtils.getColor(program.difficultyLevel!),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Duration & Sessions
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: textMuted),
                            const SizedBox(width: 4),
                            Text(
                              program.durationDisplay,
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.repeat, size: 12, color: textMuted),
                            const SizedBox(width: 4),
                            Text(
                              program.sessionsDisplay,
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Arrow
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.chevron_right,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Coming Soon overlay
          if (showComingSoon) const ComingSoonOverlay(),
        ],
      ),
    );
  }
}
