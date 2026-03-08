/// Media Preview Strip
///
/// Shows selected media above the text input in chat.
/// Supports displaying multiple thumbnails with remove buttons,
/// an add-more button, and a count/size summary.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import 'media_picker_helper.dart';

/// Cache for generated video thumbnails to avoid regenerating.
final Map<String, Uint8List> _videoThumbnailCache = {};

/// Preview strip widget shown above the chat input when media is selected.
/// Supports both single and multiple media items with undo-on-remove.
class MediaPreviewStrip extends StatefulWidget {
  final List<PickedMedia> mediaList;
  final void Function(int index) onRemoveAt;
  final void Function(int index, PickedMedia media) onInsertAt;
  final VoidCallback? onAddMore;
  final int maxItems;

  const MediaPreviewStrip({
    super.key,
    required this.mediaList,
    required this.onRemoveAt,
    required this.onInsertAt,
    this.onAddMore,
    this.maxItems = 5,
  });

  @override
  State<MediaPreviewStrip> createState() => _MediaPreviewStripState();
}

class _MediaPreviewStripState extends State<MediaPreviewStrip> {
  void _handleRemoveWithUndo(int index) {
    final removedMedia = widget.mediaList[index];
    widget.onRemoveAt(index);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Media removed'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            widget.onInsertAt(index, removedMedia);
          },
        ),
      ),
    );
  }

  void _showFullscreenPreview(BuildContext context, PickedMedia media, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // Full image preview
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: media.type == ChatMediaType.image
                      ? Image.file(
                          media.file,
                          fit: BoxFit.contain,
                        )
                      : _VideoPreviewPlaceholder(media: media),
                ),
              ),
              // Close button
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
              // Remove button
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _handleRemoveWithUndo(index);
                    },
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    label: const Text(
                      'Remove',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    if (widget.mediaList.isEmpty) return const SizedBox.shrink();

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
                  ...List.generate(widget.mediaList.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _MediaThumbnail(
                        media: widget.mediaList[index],
                        isDark: isDark,
                        onRemove: () => _handleRemoveWithUndo(index),
                        onTap: () => _showFullscreenPreview(
                          context,
                          widget.mediaList[index],
                          index,
                        ),
                      ),
                    );
                  }),

                  // Add more button
                  if (widget.onAddMore != null && widget.mediaList.length < widget.maxItems)
                    _AddMoreButton(
                      isDark: isDark,
                      onTap: widget.onAddMore!,
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
                  '${widget.mediaList.length}/${widget.maxItems}',
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
    final bytes = widget.mediaList.fold<int>(0, (sum, m) => sum + m.sizeBytes);
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Video preview placeholder for fullscreen dialog
class _VideoPreviewPlaceholder extends StatelessWidget {
  final PickedMedia media;

  const _VideoPreviewPlaceholder({required this.media});

  @override
  Widget build(BuildContext context) {
    final cached = _videoThumbnailCache[media.file.path];
    if (cached != null) {
      return Image.memory(cached, fit: BoxFit.contain);
    }

    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_rounded, color: AppColors.purple, size: 48),
          if (media.duration != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatDuration(media.duration!),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
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

/// Individual media thumbnail with remove button overlay and tap-to-preview
class _MediaThumbnail extends StatelessWidget {
  final PickedMedia media;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _MediaThumbnail({
    required this.media,
    required this.isDark,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = media.type == ChatMediaType.video;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
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
                    ? _VideoThumbnailWidget(
                        videoPath: media.file.path,
                        isDark: isDark,
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

/// Widget that generates and displays a video thumbnail frame.
/// Uses a static cache to avoid regenerating thumbnails.
class _VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;
  final bool isDark;

  const _VideoThumbnailWidget({
    required this.videoPath,
    required this.isDark,
  });

  @override
  State<_VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<_VideoThumbnailWidget> {
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _generateThumbnail();
  }

  Future<Uint8List?> _generateThumbnail() async {
    final cached = _videoThumbnailCache[widget.videoPath];
    if (cached != null) return cached;

    final bytes = await VideoThumbnail.thumbnailData(
      video: widget.videoPath,
      imageFormat: ImageFormat.JPEG,
      quality: 50,
    );

    if (bytes != null) {
      _videoThumbnailCache[widget.videoPath] = bytes;
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              ),
              // Play icon overlay
              Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          );
        }
        // Loading or error fallback
        return Container(
          color: widget.isDark ? AppColors.glassSurface : Colors.grey.shade200,
          child: const Center(
            child: Icon(
              Icons.videocam_rounded,
              color: AppColors.purple,
              size: 24,
            ),
          ),
        );
      },
    );
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
