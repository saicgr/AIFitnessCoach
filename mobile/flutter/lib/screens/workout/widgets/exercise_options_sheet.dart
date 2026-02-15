/// Exercise Options Sheet
///
/// Full options menu for an exercise during workout, styled like Hevy/Gravl.
/// Includes: Replace, Change Reps Progression, Add to superset, Video & Instructions,
/// Exercise History, Notes, and destructive actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../widgets/glass_sheet.dart';
import 'exercise_info_sheet.dart';

/// Rep progression types
enum RepProgressionType {
  straight,
  pyramid,
  reversePyramid,
  dropSet,
  wave,
  cluster,
  restPause,
  amrap,
}

extension RepProgressionTypeExtension on RepProgressionType {
  String get displayName {
    switch (this) {
      case RepProgressionType.straight:
        return 'Straight Sets';
      case RepProgressionType.pyramid:
        return 'Pyramid';
      case RepProgressionType.reversePyramid:
        return 'Reverse Pyramid';
      case RepProgressionType.dropSet:
        return 'Drop Sets';
      case RepProgressionType.wave:
        return 'Wave Loading';
      case RepProgressionType.cluster:
        return 'Cluster Sets';
      case RepProgressionType.restPause:
        return 'Rest-Pause';
      case RepProgressionType.amrap:
        return 'AMRAP';
    }
  }

  String get description {
    switch (this) {
      case RepProgressionType.straight:
        return 'Same weight and reps for all sets';
      case RepProgressionType.pyramid:
        return 'Increase weight, decrease reps each set';
      case RepProgressionType.reversePyramid:
        return 'Decrease weight, increase reps each set';
      case RepProgressionType.dropSet:
        return 'Reduce weight immediately after each set';
      case RepProgressionType.wave:
        return 'Alternate between heavy and moderate sets';
      case RepProgressionType.cluster:
        return 'Mini-sets with short rest (10-15s) within a set';
      case RepProgressionType.restPause:
        return 'One set to failure, rest 10-15s, continue';
      case RepProgressionType.amrap:
        return 'As Many Reps As Possible on final set';
    }
  }

  IconData get icon {
    switch (this) {
      case RepProgressionType.straight:
        return Icons.horizontal_rule_rounded;
      case RepProgressionType.pyramid:
        return Icons.signal_cellular_alt_rounded;
      case RepProgressionType.reversePyramid:
        return Icons.signal_cellular_alt_rounded;
      case RepProgressionType.dropSet:
        return Icons.trending_down_rounded;
      case RepProgressionType.wave:
        return Icons.waves_rounded;
      case RepProgressionType.cluster:
        return Icons.dashboard_rounded;
      case RepProgressionType.restPause:
        return Icons.pause_circle_outline_rounded;
      case RepProgressionType.amrap:
        return Icons.whatshot_rounded;
    }
  }
}

/// Show the exercise options sheet
Future<void> showExerciseOptionsSheet({
  required BuildContext context,
  required WorkoutExercise exercise,
  required RepProgressionType currentProgression,
  required Function(RepProgressionType) onProgressionChanged,
  required VoidCallback onReplace,
  required VoidCallback onViewHistory,
  required VoidCallback onViewInstructions,
  required VoidCallback onAddNotes,
  required VoidCallback onRemoveFromWorkout,
  VoidCallback? onAddToSuperset,
  VoidCallback? onRemoveAndDontRecommend,
}) {
  HapticFeedback.mediumImpact();

  return showGlassSheet(
    context: context,
    builder: (ctx) => GlassSheet(
      showHandle: false,
      child: ExerciseOptionsSheet(
        exercise: exercise,
        currentProgression: currentProgression,
        onProgressionChanged: onProgressionChanged,
        onReplace: onReplace,
        onViewHistory: onViewHistory,
        onViewInstructions: onViewInstructions,
        onAddNotes: onAddNotes,
        onRemoveFromWorkout: onRemoveFromWorkout,
        onAddToSuperset: onAddToSuperset,
        onRemoveAndDontRecommend: onRemoveAndDontRecommend,
      ),
    ),
  );
}

/// Exercise options sheet widget
class ExerciseOptionsSheet extends StatefulWidget {
  final WorkoutExercise exercise;
  final RepProgressionType currentProgression;
  final Function(RepProgressionType) onProgressionChanged;
  final VoidCallback onReplace;
  final VoidCallback onViewHistory;
  final VoidCallback onViewInstructions;
  final VoidCallback onAddNotes;
  final VoidCallback onRemoveFromWorkout;
  final VoidCallback? onAddToSuperset;
  final VoidCallback? onRemoveAndDontRecommend;

  const ExerciseOptionsSheet({
    super.key,
    required this.exercise,
    required this.currentProgression,
    required this.onProgressionChanged,
    required this.onReplace,
    required this.onViewHistory,
    required this.onViewInstructions,
    required this.onAddNotes,
    required this.onRemoveFromWorkout,
    this.onAddToSuperset,
    this.onRemoveAndDontRecommend,
  });

