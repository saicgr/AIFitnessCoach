import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/video_cache_provider.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../components/exercise_detail_sheet.dart';
import '../screens/category_exercises_screen.dart';

/// Netflix-style horizontal carousel for a category of exercises
/// Shows multiple small cards per row that scroll horizontally
class NetflixExerciseCarousel extends StatelessWidget {
  final String categoryTitle;
  final List<LibraryExercise> exercises;
  /// Optional: all exercises for this category (for See All screen)
  final List<LibraryExercise>? allExercises;
  /// Whether to show the See All button
  final bool showSeeAll;

  const NetflixExerciseCarousel({
    super.key,
    required this.categoryTitle,
    required this.exercises,
    this.allExercises,
    this.showSeeAll = true,
  });

  void _navigateToSeeAll(BuildContext context) {
    HapticService.light();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CategoryExercisesScreen(
          categoryName: categoryTitle,
          initialExercises: allExercises ?? exercises,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    if (exercises.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title with "See All" button
        GestureDetector(
          onTap: showSeeAll ? () => _navigateToSeeAll(context) : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
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
                        '${exercises.length}${(allExercises?.length ?? exercises.length) > exercises.length ? '+' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cyan,
                        ),
                      ),
                    ),
                  ],
                ),
                if (showSeeAll)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cyan,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: cyan,
                        size: 20,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Horizontal scrolling row of cards with improved physics
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              return _NetflixCard(
                exercise: exercises[index],
                index: index,
              );
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

class _NetflixHeroSectionState extends ConsumerState<NetflixHeroSection>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _isLoadingVideo = false;

  /// Animation controller for fade-in effect
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  /// Animation controller for page transitions
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  /// Whether reduced motion is enabled
  bool _reducedMotion = false;

  /// Drag state for swipe gesture
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Initialize slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Check accessibility and load video after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccessibilityAndLoad();
    });
  }

  void _checkAccessibilityAndLoad() {
    final mediaQuery = MediaQuery.of(context);
    _reducedMotion = mediaQuery.disableAnimations;

    // Load video for first exercise
    if (widget.exercises.isNotEmpty) {
      _loadVideoForExercise(widget.exercises[0]);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideoForExercise(LibraryExercise exercise) async {
    // Dispose old video
    _videoController?.dispose();
    _videoController = null;
    _fadeController.reset();
    setState(() {
      _videoInitialized = false;
      _isLoadingVideo = true;
    });

    final exerciseName = exercise.originalName ?? exercise.name;
    final exerciseId =
        exercise.id ?? exercise.name.toLowerCase().replaceAll(' ', '_');

    try {
      // First check for cached video
      final cacheNotifier = ref.read(videoCacheProvider.notifier);
      final localPath = cacheNotifier.getLocalVideoPath(exerciseId);

      if (localPath != null) {
        debugPrint('Using cached video for hero: $exerciseName');
        await _initializeVideoController(localPath, isLocal: true);
        return;
      }

      // Fetch from API
      final apiClient = ref.read(apiClientProvider);
      final videoResponse = await apiClient.get(
        '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
      );

      if (videoResponse.statusCode == 200 && videoResponse.data != null) {
        final videoUrl = videoResponse.data['url'] as String?;
        if (videoUrl != null && mounted) {
          await _initializeVideoController(videoUrl, isLocal: false);
        }
      } else {
        if (mounted) setState(() => _isLoadingVideo = false);
      }
    } catch (e) {
      debugPrint('Error loading hero video: $e');
      if (mounted) setState(() => _isLoadingVideo = false);
    }
  }

  Future<void> _initializeVideoController(String source,
      {required bool isLocal}) async {
    try {
      if (isLocal) {
        _videoController = VideoPlayerController.file(File(source));
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(source));
      }

      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0);

      // Auto-play unless reduced motion
      if (!_reducedMotion) {
        _videoController!.play();
      }

      if (mounted) {
        setState(() {
          _videoInitialized = true;
          _isLoadingVideo = false;
        });
        // Fade in the video
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('Error initializing hero video: $e');
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

  void _animateToPage(int newPage, int direction) {
    HapticService.selection();
    setState(() {
      _currentPage = newPage;
      _dragOffset = 0;
    });
    _loadVideoForExercise(widget.exercises[newPage]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    if (widget.exercises.isEmpty) return const SizedBox.shrink();

    final currentExercise = widget.exercises[_currentPage];

    return Column(
      children: [
        // Hero card with smooth swipe support
        GestureDetector(
          onTap: () => _showExerciseDetail(currentExercise),
          onHorizontalDragStart: (_) {
            _dragOffset = 0;
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dx;
            });
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            final screenWidth = MediaQuery.of(context).size.width;
            final threshold = screenWidth * 0.2;

            // Determine if we should change page
            if ((velocity < -300 || _dragOffset < -threshold) &&
                _currentPage < widget.exercises.length - 1) {
              // Swipe left - next
              _animateToPage(_currentPage + 1, -1);
            } else if ((velocity > 300 || _dragOffset > threshold) &&
                _currentPage > 0) {
              // Swipe right - previous
              _animateToPage(_currentPage - 1, 1);
            } else {
              // Snap back
              setState(() => _dragOffset = 0);
            }
          },
          child: AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              // Calculate offset based on drag or animation
              double offset = _dragOffset;
              if (_slideController.isAnimating) {
                offset = _slideAnimation.value.dx * MediaQuery.of(context).size.width;
              }

              return Transform.translate(
                offset: Offset(offset * 0.3, 0), // Parallax effect
                child: child,
              );
            },
            child: Container(
            height: 180,
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
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
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
                          ? _buildLoadingIndicator(cyan, purple)
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

                // Content - simplified
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentExercise.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (currentExercise.muscleGroup != null)
                            _HeroChip(
                              label: currentExercise.muscleGroup!,
                              color: purple,
                            ),
                          if (currentExercise.difficulty != null) ...[
                            const SizedBox(width: 6),
                            _HeroChip(
                              label: DifficultyUtils.getDisplayName(currentExercise.difficulty!),
                              color: DifficultyUtils.getColor(currentExercise.difficulty!),
                            ),
                          ],
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
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Build loading indicator for hero video
  Widget _buildLoadingIndicator(Color cyan, Color purple) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    cyan.withValues(alpha: 0.3),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(cyan),
                ),
              ),
              Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: cyan.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Loading...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
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

/// Netflix-style small card - clean and minimal
class _NetflixCard extends StatelessWidget {
  final LibraryExercise exercise;
  final int index;

  const _NetflixCard({
    required this.exercise,
    this.index = 0,
  });

  void _showExerciseDetail(BuildContext context) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: exercise),
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
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(8),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area - clean gradient with icon
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
                    // Body part icon
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
                            color: DifficultyUtils.getColor(exercise.difficulty!)
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            DifficultyUtils.getDisplayName(exercise.difficulty!)[0],
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
            // Title and body part
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exercise.bodyPart != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      exercise.bodyPart!,
                      style: TextStyle(
                        fontSize: 9,
                        color: textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
