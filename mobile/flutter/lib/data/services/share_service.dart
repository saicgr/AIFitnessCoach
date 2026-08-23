import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Share destination enum
enum ShareDestination {
  instagramStories,
  systemShare,
  saveToGallery,
}

/// Result of a share operation
class ShareResult {
  final bool success;
  final ShareDestination destination;
  final String? error;

  const ShareResult({
    required this.success,
    required this.destination,
    this.error,
  });
}

/// Service for sharing images to external platforms
class ShareService {
  /// Anchor rect for the iOS share sheet.
  ///
  /// E2E register row 138: "Tapping Share never presents the OS share sheet —
  /// the controller activates and deallocates in ~19 ms." That was filed as
  /// possibly Simulator-only. It is not: on **iPad** — and this app ships for
  /// iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) — `UIActivityViewController` is
  /// presented as a POPOVER, and a popover must have an anchor. `share_plus`
  /// supplies that anchor from `sharePositionOrigin`. Pass nothing and there is
  /// nowhere to attach it, so iOS tears the controller straight back down —
  /// exactly the activate-then-deallocate signature in the report.
  ///
  /// 19 of 20 `shareXFiles` call sites in this app passed nothing, so every
  /// share entry point was affected on iPad.
  ///
  /// A caller that knows which widget was tapped should still pass its real
  /// global rect (the popover then points at the button). This is the FALLBACK
  /// so that not doing so degrades to a centred sheet instead of no sheet at
  /// all. Deliberately a real, non-empty rect: a zero-size origin is treated the
  /// same as none.
  static Rect defaultSharePositionOrigin() => _fallbackSharePositionOrigin();

  static Rect _fallbackSharePositionOrigin() {
    final view = ui.PlatformDispatcher.instance.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    // A small rect at the centre — visually neutral, and valid as an anchor.
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
  }

  /// Share to Instagram Stories via deep link
  ///
  /// This uses Instagram's native Stories composer.
  /// Returns true if Instagram was opened successfully.
  static Future<ShareResult> shareToInstagramStories(
    Uint8List imageBytes, {
    String? stickerAssetPath,
  }) async {
    try {
      // Save image to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/workout_story_$timestamp.png');
      await file.writeAsBytes(imageBytes);

      if (Platform.isIOS) {
        return await _shareToInstagramStoriesIOS(file);
      } else if (Platform.isAndroid) {
        return await _shareToInstagramStoriesAndroid(file);
      } else {
        // Fallback to system share for other platforms
        return await shareGeneric(imageBytes, caption: 'Check out my workout!');
      }
    } catch (e) {
      debugPrint('❌ [Share] Instagram Stories error: $e');
      return ShareResult(
        success: false,
        destination: ShareDestination.instagramStories,
        error: e.toString(),
      );
    }
  }

  /// iOS-specific Instagram Stories sharing.
  ///
  /// Routes through the `com.fitwiz/instagram_share` MethodChannel implemented
  /// in `AppDelegate.swift` (InstagramSharePlugin) which stages the image on
  /// UIPasteboard and opens `instagram-stories://share?source_application=...`.
  /// On failure (Instagram not installed, channel missing, user cancels) we
  /// fall through to the system share sheet so the user still has a path to
  /// share — but we report `instagramStories: false` so the caller knows the
  /// "Opening Instagram..." snackbar would be a lie.
  static Future<ShareResult> _shareToInstagramStoriesIOS(File imageFile) async {
    try {
      const platform = MethodChannel('com.fitwiz/instagram_share');

      try {
        final result = await platform.invokeMethod('shareToInstagramStories', {
          'imagePath': imageFile.path,
        });

        if (result == true) {
          debugPrint('✅ [Share] Shared to Instagram Stories (iOS)');
          return const ShareResult(
            success: true,
            destination: ShareDestination.instagramStories,
          );
        }
        debugPrint('⚠️ [Share] iOS native handler returned false (Instagram missing or open denied)');
      } on MissingPluginException {
        // Native plugin not registered for this build — should never happen
        // post-AppDelegate change, but fall through to system share if it does.
        debugPrint('⚠️ [Share] iOS Instagram MethodChannel not registered');
      }

      // Native path failed — surface system share sheet so the user can still
      // share via Instagram Direct / DMs / etc. Report systemShare destination
      // so the UI doesn't claim Stories opened.
      final bytes = await imageFile.readAsBytes();
      return await shareGeneric(bytes, caption: 'Check out my workout!');
    } catch (e) {
      debugPrint('❌ [Share] iOS Instagram share error: $e');
      return ShareResult(
        success: false,
        destination: ShareDestination.instagramStories,
        error: e.toString(),
      );
    }
  }

