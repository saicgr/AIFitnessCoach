/// Media Picker Helper
///
/// Handles image/video selection, validation, and compression
/// for the AI coach chat media upload feature.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';

/// Supported media types for chat uploads
enum ChatMediaType { image, video }

/// Result of a media pick operation
class PickedMedia {
  final File file;
  final ChatMediaType type;
  final int sizeBytes;
  final Duration? duration; // video only
  final String mimeType;

  const PickedMedia({
    required this.file,
    required this.type,
    required this.sizeBytes,
    this.duration,
    required this.mimeType,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Result of a media pick operation - supports single or multiple media
class PickedMediaResult {
  final List<PickedMedia> media;

  const PickedMediaResult({required this.media});

  bool get isEmpty => media.isEmpty;
  bool get isNotEmpty => media.isNotEmpty;
  bool get isMultiple => media.length > 1;
  bool get hasVideo => media.any((m) => m.type == ChatMediaType.video);
  bool get hasImage => media.any((m) => m.type == ChatMediaType.image);
  int get imageCount => media.where((m) => m.type == ChatMediaType.image).length;
  int get videoCount => media.where((m) => m.type == ChatMediaType.video).length;
  int get totalSizeBytes => media.fold(0, (sum, m) => sum + m.sizeBytes);

  String get formattedTotalSize {
    final bytes = totalSizeBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get as single PickedMedia (for backward compatibility)
  PickedMedia? get single => media.length == 1 ? media.first : null;
}

/// Helper class for picking and validating media for chat
class MediaPickerHelper {
  static final ImagePicker _picker = ImagePicker();

  // Limits
  static const int maxImageBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoSeconds = 60;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'heic', 'webp'];
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi', 'mkv'];

  /// Pick an image from the given source
  static Future<PickedMedia?> pickImage(ImageSource source) async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (xfile == null) return null;

      final file = File(xfile.path);
      final sizeBytes = await file.length();

      // Validate size
      if (sizeBytes > maxImageBytes) {
        throw MediaValidationException(
          'Image is too large (${_formatBytes(sizeBytes)}). Maximum size is 10 MB.',
        );
      }

      // Validate format
      final ext = xfile.path.split('.').last.toLowerCase();
      if (!supportedImageFormats.contains(ext)) {
        throw MediaValidationException(
          'Unsupported image format (.$ext). Supported: ${supportedImageFormats.join(", ")}',
        );
      }

      final mimeType = _getMimeType(ext);

      return PickedMedia(
        file: file,
        type: ChatMediaType.image,
        sizeBytes: sizeBytes,
        mimeType: mimeType,
      );
    } catch (e) {
      if (e is MediaValidationException) rethrow;
      debugPrint('❌ [MediaPicker] Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery (max 5)
  static Future<List<PickedMedia>> pickMultipleImages() async {
    try {
      final List<XFile> xfiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (xfiles.isEmpty) return [];

      // Enforce max 5
      final selected = xfiles.take(5).toList();
      final results = <PickedMedia>[];

      for (final xfile in selected) {
        final file = File(xfile.path);
        final sizeBytes = await file.length();

        if (sizeBytes > maxImageBytes) {
          debugPrint('⚠️ [MediaPicker] Skipping oversized image: ${_formatBytes(sizeBytes)}');
          continue;
        }

        final ext = xfile.path.split('.').last.toLowerCase();
        if (!supportedImageFormats.contains(ext)) continue;

        results.add(PickedMedia(
          file: file,
          type: ChatMediaType.image,
          sizeBytes: sizeBytes,
          mimeType: _getMimeType(ext),
        ));
      }

      return results;
    } catch (e) {
      debugPrint('❌ [MediaPicker] Error picking multiple images: $e');
      return [];
    }
  }

  /// Pick a video from the given source with auto-compression
  static Future<PickedMedia?> pickVideo(ImageSource source) async {
    try {
      final XFile? xfile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: maxVideoSeconds),
      );
      if (xfile == null) return null;

      File file = File(xfile.path);

      // Validate format
      final ext = xfile.path.split('.').last.toLowerCase();
      if (!supportedVideoFormats.contains(ext)) {
        throw MediaValidationException(
          'Unsupported video format (.$ext). Supported: ${supportedVideoFormats.join(", ")}',
        );
      }

      // Get video info for duration check
      final mediaInfo = await VideoCompress.getMediaInfo(file.path);
      final durationMs = mediaInfo.duration ?? 0;
      final duration = Duration(milliseconds: durationMs.toInt());

      if (duration.inSeconds > maxVideoSeconds) {
        throw MediaValidationException(
          'Video is too long (${duration.inSeconds}s). Maximum duration is ${maxVideoSeconds}s.',
        );
      }

      // Compress video
      debugPrint('🔍 [MediaPicker] Compressing video...');
      final compressed = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (compressed != null && compressed.file != null) {
        file = compressed.file!;
        debugPrint('✅ [MediaPicker] Video compressed: ${_formatBytes(compressed.filesize ?? 0)}');
      }

      final sizeBytes = await file.length();

      return PickedMedia(
        file: file,
        type: ChatMediaType.video,
        sizeBytes: sizeBytes,
        duration: duration,
        mimeType: 'video/mp4',
      );
    } catch (e) {
      if (e is MediaValidationException) rethrow;
      debugPrint('❌ [MediaPicker] Error picking video: $e');
      return null;
    }
  }

  /// Show bottom sheet with media picker options
  /// Returns a PickedMediaResult (which may contain one or multiple media items)
  static Future<PickedMediaResult?> showMediaPickerSheet(BuildContext context) async {
    PickedMediaResult? result;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        final isDark = colors.isDark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Add Media',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Images: max 10 MB | Videos: max 60s (BETA)',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),

                // Photo options
                _PickerOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose Photo',
                  subtitle: 'From gallery',
                  color: AppColors.info,
                  onTap: () async {
                    Navigator.pop(ctx);
                    HapticService.selection();
                    final media = await pickImage(ImageSource.gallery);
                    if (media != null) {
                      result = PickedMediaResult(media: [media]);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _PickerOption(
                  icon: Icons.collections_outlined,
                  label: 'Choose Multiple Photos',
                  subtitle: 'Select up to 5 from gallery',
                  color: const Color(0xFF00BCD4),
                  onTap: () async {
                    Navigator.pop(ctx);
                    HapticService.selection();
                    final mediaList = await pickMultipleImages();
                    if (mediaList.isNotEmpty) {
                      result = PickedMediaResult(media: mediaList);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _PickerOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take Photo',
                  subtitle: 'Use camera',
                  color: AppColors.success,
                  onTap: () async {
                    Navigator.pop(ctx);
                    HapticService.selection();
                    final media = await pickImage(ImageSource.camera);
                    if (media != null) {
                      result = PickedMediaResult(media: [media]);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Video options
                Row(
                  children: [
                    Text(
                      'Video',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BETA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _PickerOption(
                  icon: Icons.video_library_outlined,
                  label: 'Choose Video',
                  subtitle: 'From gallery (max 60s)',
                  color: AppColors.purple,
                  onTap: () async {
                    Navigator.pop(ctx);
                    HapticService.selection();
                    final media = await pickVideo(ImageSource.gallery);
                    if (media != null) {
                      result = PickedMediaResult(media: [media]);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _PickerOption(
                  icon: Icons.videocam_outlined,
                  label: 'Record Video',
                  subtitle: 'Use camera (max 60s)',
                  color: AppColors.orange,
                  onTap: () async {
                    Navigator.pop(ctx);
                    HapticService.selection();
                    final media = await pickVideo(ImageSource.camera);
                    if (media != null) {
                      result = PickedMediaResult(media: [media]);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    return result;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _getMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Exception for media validation failures
class MediaValidationException implements Exception {
  final String message;
  const MediaValidationException(this.message);

  @override
  String toString() => message;
}

/// A single option row in the media picker sheet
class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
