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
            },
            onDragEnded: () {
              setState(() => _draggingIndex = null);
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
                },
                onDragEnded: () {
                  setState(() => _draggingIndex = null);
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

/// Gap drop target for reordering exercises
class _GapDropTarget extends StatefulWidget {
  final int insertIndex;
  final bool isDark;
  final void Function(int fromIndex) onReorder;

  const _GapDropTarget({
    super.key,
    required this.insertIndex,
    required this.isDark,
    required this.onReorder,
  });

  @override
  State<_GapDropTarget> createState() => _GapDropTargetState();
}

class _GapDropTargetState extends State<_GapDropTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        // Accept if dragging a different position
        // Don't accept if it would result in same position
        final fromIndex = details.data;
        if (fromIndex == widget.insertIndex || fromIndex == widget.insertIndex - 1) {
          return false;
        }
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _isHovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        HapticFeedback.mediumImpact();
        widget.onReorder(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = _isHovering && candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isActive ? 24 : 6,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.blue.withValues(alpha: 0.4)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isActive
                ? Border.all(color: Colors.blue, width: 2)
                : null,
          ),
          child: isActive
              ? const Center(
                  child: Icon(Icons.arrow_downward, color: Colors.blue, size: 16),
                )
              : null,
        );
      },
    );
  }
}

/// Container that wraps multiple superset exercise thumbnails in a single border
class _SupersetGroupContainer extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SupersetGroupContainer({
    super.key,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple, width: 2.5),
        color: Colors.purple.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Link icon at the start
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.link, color: Colors.white, size: 12),
          ),
          // Thumbnails
          ...children,
        ],
      ),
    );
  }
}

/// Draggable thumbnail that supports both reorder and superset creation
class _DraggableThumbnail extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;
  final int index;
  final bool isActive;
  final bool isCompleted;
  final bool isDragging;
  final bool isInSupersetGroup; // Whether this thumbnail is inside a superset group container
  final VoidCallback onTap;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final void Function(int draggedIndex)? onCreateSuperset;

  const _DraggableThumbnail({
    super.key,
    required this.exercise,
    required this.index,
    required this.isActive,
    required this.isCompleted,
    required this.isDragging,
    this.isInSupersetGroup = false,
    required this.onTap,
    required this.onDragStarted,
    required this.onDragEnded,
    this.onCreateSuperset,
  });

  @override
  ConsumerState<_DraggableThumbnail> createState() => _DraggableThumbnailState();
}

