/// Media Picker Helper
///
/// Handles image/video selection, validation, and compression
/// for the AI coach chat media upload feature.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_compress/video_compress.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Supported media types for chat uploads
enum ChatMediaType { image, video, document }

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

/// Phase-2 §2.0: paired image artifact for the food-scan path.
///
/// Carries BOTH the original full-resolution image (for S3 archive so the
/// user sees a crisp picture later in the nutrition tab) AND a 768px-resized
/// JPEG byte buffer (for Gemini Vision API — single tile, ~258 input tokens
/// vs ~4000 for a 1920px image).
///
/// Built by [pickFoodScanArtifacts] / [pickFoodScanArtifactsBatch] before
/// calling [analyzeFoodFromImageStreaming] / [analyzeFoodFromImagesStreaming].
class FoodScanArtifacts {
  /// Full-resolution original. Sent to backend as `image_original` multipart
  /// field; ends up in S3 as the food_log.image_url archive.
  final File original;

  /// 768px-resized JPEG bytes. Sent to backend as `image` multipart field;
  /// used for Vision API. Smaller upload, single Gemini tile.
  final Uint8List thumbBytes;

  /// MIME type of the original.
  final String originalMimeType;

  /// Original file size in bytes (for logging / debug).
  final int originalSizeBytes;

  const FoodScanArtifacts({
    required this.original,
    required this.thumbBytes,
    required this.originalMimeType,
    required this.originalSizeBytes,
  });
}

/// Pick ONE food image and return the paired (original + 768px thumb)
/// artifacts for the Phase-2 two-artifact upload path.
///
/// Returns null if the user cancels or the picker fails. On compression
/// failure (e.g. corrupted image, out-of-memory), falls back to using the
/// original bytes for both artifacts so the upload still succeeds (legacy
/// single-artifact behavior).
Future<FoodScanArtifacts?> pickFoodScanArtifacts(ImageSource source) async {
  try {
    // Pick original (NO maxWidth — we want full res for S3 archive)
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      // imageQuality kept conservative to keep the original under ~25MB
      imageQuality: 90,
    );
    if (picked == null) return null;

    final originalFile = File(picked.path);
    final originalBytes = await originalFile.length();

    // Compress to 768px max-edge JPEG for Vision (single Gemini tile).
    // autoCorrectionAngle handles iPhone EXIF rotation.
    final Uint8List? thumb = await FlutterImageCompress.compressWithFile(
      picked.path,
      minWidth: 768,
      minHeight: 768,
      quality: 85,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: true,
    );

    if (thumb == null) {
      // Compression failed — fall back to using the original for both fields.
      // Backend handles missing image_original via legacy single-artifact path.
      debugPrint('[food-scan] thumb compression returned null — using original for both');
      final origBytes = await originalFile.readAsBytes();
      return FoodScanArtifacts(
        original: originalFile,
        thumbBytes: origBytes,
        originalMimeType: 'image/jpeg',
        originalSizeBytes: originalBytes,
      );
    }

    debugPrint(
      '[food-scan] artifacts: original=${(originalBytes / 1024).toStringAsFixed(0)}KB '
      'thumb=${(thumb.lengthInBytes / 1024).toStringAsFixed(0)}KB',
    );

    return FoodScanArtifacts(
      original: originalFile,
      thumbBytes: thumb,
      originalMimeType: 'image/jpeg',
      originalSizeBytes: originalBytes,
    );
  } catch (e, st) {
    debugPrint('[food-scan] pickFoodScanArtifacts failed: $e\n$st');
    return null;
  }
}

