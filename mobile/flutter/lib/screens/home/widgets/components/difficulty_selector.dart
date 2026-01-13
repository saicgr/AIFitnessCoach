import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/utils/difficulty_utils.dart';
import 'sheet_theme_colors.dart';
import 'section_title.dart';

/// Default list of difficulty levels (internal values)
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

  /// User's fitness level for showing warnings (e.g., 'beginner', 'intermediate', 'advanced')
  final String? fitnessLevel;

  const DifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onSelectionChanged,
    this.disabled = false,
    this.difficulties = defaultDifficulties,
    this.showIcons = true,
    this.fitnessLevel,
  });

  /// Check if the user is a beginner
  bool get _isBeginner {
    if (fitnessLevel == null) return false;
    final level = fitnessLevel!.toLowerCase();
    return level == 'beginner' || level == 'new' || level == 'novice';
  }

  /// Check if selected difficulty warrants a warning for beginners
  bool get _shouldShowWarning {
    if (!_isBeginner) return false;
    final diff = selectedDifficulty.toLowerCase();
    return diff == 'hard' || diff == 'hell';
  }

  /// Show warning dialog for beginners selecting hard difficulties
  void _showBeginnerWarning(BuildContext context, String difficulty, SheetColors colors) {
    final isHell = difficulty.toLowerCase() == 'hell';
    final displayName = DifficultyUtils.getDisplayName(difficulty);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isHell ? 'Hell Intensity' : 'High Intensity',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isHell
              ? '$displayName mode is designed for experienced athletes. As a beginner, this may lead to injury or burnout. We recommend starting with Beginner or Moderate difficulty.'
              : '$displayName mode may be intense for beginners. Consider starting with Beginner or Moderate difficulty and progressing as you build strength and endurance.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Choose Another',
              style: TextStyle(color: colors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSelectionChanged(difficulty);
            },
            child: Text(
              'Continue Anyway',
              style: TextStyle(
                color: isHell ? colors.error : colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show HELL mode warning dialog for ALL users (not just beginners)
  void _showHellModeWarning(BuildContext context, SheetColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'HELL Mode Warning',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is an extreme intensity workout designed to push your absolute limits.',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildWarningItem(colors, 'High injury risk if form breaks down'),
            _buildWarningItem(colors, 'Requires extended recovery time (48-72 hours)'),
            _buildWarningItem(colors, 'Not recommended for consecutive days'),
            _buildWarningItem(colors, 'Only proceed if fully rested and warmed up'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates, color: colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consider "Challenging" for a safer intense workout',
                      style: TextStyle(
                        color: colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Choose Different',
              style: TextStyle(color: colors.textMuted, fontSize: 15),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSelectionChanged('hell');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, size: 18),
                SizedBox(width: 6),
                Text(
                  'I Accept the Risk',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(SheetColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: Colors.red.withOpacity(0.8), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show difficulty description on long press
  void _showDifficultyDescription(
    BuildContext context,
    String displayName,
    String description,
    Color color,
    SheetColors colors,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                DifficultyUtils.getIcon(DifficultyUtils.getInternalValue(displayName)),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              displayName,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got it',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              final color = DifficultyUtils.getColor(difficulty);
              final icon = DifficultyUtils.getIcon(difficulty);
              final displayName = DifficultyUtils.getDisplayName(difficulty);
              final description = DifficultyUtils.getDescription(difficulty);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: difficulty != difficulties.last ? 8 : 0,
                  ),
                  child: Tooltip(
                    message: description,
                    preferBelow: true,
                    waitDuration: const Duration(milliseconds: 500),
                    child: GestureDetector(
                      onTap: disabled
                          ? null
                          : () {
                              final diff = difficulty.toLowerCase();
                              // Show HELL mode warning for ALL users
                              if (diff == 'hell') {
                                _showHellModeWarning(context, colors);
                              }
                              // Show warning for beginners selecting hard
                              else if (_isBeginner && diff == 'hard') {
                                _showBeginnerWarning(context, difficulty, colors);
                              } else {
                                onSelectionChanged(difficulty);
                              }
                            },
                      onLongPress: disabled
                          ? null
                          : () {
                              // Show description on long press
                              _showDifficultyDescription(context, displayName, description, color, colors);
                            },
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showIcons) ...[
                                  _buildDifficultyIcon(
                                    icon: icon,
                                    color: isSelected ? color : colors.textSecondary,
                                    isSelected: isSelected,
                                    difficulty: difficulty,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: isSelected ? color : colors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // Warning message for beginners with hard/hell selected
          if (_shouldShowWarning) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedDifficulty.toLowerCase() == 'hell'
                          ? 'Hell mode is very intense for beginners'
                          : 'Challenging mode may be intense for beginners',
                      style: TextStyle(
                        color: colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    // Only animate when Hell is selected - flickering fire effect
    if (isSelected && difficulty.toLowerCase() == 'hell') {
      return baseIcon
          .animate(onPlay: (controller) => controller.repeat())
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.3, 1.3),
            duration: 300.ms,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            end: const Offset(0.85, 0.85),
            duration: 250.ms,
            curve: Curves.easeIn,
          )
          .then()
          .scale(
            end: const Offset(1.15, 1.15),
            duration: 200.ms,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            end: const Offset(1.0, 1.0),
            duration: 150.ms,
            curve: Curves.easeInOut,
          )
          .shimmer(
            color: Colors.red.withValues(alpha: 0.8),
            duration: 800.ms,
          );
    }

    return baseIcon;
  }
}