class _DraggableThumbnailState extends ConsumerState<_DraggableThumbnail>
    with SingleTickerProviderStateMixin {
  bool _isSupersetTarget = false;
  String? _imageUrl;
  bool _isLoadingImage = true;

  // Static cache shared across all thumbnails
  static final Map<String, String> _imageCache = {};

  // Animation controller for the rotating border
  late AnimationController _borderAnimController;

  static const double _width = 44.0;
  static const double _height = 56.0;

  @override
  void initState() {
    super.initState();
    _borderAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.isActive) {
      _borderAnimController.repeat();
    }
    _loadImage();
  }

  @override
  void didUpdateWidget(_DraggableThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _borderAnimController.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _borderAnimController.stop();
      _borderAnimController.reset();
    }
  }

  @override
  void dispose() {
    _borderAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingImage = false);
      return;
    }

    final exerciseGifUrl = widget.exercise.gifUrl;
    if (exerciseGifUrl != null && exerciseGifUrl.isNotEmpty) {
      final cacheKey = exerciseName.toLowerCase();
      _imageCache[cacheKey] = exerciseGifUrl;
      if (mounted) {
        setState(() {
          _imageUrl = exerciseGifUrl;
          _isLoadingImage = false;
        });
      }
      return;
    }

    final cacheKey = exerciseName.toLowerCase();
    if (_imageCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _imageUrl = _imageCache[cacheKey];
          _isLoadingImage = false;
        });
      }
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
          _imageCache[cacheKey] = url;
          setState(() {
            _imageUrl = url;
            _isLoadingImage = false;
          });
          return;
        }
      }
    } catch (e) {
      // Image not found - fail silently
    }

    if (mounted) {
      setState(() => _isLoadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show placeholder when this item is being dragged
    if (widget.isDragging) {
      return Container(
        width: _width,
        height: _height,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
      );
    }

    return LongPressDraggable<int>(
      data: widget.index,
      delay: const Duration(milliseconds: 200),
      feedback: _buildDragFeedback(isDark),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        widget.onDragStarted();
      },
      onDraggableCanceled: (_, __) => widget.onDragEnded(),
      onDragEnd: (_) => widget.onDragEnded(),
      child: widget.onCreateSuperset != null
          ? DragTarget<int>(
              onWillAcceptWithDetails: (details) {
                if (details.data != widget.index) {
                  setState(() => _isSupersetTarget = true);
                  HapticFeedback.selectionClick();
                  return true;
                }
                return false;
              },
              onLeave: (_) => setState(() => _isSupersetTarget = false),
              onAcceptWithDetails: (details) {
                setState(() => _isSupersetTarget = false);
                HapticFeedback.mediumImpact();
                widget.onCreateSuperset?.call(details.data);
              },
              builder: (context, candidateData, rejectedData) {
                return _buildThumbnailContent(
                  isDark: isDark,
                  isSupersetTarget: _isSupersetTarget && candidateData.isNotEmpty,
                );
              },
            )
          : _buildThumbnailContent(isDark: isDark, isSupersetTarget: false),
    );
  }

  Widget _buildThumbnailContent({
    required bool isDark,
    required bool isSupersetTarget,
  }) {
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);
    final HSLColor hsl = HSLColor.fromColor(accentColor);
    final lighterAccent = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final lightestAccent = hsl.withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0)).toColor();

    // Check if this exercise is part of a superset
    // If isInSupersetGroup is true, the parent container handles the visual grouping
    final isInSuperset = widget.exercise.isInSuperset;

    Widget thumbnailContent = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: _width,
        height: _height,
        color: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
        child: Stack(
          children: [
            if (_isLoadingImage)
              _buildLoadingPlaceholder(isDark)
            else if (_imageUrl != null && _imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _imageUrl!,
                fit: BoxFit.cover,
                width: _width,
                height: _height,
                placeholder: (_, __) => _buildPlaceholder(isDark),
                errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
              )
            else
              _buildPlaceholder(isDark),

            if (widget.isCompleted)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
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

            // Superset drop overlay (when dragging onto this)
            if (isSupersetTarget)
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(
                    Icons.link,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Active border animation (always show for active exercise)
    if (widget.isActive && !isSupersetTarget) {
      // Use purple gradient for superset exercises in group, otherwise accent
      final usesPurple = widget.isInSupersetGroup && isInSuperset;
      thumbnailContent = AnimatedBuilder(
        animation: _borderAnimController,
        builder: (context, child) {
          final angle = _borderAnimController.value * 2 * 3.14159;
          return Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: SweepGradient(
                startAngle: angle,
                endAngle: angle + 2 * 3.14159,
                colors: usesPurple
                    ? [
                        Colors.purple,
                        Colors.purple.shade300,
                        Colors.purple.shade100,
                        Colors.purple.shade300,
                        Colors.purple,
                      ]
                    : [
                        accentColor,
                        lighterAccent,
                        lightestAccent,
                        lighterAccent,
                        accentColor,
                      ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: thumbnailContent,
      );
    }

    // Superset target highlight (when dragging over)
    if (isSupersetTarget) {
      thumbnailContent = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: thumbnailContent,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: thumbnailContent,
      ),
    );
  }

  Widget _buildDragFeedback(bool isDark) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(8),
      shadowColor: Colors.black.withValues(alpha: 0.4),
      child: Container(
        width: _width + 8,
        height: _height + 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              if (_imageUrl != null && _imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: _imageUrl!,
                  fit: BoxFit.cover,
                  width: _width + 8,
                  height: _height + 8,
                )
              else
                Container(
                  color: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
                  child: const Center(
                    child: Icon(Icons.fitness_center, size: 20),
                  ),
                ),
              // Tint overlay
              Container(
                color: Colors.purple.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(bool isDark) {
    return Container(
      width: _width,
      height: _height,
      color: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade400,
          ),
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

/// Individual exercise thumbnail (non-draggable version)
class _ExerciseThumbnail extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;
  final bool isActive;
  final bool isCompleted;
  final bool isInSupersetGroup; // Whether this thumbnail is inside a superset group container
  final VoidCallback onTap;

  static const double _width = 44.0;
  static const double _height = 56.0;

  const _ExerciseThumbnail({
    super.key,
    required this.exercise,
    required this.isActive,
    required this.isCompleted,
    this.isInSupersetGroup = false,
    required this.onTap,
  });

  @override
  ConsumerState<_ExerciseThumbnail> createState() => _ExerciseThumbnailState();
}

class _ExerciseThumbnailState extends ConsumerState<_ExerciseThumbnail>
    with SingleTickerProviderStateMixin {
  String? _imageUrl;
  bool _isLoadingImage = true;

  static final Map<String, String> _imageCache = {};
  late AnimationController _borderAnimController;

  @override
  void initState() {
    super.initState();
    _borderAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.isActive) {
      _borderAnimController.repeat();
    }
    _loadImage();
  }

  @override
  void didUpdateWidget(_ExerciseThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _borderAnimController.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _borderAnimController.stop();
      _borderAnimController.reset();
    }
  }

  @override
  void dispose() {
    _borderAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingImage = false);
      return;
    }

    final exerciseGifUrl = widget.exercise.gifUrl;
    if (exerciseGifUrl != null && exerciseGifUrl.isNotEmpty) {
      final cacheKey = exerciseName.toLowerCase();
      _imageCache[cacheKey] = exerciseGifUrl;
      if (mounted) {
        setState(() {
          _imageUrl = exerciseGifUrl;
          _isLoadingImage = false;
        });
      }
      return;
    }

    final cacheKey = exerciseName.toLowerCase();
    if (_imageCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _imageUrl = _imageCache[cacheKey];
          _isLoadingImage = false;
        });
      }
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
          _imageCache[cacheKey] = url;
          setState(() {
            _imageUrl = url;
            _isLoadingImage = false;
          });
          return;
        }
      }
    } catch (e) {
      // Image not found - fail silently
    }

    if (mounted) {
      setState(() => _isLoadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);
    final HSLColor hsl = HSLColor.fromColor(accentColor);
    final lighterAccent = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final lightestAccent = hsl.withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0)).toColor();

    // Check if exercise is in a superset
    // If isInSupersetGroup is true, the parent container handles the visual grouping
    final isInSuperset = widget.exercise.isInSuperset;
    final usesPurpleActive = widget.isInSupersetGroup && isInSuperset;

    Widget thumbnailContent = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: _ExerciseThumbnail._width,
        height: _ExerciseThumbnail._height,
        color: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
        child: Stack(
          children: [
            if (_isLoadingImage)
              _buildLoadingPlaceholder(isDark)
            else if (_imageUrl != null && _imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _imageUrl!,
                fit: BoxFit.cover,
                width: _ExerciseThumbnail._width,
                height: _ExerciseThumbnail._height,
                placeholder: (_, __) => _buildPlaceholder(isDark),
                errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
              )
            else
              _buildPlaceholder(isDark),

            if (widget.isCompleted)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
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
          ],
        ),
      ),
    );

    if (widget.isActive) {
      // Use purple animated border if in superset group, otherwise use accent color
      final borderColor = usesPurpleActive ? Colors.purple : accentColor;
      final borderLighter = usesPurpleActive
          ? Colors.purple.shade300
          : lighterAccent;
      final borderLightest = usesPurpleActive
          ? Colors.purple.shade200
          : lightestAccent;

      thumbnailContent = AnimatedBuilder(
        animation: _borderAnimController,
        builder: (context, child) {
          final angle = _borderAnimController.value * 2 * 3.14159;
          return Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: SweepGradient(
                startAngle: angle,
                endAngle: angle + 2 * 3.14159,
                colors: [
                  borderColor,
                  borderLighter,
                  borderLightest,
                  borderLighter,
                  borderColor,
                ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: thumbnailContent,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: thumbnailContent,
      ),
    );
  }

  Widget _buildLoadingPlaceholder(bool isDark) {
    return Container(
      width: _ExerciseThumbnail._width,
      height: _ExerciseThumbnail._height,
      color: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: _ExerciseThumbnail._width,
      height: _ExerciseThumbnail._height,
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

  const _AddExerciseButton({super.key, this.onTap});

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