  @override
  State<ExerciseOptionsSheet> createState() => _ExerciseOptionsSheetState();
}

class _ExerciseOptionsSheetState extends State<ExerciseOptionsSheet> {
  bool _showProgressionPicker = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Exercise header
                _buildExerciseHeader(isDark, textPrimary, textMuted),

                const SizedBox(height: 8),

                // Options list
                if (_showProgressionPicker)
                  _buildProgressionPicker(isDark, textPrimary, textMuted)
                else
                  _buildOptionsList(isDark, textPrimary, textMuted),

                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
    );
  }

  Widget _buildExerciseHeader(bool isDark, Color textPrimary, Color textMuted) {
    final imageUrl = widget.exercise.gifUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          // Exercise image
          if (hasImage)
            Container(
              width: 120,
              height: 120,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.electricBlue,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 40,
                    color: textMuted,
                  ),
                ),
              ),
            ),

          // Exercise name
          Text(
            widget.exercise.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Target muscle
          Text(
            _getTargetMuscle(),
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList(bool isDark, Color textPrimary, Color textMuted) {
    return Column(
      children: [
        // Replace
        _buildOptionItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Replace',
          onTap: () {
            Navigator.pop(context);
            widget.onReplace();
          },
          isDark: isDark,
          textPrimary: textPrimary,
        ),

        // Change Reps Progression
        _buildOptionItem(
          icon: Icons.trending_up_rounded,
          label: 'Change Reps Progression',
          subtitle: widget.currentProgression.displayName,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showProgressionPicker = true);
          },
          isDark: isDark,
          textPrimary: textPrimary,
          showChevron: true,
        ),

        // Add to superset (if available)
        if (widget.onAddToSuperset != null)
          _buildOptionItem(
            icon: Icons.link_rounded,
            label: 'Add to Superset',
            onTap: () {
              Navigator.pop(context);
              widget.onAddToSuperset!();
            },
            isDark: isDark,
            textPrimary: textPrimary,
          ),

        // Video & Instructions
        _buildOptionItem(
          icon: Icons.play_circle_outline_rounded,
          label: 'Video & Instructions',
          onTap: () {
            Navigator.pop(context);
            widget.onViewInstructions();
          },
          isDark: isDark,
          textPrimary: textPrimary,
        ),

        // Exercise History
        _buildOptionItem(
          icon: Icons.history_rounded,
          label: 'Exercise History',
          onTap: () {
            Navigator.pop(context);
            widget.onViewHistory();
          },
          isDark: isDark,
          textPrimary: textPrimary,
        ),

        // Notes
        _buildOptionItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Notes',
          onTap: () {
            Navigator.pop(context);
            widget.onAddNotes();
          },
          isDark: isDark,
          textPrimary: textPrimary,
        ),

        // Divider before destructive actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Divider(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),

        // Remove from workout (destructive)
        _buildOptionItem(
          icon: Icons.delete_outline_rounded,
          label: 'Remove from Workout',
          onTap: () {
            Navigator.pop(context);
            widget.onRemoveFromWorkout();
          },
          isDark: isDark,
          textPrimary: textPrimary,
          isDestructive: true,
        ),

        // Remove and don't recommend (if available)
        if (widget.onRemoveAndDontRecommend != null)
          _buildOptionItem(
            icon: Icons.block_rounded,
            label: "Remove and Don't Recommend",
            onTap: () {
              Navigator.pop(context);
              widget.onRemoveAndDontRecommend!();
            },
            isDark: isDark,
            textPrimary: textPrimary,
            isDestructive: true,
          ),
      ],
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    bool isDestructive = false,
    bool showChevron = false,
  }) {
    final color = isDestructive ? AppColors.error : textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressionPicker(bool isDark, Color textPrimary, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showProgressionPicker = false);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: textPrimary,
                  size: 20,
                ),
              ),
              Text(
                'Change Reps Progression',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Progression options
        ...RepProgressionType.values.map((type) {
          final isSelected = type == widget.currentProgression;
          return _buildProgressionOption(
            type: type,
            isSelected: isSelected,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
          );
        }),
      ],
    );
  }

  Widget _buildProgressionOption({
    required RepProgressionType type,
    required bool isSelected,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onProgressionChanged(type);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.electricBlue.withOpacity(0.1)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04),
              ),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.electricBlue.withOpacity(0.2)
                      : (isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  type.icon,
                  color: isSelected ? AppColors.electricBlue : textMuted,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.electricBlue : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkmark if selected
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.electricBlue,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTargetMuscle() {
    if (widget.exercise.primaryMuscle != null &&
        widget.exercise.primaryMuscle!.isNotEmpty) {
      return widget.exercise.primaryMuscle!;
    } else if (widget.exercise.muscleGroup != null &&
        widget.exercise.muscleGroup!.isNotEmpty) {
      return widget.exercise.muscleGroup!;
    } else if (widget.exercise.bodyPart != null &&
        widget.exercise.bodyPart!.isNotEmpty) {
      return widget.exercise.bodyPart!;
    }
    return 'Full Body';
  }
}
