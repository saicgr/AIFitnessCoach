/// Exercise thumbnail strip widget
///
/// Horizontal scrollable strip of exercise thumbnails for quick navigation
/// during active workout. Inspired by myfitcoach.app design.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Horizontal strip of exercise thumbnails for quick navigation
class ExerciseThumbnailStrip extends StatefulWidget {
  /// All exercises in the workout
  final List<WorkoutExercise> exercises;

  /// Currently active exercise index
  final int currentIndex;

  /// Completed sets per exercise (exercise index -> completed count)
  final Map<int, int> completedSetsPerExercise;

  /// Total sets per exercise (exercise index -> total sets)
  final Map<int, int> totalSetsPerExercise;

  /// Callback when user taps an exercise to switch
  final void Function(int index) onExerciseTap;

  /// Optional: show skip button
  final bool showSkipButton;

  /// Callback for skip action
  final VoidCallback? onSkip;

  /// Whether currently resting
  final bool isResting;

  const ExerciseThumbnailStrip({
    super.key,
    required this.exercises,
    required this.currentIndex,
    required this.completedSetsPerExercise,
    required this.totalSetsPerExercise,
    required this.onExerciseTap,
    this.showSkipButton = true,
    this.onSkip,
    this.isResting = false,
  });

  @override
  State<ExerciseThumbnailStrip> createState() => _ExerciseThumbnailStripState();
}

class _ExerciseThumbnailStripState extends State<ExerciseThumbnailStrip> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Scroll to current exercise after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentExercise();
    });
  }

  @override
  void didUpdateWidget(ExerciseThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll when exercise changes
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollToCurrentExercise();
    }
  }

  void _scrollToCurrentExercise() {
    if (!_scrollController.hasClients) return;

    // Each box is ~92 wide (80 + 12 margin) - increased for better tap targets
    const itemWidth = 92.0;
    final targetOffset = (widget.currentIndex * itemWidth) -
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
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.nearBlack.withOpacity(0.95)
              : Colors.white.withOpacity(0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Exercise count header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'EXERCISES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColorsLight.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.currentIndex + 1}/${widget.exercises.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.electricBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Skip button
                  if (widget.showSkipButton && widget.onSkip != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onSkip?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.isResting
                              ? AppColors.purple.withOpacity(0.15)
                              : (isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.05)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.isResting
                                ? AppColors.purple.withOpacity(0.3)
                                : (isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.08)),
                          ),
                        ),
                        child: Text(
                          widget.isResting ? 'Skip Rest' : 'Skip',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.isResting
                                ? AppColors.purple
                                : (isDark
                                    ? AppColors.textSecondary
                                    : AppColorsLight.textSecondary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Horizontal scrollable exercise thumbnails - increased height for 80px boxes
            SizedBox(
              height: 110,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = widget.exercises[index];
                  final isActive = index == widget.currentIndex;
                  final completedSets = widget.completedSetsPerExercise[index] ?? 0;
                  final totalSets = widget.totalSetsPerExercise[index] ?? exercise.sets ?? 3;
                  final isCompleted = completedSets >= totalSets;
                  final isPast = index < widget.currentIndex;

                  return _ExerciseThumbnailBox(
                    exercise: exercise,
                    index: index,
                    isActive: isActive,
                    isCompleted: isCompleted,
                    isPast: isPast,
                    completedSets: completedSets,
                    totalSets: totalSets,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onExerciseTap(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual exercise thumbnail box
class _ExerciseThumbnailBox extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final bool isActive;
  final bool isCompleted;
  final bool isPast;
  final int completedSets;
  final int totalSets;
  final VoidCallback onTap;

  const _ExerciseThumbnailBox({
    required this.exercise,
    required this.index,
    required this.isActive,
    required this.isCompleted,
    required this.isPast,
    required this.completedSets,
    required this.totalSets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = exercise.gifUrl ?? exercise.imageS3Path;

    // Determine colors based on state
    Color borderColor;
    Color bgColor;
    double opacity;

    if (isActive) {
      borderColor = AppColors.electricBlue;
      bgColor = AppColors.electricBlue.withOpacity(0.15);
      opacity = 1.0;
    } else if (isCompleted || isPast) {
      borderColor = AppColors.success.withOpacity(0.5);
      bgColor = AppColors.success.withOpacity(0.1);
      opacity = 0.7;
    } else {
      borderColor = isDark
          ? Colors.white.withOpacity(0.15)
          : Colors.black.withOpacity(0.1);
      bgColor = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03);
      opacity = 0.6;
    }

    // Use glow colors for active state
    final activeColor = AppColors.glowCyan;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        width: 80,
        child: Column(
          children: [
            // Thumbnail box - increased to 80px for better tap targets
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive ? activeColor : borderColor,
                  width: isActive ? 2.5 : 1.5,
                ),
                boxShadow: isActive
                    ? [
                        // Primary glow
                        BoxShadow(
                          color: activeColor.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                        // Secondary outer glow
                        BoxShadow(
                          color: activeColor.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Exercise image or placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Opacity(
                            opacity: opacity,
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              placeholder: (context, url) => _buildPlaceholder(isDark),
                              errorWidget: (context, url, error) => _buildPlaceholder(isDark),
                            ),
                          )
                        : _buildPlaceholder(isDark),
                  ),
                  // Completed overlay
                  if (isCompleted || isPast)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.glowGreen.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  // Active indicator dot with glow
                  if (isActive)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withOpacity(0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Set progress indicator (larger dots at bottom)
                  if (!isCompleted && !isPast)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          totalSets.clamp(1, 6), // Max 6 dots to fit in 80px
                          (setIndex) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: setIndex < completedSets
                                  ? AppColors.glowGreen
                                  : (isActive
                                      ? activeColor.withOpacity(0.4)
                                      : Colors.white.withOpacity(0.3)),
                              border: setIndex < completedSets
                                  ? null
                                  : Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 0.5,
                                    ),
                              boxShadow: setIndex < completedSets
                                  ? [
                                      BoxShadow(
                                        color: AppColors.glowGreen.withOpacity(0.4),
                                        blurRadius: 3,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Exercise number with truncated name
            Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? activeColor
                    : (isCompleted || isPast)
                        ? AppColors.glowGreen
                        : (isDark
                            ? AppColors.textMuted
                            : AppColorsLight.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03),
      child: Icon(
        Icons.fitness_center,
        size: 28,
        color: isDark
            ? Colors.white.withOpacity(0.3)
            : Colors.black.withOpacity(0.2),
      ),
    );
  }
}