/// Pick MULTIPLE food images (the 2-5 angles UX). Returns paired artifacts
/// for each. Capped at 5 photos. On per-photo failure, that photo is skipped
/// (others succeed).
Future<List<FoodScanArtifacts>> pickFoodScanArtifactsBatch() async {
  try {
    final picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage(
      imageQuality: 90,
      limit: 5,
    );
    if (picked.isEmpty) return const [];

    final List<FoodScanArtifacts> out = [];
    for (final xf in picked.take(5)) {
      try {
        final originalFile = File(xf.path);
        final originalBytes = await originalFile.length();
        final Uint8List? thumb = await FlutterImageCompress.compressWithFile(
          xf.path,
          minWidth: 768,
          minHeight: 768,
          quality: 85,
          format: CompressFormat.jpeg,
          autoCorrectionAngle: true,
        );
        if (thumb == null) {
          final origBytes = await originalFile.readAsBytes();
          out.add(FoodScanArtifacts(
            original: originalFile,
            thumbBytes: origBytes,
            originalMimeType: 'image/jpeg',
            originalSizeBytes: originalBytes,
          ));
        } else {
          out.add(FoodScanArtifacts(
            original: originalFile,
            thumbBytes: thumb,
            originalMimeType: 'image/jpeg',
            originalSizeBytes: originalBytes,
          ));
        }
      } catch (e) {
        debugPrint('[food-scan] batch pick: skipping bad image ${xf.path}: $e');
      }
    }
    return out;
  } catch (e, st) {
    debugPrint('[food-scan] pickFoodScanArtifactsBatch failed: $e\n$st');
    return const [];
  }
}

/// A menu / bill page, prepared identically no matter where it came from.
///
/// The camera and gallery paths used to prepare menu photos differently — the
/// camera capped every shot at 1600px and baked EXIF orientation as a side
/// effect of that resize, while the gallery handed the raw pick straight
/// through. Same menu, two different inputs, and gallery imports came back
/// with noticeably fewer dishes. [pickMenuPages] is the single path both now
/// use: full resolution (menus are read, not glanced at — nothing is
/// downscaled), orientation baked in and EXIF stripped so a portrait photo is
/// never fed to the model sideways.
///
/// Deliberately NOT [FoodScanArtifacts]: that type carries a 768px thumb for
/// the Vision call, which is the right trade for a plate of food and
/// catastrophic for 8-pt menu print.
class MenuPageArtifact {
  /// Upright, EXIF-stripped, full-resolution JPEG ready to upload.
  final File file;

  /// Pixel dimensions after orientation correction, for diagnostics.
  final int sizeBytes;

  const MenuPageArtifact({required this.file, required this.sizeBytes});
}

/// Pick menu / bill pages from the camera (one shot) or the gallery (many),
/// normalized for OCR. [maxPages] caps how many are returned.
///
/// Returns an empty list when the user cancels.
Future<List<MenuPageArtifact>> pickMenuPages({
  required ImageSource source,
  int maxPages = 10,
}) async {
  try {
    final picker = ImagePicker();
    final List<XFile> picked;
    if (source == ImageSource.camera) {
      // No maxWidth/maxHeight: capping the capture is exactly what was
      // costing us dishes. Quality 95 keeps small type legible.
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      picked = shot == null ? const <XFile>[] : <XFile>[shot];
    } else {
      picked = await picker.pickMultiImage(imageQuality: 95, limit: maxPages);
    }
    if (picked.isEmpty) return const [];

    final out = <MenuPageArtifact>[];
    for (final xf in picked.take(maxPages)) {
      out.add(await _normalizeMenuPage(xf));
    }
    return out;
  } catch (e, st) {
    debugPrint('[menu-scan] pickMenuPages failed: $e\n$st');
    return const [];
  }
}

