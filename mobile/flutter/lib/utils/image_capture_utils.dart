import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Utility class for capturing widgets as images
class ImageCaptureUtils {
  /// Capture a widget wrapped in RepaintBoundary as PNG bytes
  ///
  /// The widget must be wrapped in a RepaintBoundary with the provided [repaintKey].
  /// Returns null if capture fails.
  ///
  /// Example:
  /// ```dart
  /// final _captureKey = GlobalKey();
  ///
  /// Widget build(BuildContext context) {
  ///   return RepaintBoundary(
  ///     key: _captureKey,
  ///     child: MyWidget(),
  ///   );
  /// }
  ///
  /// Future<void> capture() async {
  ///   final bytes = await ImageCaptureUtils.captureWidget(_captureKey);
  ///   if (bytes != null) {
  ///     // Use bytes...
  ///   }
  /// }
  /// ```
  static Future<Uint8List?> captureWidget(
    GlobalKey repaintKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      // Get the RenderRepaintBoundary
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('❌ [ImageCapture] RenderRepaintBoundary not found');
        return null;
      }

      // Wait for any pending layout/paint operations
      await Future.delayed(const Duration(milliseconds: 20));

      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      // Convert to PNG bytes
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        debugPrint('❌ [ImageCapture] Failed to convert image to bytes');
        return null;
      }

      debugPrint('✅ [ImageCapture] Widget captured successfully');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ [ImageCapture] Error capturing widget: $e');
      return null;
    }
  }

  /// Capture multiple widgets and return all as PNG bytes
  ///
  /// Useful for capturing all templates in a carousel.
  /// Returns a list of byte arrays (some may be null if capture failed).
  static Future<List<Uint8List?>> captureMultipleWidgets(
    List<GlobalKey> repaintKeys, {
    double pixelRatio = 3.0,
  }) async {
    final results = <Uint8List?>[];

    for (final key in repaintKeys) {
      final bytes = await captureWidget(key, pixelRatio: pixelRatio);
      results.add(bytes);
    }

    return results;
  }

  /// Capture a widget with a specific size override
  ///
  /// This is useful when you need to capture a widget at a specific size
  /// regardless of screen size (e.g., for Instagram Stories 1080x1920).
  static Future<Uint8List?> captureWidgetWithSize(
    GlobalKey repaintKey, {
    required double width,
    required double height,
    double pixelRatio = 1.0,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('❌ [ImageCapture] RenderRepaintBoundary not found');
        return null;
      }

      await Future.delayed(const Duration(milliseconds: 20));

      // Calculate pixel ratio to achieve target size
      final currentSize = boundary.size;
      final scaleX = width / currentSize.width;
      final scaleY = height / currentSize.height;
      final scale = (scaleX < scaleY ? scaleX : scaleY) * pixelRatio;

      final ui.Image image = await boundary.toImage(pixelRatio: scale);

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        debugPrint('❌ [ImageCapture] Failed to convert image to bytes');
        return null;
      }

      debugPrint(
          '✅ [ImageCapture] Widget captured with size ${image.width}x${image.height}');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ [ImageCapture] Error capturing widget with size: $e');
      return null;
    }
  }

  /// Instagram Stories optimal size (9:16 aspect ratio)
  static const Size instagramStoriesSize = Size(1080, 1920);

  /// Instagram Post optimal size (1:1 square)
  static const Size instagramPostSize = Size(1080, 1080);

  /// Standard share image size (16:9 landscape)
  static const Size standardShareSize = Size(1920, 1080);
}

/// A wrapper widget that makes its child capturable
///
/// This is a convenience widget that wraps content in a RepaintBoundary
/// and provides the capture key for later use.
class CapturableWidget extends StatelessWidget {
  final GlobalKey captureKey;
  final Widget child;

  const CapturableWidget({
    super.key,
    required this.captureKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: captureKey,
      child: child,
    );
  }
}
