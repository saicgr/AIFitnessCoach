import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../components/exercise_detail_sheet.dart';

/// Netflix-style horizontal carousel for a category of exercises
class NetflixExerciseCarousel extends ConsumerStatefulWidget {
  final String categoryTitle;
  final List<LibraryExercise> exercises;
  final bool isHeroRow;

  const NetflixExerciseCarousel({
    super.key,
    required this.categoryTitle,
    required this.exercises,
    this.isHeroRow = false,
  });

  @override
  ConsumerState<NetflixExerciseCarousel> createState() =>
      _NetflixExerciseCarouselState();
}

class _NetflixExerciseCarouselState
    extends ConsumerState<NetflixExerciseCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
      HapticService.selection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (widget.exercises.isEmpty) return const SizedBox.shrink();

    final cardHeight = widget.isHeroRow ? 280.0 : 180.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Text(
                widget.categoryTitle,
                style: TextStyle(
                  fontSize: widget.isHeroRow ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.exercises.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),

        // Carousel
        SizedBox(
          height: cardHeight,
          child: widget.isHeroRow
              ? PageView.builder(
                  controller: _pageController,
                  itemCount: widget.exercises.length,
                  itemBuilder: (context, index) {
                    return _HeroExerciseCard(
                      exercise: widget.exercises[index],
                      isActive: index == _currentPage,
                    );
                  },
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.exercises.length,
                  itemBuilder: (context, index) {
                    return _CompactExerciseCard(
                      exercise: widget.exercises[index],
                    );
                  },
                ),
        ),

        // Page indicators for hero row
        if (widget.isHeroRow && widget.exercises.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.exercises.length.clamp(0, 10),
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? (isDark ? AppColors.cyan : AppColorsLight.cyan)
                        : textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Hero card with video auto-play capability
class _HeroExerciseCard extends ConsumerStatefulWidget {
  final LibraryExercise exercise;
  final bool isActive;

  const _HeroExerciseCard({
    required this.exercise,
    required this.isActive,
  });

  @override
  ConsumerState<_HeroExerciseCard> createState() => _HeroExerciseCardState();
}

class _HeroExerciseCardState extends ConsumerState<_HeroExerciseCard> {
  VideoPlayerController? _videoController;
  bool _isLoadingVideo = false;
  bool _videoInitialized = false;
  bool _wasActive = false;

  @override
  void didUpdateWidget(covariant _HeroExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle activation/deactivation
    if (widget.isActive && !_wasActive) {
      _loadAndPlayVideo();
    } else if (!widget.isActive && _wasActive) {
      _pauseVideo();
    }
    _wasActive = widget.isActive;
  }

  @override
  void initState() {
    super.initState();
    _wasActive = widget.isActive;
    if (widget.isActive) {
      // Delay video load slightly for smoother initial animation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && widget.isActive) {
          _loadAndPlayVideo();
        }
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadAndPlayVideo() async {
    if (_videoInitialized && _videoController != null) {
      _videoController!.play();
      return;
    }

    if (_isLoadingVideo) return;

    setState(() => _isLoadingVideo = true);

    final exerciseName =
        widget.exercise.originalName ?? widget.exercise.name;

    try {
      final apiClient = ref.read(apiClientProvider);
      final videoResponse = await apiClient.get(
        '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
      );

      if (videoResponse.statusCode == 200 && videoResponse.data != null) {
        final videoUrl = videoResponse.data['url'] as String?;
        if (videoUrl != null && mounted) {
          _videoController =
              VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          await _videoController!.initialize();
          _videoController!.setLooping(true);
          _videoController!.setVolume(0);

          if (mounted && widget.isActive) {
            _videoController!.play();
          }

          setState(() {
            _videoInitialized = true;
            _isLoadingVideo = false;
          });
        }
      } else {
        setState(() => _isLoadingVideo = false);
      }
    } catch (e) {
      debugPrint('Error loading hero video: $e');
      if (mounted) {
        setState(() => _isLoadingVideo = false);
      }
    }
  }

  void _pauseVideo() {
    _videoController?.pause();
  }

  void _showExerciseDetail(BuildContext context) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: widget.exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return GestureDetector(
      onTap: () => _showExerciseDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: widget.isActive ? 0 : 12,
        ),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? Border.all(
                  color: widget.isActive ? cyan.withOpacity(0.5) : Colors.transparent,
                  width: 2,
                )
              : Border.all(color: AppColorsLight.cardBorder),
          boxShadow: widget.isActive
              ? [
                  BoxShadow(
                    color: cyan.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video or Gradient background
            if (_videoInitialized && _videoController != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      purple.withOpacity(0.4),
                      cyan.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: _isLoadingVideo
                      ? CircularProgressIndicator(
                          color: cyan,
                          strokeWidth: 2,
                        )
                      : Icon(
                          _getBodyPartIcon(widget.exercise.bodyPart),
                          size: 64,
                          color: purple.withOpacity(0.6),
                        ),
                ),
              ),

            // Gradient overlay for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Exercise info overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exercise.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (widget.exercise.muscleGroup != null) ...[
                        _InfoChip(
                          icon: Icons.accessibility_new,
                          label: widget.exercise.muscleGroup!,
                          color: purple,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (widget.exercise.difficulty != null)
                        _InfoChip(
                          icon: Icons.signal_cellular_alt,
                          label: widget.exercise.difficulty!,
                          color: AppColors.getDifficultyColor(
                              widget.exercise.difficulty!),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Video indicator
            if (_videoInitialized && widget.isActive)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        size: 14,
                        color: cyan,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Playing',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Muted indicator
            if (_videoInitialized)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.volume_off,
                    size: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getBodyPartIcon(String? bodyPart) {
    switch (bodyPart?.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.airline_seat_flat;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'biceps':
      case 'triceps':
      case 'arms':
        return Icons.sports_martial_arts;
      case 'core':
      case 'abdominals':
        return Icons.self_improvement;
      case 'quadriceps':
      case 'legs':
      case 'glutes':
      case 'hamstrings':
      case 'calves':
        return Icons.directions_run;
      case 'cardio':
      case 'other':
        return Icons.monitor_heart;
      default:
        return Icons.fitness_center;
    }
  }
}

/// Compact card for non-hero rows
class _CompactExerciseCard extends StatelessWidget {
  final LibraryExercise exercise;

  const _CompactExerciseCard({required this.exercise});

  void _showExerciseDetail(BuildContext context) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return GestureDetector(
      onTap: () => _showExerciseDetail(context),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border:
              isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      purple.withOpacity(0.3),
                      cyan.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _getBodyPartIcon(exercise.bodyPart),
                      size: 40,
                      color: purple.withOpacity(0.6),
                    ),
                    // Video indicator if available
                    if (exercise.videoUrl != null &&
                        exercise.videoUrl!.isNotEmpty)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cyan,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (exercise.difficulty != null)
                    Text(
                      exercise.difficulty!,
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBodyPartIcon(String? bodyPart) {
    switch (bodyPart?.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.airline_seat_flat;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'biceps':
      case 'triceps':
      case 'arms':
        return Icons.sports_martial_arts;
      case 'core':
      case 'abdominals':
        return Icons.self_improvement;
      case 'quadriceps':
      case 'legs':
      case 'glutes':
      case 'hamstrings':
      case 'calves':
        return Icons.directions_run;
      case 'cardio':
      case 'other':
        return Icons.monitor_heart;
      default:
        return Icons.fitness_center;
    }
  }
}

/// Small info chip for hero cards
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
