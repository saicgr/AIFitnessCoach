/// Exercise Thumbnail Strip V2
///
/// Redesigned horizontal scrollable strip of exercise thumbnails inspired by
/// MacroFactor Workouts 2026. Simpler, cleaner design with:
/// - Thumbnails at the top of the screen (not in a container)
/// - Current exercise indicated by colored underline
/// - Completed exercises show checkmark overlay
/// - "+" button at end to add exercises
/// - Drag-to-reorder (drop in gaps) and drag-to-superset (drop on exercise)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/workout_design.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';

part 'exercise_thumbnail_strip_v2_part_gap_drop_target.dart';


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

  /// Callback when exercises are reordered via drag to gap
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Callback when superset is created via drag onto another exercise
  final void Function(int draggedIndex, int targetIndex)? onCreateSuperset;

  /// Callback when user long-presses an exercise
  final void Function(int index)? onExerciseLongPress;

  /// Callback when drag state changes (true = drag started, false = drag ended).
  /// Used by parent to show/hide drop zones (Delete, Swap) at the top of screen.
  final void Function(bool isDragging, int? draggedIndex)? onDragActiveChanged;

  const ExerciseThumbnailStripV2({
    super.key,
    required this.exercises,
    required this.currentIndex,
    required this.completedExercises,
    required this.onExerciseTap,
    this.onAddTap,
    this.showAddButton = true,
    this.onReorder,
    this.onCreateSuperset,
    this.onExerciseLongPress,
    this.onDragActiveChanged,
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
  static const double _gapWidth = 6.0;

  // Track which index is being dragged (null if none)
  int? _draggingIndex;

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

    // Account for gaps in width calculation
    final itemWidth = _thumbnailWidth + _gapWidth;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canDrag = widget.onReorder != null || widget.onCreateSuperset != null;

    // Group consecutive exercises by superset
    final groups = _groupExercisesBySuperset();

    // Build list with gaps for reorder drop targets
    // Pattern: [Gap0] [Group/Thumb0] [Gap1] [Group/Thumb1] [Gap2] ... [GapN] [Add]
    final items = <Widget>[];
    int globalIndex = 0;

    for (final group in groups) {
      // Add gap before each group/thumbnail (for reorder drops)
      if (canDrag && widget.onReorder != null) {
        items.add(_GapDropTarget(
          key: ValueKey('gap_$globalIndex'),
          insertIndex: globalIndex,
          isDark: isDark,
          onReorder: (fromIndex) {
            widget.onReorder?.call(fromIndex, globalIndex);
          },
        ));
      }

      if (group.length == 1) {
        // Single exercise - render normally
        final i = group.first;
        final exercise = widget.exercises[i];
        final isActive = i == widget.currentIndex;
        final isCompleted = widget.completedExercises.contains(i);
        final stableKey = exercise.id ??
            exercise.exerciseId ??
            '${exercise.name}_${exercise.hashCode}';

        if (canDrag) {
          items.add(_DraggableThumbnail(
            key: ValueKey('thumb_$stableKey'),
            exercise: exercise,
            index: i,
            isActive: isActive,
            isCompleted: isCompleted,
            isDragging: _draggingIndex == i,
            isInSupersetGroup: false,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onExerciseTap(i);
            },
            onDragStarted: () {
              setState(() => _draggingIndex = i);
              widget.onDragActiveChanged?.call(true, i);
            },
            onDragEnded: () {
              setState(() => _draggingIndex = null);
              widget.onDragActiveChanged?.call(false, null);
            },
            onCreateSuperset: widget.onCreateSuperset != null
                ? (draggedIndex) {
                    widget.onCreateSuperset?.call(draggedIndex, i);
                  }
                : null,
          ));
        } else {
          items.add(_ExerciseThumbnail(
            key: ValueKey('thumb_$stableKey'),
            exercise: exercise,
            isActive: isActive,
            isCompleted: isCompleted,
            isInSupersetGroup: false,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onExerciseTap(i);
            },
            onLongPress: widget.onExerciseLongPress != null
                ? () => widget.onExerciseLongPress!(i)
                : null,
          ));
        }
        globalIndex++;
      } else {
        // Superset group - wrap multiple thumbnails in a single container
        items.add(_SupersetGroupContainer(
          key: ValueKey('superset_${group.first}_${group.last}'),
          isDark: isDark,
          children: group.map((i) {
            final exercise = widget.exercises[i];
            final isActive = i == widget.currentIndex;
            final isCompleted = widget.completedExercises.contains(i);
            final stableKey = exercise.id ??
                exercise.exerciseId ??
                '${exercise.name}_${exercise.hashCode}';

            if (canDrag) {
              return _DraggableThumbnail(
                key: ValueKey('thumb_$stableKey'),
                exercise: exercise,
                index: i,
                isActive: isActive,
                isCompleted: isCompleted,
                isDragging: _draggingIndex == i,
                isInSupersetGroup: true,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onExerciseTap(i);
                },
                onDragStarted: () {
                  setState(() => _draggingIndex = i);
                  widget.onDragActiveChanged?.call(true, i);
                },
                onDragEnded: () {
                  setState(() => _draggingIndex = null);
                  widget.onDragActiveChanged?.call(false, null);
                },
                onCreateSuperset: widget.onCreateSuperset != null
                    ? (draggedIndex) {
                        widget.onCreateSuperset?.call(draggedIndex, i);
                      }
                    : null,
              );
            } else {
              return _ExerciseThumbnail(
                key: ValueKey('thumb_$stableKey'),
                exercise: exercise,
                isActive: isActive,
                isCompleted: isCompleted,
                isInSupersetGroup: true,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onExerciseTap(i);
                },
                onLongPress: widget.onExerciseLongPress != null
                    ? () => widget.onExerciseLongPress!(i)
                    : null,
              );
            }
          }).toList(),
        ));
        globalIndex += group.length;
      }
    }

    // Add final gap after last thumbnail (for reorder to end)
    if (canDrag && widget.onReorder != null) {
      items.add(_GapDropTarget(
        key: ValueKey('gap_${widget.exercises.length}'),
        insertIndex: widget.exercises.length,
        isDark: isDark,
        onReorder: (fromIndex) {
          widget.onReorder?.call(fromIndex, widget.exercises.length);
        },
      ));
    }

    // Add button at the end
    if (widget.showAddButton) {
      items.add(_AddExerciseButton(
        key: const ValueKey('add_button'),
        onTap: widget.onAddTap,
      ));
    }

    return SizedBox(
      height: _thumbnailHeight + 20, // Extra height for superset border
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: items,
      ),
    );
  }

  /// Groups consecutive exercises by superset group ID.
  /// Returns a list of lists, where each inner list contains indices of
  /// exercises that should be displayed together (either a single exercise
  /// or a group of superset exercises).
  List<List<int>> _groupExercisesBySuperset() {
    final groups = <List<int>>[];

    int i = 0;
    while (i < widget.exercises.length) {
      final exercise = widget.exercises[i];
      final supersetGroup = exercise.supersetGroup;

      if (supersetGroup == null) {
        // Not in a superset - single exercise
        groups.add([i]);
        i++;
      } else {
        // In a superset - find all consecutive exercises with same group
        final groupIndices = <int>[i];
        int j = i + 1;
        while (j < widget.exercises.length &&
            widget.exercises[j].supersetGroup == supersetGroup) {
          groupIndices.add(j);
          j++;
        }
        groups.add(groupIndices);
        i = j;
      }
    }

    return groups;
  }
}
