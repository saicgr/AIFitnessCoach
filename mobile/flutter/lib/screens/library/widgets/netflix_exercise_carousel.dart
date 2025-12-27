import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../components/exercise_detail_sheet.dart';

/// Netflix-style horizontal carousel for a category of exercises
/// Shows multiple small cards per row that scroll horizontally
class NetflixExerciseCarousel extends StatelessWidget {
  final String categoryTitle;
  final List<LibraryExercise> exercises;

  const NetflixExerciseCarousel({
    super.key,
    required this.categoryTitle,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    if (exercises.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title with "See All" button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    categoryTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${exercises.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cyan,
                      ),
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right,
                color: textMuted,
                size: 24,
              ),
            ],
          ),
        ),

        // Horizontal scrolling row of cards (Netflix style - multiple visible)
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              return _NetflixCard(exercise: exercises[index]);
            },
          ),
        ),
      ],
    );
  }
}

/// Netflix-style featured hero section at the top
class NetflixHeroSection extends ConsumerStatefulWidget {
  final List<LibraryExercise> exercises;

  const NetflixHeroSection({
    super.key,
    required this.exercises,
  });

  @override
  ConsumerState<NetflixHeroSection> createState() => _NetflixHeroSectionState();
}

class _NetflixHeroSectionState extends ConsumerState<NetflixHeroSection> {
  int _currentPage = 0;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _isLoadingVideo = false;

  @override
  void initState() {
    super.initState();
    // Load video for first exercise
    if (widget.exercises.isNotEmpty) {
      _loadVideoForExercise(widget.exercises[0]);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideoForExercise(LibraryExercise exercise) async {
    // Dispose old video
    _videoController?.dispose();
    _videoController = null;
    setState(() {
      _videoInitialized = false;
      _isLoadingVideo = true;
    });

    final exerciseName = exercise.originalName ?? exercise.name;

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
          _videoController!.play();

          if (mounted) {
            setState(() {
              _videoInitialized = true;
              _isLoadingVideo = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingVideo = false);
      }
    } catch (e) {
      debugPrint('Error loading hero video: $e');
      if (mounted) setState(() => _isLoadingVideo = false);
    }
  }

  void _showExerciseDetail(LibraryExercise exercise) {
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    if (widget.exercises.isEmpty) return const SizedBox.shrink();

    final currentExercise = widget.exercises[_currentPage];

    return Column(
      children: [
        // Hero card with swipe support
        GestureDetector(
          onTap: () => _showExerciseDetail(currentExercise),
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -200 &&
                  _currentPage < widget.exercises.length - 1) {
                // Swipe left - next
                setState(() => _currentPage++);
                HapticService.selection();
                _loadVideoForExercise(widget.exercises[_currentPage]);
              } else if (details.primaryVelocity! > 200 && _currentPage > 0) {
                // Swipe right - previous
                setState(() => _currentPage--);
                HapticService.selection();
                _loadVideoForExercise(widget.exercises[_currentPage]);
              }
            }
          },
          child: Container(
            height: 280,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : AppColorsLight.elevated,
              borderRadius: BorderRadius.circular(20),
              border: isDark
                  ? Border.all(color: cyan.withValues(alpha: 0.3))
                  : Border.all(color: AppColorsLight.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: cyan.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video or gradient background
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
                          purple.withValues(alpha: 0.4),
                          cyan.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: _isLoadingVideo
                          ? CircularProgressIndicator(color: cyan, strokeWidth: 2)
                          : Icon(
                              _getBodyPartIcon(currentExercise.bodyPart),
                              size: 80,
                              color: purple.withValues(alpha: 0.5),
                            ),
                    ),
                  ),

                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentExercise.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (currentExercise.muscleGroup != null)
                            _HeroChip(
                              label: currentExercise.muscleGroup!,
                              color: purple,
                            ),
                          if (currentExercise.difficulty != null) ...[
                            const SizedBox(width: 8),
                            _HeroChip(
                              label: currentExercise.difficulty!,
                              color: AppColors.getDifficultyColor(
                                  currentExercise.difficulty!),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _HeroButton(
                            icon: Icons.play_arrow,
                            label: 'View',
                            isPrimary: true,
                            onTap: () => _showExerciseDetail(currentExercise),
                          ),
                          const SizedBox(width: 12),
                          _HeroButton(
                            icon: Icons.add,
                            label: 'Add',
                            isPrimary: false,
                            onTap: () {
                              // TODO: Add to workout functionality
                            },
                          ),
                        ],
                      ),
                    ],
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
        ),

        // Page indicators
        if (widget.exercises.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.exercises.length.clamp(0, 8),
                (index) => GestureDetector(
                  onTap: () {
                    setState(() => _currentPage = index);
                    HapticService.selection();
                    _loadVideoForExercise(widget.exercises[index]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? cyan
                          : textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),
      ],
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
      default:
        return Icons.fitness_center;
    }
  }
}

/// Hero section chip
class _HeroChip extends StatelessWidget {
  final String label;
  final Color color;

  const _HeroChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Hero section button (like Netflix Play/More Info)
class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HeroButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Netflix-style small card (poster style)
class _NetflixCard extends StatelessWidget {
  final LibraryExercise exercise;

  const _NetflixCard({required this.exercise});

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
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return GestureDetector(
      onTap: () => _showExerciseDetail(context),
      child: Container(
        width: 120, // Netflix poster width
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(8),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail (poster area)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      purple.withValues(alpha: 0.3),
                      cyan.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Icon
                    Center(
                      child: Icon(
                        _getBodyPartIcon(exercise.bodyPart),
                        size: 36,
                        color: purple.withValues(alpha: 0.6),
                      ),
                    ),
                    // Difficulty badge
                    if (exercise.difficulty != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.getDifficultyColor(
                                    exercise.difficulty!)
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exercise.difficulty![0], // First letter: B, I, A
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Title area
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                exercise.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
      default:
        return Icons.fitness_center;
    }
  }
}
