import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/video_cache_provider.dart';
import '../../../data/services/video_cache_service.dart';
import '../../../widgets/pill_app_bar.dart';

/// Screen for managing downloaded exercise videos
class DownloadedVideosScreen extends ConsumerWidget {
  const DownloadedVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;

    final cacheState = ref.watch(videoCacheProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: 'Downloaded Videos',
        actions: [
          PillAppBarAction(
            icon: Icons.delete_sweep,
            visible: cacheState.cachedVideoCount > 0,
            onTap: () => _showClearAllDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Storage info header
          _StorageInfoCard(cacheState: cacheState),

          // Video list
          Expanded(
            child: cacheState.cachedVideoCount == 0
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cacheState.cachedVideos.length,
                    itemBuilder: (context, index) {
                      final video = cacheState.cachedVideos[index];
                      return _CachedVideoTile(
                        video: video,
                        onDelete: () => _deleteVideo(context, ref, video),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Clear All Downloads?',
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'This will delete all downloaded exercise videos from your device. You can re-download them anytime.',
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
              ref.read(videoCacheProvider.notifier).clearAllVideos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All downloads cleared'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteVideo(BuildContext context, WidgetRef ref, CachedVideoInfo video) {
    HapticFeedback.lightImpact();
    ref.read(videoCacheProvider.notifier).deleteVideo(video.exerciseId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${video.exerciseName}"'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

/// Storage info card showing cache usage
class _StorageInfoCard extends StatelessWidget {
  final VideoCacheState cacheState;

  const _StorageInfoCard({required this.cacheState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Calculate percentage of 500 MB limit
    const maxBytes = 500 * 1024 * 1024;
    final usagePercent = cacheState.totalCacheSizeBytes / maxBytes;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder,
                  color: AppColors.cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage Used',
                      style: TextStyle(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cacheState.formattedCacheSize} / 500 MB',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${cacheState.cachedVideoCount} videos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usagePercent.clamp(0.0, 1.0),
              backgroundColor: AppColors.cyan.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercent > 0.9 ? AppColors.error : AppColors.cyan,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            usagePercent > 0.9
                ? 'Storage almost full. Oldest videos will be auto-deleted.'
                : 'Videos are cached for offline viewing.',
            style: TextStyle(
              fontSize: 12,
              color: usagePercent > 0.9 ? AppColors.error : textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no videos are downloaded
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 64,
              color: textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Downloads Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save exercise videos for offline viewing — great for the gym when WiFi is spotty.',
              style: TextStyle(
                fontSize: 14,
                color: textMuted.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _HowToCard(
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/library');
                },
                icon: const Icon(Icons.video_library_outlined, size: 20),
                label: const Text(
                  'Browse Exercise Library',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step-by-step card explaining how to download a video
class _HowToCard extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _HowToCard({
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW TO DOWNLOAD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _step(1, 'Open the Library and tap any exercise', textPrimary, textSecondary),
          const SizedBox(height: 10),
          _step(2, 'Wait for the video preview to load', textPrimary, textSecondary),
          const SizedBox(height: 10),
          _step(
            3,
            'Tap the "Download" button to save it offline',
            textPrimary,
            textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _step(int n, String label, Color primary, Color secondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$n',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.cyan,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tile for a single cached video
class _CachedVideoTile extends StatelessWidget {
  final CachedVideoInfo video;
  final VoidCallback onDelete;

  const _CachedVideoTile({
    required this.video,
    required this.onDelete,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.play_circle_filled,
            color: AppColors.purple,
            size: 28,
          ),
        ),
        title: Text(
          video.exerciseName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatFileSize(video.fileSizeBytes)} • Downloaded ${_formatDate(video.downloadedAt)}',
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: AppColors.error.withOpacity(0.8),
          ),
          onPressed: onDelete,
          tooltip: 'Delete',
        ),
      ),
    );
  }
}
