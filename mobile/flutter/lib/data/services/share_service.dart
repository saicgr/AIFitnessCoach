import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// iOS-specific Instagram Stories sharing
  static Future<ShareResult> _shareToInstagramStoriesIOS(File imageFile) async {
    try {
      // Check if Instagram is installed
      final instagramUrl = Uri.parse('instagram-stories://share');
      if (!await canLaunchUrl(instagramUrl)) {
        debugPrint('⚠️ [Share] Instagram not installed, falling back to system share');
        final bytes = await imageFile.readAsBytes();
        return await shareGeneric(bytes, caption: 'Check out my workout!');
      }

      // iOS uses UIPasteboard to share to Instagram Stories
      // This requires platform channel for proper implementation
      // For now, we'll use the system share as fallback

      // Method channel for Instagram Stories (iOS)
      const platform = MethodChannel('com.aifitnesscoach/instagram_share');

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
      } on MissingPluginException {
        // Platform channel not implemented, fall back to URL scheme
        debugPrint('⚠️ [Share] Platform channel not available, trying URL scheme');
      }

      // Fallback: Try opening Instagram app directly
      // User will need to manually share from camera roll
      if (await canLaunchUrl(Uri.parse('instagram://'))) {
        await launchUrl(Uri.parse('instagram://'));
        debugPrint('✅ [Share] Opened Instagram app');
        return const ShareResult(
          success: true,
          destination: ShareDestination.instagramStories,
        );
      }

      // Last resort: system share
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

  /// Android-specific Instagram Stories sharing
  static Future<ShareResult> _shareToInstagramStoriesAndroid(File imageFile) async {
    try {
      // Check if Instagram is installed
      final instagramUrl = Uri.parse('instagram://');
      if (!await canLaunchUrl(instagramUrl)) {
        debugPrint('⚠️ [Share] Instagram not installed, falling back to system share');
        final bytes = await imageFile.readAsBytes();
        return await shareGeneric(bytes, caption: 'Check out my workout!');
      }

      // Android uses Intent to share to Instagram Stories
      const platform = MethodChannel('com.aifitnesscoach/instagram_share');

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
      } on MissingPluginException {
        // Platform channel not implemented, fall back to share_plus with Instagram package
        debugPrint('⚠️ [Share] Platform channel not available, trying share_plus');
      }

      // Fallback: Use share_plus to target Instagram
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: 'Check out my workout!',
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

  /// Generic share using system share sheet
  static Future<ShareResult> shareGeneric(
    Uint8List imageBytes, {
    String? caption,
    String? subject,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/workout_recap_$timestamp.png');
      await file.writeAsBytes(imageBytes);

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: caption ?? 'Check out my workout!',
        subject: subject ?? 'My Workout Recap',
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
      final fileName = 'FitWiz_Workout_$timestamp.png';

      // Save to temp file first
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Use Gal to save to device gallery
      // This works on both iOS (Camera Roll) and Android (Pictures/MediaStore)
      await Gal.putImage(file.path, album: 'FitWiz');

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
