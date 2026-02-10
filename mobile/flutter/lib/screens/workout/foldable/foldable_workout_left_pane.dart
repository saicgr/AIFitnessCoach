/// Foldable Workout Left Pane
///
/// Left pane for foldable/tablet tri-layout containing:
/// - Compact top bar (back button + timer pill)
/// - Video player area (or ExerciseImage fallback)
/// - InlineExerciseInfo (collapsible exercise details)
/// - "Up Next" horizontal chip list
/// - ExerciseThumbnailStripV2 at bottom
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/workout_design.dart';
import '../../../data/models/exercise.dart';
import '../../../widgets/exercise_image.dart';
import '../widgets/exercise_thumbnail_strip_v2.dart';
import '../widgets/inline_exercise_info.dart';

/// Left pane of the foldable workout layout.
///
/// Displays video/image, exercise info, upcoming exercises, and thumbnail strip.
class FoldableWorkoutLeftPane extends StatelessWidget {
  /// All exercises in the workout
  final List<WorkoutExercise> exercises;

  /// Index of the exercise currently being performed
  final int currentExerciseIndex;

  /// Index of the exercise currently being viewed
  final int viewingExerciseIndex;

  /// Video player controller (null if no video)
  final VideoPlayerController? videoController;

  /// Whether the video controller is initialized and ready
  final bool isVideoInitialized;

  /// Fallback image URL when no video is available
  final String? imageUrl;

  /// Set of exercise indices that are completed
  final Set<int> completedExerciseIndices;

  /// Elapsed workout seconds for timer display
  final int workoutSeconds;

  /// Callback when an exercise thumbnail is tapped
  final void Function(int index) onExerciseTap;

  /// Callback when the add exercise button is tapped
  final VoidCallback onAddExercise;

  /// Callback when the user requests to quit the workout
  final VoidCallback onQuitRequested;

  /// Callback when exercises are reordered via drag
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Callback when a superset is created via drag
  final void Function(int draggedIndex, int targetIndex)? onCreateSuperset;

  /// Callback when the video area is tapped (play/pause toggle)
  final VoidCallback? onVideoTap;

  /// Callback when the info button is tapped
  final VoidCallback? onInfoTap;

  const FoldableWorkoutLeftPane({
    super.key,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.viewingExerciseIndex,
    this.videoController,
    this.isVideoInitialized = false,
    this.imageUrl,
    required this.completedExerciseIndices,
    required this.workoutSeconds,
    required this.onExerciseTap,
    required this.onAddExercise,
    required this.onQuitRequested,
    this.onReorder,
    this.onCreateSuperset,
    this.onVideoTap,
    this.onInfoTap,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? WorkoutDesign.background : Colors.grey.shade50;
    final surfaceColor = isDark ? WorkoutDesign.surface : Colors.white;
    final exercise = exercises.isNotEmpty ? exercises[viewingExerciseIndex] : null;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // 1. Compact top bar: back button + timer pill
          _buildCompactTopBar(isDark, surfaceColor),

          // 2. Video / image area + exercise info (scrollable)
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Video player or image fallback
                SliverToBoxAdapter(
                  child: _buildMediaArea(isDark, exercise),
                ),

                // Inline exercise info
                if (exercise != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WorkoutDesign.paddingMedium,
                        vertical: WorkoutDesign.paddingSmall,
                      ),
                      child: InlineExerciseInfo(exercise: exercise),
                    ),
                  ),

                // "Up Next" section
                SliverToBoxAdapter(
                  child: _buildUpNextSection(isDark),
                ),
              ],
            ),
          ),

          // 3. Thumbnail strip at bottom
          Container(
            color: surfaceColor,
            child: SafeArea(
              top: false,
              child: ExerciseThumbnailStripV2(
                exercises: exercises.toList(),
                currentIndex: viewingExerciseIndex,
                completedExercises: completedExerciseIndices,
                onExerciseTap: onExerciseTap,
                onAddTap: onAddExercise,
                showAddButton: true,
                onReorder: onReorder,
                onCreateSuperset: onCreateSuperset,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact top bar with back arrow and timer pill
  Widget _buildCompactTopBar(bool isDark, Color surfaceColor) {
    return Container(
      color: isDark ? WorkoutDesign.background : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WorkoutDesign.paddingSmall,
            vertical: 6,
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800,
                  size: 22,
                ),
                onPressed: onQuitRequested,
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
              const Spacer(),
              // Timer pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? WorkoutDesign.surface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(WorkoutDesign.radiusRound),
                  border: Border.all(
                    color: isDark ? WorkoutDesign.border : WorkoutDesign.borderLight,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(workoutSeconds),
                      style: WorkoutDesign.timerStyle.copyWith(
                        fontSize: 14,
                        color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Placeholder to balance the row
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Video player area or ExerciseImage fallback
  Widget _buildMediaArea(bool isDark, WorkoutExercise? exercise) {
    if (exercise == null) return const SizedBox.shrink();

    final backgroundColor = isDark ? AppColors.elevated : Colors.grey.shade100;

    return Padding(
      padding: const EdgeInsets.all(WorkoutDesign.paddingSmall),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WorkoutDesign.radiusMedium),
        child: Container(
          color: backgroundColor,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                // Video or image content
                Positioned.fill(
                  child: _buildMediaContent(exercise, isDark),
                ),

                // Play/pause overlay for video
                if (isVideoInitialized && videoController != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: onVideoTap,
                      behavior: HitTestBehavior.translucent,
                      child: AnimatedOpacity(
                        opacity: !(videoController?.value.isPlaying ?? false) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build either the video player or an exercise image
  Widget _buildMediaContent(WorkoutExercise exercise, bool isDark) {
    // If video is ready, show it
    if (isVideoInitialized && videoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: videoController!.value.size.width,
          height: videoController!.value.size.height,
          child: VideoPlayer(videoController!),
        ),
      );
    }

    // Fallback to exercise image
    return ExerciseImage(
      exerciseName: exercise.name,
      width: double.infinity,
      height: double.infinity,
      borderRadius: 0,
      fit: BoxFit.cover,
    );
  }

  /// "Up Next" horizontal chip list showing upcoming exercises
  Widget _buildUpNextSection(bool isDark) {
    // Get exercises after the current one
    final upcomingStartIndex = currentExerciseIndex + 1;
    if (upcomingStartIndex >= exercises.length) return const SizedBox.shrink();

    final upcoming = exercises.sublist(upcomingStartIndex);
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(
        left: WorkoutDesign.paddingMedium,
        top: WorkoutDesign.paddingSmall,
        bottom: WorkoutDesign.paddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UP NEXT',
            style: WorkoutDesign.labelStyle.copyWith(
              color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: upcoming.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final exercise = upcoming[index];
                final globalIndex = upcomingStartIndex + index;
                final isCompleted = completedExerciseIndices.contains(globalIndex);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onExerciseTap(globalIndex);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? (isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50)
                          : (isDark ? WorkoutDesign.surface : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(WorkoutDesign.radiusRound),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.green.withValues(alpha: 0.3)
                            : (isDark ? WorkoutDesign.border : WorkoutDesign.borderLight),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted) ...[
                          Icon(Icons.check, size: 14, color: Colors.green.shade400),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          exercise.name,
                          style: WorkoutDesign.chipStyle.copyWith(
                            fontSize: 12,
                            color: isCompleted
                                ? Colors.green.shade400
                                : (isDark ? WorkoutDesign.textSecondary : Colors.grey.shade700),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
