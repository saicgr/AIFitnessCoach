/// Media Preview Strip
///
/// Shows selected media above the text input in chat.
/// Supports displaying multiple thumbnails with remove buttons,
/// an add-more button, and a count/size summary.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import 'media_picker_helper.dart';

/// Preview strip widget shown above the chat input when media is selected.
/// Supports both single and multiple media items.
class MediaPreviewStrip extends StatelessWidget {
  final List<PickedMedia> mediaList;
  final void Function(int index) onRemoveAt;
  final VoidCallback? onAddMore;
  final int maxItems;

  const MediaPreviewStrip({
    super.key,
    required this.mediaList,
    required this.onRemoveAt,
    this.onAddMore,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    if (mediaList.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        border: Border(
          bottom: BorderSide(
            color: colors.cardBorder.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnails row with horizontal scroll
          SizedBox(
            height: 64,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Media thumbnails
                  ...List.generate(mediaList.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _MediaThumbnail(
                        media: mediaList[index],
                        isDark: isDark,
                        onRemove: () => onRemoveAt(index),
                      ),
                    );
                  }),

                  // Add more button
                  if (onAddMore != null && mediaList.length < maxItems)
                    _AddMoreButton(
                      isDark: isDark,
                      onTap: onAddMore!,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Count and total size info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${mediaList.length}/$maxItems',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formattedTotalSize(),
                style: TextStyle(
                  fontSize: 10,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 200.ms, curve: Curves.easeOut);
  }

  String _formattedTotalSize() {
    final bytes = mediaList.fold<int>(0, (sum, m) => sum + m.sizeBytes);
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Individual media thumbnail with remove button overlay
class _MediaThumbnail extends StatelessWidget {
  final PickedMedia media;
  final bool isDark;
  final VoidCallback onRemove;

  const _MediaThumbnail({
    required this.media,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = media.type == ChatMediaType.video;

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: isVideo
                  ? Container(
                      color: isDark ? AppColors.glassSurface : Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.videocam_rounded,
                          color: AppColors.purple,
                          size: 24,
                        ),
                      ),
                    )
                  : Image.file(
                      media.file,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark ? AppColors.glassSurface : Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image, size: 24),
                        ),
                      ),
                    ),
            ),
          ),

          // Video duration badge overlay
          if (isVideo && media.duration != null)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(media.duration!),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Remove button overlay (top-right)
          Positioned(
            top: -2,
            right: -2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final seconds = d.inSeconds;
    if (seconds >= 60) {
      return '${d.inMinutes}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }
}

/// Dashed border "+" button for adding more media
class _AddMoreButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AddMoreButton({
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.textMuted.withOpacity(0.4),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.02),
        ),
        child: Icon(
          Icons.add_rounded,
          size: 24,
          color: colors.textMuted,
        ),
      ),
    );
  }
}
