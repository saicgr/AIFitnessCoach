import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Card widget displaying exercise information with video/image during calibration
class CalibrationExerciseCard extends StatelessWidget {
  /// The exercise to display
  final WorkoutExercise exercise;

  /// Video controller if video is available
  final VideoPlayerController? videoController;

  /// Whether the video is initialized and ready to play
  final bool isVideoInitialized;

  /// Fallback image URL
  final String? imageUrl;

  /// Whether media is currently loading
  final bool isLoadingMedia;

  const CalibrationExerciseCard({
    super.key,
    required this.exercise,
    this.videoController,
    this.isVideoInitialized = false,
    this.imageUrl,
    this.isLoadingMedia = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video/Image section
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                // Background
                Container(
                  color: isDark ? AppColors.pureBlack : AppColorsLight.glassSurface,
                ),

                // Media content
                if (isLoadingMedia)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else if (isVideoInitialized && videoController != null)
                  _buildVideoPlayer()
                else if (imageUrl != null && imageUrl!.isNotEmpty)
                  _buildImage()
                else
                  _buildPlaceholder(isDark),

                // Play/pause overlay for video
                if (isVideoInitialized && videoController != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        if (videoController!.value.isPlaying) {
                          videoController!.pause();
                        } else {
                          videoController!.play();
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: videoController!.value.isPlaying ? 0.0 : 0.8,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Target muscle badge
                if (exercise.muscleGroup != null || exercise.primaryMuscle != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatMuscleName(exercise.muscleGroup ?? exercise.primaryMuscle!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Equipment badge
                if (exercise.equipment != null && exercise.equipment!.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exercise.equipment!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Exercise info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise name
                Text(
                  exercise.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                // Suggested parameters row
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.fitness_center,
                      label: '${exercise.weight ?? 0} kg',
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.repeat,
                      label: '${exercise.reps ?? 10} reps',
                      color: AppColors.cyan,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.layers,
                      label: '${exercise.sets ?? 3} sets',
                      color: AppColors.purple,
                    ),
                  ],
                ),

                // Rest time
                if (exercise.restSeconds != null && exercise.restSeconds! > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${exercise.restSeconds}s rest between sets',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],

                // Instructions (if available)
                if (exercise.instructions != null && exercise.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.instructions!,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: AspectRatio(
        aspectRatio: videoController!.value.aspectRatio,
        child: VideoPlayer(videoController!),
      ),
    );
  }

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(
        Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              'No preview available',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
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
    );
  }

  String _formatMuscleName(String muscle) {
    // Convert snake_case to Title Case
    return muscle
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}
