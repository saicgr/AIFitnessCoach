part of 'exercise_detail_sheet.dart';


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

