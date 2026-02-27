import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/wrapped_data.dart';
import '../../data/services/share_service.dart';
import '../../utils/image_capture_utils.dart';
import '../workout/widgets/share_templates/app_watermark.dart';
import 'cards/intro_card.dart';
import 'cards/volume_card.dart';
import 'cards/favorites_card.dart';
import 'cards/consistency_card.dart';
import 'cards/records_card.dart';
import 'cards/time_card.dart';
import 'cards/personality_card.dart';
import 'cards/summary_card.dart';

/// Bottom sheet for sharing a Wrapped card image.
/// Follows the same pattern as ActivityShareSheet.
class WrappedShareSheet extends StatefulWidget {
  final WrappedData data;
  final int currentCardIndex;

  const WrappedShareSheet({
    super.key,
    required this.data,
    required this.currentCardIndex,
  });

  @override
  State<WrappedShareSheet> createState() => _WrappedShareSheetState();
}

class _WrappedShareSheetState extends State<WrappedShareSheet> {
  bool _showWatermark = true;
  bool _isSharing = false;
  bool _isSaving = false;
  final GlobalKey _captureKey = GlobalKey();

  Widget _buildCurrentCard() {
    final data = widget.data;
    switch (widget.currentCardIndex) {
      case 0:
        return WrappedIntroCard(data: data, showWatermark: _showWatermark);
      case 1:
        return WrappedVolumeCard(data: data, showWatermark: _showWatermark);
      case 2:
        return WrappedFavoritesCard(data: data, showWatermark: _showWatermark);
      case 3:
        return WrappedConsistencyCard(
            data: data, showWatermark: _showWatermark);
      case 4:
        return WrappedRecordsCard(data: data, showWatermark: _showWatermark);
      case 5:
        return WrappedTimeCard(data: data, showWatermark: _showWatermark);
      case 6:
        return WrappedPersonalityCard(
            data: data, showWatermark: _showWatermark);
      case 7:
        return WrappedSummaryCard(data: data, showWatermark: _showWatermark);
      default:
        return WrappedIntroCard(data: data, showWatermark: _showWatermark);
    }
  }

  Future<Uint8List?> _captureCard() async {
    return await ImageCaptureUtils.captureWidgetWithSize(
      _captureKey,
      width: ImageCaptureUtils.instagramStoriesSize.width,
      height: ImageCaptureUtils.instagramStoriesSize.height,
      pixelRatio: 1.0,
    );
  }

  Future<void> _shareToInstagram() async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCard();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      final result = await ShareService.shareToInstagramStories(bytes);
      if (result.success && mounted) {
        Navigator.pop(context);
        _showSuccess('Opening Instagram...');
      } else if (result.error != null) {
        _showError('Could not open Instagram');
      }
    } catch (e) {
      _showError('Failed to share');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareGeneric() async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCard();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      await ShareService.shareGeneric(
        bytes,
        caption: _buildShareText(),
      );
    } catch (e) {
      _showError('Failed to share');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final bytes = await _captureCard();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      final result = await ShareService.saveToGallery(bytes);
      if (result.success && mounted) {
        Navigator.pop(context);
        _showSuccess('Saved to device!');
      } else {
        _showError(result.error ?? 'Failed to save image');
      }
    } catch (e) {
      _showError('Failed to save');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _copyText() {
    HapticFeedback.lightImpact();
    final text = _buildShareText();
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      Navigator.pop(context);
      _showSuccess('Copied to clipboard!');
    }
  }

  String _buildShareText() {
    final d = widget.data;
    return 'My ${d.monthDisplayName} ${d.yearDisplay} Wrapped on FitWiz! '
        '${d.totalWorkouts} workouts | ${d.personalRecordsCount} PRs | '
        '${d.workoutConsistencyPct.round()}% consistency '
        '#FitWiz #FitnessWrapped #${d.monthDisplayName}Wrapped';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Text(
                        'Share Wrapped',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Watermark toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.branding_watermark_rounded,
                        size: 18,
                        color: _showWatermark ? AppColors.cyan : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Show Watermark',
                        style: TextStyle(
                          fontSize: 14,
                          color: _showWatermark ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: _showWatermark,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          setState(() => _showWatermark = value);
                        },
                        activeTrackColor: AppColors.cyan,
                        activeThumbColor: Colors.white,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Card preview
                Expanded(
                  child: Center(
                    child: CapturableWidget(
                      captureKey: _captureKey,
                      child: _buildCurrentCard(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Instagram + More
                      Row(
                        children: [
                          Expanded(
                            child: _buildShareButton(
                              onPressed: _shareToInstagram,
                              icon: Icons.camera_alt_rounded,
                              label: 'Instagram',
                              isPrimary: true,
                              isLoading: _isSharing,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildShareButton(
                              onPressed: _shareGeneric,
                              icon: Icons.share_rounded,
                              label: 'More',
                              isPrimary: false,
                              isLoading: _isSharing,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Row 2: Save Image + Copy Text
                      Row(
                        children: [
                          Expanded(
                            child: _buildShareButton(
                              onPressed: _saveToGallery,
                              icon: Icons.save_alt_rounded,
                              label: 'Save Image',
                              isPrimary: false,
                              isLoading: _isSaving,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildShareButton(
                              onPressed: _copyText,
                              icon: Icons.copy_rounded,
                              label: 'Copy Text',
                              isPrimary: false,
                              isLoading: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isLoading,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyan,
        side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.cyan),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }
}
