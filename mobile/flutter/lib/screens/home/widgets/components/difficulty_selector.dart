import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
                            _buildDifficultyIcon(
                              icon: icon,
                              color: isSelected ? color : colors.textSecondary,
                              isSelected: isSelected,
                              difficulty: difficulty,
                            ),
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

  /// Builds the difficulty icon with animation for Hell difficulty
  Widget _buildDifficultyIcon({
    required IconData icon,
    required Color color,
    required bool isSelected,
    required String difficulty,
  }) {
    final baseIcon = Icon(icon, size: 16, color: color);

    // Only animate when Hell is selected
    if (isSelected && difficulty.toLowerCase() == 'hell') {
      return baseIcon
          .animate(onPlay: (controller) => controller.repeat())
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.2, 1.2),
            duration: 400.ms,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            end: const Offset(0.9, 0.9),
            duration: 300.ms,
            curve: Curves.easeIn,
          )
          .then()
          .scale(
            end: const Offset(1.0, 1.0),
            duration: 200.ms,
            curve: Curves.easeOut,
          )
          .shimmer(
            color: Colors.orange.withValues(alpha: 0.6),
            duration: 1500.ms,
          );
    }

    return baseIcon;
  }
}