/// Bake EXIF orientation and re-encode at full resolution.
///
/// `minWidth`/`minHeight` of 1 mean "never scale down" in
/// flutter_image_compress — the call is here purely for
/// `autoCorrectionAngle`, which rotates the pixels and drops the EXIF tag so
/// no downstream consumer has to interpret it. On failure we hand back the
/// original file rather than dropping the page.
Future<MenuPageArtifact> _normalizeMenuPage(XFile xf) async {
  final original = File(xf.path);
  try {
    final bytes = await FlutterImageCompress.compressWithFile(
      xf.path,
      minWidth: 1,
      minHeight: 1,
      quality: 95,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: true,
      keepExif: false,
    );
    if (bytes == null || bytes.isEmpty) {
      final size = await original.length();
      debugPrint('[menu-scan] normalize returned null — using original');
      return MenuPageArtifact(file: original, sizeBytes: size);
    }
    final dir = original.parent;
    final normalized = File(
      '${dir.path}/menu_page_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await normalized.writeAsBytes(bytes, flush: true);
    debugPrint(
      '[menu-scan] page normalized: ${(bytes.lengthInBytes / 1024).toStringAsFixed(0)}KB',
    );
    return MenuPageArtifact(file: normalized, sizeBytes: bytes.lengthInBytes);
  } catch (e) {
    debugPrint('[menu-scan] normalize failed ($e) — using original');
    return MenuPageArtifact(file: original, sizeBytes: await original.length());
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
  static const int maxDocumentBytes = 15 * 1024 * 1024; // 15 MB (matches backend doc cap)
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'heic', 'webp'];
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi', 'mkv'];
  static const List<String> supportedDocumentFormats = ['pdf', 'docx'];

  /// Pick a PDF or DOCX document using file_picker.
  ///
  /// Returns null when the user cancels. Throws [MediaValidationException]
  /// for oversized files or unsupported formats.
  ///
  /// The file_picker plugin gives us either an on-disk path (desktop / mobile)
  /// or in-memory bytes (web / some Android configs). We normalize to a
  /// [PickedMedia] with a real [File] so downstream upload code (which reads
  /// from disk) works uniformly — writing bytes to a temp file when needed.
  static Future<PickedMedia?> pickDocument({BuildContext? context}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedDocumentFormats,
        // On small docs we want bytes for immediate validation. On mobile
        // a path is also returned and we prefer that to avoid double-RAM.
        withData: true,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        if (kDebugMode) debugPrint('🔍 [MediaPicker] pickDocument cancelled');
        return null;
      }

      final picked = result.files.first;
      final ext = (picked.extension ?? '').toLowerCase();

      // Edge case: file_picker on some platforms strips the extension; fall
      // back to the filename suffix.
      final effectiveExt = ext.isNotEmpty
          ? ext
          : (picked.name.contains('.')
              ? picked.name.split('.').last.toLowerCase()
              : '');

      if (!supportedDocumentFormats.contains(effectiveExt)) {
        throw MediaValidationException(
          'Unsupported document format (.$effectiveExt). Supported: ${supportedDocumentFormats.join(", ")}',
        );
      }

      if (picked.size > maxDocumentBytes) {
        throw MediaValidationException(
          'Document is too large (${_formatBytes(picked.size)}). Maximum size is 15 MB.',
        );
      }

      // Resolve to a File: prefer the on-disk path, else write bytes to temp.
      File file;
      if (picked.path != null && picked.path!.isNotEmpty) {
        file = File(picked.path!);
      } else if (picked.bytes != null) {
        // Write to a temp file so upstream S3 upload (which streams from a
        // File) works unchanged.
        final dir = Directory.systemTemp;
        final tmpPath =
            '${dir.path}/fitwiz_doc_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        file = await File(tmpPath).writeAsBytes(picked.bytes!, flush: true);
      } else {
        throw const MediaValidationException(
          'Could not read the selected document. Please try a different file.',
        );
      }

      final mimeType = _getMimeType(effectiveExt);
      if (kDebugMode) {
        debugPrint('✅ [MediaPicker] pickDocument: ${picked.name} '
            '(${_formatBytes(picked.size)}, $mimeType)');
      }

      return PickedMedia(
        file: file,
        type: ChatMediaType.document,
        sizeBytes: picked.size,
        mimeType: mimeType,
      );
    } on MediaValidationException {
      rethrow;
    } catch (e, stack) {
      debugPrint('❌ [MediaPicker] Error picking document: $e');
      debugPrint('❌ [MediaPicker] Stack: $stack');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file picker: $e')),
        );
      }
      return null;
    }
  }

  /// Request camera permission, returns true if granted.
  static Future<bool> _requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(context, 'Camera');
      return false;
    }

    final result = await Permission.camera.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      _showPermissionDeniedDialog(context, 'Camera');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).mediaPickerHelperCameraPermissionRequired)),
      );
    }
    return false;
  }

  /// Request gallery/photos permission, returns true if granted.
  static Future<bool> _requestGalleryPermission(BuildContext context) async {
    // On Android 13+ use Permission.photos, otherwise storage
    final permission = Platform.isAndroid ? Permission.photos : Permission.photos;
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(context, 'Photo Library');
      return false;
    }

    final result = await permission.request();
    if (result.isGranted || result.isLimited) return true;

    if (result.isPermanentlyDenied) {
      _showPermissionDeniedDialog(context, 'Photo Library');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).mediaPickerHelperPhotoLibraryPermissionRequi)),
      );
    }
    return false;
  }

  /// Show dialog prompting user to open app settings for permanently denied permissions.
  static void _showPermissionDeniedDialog(BuildContext context, String permissionName) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          '$permissionName access has been permanently denied. '
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).buttonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(AppLocalizations.of(context).mediaPickerHelperOpenSettings),
          ),
        ],
      ),
    );
  }

  /// Pick an image from the given source
  static Future<PickedMedia?> pickImage(ImageSource source, {BuildContext? context}) async {
    try {
      // Check permissions when context is provided and still mounted
      if (context != null && context.mounted) {
        if (source == ImageSource.camera) {
          if (!await _requestCameraPermission(context)) return null;
        } else {
          if (!await _requestGalleryPermission(context)) return null;
        }
      }

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
    } catch (e, stackTrace) {
      if (e is MediaValidationException) rethrow;
      debugPrint('❌ [MediaPicker] Error picking image: $e');
      debugPrint('❌ [MediaPicker] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Pick multiple images from gallery (max 5)
  static Future<List<PickedMedia>> pickMultipleImages({BuildContext? context}) async {
    try {
      if (context != null && context.mounted) {
        if (!await _requestGalleryPermission(context)) return [];
      }

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
  static Future<PickedMedia?> pickVideo(ImageSource source, {BuildContext? context}) async {
    try {
      // Check permissions when context is provided and still mounted
      if (context != null && context.mounted) {
        if (source == ImageSource.camera) {
          if (!await _requestCameraPermission(context)) return null;
        } else {
          if (!await _requestGalleryPermission(context)) return null;
        }
      }

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

      // Compress video with progress dialog
      debugPrint('🔍 [MediaPicker] Compressing video...');
      final compressed = context != null && context.mounted
          ? await _compressVideoWithProgress(context, file.path)
          : await VideoCompress.compressVideo(
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

  /// Compress video while showing a modal progress dialog.
  static Future<MediaInfo?> _compressVideoWithProgress(
    BuildContext context,
    String videoPath,
  ) async {
    final navigatorContext = Navigator.of(context, rootNavigator: true).context;
    MediaInfo? result;

    showDialog(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).mediaPickerHelperCompressingVideo,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
          ),
        );
      },
    );

    try {
      result = await VideoCompress.compressVideo(
        videoPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
    } finally {
      if (navigatorContext.mounted) {
        Navigator.of(navigatorContext, rootNavigator: true).pop();
      }
    }

    return result;
  }

  /// Show bottom sheet with media picker options
  /// Returns a PickedMediaResult (which may contain one or multiple media items)
  static Future<PickedMediaResult?> showMediaPickerSheet(BuildContext context) async {
    debugPrint('🔍 [MediaPicker] showMediaPickerSheet called, context.mounted=${context.mounted}');
    final completer = Completer<PickedMediaResult?>();
    // Track whether a pick operation was initiated so the .then() dismissal
    // callback doesn't race ahead and complete the completer with null before
    // the picker returns.
    bool pickingInProgress = false;

    showGlassSheet<void>(
      context: context,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        return GlassSheet(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  AppLocalizations.of(context).mediaPickerHelperAddMedia,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).mediaPickerHelperImagesMax10Mb,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),

                // Photo options
                _PickerOption(
                  icon: Icons.photo_library_outlined,
                  label: AppLocalizations.of(context).mediaPickerHelperChoosePhoto,
                  subtitle: AppLocalizations.of(context).mediaPickerHelperFromGallery,
                  color: AppColors.info,
                  onTap: () async {
                    pickingInProgress = true;
                    Navigator.pop(ctx);
                    HapticService.selection();
                    debugPrint('🔍 [MediaPicker] Picking single image from gallery...');
                    final media = await pickImage(ImageSource.gallery, context: context);
                    debugPrint('🔍 [MediaPicker] pickImage returned: ${media != null ? 'file(${media.formattedSize})' : 'null'}');
                    if (!completer.isCompleted) {
                      completer.complete(media != null ? PickedMediaResult(media: [media]) : null);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _PickerOption(
                  icon: Icons.collections_outlined,
                  label: AppLocalizations.of(context).mediaPickerHelperChooseMultiplePhotos,
                  subtitle: AppLocalizations.of(context).mediaPickerHelperSelectUpTo5,
                  color: const Color(0xFF00BCD4),
                  onTap: () async {
                    pickingInProgress = true;
                    Navigator.pop(ctx);
                    HapticService.selection();
                    debugPrint('🔍 [MediaPicker] Picking multiple images from gallery...');
                    final mediaList = await pickMultipleImages(context: context);
                    debugPrint('🔍 [MediaPicker] pickMultipleImages returned ${mediaList.length} items');
                    if (!completer.isCompleted) {
                      completer.complete(mediaList.isNotEmpty ? PickedMediaResult(media: mediaList) : null);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _PickerOption(
                  icon: Icons.camera_alt_outlined,
                  label: AppLocalizations.of(context).progressTakePhoto,
                  subtitle: AppLocalizations.of(context).progressUseCamera,
                  color: AppColors.success,
                  onTap: () async {
                    pickingInProgress = true;
                    Navigator.pop(ctx);
                    HapticService.selection();
                    debugPrint('🔍 [MediaPicker] Taking photo with camera...');
                    final media = await pickImage(ImageSource.camera, context: context);
                    debugPrint('🔍 [MediaPicker] pickImage (camera) returned: ${media != null ? 'file(${media.formattedSize})' : 'null'}');
                    if (!completer.isCompleted) {
                      completer.complete(media != null ? PickedMediaResult(media: [media]) : null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Video options
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).workoutShowcaseVideo,
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
                  label: AppLocalizations.of(context).mediaPickerHelperChooseVideo,
                  subtitle: AppLocalizations.of(context).mediaPickerHelperFromGalleryMax60s,
                  color: AppColors.purple,
                  onTap: () async {
                    pickingInProgress = true;
                    Navigator.pop(ctx);
                    HapticService.selection();
                    debugPrint('🔍 [MediaPicker] Picking video from gallery...');
                    final media = await pickVideo(ImageSource.gallery, context: context);
                    debugPrint('🔍 [MediaPicker] pickVideo returned: ${media != null ? 'file(${media.formattedSize})' : 'null'}');
                    if (!completer.isCompleted) {
                      completer.complete(media != null ? PickedMediaResult(media: [media]) : null);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _PickerOption(
                  icon: Icons.videocam_outlined,
                  label: AppLocalizations.of(context).mediaPickerHelperRecordVideo,
                  subtitle: AppLocalizations.of(context).mediaPickerHelperUseCameraMax60s,
                  color: AppColors.orange,
                  onTap: () async {
                    pickingInProgress = true;
                    Navigator.pop(ctx);
                    HapticService.selection();
                    debugPrint('🔍 [MediaPicker] Recording video with camera...');
                    final media = await pickVideo(ImageSource.camera, context: context);
                    debugPrint('🔍 [MediaPicker] pickVideo (camera) returned: ${media != null ? 'file(${media.formattedSize})' : 'null'}');
                    if (!completer.isCompleted) {
                      completer.complete(media != null ? PickedMediaResult(media: [media]) : null);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Sheet dismissed without picking (swipe down / tap outside).
      // Only complete with null if no pick operation is in progress -
      // otherwise the picker's own completion will handle it.
      debugPrint('🔍 [MediaPicker] Sheet dismissed. pickingInProgress=$pickingInProgress, completer.isCompleted=${completer.isCompleted}');
      if (!pickingInProgress && !completer.isCompleted) {
        debugPrint('🔍 [MediaPicker] No pick in progress, completing with null (user dismissed sheet)');
        completer.complete(null);
      }
    });

    return completer.future;
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
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
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
