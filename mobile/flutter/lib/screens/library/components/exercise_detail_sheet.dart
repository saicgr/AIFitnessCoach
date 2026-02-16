import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/avoided_provider.dart';
import '../../../core/providers/exercise_queue_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../core/providers/video_cache_provider.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/context_logging_service.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/video_cache_service.dart';
import '../../../widgets/log_1rm_sheet.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../widgets/info_badge.dart';

/// Bottom sheet showing exercise details with video player
/// Auto-plays video when sheet opens (respects reduced motion settings)
class ExerciseDetailSheet extends ConsumerStatefulWidget {
  final LibraryExercise exercise;

  const ExerciseDetailSheet({
    super.key,
    required this.exercise,
  });

  @override
  ConsumerState<ExerciseDetailSheet> createState() =>
      _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends ConsumerState<ExerciseDetailSheet>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isLoadingVideo = true;
  bool _videoInitialized = false;
  String? _videoError;
  String? _videoUrl;

  /// Animation controller for fade-in effect
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  /// Whether reduced motion is enabled (respects accessibility)
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation for smooth video appearance
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Check accessibility settings and start loading after sheet animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccessibilityAndLoad();
      _logExerciseView();
    });
  }

  /// Log the exercise view for AI preference learning
  void _logExerciseView() {
    final exercise = widget.exercise;
    ref.read(contextLoggingServiceProvider).logExerciseViewed(
      exerciseId: exercise.id ?? exercise.name.toLowerCase().replaceAll(' ', '_'),
      exerciseName: exercise.name,
      source: 'library_browse',
      muscleGroup: exercise.muscleGroup,
      difficulty: exercise.difficulty,
      equipment: exercise.equipment,
    );
  }

  /// Check reduced motion setting and load video with delay for sheet animation
  void _checkAccessibilityAndLoad() {
    final mediaQuery = MediaQuery.of(context);
    _reducedMotion = mediaQuery.disableAnimations;

    // Delay video load slightly to let sheet animation complete (300ms)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _loadVideo();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    // Use original_name to fetch the video
    final exerciseName =
        widget.exercise.originalName ?? widget.exercise.name;
    if (exerciseName.isEmpty) {
      setState(() {
        _isLoadingVideo = false;
        _videoError = 'No exercise name';
      });
      return;
    }

    // Get exercise ID for cache lookup
    final exerciseId = widget.exercise.id ??
        widget.exercise.name.toLowerCase().replaceAll(' ', '_');

    try {
      // First check if video is cached locally
      final cacheNotifier = ref.read(videoCacheProvider.notifier);
      final localPath = cacheNotifier.getLocalVideoPath(exerciseId);

      if (localPath != null) {
        // Use cached video for faster loading
        debugPrint('Using cached video for: $exerciseName');
        await _initializeVideo(localPath, isLocal: true);
        return;
      }

      // Fetch video URL from API
      final apiClient = ref.read(apiClientProvider);
      final videoResponse = await apiClient.get(
        '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
      );

      if (videoResponse.statusCode == 200 && videoResponse.data != null) {
        final videoUrl = videoResponse.data['url'] as String?;
        if (videoUrl != null && mounted) {
          _videoUrl = videoUrl;
          await _initializeVideo(videoUrl, isLocal: false);
        } else if (mounted) {
          setState(() {
            _isLoadingVideo = false;
            _videoError = 'Video not available';
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _videoError = 'Video not available';
        });
      }
    } catch (e) {
      debugPrint('Error loading video: $e');
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _videoError = 'Failed to load video';
        });
      }
    }
  }

  /// Initialize video controller with given path/URL
  Future<void> _initializeVideo(String source, {required bool isLocal}) async {
    try {
      if (isLocal) {
        _videoController = VideoPlayerController.file(File(source));
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(source));
      }

      // Timeout prevents hanging forever if S3 returns an error response
      await _videoController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _videoController?.dispose();
          _videoController = null;
          throw TimeoutException('Video initialization timed out');
        },
      );
      _videoController!.setLooping(true);
      _videoController!.setVolume(0);

      // Auto-play unless reduced motion is enabled
      if (!_reducedMotion) {
        _videoController!.play();
      }

      if (mounted) {
        setState(() {
          _videoInitialized = true;
          _isLoadingVideo = false;
        });
        // Trigger fade-in animation for smooth appearance
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _videoError = 'Failed to play video';
        });
      }
    }
  }

  void _toggleVideo() {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {});
  }

  Widget _buildVideoContent(Color cyan, Color textMuted, Color purple) {
    if (_isLoadingVideo) {
      return _buildLoadingIndicator(cyan, textMuted, purple);
    }

    if (_videoInitialized && _videoController != null) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            // Play/Pause overlay - only show if paused or reduced motion
            AnimatedOpacity(
              opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cyan.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  Icons.play_arrow,
                  size: 48,
                  color: cyan,
                ),
              ),
            ),
            // Muted indicator
            Positioned(
              bottom: 8,
              right: 8,
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
            // Auto-play indicator (briefly shown)
            if (!_reducedMotion)
              Positioned(
                top: 8,
                left: 8,
                child: AnimatedOpacity(
                  opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 14,
                          color: cyan,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Auto-play',
                          style: TextStyle(
                            fontSize: 11,
                            color: cyan,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Fallback - no video available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 48,
            color: purple.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            _videoError ?? 'Video not available',
            style: TextStyle(color: textMuted, fontSize: 12),
          ),
          // Retry button for failed loads
          if (_videoError != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isLoadingVideo = true;
                  _videoError = null;
                });
                _loadVideo();
              },
              icon: Icon(Icons.refresh, color: cyan, size: 18),
              label: Text(
                'Retry',
                style: TextStyle(color: cyan),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build an enhanced loading indicator with shimmer effect
  Widget _buildLoadingIndicator(Color cyan, Color textMuted, Color purple) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                purple.withOpacity(0.2),
                cyan.withOpacity(0.1),
              ],
            ),
          ),
        ),
        // Loading animation
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading indicator
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        cyan.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // Inner ring (faster)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(cyan),
                    ),
                  ),
                  // Play icon in center
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 24,
                    color: cyan.withOpacity(0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Will auto-play when ready',
              style: TextStyle(
                color: textMuted.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context, bool isDark, Color textPrimary, Color textMuted, Color cyan, Color purple) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Action Guide',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _helpItem(Icons.favorite, AppColors.error, 'Favorite', 'Prioritizes this exercise in AI suggestions', textPrimary, textMuted),
              const SizedBox(height: 12),
              _helpItem(Icons.playlist_add, AppColors.cyan, 'Queue', 'Adds to your exercise queue for the next workout', textPrimary, textMuted),
              const SizedBox(height: 12),
              _helpItem(Icons.block, AppColors.orange, 'Avoid', 'AI will never include this exercise in your workouts', textPrimary, textMuted),
              const SizedBox(height: 12),
              _helpItem(Icons.push_pin, purple, 'Staple', 'Locks this exercise so it\'s NEVER rotated out', textPrimary, textMuted),
              const SizedBox(height: 16),
              Divider(color: textMuted.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              Text(
                'Staple Options',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _helpItem(Icons.bolt, cyan, 'Current Workout', 'Change applies to today\'s workout immediately', textPrimary, textMuted),
              const SizedBox(height: 8),
              _helpItem(Icons.skip_next, textMuted, 'Upcoming', 'Change takes effect from next generation', textPrimary, textMuted),
              const SizedBox(height: 8),
              _helpItem(Icons.whatshot_outlined, AppColors.orange, 'Add to Warmup', 'Places exercise in the warmup section', textPrimary, textMuted),
              const SizedBox(height: 8),
              _helpItem(Icons.self_improvement, purple, 'Add to Stretch', 'Places exercise in the stretch section', textPrimary, textMuted),
              const SizedBox(height: 8),
              _helpItem(Icons.add, cyan, 'Add as Exercise', 'Adds as a main workout exercise', textPrimary, textMuted),
              const SizedBox(height: 8),
              _helpItem(Icons.swap_horiz, AppColors.orange, 'Replace Exercise', 'Swaps out an existing exercise', textPrimary, textMuted),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it', style: TextStyle(color: cyan)),
          ),
        ],
      ),
    );
  }

  Widget _helpItem(IconData icon, Color iconColor, String title, String desc, Color textPrimary, Color textMuted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 12, color: textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground =
        isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle + Help button
                      Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: textMuted.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => _showHelpDialog(context, isDark, textPrimary, textMuted, cyan, purple),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: textMuted.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.help_outline,
                                  size: 16,
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                  // Video Player
                  GestureDetector(
                    onTap: _toggleVideo,
                    child: Container(
                      width: double.infinity,
                      height: 300,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(16),
                        border: isDark
                            ? null
                            : Border.all(color: AppColorsLight.cardBorder),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _buildVideoContent(cyan, textMuted, purple),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Badges
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (exercise.muscleGroup != null)
                          DetailBadge(
                            icon: Icons.accessibility_new,
                            label: 'Muscle',
                            value: exercise.muscleGroup!,
                            color: purple,
                          ),
                        if (exercise.difficulty != null)
                          DetailBadge(
                            icon: Icons.signal_cellular_alt,
                            label: 'Level',
                            value: DifficultyUtils.getDisplayName(exercise.difficulty!),
                            color: DifficultyUtils.getColor(exercise.difficulty!),
                          ),
                        if (exercise.type != null)
                          DetailBadge(
                            icon: Icons.category,
                            label: 'Type',
                            value: exercise.type!,
                            color: cyan,
                          ),
                      ],
                    ),
                  ),

                  // Equipment
                  if (exercise.equipment.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EQUIPMENT NEEDED',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: exercise.equipment.map((eq) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: elevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isDark
                                      ? null
                                      : Border.all(
                                          color: AppColorsLight.cardBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      size: 14,
                                      color: textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      eq,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Instructions
                  if (exercise.instructions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INSTRUCTIONS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...exercise.instructions.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: cyan.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: cyan,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  // Action Buttons Row
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Download Video Button
                        if (_videoUrl != null)
                          Expanded(
                            child: _DownloadVideoButton(
                              exerciseId: exercise.id ??
                                  exercise.name.toLowerCase().replaceAll(' ', '_'),
                              exerciseName: exercise.name,
                              videoUrl: _videoUrl!,
                            ),
                          ),
                        if (_videoUrl != null) const SizedBox(width: 12),
                        // Log 1RM Button
                        Expanded(
                          child: _Log1RMButton(
                            exerciseName: exercise.name,
                            exerciseId: exercise.id ??
                                exercise.name.toLowerCase().replaceAll(' ', '_'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom clearance for floating action icons
                  const SizedBox(height: 120),
                ],
                  ),
                ),
                // Floating action buttons at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _ExerciseActionButtons(
                    exerciseName: exercise.name,
                    muscleGroup: exercise.muscleGroup,
                    equipmentValue: exercise.equipmentValue,
                    category: exercise.category,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button to log 1RM for an exercise
class _Log1RMButton extends ConsumerStatefulWidget {
  final String exerciseName;
  final String exerciseId;

  const _Log1RMButton({
    required this.exerciseName,
    required this.exerciseId,
  });

  @override
  ConsumerState<_Log1RMButton> createState() => _Log1RMButtonState();
}

class _Log1RMButtonState extends ConsumerState<_Log1RMButton> {
  double? _current1rm;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrent1rm();
  }

  Future<void> _loadCurrent1rm() async {
    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final repository = ref.read(workoutRepositoryProvider);
      final current1rm = await repository.getExercise1rm(
        userId: userId,
        exerciseName: widget.exerciseName,
      );

      if (mounted) {
        setState(() {
          _current1rm = current1rm;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showLog1RMSheet() async {
    final result = await showLog1RMSheet(
      context,
      ref,
      exerciseName: widget.exerciseName,
      exerciseId: widget.exerciseId,
      current1rm: _current1rm,
    );

    if (result != null && mounted) {
      // Refresh the current 1RM display
      _loadCurrent1rm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                  '1RM logged: ${(result['estimated_1rm'] as num?)?.toStringAsFixed(1) ?? 'N/A'} kg'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showLog1RMSheet,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log 1RM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (_isLoading)
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        )
                      else if (_current1rm != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 14,
                              color: AppColors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Current: ${_current1rm!.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Track your max strength',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button to download video for offline use
class _DownloadVideoButton extends ConsumerWidget {
  final String exerciseId;
  final String exerciseName;
  final String videoUrl;

  const _DownloadVideoButton({
    required this.exerciseId,
    required this.exerciseName,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final downloadStatus = ref.watch(videoDownloadStatusProvider(exerciseId));
    final downloadProgress = ref.watch(videoDownloadProgressProvider(exerciseId));

    IconData icon;
    Color iconColor;
    String title;
    String subtitle;
    VoidCallback? onTap;

    switch (downloadStatus) {
      case VideoDownloadStatus.downloaded:
        icon = Icons.download_done;
        iconColor = AppColors.success;
        title = 'Downloaded';
        subtitle = 'Available offline';
        onTap = () => _showDeleteDialog(context, ref);
        break;
      case VideoDownloadStatus.downloading:
        icon = Icons.downloading;
        iconColor = AppColors.cyan;
        title = 'Downloading...';
        subtitle = '${(downloadProgress * 100).toInt()}%';
        onTap = () => _cancelDownload(context, ref);
        break;
      case VideoDownloadStatus.error:
        icon = Icons.error_outline;
        iconColor = AppColors.error;
        title = 'Download Failed';
        subtitle = 'Tap to retry';
        onTap = () => _startDownload(context, ref);
        break;
      case VideoDownloadStatus.notDownloaded:
        icon = Icons.download_for_offline_outlined;
        iconColor = AppColors.cyan;
        title = 'Download';
        subtitle = 'Save for offline';
        onTap = () => _startDownload(context, ref);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon with optional progress indicator
                if (downloadStatus == VideoDownloadStatus.downloading)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: downloadProgress,
                          strokeWidth: 3,
                          backgroundColor: AppColors.cyan.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.cyan,
                          ),
                        ),
                        Icon(
                          Icons.pause,
                          color: AppColors.cyan,
                          size: 18,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: downloadStatus == VideoDownloadStatus.downloaded
                              ? AppColors.success
                              : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startDownload(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(videoCacheProvider.notifier).downloadVideo(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          videoUrl: videoUrl,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Downloading video...'),
          ],
        ),
        backgroundColor: AppColors.cyan,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _cancelDownload(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(videoCacheProvider.notifier).cancelDownload(exerciseId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download cancelled'),
        backgroundColor: AppColors.textMuted,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Text(
          'Delete Download?',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          ),
        ),
        content: Text(
          'Remove the offline video for "$exerciseName"? You can re-download it anytime.',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(videoCacheProvider.notifier).deleteVideo(exerciseId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download removed'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating action buttons for exercise preferences with inline staple pills
class _ExerciseActionButtons extends ConsumerStatefulWidget {
  final String exerciseName;
  final String? muscleGroup;
  final String? equipmentValue;
  final String? category;

  const _ExerciseActionButtons({
    required this.exerciseName,
    this.muscleGroup,
    this.equipmentValue,
    this.category,
  });

  @override
  ConsumerState<_ExerciseActionButtons> createState() => _ExerciseActionButtonsState();
}

class _ExerciseActionButtonsState extends ConsumerState<_ExerciseActionButtons> {
  bool _showStaplePills = false;
  bool _isProcessing = false;
  bool _currentWorkout = true; // true = current workout, false = upcoming

  Future<void> _handleStaple(String section) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final success = await ref.read(staplesProvider.notifier).addStaple(
        widget.exerciseName,
        muscleGroup: widget.muscleGroup,
        section: section,
        addToCurrentWorkout: _currentWorkout,
      );
      if (mounted) {
        setState(() { _showStaplePills = false; _isProcessing = false; });
        if (success) {
          final timing = _currentWorkout ? 'current workout' : 'upcoming workouts';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.push_pin, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Stapled "${widget.exerciseName}" to $section ($timing)')),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to staple: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleUnstaple() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await ref.read(staplesProvider.notifier).toggleStaple(
      widget.exerciseName,
      muscleGroup: widget.muscleGroup,
    );
    if (mounted) {
      setState(() { _showStaplePills = false; _isProcessing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.push_pin_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('"${widget.exerciseName}" unstapled'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleReplaceExercise() async {
    final todayResponse = ref.read(todayWorkoutProvider).valueOrNull;
    final workout = todayResponse?.todayWorkout ?? todayResponse?.nextWorkout;
    final exercises = workout?.exercises ?? [];

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No exercises in current workout to replace'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Replace which exercise?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: exercises.length,
            itemBuilder: (ctx, index) {
              final ex = exercises[index];
              return ListTile(
                leading: Icon(Icons.fitness_center, size: 18, color: textMuted),
                title: Text(
                  ex.name,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                ),
                subtitle: ex.muscleGroup != null
                    ? Text(ex.muscleGroup!, style: TextStyle(fontSize: 12, color: textMuted))
                    : null,
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () => Navigator.pop(ctx, ex.name),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
        ],
      ),
    );

    if (selected != null && mounted) {
      setState(() => _isProcessing = true);
      final success = await ref.read(staplesProvider.notifier).addStaple(
        widget.exerciseName,
        muscleGroup: widget.muscleGroup,
        section: 'main',
        addToCurrentWorkout: _currentWorkout,
        swapExerciseId: selected,
      );
      if (mounted) {
        setState(() { _showStaplePills = false; _isProcessing = false; });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Replaced "$selected" with "${widget.exerciseName}"')),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Widget _buildStaplePillsSection(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final isAlreadyStaple = ref.watch(staplesProvider).isStaple(widget.exerciseName);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timing toggle row
          Row(
            children: [
              Expanded(
                child: _buildTimingChip(
                  'Current Workout',
                  isSelected: _currentWorkout,
                  onTap: () => setState(() => _currentWorkout = true),
                  isDark: isDark,
                  cyan: cyan,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimingChip(
                  'Upcoming Workouts',
                  isSelected: !_currentWorkout,
                  onTap: () => setState(() => _currentWorkout = false),
                  isDark: isDark,
                  cyan: cyan,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 1: section pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isAlreadyStaple)
                _buildPill(
                  'Unstaple',
                  Icons.push_pin_outlined,
                  onTap: _handleUnstaple,
                  color: AppColors.error,
                  isDark: isDark,
                  textPrimary: textPrimary,
                ),
              _buildPill(
                'Add to Warmup',
                Icons.whatshot_outlined,
                onTap: () => _handleStaple('warmup'),
                color: AppColors.orange,
                isDark: isDark,
                textPrimary: textPrimary,
              ),
              _buildPill(
                'Add to Stretch',
                Icons.self_improvement,
                onTap: () => _handleStaple('stretches'),
                color: purple,
                isDark: isDark,
                textPrimary: textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: action pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPill(
                'Add as Exercise',
                Icons.add,
                onTap: () => _handleStaple('main'),
                color: cyan,
                isDark: isDark,
                textPrimary: textPrimary,
              ),
              _buildPill(
                'Replace Exercise',
                Icons.swap_horiz,
                onTap: _handleReplaceExercise,
                color: AppColors.orange,
                isDark: isDark,
                textPrimary: textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimingChip(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color cyan,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cyan.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? cyan : textMuted.withValues(alpha: 0.3),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? cyan : textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildPill(
    String label,
    IconData icon, {
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    // Watch providers for state
    final isFavorite = ref.watch(favoritesProvider).isFavorite(widget.exerciseName);
    final isQueued = ref.watch(exerciseQueueProvider).isQueued(widget.exerciseName);
    final isAvoided = ref.watch(avoidedProvider).isAvoided(widget.exerciseName);
    final isStaple = ref.watch(staplesProvider).isStaple(widget.exerciseName);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated pills section (only when staple is tapped)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _showStaplePills
              ? _buildStaplePillsSection(isDark)
              : const SizedBox.shrink(),
        ),
        // Processing indicator
        if (_isProcessing)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: purple,
              ),
            ),
          ),
        // 4 floating action icons
        Container(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.97),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFloatingIcon(
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  label: 'Favorite',
                  isActive: isFavorite,
                  activeColor: AppColors.error,
                  inactiveColor: textMuted,
                  onTap: () {
                    HapticService.light();
                    ref.read(favoritesProvider.notifier).toggleFavorite(widget.exerciseName);
                  },
                ),
                _buildFloatingIcon(
                  icon: isQueued ? Icons.playlist_add_check : Icons.playlist_add,
                  label: 'Queue',
                  isActive: isQueued,
                  activeColor: AppColors.cyan,
                  inactiveColor: textMuted,
                  onTap: () {
                    HapticService.light();
                    ref.read(exerciseQueueProvider.notifier).toggleQueue(
                      widget.exerciseName,
                      targetMuscleGroup: widget.muscleGroup,
                    );
                  },
                ),
                _buildFloatingIcon(
                  icon: isAvoided ? Icons.block : Icons.block_outlined,
                  label: 'Avoid',
                  isActive: isAvoided,
                  activeColor: AppColors.orange,
                  inactiveColor: textMuted,
                  onTap: () {
                    HapticService.light();
                    ref.read(avoidedProvider.notifier).toggleAvoided(widget.exerciseName);
                  },
                ),
                _buildFloatingIcon(
                  icon: isStaple ? Icons.push_pin : Icons.push_pin_outlined,
                  label: 'Staple',
                  isActive: isStaple || _showStaplePills,
                  activeColor: purple,
                  inactiveColor: textMuted,
                  onTap: () {
                    HapticService.light();
                    setState(() => _showStaplePills = !_showStaplePills);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingIcon({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
