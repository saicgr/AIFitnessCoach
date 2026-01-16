/// Exercise Thumbnail Strip V2
///
/// Redesigned horizontal scrollable strip of exercise thumbnails inspired by
/// MacroFactor Workouts 2026. Simpler, cleaner design with:
/// - Thumbnails at the top of the screen (not in a container)
/// - Current exercise indicated by colored underline
/// - Completed exercises show checkmark overlay
/// - "+" button at end to add exercises
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/workout_design.dart';
import '../../../data/models/exercise.dart';

/// MacroFactor-style exercise thumbnail strip
class ExerciseThumbnailStripV2 extends StatefulWidget {
  /// All exercises in the workout
  final List<WorkoutExercise> exercises;

  /// Currently active exercise index
  final int currentIndex;

  /// Set of exercise indices that are completed
  final Set<int> completedExercises;

  /// Callback when user taps an exercise to switch
  final void Function(int index) onExerciseTap;

  /// Callback when user taps the add button
  final VoidCallback? onAddTap;

  /// Whether to show the add button
  final bool showAddButton;

  const ExerciseThumbnailStripV2({
    super.key,
    required this.exercises,
    required this.currentIndex,
    required this.completedExercises,
    required this.onExerciseTap,
    this.onAddTap,
    this.showAddButton = true,
  });

  @override
  State<ExerciseThumbnailStripV2> createState() => _ExerciseThumbnailStripV2State();
}

class _ExerciseThumbnailStripV2State extends State<ExerciseThumbnailStripV2> {
  late ScrollController _scrollController;

  // Thumbnail dimensions - compact rectangular (taller than wide)
  static const double _thumbnailWidth = 44.0;
  static const double _thumbnailHeight = 56.0;
  static const double _thumbnailSpacing = 6.0;
  static const double _indicatorHeight = 2.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentExercise(animate: false);
    });
  }

  @override
  void didUpdateWidget(ExerciseThumbnailStripV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollToCurrentExercise(animate: true);
    }
  }

  void _scrollToCurrentExercise({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final itemWidth = _thumbnailWidth + _thumbnailSpacing;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = (widget.currentIndex * itemWidth) -
        (screenWidth / 2) +
        (_thumbnailWidth / 2);

    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.exercises.length + (widget.showAddButton ? 1 : 0);

    return SizedBox(
      height: _thumbnailHeight + _indicatorHeight + 8, // Extra padding
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Add button at the end
          if (widget.showAddButton && index == widget.exercises.length) {
            return _AddExerciseButton(onTap: widget.onAddTap);
          }

          final exercise = widget.exercises[index];
          final isActive = index == widget.currentIndex;
          final isCompleted = widget.completedExercises.contains(index);

          return _ExerciseThumbnail(
            exercise: exercise,
            isActive: isActive,
            isCompleted: isCompleted,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onExerciseTap(index);
            },
          );
        },
      ),
    );
  }
}

/// Individual exercise thumbnail with MacroFactor styling
class _ExerciseThumbnail extends StatelessWidget {
  final WorkoutExercise exercise;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  static const double _width = 44.0;
  static const double _height = 56.0;

  const _ExerciseThumbnail({
    required this.exercise,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = exercise.gifUrl ?? exercise.imageS3Path;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail image
            SizedBox(
              width: _width,
              height: _height,
              child: Stack(
                children: [
                  // Image container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: _width,
                      height: _height,
                      color: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _buildPlaceholder(isDark),
                              errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
                            )
                          : _buildPlaceholder(isDark),
                    ),
                  ),

                  // Completed checkmark overlay
                  if (isCompleted)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 3),

            // Active indicator line
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _width,
              height: 2,
              decoration: BoxDecoration(
                color: isActive
                    ? WorkoutDesign.accentBlue
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: _width,
      height: _height,
      color: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
      child: Icon(
        Icons.fitness_center,
        size: 16,
        color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade400,
      ),
    );
  }
}

/// Add exercise button at the end of the strip
class _AddExerciseButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddExerciseButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        width: 44,
        height: 56,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isDark ? WorkoutDesign.surface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? WorkoutDesign.border : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade500,
        ),
      ),
    );
  }
}
