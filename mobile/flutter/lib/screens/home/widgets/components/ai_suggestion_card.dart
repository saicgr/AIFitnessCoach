import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'sheet_theme_colors.dart';

/// A card displaying an AI workout suggestion
class AISuggestionCard extends StatelessWidget {
  /// The suggestion data
  final Map<String, dynamic> suggestion;

  /// Index of this suggestion in the list
  final int index;

  /// Whether this suggestion is selected
  final bool isSelected;

  /// Callback when tapped
  final VoidCallback onTap;

  const AISuggestionCard({
    super.key,
    required this.suggestion,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  Color _getTypeColor(String type, bool isDark) {
    // Use monochrome for all workout types
    return isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;

    final name = suggestion['name'] as String? ?? 'Workout ${index + 1}';
    final type = suggestion['type'] as String? ?? 'Strength';
    final difficulty = suggestion['difficulty'] as String? ?? 'medium';
    final duration = suggestion['duration_minutes'] as int? ?? 45;
    final description = suggestion['description'] as String? ?? '';
    final focusAreas =
        (suggestion['focus_areas'] as List?)?.cast<String>() ?? [];
    final sampleExercises =
        (suggestion['sample_exercises'] as List?)?.cast<String>() ?? [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final difficultyColor = getDifficultyColor(difficulty, isDark: isDark);
    final typeColor = _getTypeColor(type, isDark);

    // Ranking label based on position
    String rankLabel;
    Color rankColor;
    IconData rankIcon;
    if (index == 0) {
      rankLabel = 'Best Match';
      rankColor = colors.success;
      rankIcon = Icons.star;
    } else if (index == 1) {
      rankLabel = '2nd Choice';
      rankColor = colors.cyan;
      rankIcon = Icons.thumb_up_outlined;
    } else if (index == 2) {
      rankLabel = '3rd Choice';
      rankColor = colors.orange;
      rankIcon = Icons.recommend_outlined;
    } else {
      rankLabel = '#${index + 1}';
      rankColor = colors.textMuted;
      rankIcon = Icons.tag;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.cyan.withOpacity(0.1)
              : colors.glassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colors.cyan
                : colors.cardBorder.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ranking badge at the top
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: index == 0
                        ? Border.all(
                            color: rankColor.withOpacity(0.5),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rankIcon, size: 14, color: rankColor),
                      const SizedBox(width: 4),
                      Text(
                        rankLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: rankColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.cyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Header with name
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Tags row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(type, typeColor),
                _buildTag(_capitalize(difficulty), difficultyColor),
                _buildTag('$duration min', colors.orange),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (focusAreas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: focusAreas
                    .map((area) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.purple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            area,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],

            // Sample exercises preview
            if (sampleExercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.glassSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.cardBorder.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 14,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Exercises Preview',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: sampleExercises
                          .map((exercise) => Text(
                                '- $exercise',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }
}
