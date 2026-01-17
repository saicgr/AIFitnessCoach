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
      height: _thumbnailHeight + 16, // Extra padding for prominent animated border
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
/// Now fetches images from API if not available in exercise model
class _ExerciseThumbnail extends ConsumerStatefulWidget {
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
  ConsumerState<_ExerciseThumbnail> createState() => _ExerciseThumbnailState();
}

class _ExerciseThumbnailState extends ConsumerState<_ExerciseThumbnail>
    with SingleTickerProviderStateMixin {
  String? _imageUrl;
  bool _isLoadingImage = true;

  // Static cache shared across all thumbnails
  static final Map<String, String> _imageCache = {};

  // Animation controller for the rotating border
  late AnimationController _borderAnimController;

  @override
  void initState() {
    super.initState();
    _borderAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Faster rotation
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

    // First check if exercise already has a gifUrl from the database
    final exerciseGifUrl = widget.exercise.gifUrl ?? widget.exercise.imageS3Path;
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

    // Fall back to cache
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

    // Last resort: fetch from API
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

    // Get accent color from settings
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    // Create lighter variants of the accent color for the gradient
    final HSLColor hsl = HSLColor.fromColor(accentColor);
    final lighterAccent = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final lightestAccent = hsl.withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0)).toColor();

    // Build the core thumbnail content
    Widget thumbnailContent = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: _ExerciseThumbnail._width,
        height: _ExerciseThumbnail._height,
        color: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
        child: Stack(
          children: [
            // Image
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

            // Completed checkmark overlay
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

    // Wrap with animated border if active
    if (widget.isActive) {
      thumbnailContent = AnimatedBuilder(
        animation: _borderAnimController,
        builder: (context, child) {
          // Calculate rotation angle - full circle
          final angle = _borderAnimController.value * 2 * 3.14159;
          return Container(
            padding: const EdgeInsets.all(2.5), // Border width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              // Use a conic gradient for smooth continuous rotation
              gradient: SweepGradient(
                startAngle: angle,
                endAngle: angle + 2 * 3.14159,
                colors: [
                  accentColor, // Accent color from settings
                  lighterAccent, // Lighter variant
                  lightestAccent, // Lightest variant
                  lighterAccent, // Lighter variant
                  accentColor, // Back to accent (matches start for seamless loop)
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