  /// Android-specific Instagram Stories sharing.
  ///
  /// Routes through the `com.fitwiz/instagram_share` MethodChannel implemented
  /// in `MainActivity.kt`, which fires the `com.instagram.share.ADD_TO_STORY`
  /// intent with a FileProvider content:// URI so Instagram drops the user
  /// straight into the Stories composer with the workout image pre-loaded.
  static Future<ShareResult> _shareToInstagramStoriesAndroid(File imageFile) async {
    try {
      const platform = MethodChannel('com.fitwiz/instagram_share');

      try {
        final result = await platform.invokeMethod('shareToInstagramStories', {
          'imagePath': imageFile.path,
        });

        if (result == true) {
          debugPrint('✅ [Share] Shared to Instagram Stories (Android)');
          return const ShareResult(
            success: true,
            destination: ShareDestination.instagramStories,
          );
        }
        debugPrint('⚠️ [Share] Android native handler returned false (Instagram missing or intent unresolved)');
      } on MissingPluginException {
        debugPrint('⚠️ [Share] Android Instagram MethodChannel not registered');
      }

      // Native path failed — surface system share sheet so user can still pick
      // Instagram (post/feed/DM) manually. Report systemShare so the UI label
      // matches reality.
      await Share.shareXFiles(
        [XFile(imageFile.path, mimeType: 'image/png')],
        text: 'Check out my workout!',
        sharePositionOrigin: _fallbackSharePositionOrigin(),
      );

      return const ShareResult(
        success: true,
        destination: ShareDestination.systemShare,
      );
    } catch (e) {
      debugPrint('❌ [Share] Android Instagram share error: $e');
      return ShareResult(
        success: false,
        destination: ShareDestination.instagramStories,
        error: e.toString(),
      );
    }
  }

  /// Share a workout-card sticker over a user-picked video to Instagram
  /// Stories.
  ///
  /// The card is handed over as a transparent PNG sticker and [videoPath]
  /// becomes the story background — Instagram composites the two natively,
  /// so there is no on-device video encoding. Routes through the same
  /// `com.fitwiz/instagram_share` MethodChannel as the image path, via the
  /// `shareVideoToInstagramStories` method. Falls back to a plain system
  /// share of the video if the native handler or Instagram is unavailable.
  static Future<ShareResult> shareVideoToInstagramStories({
    required String videoPath,
    required Uint8List stickerBytes,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Stage the sticker PNG in our cache dir.
      final stickerFile = File('${tempDir.path}/workout_sticker_$ts.png');
      await stickerFile.writeAsBytes(stickerBytes);

      // Copy the picked video into our cache dir so the Android FileProvider
      // can serve it (the picker's path can sit outside the exposed paths).
      final ext = videoPath.split('.').last.toLowerCase();
      final videoExt = (ext == 'mov' || ext == 'mp4') ? ext : 'mp4';
      final videoCopy = File('${tempDir.path}/workout_bg_$ts.$videoExt');
      await File(videoPath).copy(videoCopy.path);

      if (!Platform.isIOS && !Platform.isAndroid) {
        return await _shareVideoGeneric(videoCopy.path);
      }

      const platform = MethodChannel('com.fitwiz/instagram_share');
      try {
        final result = await platform.invokeMethod(
          'shareVideoToInstagramStories',
          {
            'videoPath': videoCopy.path,
            'stickerImagePath': stickerFile.path,
          },
        );
        if (result == true) {
          debugPrint('✅ [Share] Shared video to Instagram Stories');
          return const ShareResult(
            success: true,
            destination: ShareDestination.instagramStories,
          );
        }
        debugPrint('⚠️ [Share] video IG handler returned false');
      } on MissingPluginException {
        debugPrint('⚠️ [Share] video IG MethodChannel not registered');
      }

      // Native path failed (Instagram missing / channel absent) — surface
      // the system share sheet with the video so the user still has a path.
      return await _shareVideoGeneric(videoCopy.path);
    } catch (e) {
      debugPrint('❌ [Share] Instagram video share error: $e');
      return ShareResult(
        success: false,
        destination: ShareDestination.instagramStories,
        error: e.toString(),
      );
    }
  }

