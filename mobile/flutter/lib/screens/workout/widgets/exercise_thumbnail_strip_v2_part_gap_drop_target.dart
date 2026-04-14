part of 'exercise_thumbnail_strip_v2.dart';


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

    final preResolvedUrl = widget.exercise.imageS3Path ?? widget.exercise.gifUrl;
    if (preResolvedUrl != null && preResolvedUrl.isNotEmpty) {
      final cacheKey = exerciseName.toLowerCase();
      _imageCache[cacheKey] = preResolvedUrl;
      if (mounted) {
        setState(() {
          _imageUrl = preResolvedUrl;
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
  final VoidCallback? onLongPress;

  static const double _width = 44.0;
  static const double _height = 56.0;

  const _ExerciseThumbnail({
    super.key,
    required this.exercise,
    required this.isActive,
    required this.isCompleted,
    this.isInSupersetGroup = false,
    required this.onTap,
    this.onLongPress,
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

    final preResolvedUrl = widget.exercise.imageS3Path ?? widget.exercise.gifUrl;
    if (preResolvedUrl != null && preResolvedUrl.isNotEmpty) {
      final cacheKey = exerciseName.toLowerCase();
      _imageCache[cacheKey] = preResolvedUrl;
      if (mounted) {
        setState(() {
          _imageUrl = preResolvedUrl;
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
      onLongPress: widget.onLongPress,
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

