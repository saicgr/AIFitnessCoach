import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../data/services/share_service.dart';
import 'image_capture_utils.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Capture the widget bound to [repaintKey] and open the system share sheet.
///
/// Used on report screens (Insights, Weekly Summary, Progress) so users can
/// send a rendered snapshot of the report to anyone — SMS, WhatsApp, etc. —
/// without the recipient needing the app installed.
///
/// The caller is responsible for wrapping the report body in a
/// `RepaintBoundary(key: repaintKey, ...)` with an opaque background so the
/// PNG capture isn't transparent.
Future<void> shareReportScreen({
  required BuildContext context,
  required GlobalKey repaintKey,
  String caption = 'Check out my ${Branding.appName} report!',
  String subject = 'My ${Branding.appName} Report',
}) async {
  HapticFeedback.mediumImpact();

  // Show a brief inline loader while the capture happens — capture can take
  // ~200-400ms for a full screen at 3x pixel ratio.
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Preparing report...'),
        ],
      ),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );

  try {
    final bytes = await ImageCaptureUtils.captureWidget(
      repaintKey,
      pixelRatio: 3.0,
    );

    messenger?.hideCurrentSnackBar();

    if (bytes == null) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Could not capture report. Try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // iOS requires a non-zero sharePositionOrigin for the share popover.
    Rect? origin;
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }

    final result = await ShareService.shareGeneric(
      bytes,
      caption: caption,
      subject: subject,
      sharePositionOrigin: origin,
    );

    if (!result.success && result.error != null) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Share failed: ${result.error}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Share failed: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