  static Future<ShareResult> _shareVideoGeneric(String videoPath) async {
    try {
      await Share.shareXFiles(
        [XFile(videoPath, mimeType: 'video/mp4')],
        text: 'Check out my workout!',
        sharePositionOrigin: _fallbackSharePositionOrigin(),
      );
      return const ShareResult(
        success: true,
        destination: ShareDestination.systemShare,
      );
    } catch (e) {
      debugPrint('❌ [Share] system video share error: $e');
      return ShareResult(
        success: false,
        destination: ShareDestination.systemShare,
        error: e.toString(),
      );
    }
  }

  /// Generic share using system share sheet
  static Future<ShareResult> shareGeneric(
    Uint8List imageBytes, {
    String? caption,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/workout_recap_$timestamp.png');
      await file.writeAsBytes(imageBytes);

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: caption ?? 'Check out my workout!',
        subject: subject ?? 'My Workout Recap',
        sharePositionOrigin:
            sharePositionOrigin ?? _fallbackSharePositionOrigin(),
      );

      debugPrint('✅ [Share] System share completed: ${result.status}');

      return ShareResult(
        success: result.status == ShareResultStatus.success ||
            result.status == ShareResultStatus.dismissed,
        destination: ShareDestination.systemShare,
      );
    } catch (e) {
      debugPrint('❌ [Share] System share error: $e');
      return ShareResult(
        success: false,
        destination: ShareDestination.systemShare,
        error: e.toString(),
      );
    }
  }

  /// Check if Instagram is installed
  static Future<bool> isInstagramInstalled() async {
    try {
      return await canLaunchUrl(Uri.parse('instagram://'));
    } catch (e) {
      return false;
    }
  }

  /// Check if Instagram Stories deep link is available
  static Future<bool> canShareToInstagramStories() async {
    try {
      if (Platform.isIOS) {
        return await canLaunchUrl(Uri.parse('instagram-stories://share'));
      } else if (Platform.isAndroid) {
        return await canLaunchUrl(Uri.parse('instagram://'));
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Save image to device gallery (Photos app)
  ///
  /// Uses gal package to properly save to the device's
  /// photo gallery on both iOS (Camera Roll) and Android (Pictures).
  static Future<ShareResult> saveToGallery(Uint8List imageBytes) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${Branding.appName}_Workout_$timestamp.png';

      // Save to temp file first
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Use Gal to save to device gallery.
      // Works on both iOS (Camera Roll) and Android (Pictures/MediaStore).
      //
      // Register row 81: do NOT pass `album:`. Creating/among an album needs
      // FULL photo-library access, so iOS prompted with
      // NSPhotoLibraryUsageDescription — "...pick food photos for AI nutrition
      // analysis and progress photos for body tracking" — copy about PICKING
      // photos, shown for an action that only SAVES one. Without `album:`,
      // Gal uses the add-only scope and iOS shows
      // NSPhotoLibraryAddUsageDescription, which already says the right thing
      // ("save workout recap images to your photo library"). Add-only is also
      // the least privilege this feature needs: we never read the library.
      await Gal.putImage(file.path);

      debugPrint('✅ [Share] Saved to gallery: ${file.path}');
      return const ShareResult(
        success: true,
        destination: ShareDestination.saveToGallery,
      );
    } catch (e) {
      debugPrint('❌ [Share] Save to gallery error: $e');
      return ShareResult(
        success: false,
        destination: ShareDestination.saveToGallery,
        error: e.toString(),
      );
    }
  }

  /// Clean up temporary share files
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File && file.path.contains('workout_')) {
          await file.delete();
        }
      }

      debugPrint('🧹 [Share] Cleaned up temp files');
    } catch (e) {
      debugPrint('⚠️ [Share] Error cleaning up temp files: $e');
    }
  }
}
