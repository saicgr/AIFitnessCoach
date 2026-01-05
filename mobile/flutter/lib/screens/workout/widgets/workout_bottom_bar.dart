/// Workout bottom bar widget
///
/// Bottom navigation bar for the active workout screen.
/// Exercise strip design for easy navigation between exercises.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Bottom bar for workout navigation - exercise strip for easy navigation
class WorkoutBottomBar extends StatefulWidget {
  /// Current exercise
  final WorkoutExercise currentExercise;

  /// Next exercise (null if last)
  final WorkoutExercise? nextExercise;

  /// All exercises in workout
  final List<WorkoutExercise> allExercises;

  /// Current exercise index
  final int currentExerciseIndex;

  /// Completed sets per exercise (for showing progress)
  final Map<int, int> completedSetsPerExercise;

  /// Whether instructions panel is shown (kept for compatibility)
  final bool showInstructions;

  /// Whether currently resting
  final bool isResting;

  /// Callback to toggle instructions (kept for compatibility)
  final VoidCallback onToggleInstructions;

  /// Callback to skip (rest or exercise)
  final VoidCallback onSkip;

  /// Optional callback to show exercise details
  final VoidCallback? onShowExerciseDetails;

  /// Callback when exercise is tapped in strip
  final void Function(int exerciseIndex)? onExerciseTap;

  const WorkoutBottomBar({
    super.key,
    required this.currentExercise,
    this.nextExercise,
    required this.allExercises,
    required this.currentExerciseIndex,
    this.completedSetsPerExercise = const {},
    required this.showInstructions,
    required this.isResting,
    required this.onToggleInstructions,
    required this.onSkip,
    this.onShowExerciseDetails,
    this.onExerciseTap,
  });

  @override
  State<WorkoutBottomBar> createState() => _WorkoutBottomBarState();
}

class _WorkoutBottomBarState extends State<WorkoutBottomBar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentExercise());
  }

  @override
  void didUpdateWidget(WorkoutBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentExerciseIndex != widget.currentExerciseIndex) {
      _scrollToCurrentExercise();
    }
  }

  void _scrollToCurrentExercise() {
    if (!_scrollController.hasClients) return;

    // Each item is 64px wide + 12px spacing
    const itemWidth = 76.0;
    final targetOffset = (widget.currentExerciseIndex * itemWidth) -
        (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.nearBlack.withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Exercise strip
            _buildExerciseStrip(isDark),

            // Divider
            Container(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),

            // Current exercise info with large tap target for logging
            _buildCurrentExerciseInfo(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseStrip(bool isDark) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.allExercises.length,
        itemBuilder: (context, index) {
          final exercise = widget.allExercises[index];
          final isCurrent = index == widget.currentExerciseIndex;
          final isCompleted = index < widget.currentExerciseIndex;
          final completedSets = widget.completedSetsPerExercise[index] ?? 0;
          final totalSets = exercise.sets ?? 3;

          return Padding(
            padding: EdgeInsets.only(right: index < widget.allExercises.length - 1 ? 12 : 0),
            child: _ExerciseStripItem(
              exercise: exercise,
              index: index,
              isCurrent: isCurrent,
              isCompleted: isCompleted,
              completedSets: completedSets,
              totalSets: totalSets,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onExerciseTap?.call(index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentExerciseInfo(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final currentSets = widget.completedSetsPerExercise[widget.currentExerciseIndex] ?? 0;
    final totalSets = widget.currentExercise.sets ?? 3;
    final isLastExercise = widget.currentExerciseIndex == widget.allExercises.length - 1;
    final allSetsComplete = currentSets >= totalSets;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onShowExerciseDetails?.call();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          children: [
            // Exercise number badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: allSetsComplete
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.electricBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: allSetsComplete
                      ? AppColors.success.withOpacity(0.4)
                      : AppColors.electricBlue.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: allSetsComplete
                    ? Icon(
                        Icons.check_rounded,
                        size: 28,
                        color: AppColors.success,
                      )
                    : Text(
                        '${widget.currentExerciseIndex + 1}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.electricBlue,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.currentExercise.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Set progress
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: allSetsComplete
                              ? AppColors.success.withOpacity(0.12)
                              : AppColors.electricBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          allSetsComplete
                              ? 'Complete!'
                              : 'Set ${currentSets + 1} of $totalSets',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: allSetsComplete
                                ? AppColors.success
                                : AppColors.electricBlue,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Weight/Reps info
                      if (widget.currentExercise.weight != null)
                        Text(
                          '${widget.currentExercise.weight?.toStringAsFixed(0)}kg',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      if (widget.currentExercise.weight != null && widget.currentExercise.reps != null)
                        Text(
                          ' × ',
                          style: TextStyle(fontSize: 13, color: textMuted.withOpacity(0.5)),
                        ),
                      if (widget.currentExercise.reps != null)
                        Text(
                          '${widget.currentExercise.reps} reps',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Next indicator or finish flag
            if (isLastExercise && allSetsComplete)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  size: 24,
                  color: AppColors.success,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

/// Individual exercise item in the strip
class _ExerciseStripItem extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final bool isCurrent;
  final bool isCompleted;
  final int completedSets;
  final int totalSets;
  final bool isDark;
  final VoidCallback onTap;

  const _ExerciseStripItem({
    required this.exercise,
    required this.index,
    required this.isCurrent,
    required this.isCompleted,
    required this.completedSets,
    required this.totalSets,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty;
    final allSetsComplete = completedSets >= totalSets;

    // Determine colors based on state
    Color borderColor;
    Color bgColor;
    if (isCurrent) {
      borderColor = AppColors.electricBlue;
      bgColor = AppColors.electricBlue.withOpacity(0.15);
    } else if (isCompleted || allSetsComplete) {
      borderColor = AppColors.success.withOpacity(0.6);
      bgColor = AppColors.success.withOpacity(0.1);
    } else {
      borderColor = isDark
          ? Colors.white.withOpacity(0.15)
          : Colors.black.withOpacity(0.1);
      bgColor = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03);
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail with progress ring
          Stack(
            children: [
              // Progress ring background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isCurrent ? 3 : 2,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: exercise.gifUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildPlaceholder(),
                          errorWidget: (context, url, error) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),

              // Completed checkmark overlay
              if (isCompleted || allSetsComplete)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.nearBlack : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Current indicator dot
              if (isCurrent && !allSetsComplete)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.nearBlack : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${completedSets + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // Exercise number
          Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent
                  ? AppColors.electricBlue
                  : (isCompleted
                      ? AppColors.success
                      : (isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.fitness_center_rounded,
        size: 22,
        color: isCurrent
            ? AppColors.electricBlue
            : (isCompleted
                ? AppColors.success
                : AppColors.textMuted.withOpacity(0.5)),
      ),
    );
  }
}

/// Set dots progress indicator
class SetDotsIndicator extends StatelessWidget {
  final int totalSets;
  final int completedSets;

  const SetDotsIndicator({
    super.key,
    required this.totalSets,
    required this.completedSets,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          'Set ${completedSets + 1} of $totalSets',
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSets, (index) {
            final isCompleted = index < completedSets;
            final isCurrent = index == completedSets;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 24 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isCurrent
                        ? AppColors.electricBlue
                        : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent ? AppColors.electricBlue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            );
          }),
        ),
      ],
    );
  }
}

/// Exercise option tile for action sheets
class ExerciseOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const ExerciseOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColorsLight.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
