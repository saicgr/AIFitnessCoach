import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/services/share_service.dart';
import '../../../utils/image_capture_utils.dart';
import '../../../widgets/glass_sheet.dart';
import 'share_templates/single_meal_template.dart';

/// Compact share sheet scoped to a single meal. Reuses the same
/// `ImageCaptureUtils` + `ShareService` pipeline as the full
/// `ShareNutritionSheet` (instagram-stories sized PNG via RepaintBoundary →
/// share_plus). Mounted from the meal long-press menu.
class ShareSingleMealSheet extends StatefulWidget {
  final FoodLog meal;
  const ShareSingleMealSheet({super.key, required this.meal});

  static Future<void> show(BuildContext context, FoodLog meal) async {
    await showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (_) => ShareSingleMealSheet(meal: meal),
    );
  }

  @override
  State<ShareSingleMealSheet> createState() => _ShareSingleMealSheetState();
}

class _ShareSingleMealSheetState extends State<ShareSingleMealSheet> {
  final GlobalKey _captureKey = GlobalKey();
  bool _busy = false;
  bool _showWatermark = true;

  Future<Uint8List?> _capture() async {
    return await ImageCaptureUtils.captureWidgetWithSize(
      _captureKey,
      width: ImageCaptureUtils.instagramStoriesSize.width,
      height: ImageCaptureUtils.instagramStoriesSize.height,
      pixelRatio: 1.0,
    );
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      await ShareService.shareGeneric(bytes, caption: 'Logged on Zealova 🍽️');
    } catch (e) {
      debugPrint('[share-meal] share failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      final result = await ShareService.saveToGallery(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? 'Saved to your photos' : 'Couldn’t save image'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : Colors.black87;

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Share this meal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 12),
          // Preview card — scaled down so the full Instagram-Stories aspect
          // fits in a sheet without distortion. RepaintBoundary stays at
          // native 1080x1920 for crisp capture.
          AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: ImageCaptureUtils.instagramStoriesSize.width,
                  height: ImageCaptureUtils.instagramStoriesSize.height,
                  child: RepaintBoundary(
                    key: _captureKey,
                    child: SingleMealShareTemplate(
                      meal: widget.meal,
                      showWatermark: _showWatermark,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch.adaptive(
                value: _showWatermark,
                onChanged: (v) => setState(() => _showWatermark = v),
              ),
              const SizedBox(width: 4),
              Text('Show "Powered by Zealova"',
                  style: TextStyle(fontSize: 13, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.download),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: const Icon(Icons.ios_share),
                  label: Text(_busy ? 'Sharing…' : 'Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
