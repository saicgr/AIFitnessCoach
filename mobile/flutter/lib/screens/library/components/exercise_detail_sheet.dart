import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/log_1rm_sheet.dart';
import '../../../data/repositories/workout_repository.dart';
import '../widgets/info_badge.dart';

/// Bottom sheet showing exercise details with video player
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

class _ExerciseDetailSheetState extends ConsumerState<ExerciseDetailSheet> {
  VideoPlayerController? _videoController;
  bool _isLoadingVideo = true;
  bool _videoInitialized = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void dispose() {
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
          setState(() {
            _videoInitialized = true;
            _isLoadingVideo = false;
          });
        }
      } else {
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cyan),
            const SizedBox(height: 12),
            Text(
              'Loading video...',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_videoInitialized && _videoController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          // Play/Pause overlay
          AnimatedOpacity(
            opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.volume_off,
                size: 16,
                color: Colors.white70,
              ),
            ),
          ),
        ],
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
        ],
      ),
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
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                        value: exercise.difficulty!,
                        color: AppColors.getDifficultyColor(
                            exercise.difficulty!),
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
              if (exercise.equipment != null &&
                  exercise.equipment!.isNotEmpty) ...[
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
                        children: exercise.equipment!.map((eq) {
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
              if (exercise.instructions != null &&
                  exercise.instructions!.isNotEmpty) ...[
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
                      ...exercise.instructions!.asMap().entries.map((entry) {
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

              // Log 1RM Button
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Log1RMButton(
                  exerciseName: exercise.name,
                  exerciseId: exercise.id ??
                      exercise.name.toLowerCase().replaceAll(' ', '_'),
                ),
              ),

              const SizedBox(height: 40),
            ],
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
