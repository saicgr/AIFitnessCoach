import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'comparison_layouts.dart';

/// Service for capturing, saving, and sharing comparison images
class ComparisonExportService {
  /// Capture a widget tree to an image file via RepaintBoundary
  static Future<File> captureCanvas(
    GlobalKey captureKey, {
    double pixelRatio = 3.0,
    ExportAspectRatio? targetAspectRatio,
  }) async {
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/fitwiz_comparison_$timestamp.png');
    await file.writeAsBytes(pngBytes);

    return file;
  }

  /// Share an image file via the native share sheet
  static Future<void> shareImage(File imageFile) async {
    await Share.shareXFiles(
      [XFile(imageFile.path)],
      text: 'My fitness progress - FitWiz',
    );
  }

  /// Save an image file to the device gallery
  static Future<void> saveToGallery(File imageFile) async {
    await Gal.putImage(imageFile.path, album: 'FitWiz');
  }

  /// Capture and share in one step
  static Future<void> captureAndShare(
    GlobalKey captureKey, {
    double pixelRatio = 3.0,
    ExportAspectRatio? targetAspectRatio,
  }) async {
    final file = await captureCanvas(
      captureKey,
      pixelRatio: pixelRatio,
      targetAspectRatio: targetAspectRatio,
    );
    await shareImage(file);
  }

  /// Capture and save to gallery in one step
  static Future<void> captureAndSave(
    GlobalKey captureKey, {
    double pixelRatio = 3.0,
    ExportAspectRatio? targetAspectRatio,
  }) async {
    final file = await captureCanvas(
      captureKey,
      pixelRatio: pixelRatio,
      targetAspectRatio: targetAspectRatio,
    );
    await saveToGallery(file);
  }

  /// Export sizes for each aspect ratio
  static const exportSizes = {
    '1:1': Size(1080, 1080),
    '4:5': Size(1080, 1350),
    '9:16': Size(1080, 1920),
  };
}
