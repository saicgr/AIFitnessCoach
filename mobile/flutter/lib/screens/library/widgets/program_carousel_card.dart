import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/branded_program.dart';
import '../components/coming_soon_bottom_sheet.dart';

/// Compact card for horizontal carousel display
/// Netflix-style card optimized for horizontal scrolling
class ProgramCarouselCard extends StatelessWidget {
  final BrandedProgram program;
  final double width;
  final double height;
  final bool isFeatured;

  const ProgramCarouselCard({
    super.key,
    required this.program,
    this.width = 160,
    this.height = 200,
    this.isFeatured = false,
  });

  Color _getCategoryColor(String? category, bool isDark) {
    switch (category?.toLowerCase()) {
      case 'celebrity workout':
        return isDark ? AppColors.purple : AppColorsLight.purple;
      case 'goal-based':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'sport training':
        return isDark ? AppColors.success : AppColorsLight.success;
      case 'strength':
      case 'hypertrophy':
        return isDark ? AppColors.orange : AppColorsLight.orange;
      case 'athletic':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'bodyweight':
        return isDark ? AppColors.success : AppColorsLight.success;
      default:
        return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'celebrity workout':
        return Icons.star_rounded;
      case 'goal-based':
        return Icons.track_changes_rounded;
      case 'sport training':
      case 'athletic':
        return Icons.sports_rounded;
      case 'strength':
      case 'hypertrophy':
        return Icons.fitness_center_rounded;
      case 'bodyweight':
        return Icons.self_improvement_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  void _handleTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComingSoonBottomSheet(program: program),
    );
  }

  /// Shorten duration text to fit in card
  String _shortenDuration(String duration) {
    return duration
        .replaceAll(' weeks', 'w')
        .replaceAll(' week', 'w')
        .replaceAll(' days', 'd')
        .replaceAll(' day', 'd');
  }

  /// Shorten difficulty text
  String _shortenDifficulty(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return 'Beg';
      case 'intermediate':
        return 'Int';
      case 'advanced':
        return 'Adv';
      default:
        return level.substring(0, 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final categoryColor = _getCategoryColor(program.category, isDark);

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon area with gradient
                Container(
                  height: isFeatured ? 110 : 85,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        categoryColor.withOpacity(0.3),
                        categoryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(program.category),
                      size: isFeatured ? 48 : 36,
                      color: categoryColor,
                    ),
                  ),
                ),

                // Info section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Program name - constrained width
                        Text(
                          program.name,
                          style: TextStyle(
                            fontSize: isFeatured ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Duration and difficulty row - constrained
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _shortenDuration(program.durationDisplay),
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (program.difficultyLevel != null) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: DifficultyUtils.getColor(program.difficultyLevel!),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _shortenDifficulty(program.difficultyLevel!),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: DifficultyUtils.getColor(program.difficultyLevel!),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Coming Soon badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
