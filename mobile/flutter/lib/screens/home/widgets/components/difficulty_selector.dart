import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';
import 'section_title.dart';

/// Default list of difficulty levels
const List<String> defaultDifficulties = ['easy', 'medium', 'hard', 'hell'];

/// A widget for selecting workout difficulty
class DifficultySelector extends StatelessWidget {
  /// Currently selected difficulty
  final String selectedDifficulty;

  /// Callback when selection changes
  final ValueChanged<String> onSelectionChanged;

  /// Whether the selector is disabled
  final bool disabled;

  /// List of difficulty options (defaults to standard options)
  final List<String> difficulties;

  /// Whether to show difficulty icons
  final bool showIcons;

  const DifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onSelectionChanged,
    this.disabled = false,
    this.difficulties = defaultDifficulties,
    this.showIcons = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            icon: Icons.speed,
            title: 'Difficulty',
            iconColor: colors.cyan,
          ),
          const SizedBox(height: 12),
          Row(
            children: difficulties.map((difficulty) {
              final isSelected = selectedDifficulty == difficulty;
              final color = getDifficultyColor(difficulty);
              final icon = getDifficultyIcon(difficulty);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: difficulty != difficulties.last ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: disabled
                        ? null
                        : () => onSelectionChanged(difficulty),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.2)
                            : colors.glassSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : colors.cardBorder.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showIcons) ...[
                            Icon(icon, size: 16, color: isSelected ? color : colors.textSecondary),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            difficulty[0].toUpperCase() +
                                difficulty.substring(1),
                            style: TextStyle(
                              color: isSelected ? color : colors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
