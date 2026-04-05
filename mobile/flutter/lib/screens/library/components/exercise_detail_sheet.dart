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
import '../../../widgets/staple_choice_sheet.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../widgets/info_badge.dart';

part 'exercise_detail_sheet_part_log1_r_m_button.dart';
part 'exercise_detail_sheet_part_exercise_action_buttons_state.dart';


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
