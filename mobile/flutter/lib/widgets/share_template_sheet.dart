import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../data/services/share_service.dart';
import '../utils/image_capture_utils.dart';
import 'glass_sheet.dart';

/// Declarative description of a single shareable template inside a
/// [ShareTemplateSheet] carousel.
///
/// [content] is the raw 9:16-friendly card (the design shown in the carousel).
/// The sheet wraps it in a [CapturableWidget] + [InstagramStoryWrapper] using
/// [backgroundGradient] so the final captured image fills an Instagram Story
/// canvas without letterboxing.
class ShareTemplateDef {
  final String name;
  final Widget content;
  final List<Color> backgroundGradient;

  const ShareTemplateDef({
    required this.name,
    required this.content,
    required this.backgroundGradient,
  });
}

/// Reusable share sheet with the same UX as `ShareStatsSheet`:
/// - carousel of templates (swipe or tap pill indicators)
/// - watermark toggle
/// - Instagram Stories / system share / save-to-gallery buttons
/// - loading and error snackbars
///
/// Pass a builder so the watermark toggle can be reflected in templates that
/// accept a `showWatermark` flag — the builder is re-invoked whenever the
/// toggle flips.
class ShareTemplateSheet extends StatefulWidget {
  final String title;
  final String caption;
  final String subject;

  /// Called with the current watermark-toggle value. Must return a stable
  /// list of templates whose order matches the page indicator labels.
  final List<ShareTemplateDef> Function(bool showWatermark) templatesBuilder;

  const ShareTemplateSheet({
    super.key,
    required this.title,
    required this.caption,
    required this.subject,
    required this.templatesBuilder,
  });

  /// Show the sheet via `showGlassSheet` (uses root navigator so it layers
  /// above the tab bar).
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String caption,
    required String subject,
    required List<ShareTemplateDef> Function(bool showWatermark)
        templatesBuilder,
  }) async {
    await showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => ShareTemplateSheet(
        title: title,
        caption: caption,
        subject: subject,
        templatesBuilder: templatesBuilder,
      ),
    );
  }

  @override
  State<ShareTemplateSheet> createState() => _ShareTemplateSheetState();
}

class _ShareTemplateSheetState extends State<ShareTemplateSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSharing = false;
  bool _isSaving = false;
  bool _showWatermark = true;
  late List<GlobalKey> _captureKeys;

  @override
  void initState() {
    super.initState();
    // Size the key list once based on the templates produced at init time.
    // We assume the builder always produces the same number of templates.
    final templates = widget.templatesBuilder(_showWatermark);
    _captureKeys = List.generate(templates.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureCurrentTemplate() async {
    return ImageCaptureUtils.captureWidgetWithSize(
      _captureKeys[_currentPage],
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
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }
      final result = await ShareService.shareToInstagramStories(bytes);
      if (result.success) {
        if (mounted) {
          Navigator.pop(context);
          _showSuccess('Opening Instagram...');
        }
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
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }
      await ShareService.shareGeneric(
        bytes,
        caption: widget.caption,
        subject: widget.subject,
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
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }
      final result = await ShareService.saveToGallery(bytes);
      if (!result.success) {
        _showError(result.error ?? 'Failed to save image');
        return;
      }
      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Saved to device!');
      }
    } catch (e) {
      _showError('Failed to save');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
    final templates = widget.templatesBuilder(_showWatermark);
    // If the builder ever returns a different count, resize keys defensively
    // so capture indices stay valid.
    if (templates.length != _captureKeys.length) {
      _captureKeys = List.generate(templates.length, (_) => GlobalKey());
    }

    return GlassSheet(
      maxHeightFraction: 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(title: widget.title),
          _WatermarkRow(
            isDark: isDark,
            value: _showWatermark,
            onChanged: (v) => setState(() => _showWatermark = v),
          ),
          Expanded(child: _buildCarousel(templates)),
          _PageIndicators(
            templates: templates,
            currentPage: _currentPage,
            isDark: isDark,
            onTap: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          const SizedBox(height: 16),
          _ActionButtons(
            isSharing: _isSharing,
            isSaving: _isSaving,
            onInstagram: _shareToInstagram,
            onShare: _shareGeneric,
            onSave: _saveToGallery,
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(List<ShareTemplateDef> templates) {
    return PageView.builder(
      controller: _pageController,
      itemCount: templates.length,
      onPageChanged: (index) {
        HapticFeedback.selectionClick();
        setState(() => _currentPage = index);
      },
      itemBuilder: (context, index) {
        final def = templates[index];
        return Center(
          child: CapturableWidget(
            captureKey: _captureKeys[index],
            child: InstagramStoryWrapper(
              backgroundGradient: def.backgroundGradient,
              child: def.content,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Private sub-widgets kept in this file so the base sheet is self-contained.
// ─────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _WatermarkRow extends StatelessWidget {
  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _WatermarkRow({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast =
        isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.branding_watermark_rounded,
            size: 18,
            color: value ? accent : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            'Show Watermark',
            style: TextStyle(
              fontSize: 14,
              color: value ? null : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
            activeTrackColor: accent,
            activeThumbColor: accentContrast,
          ),
        ],
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final List<ShareTemplateDef> templates;
  final int currentPage;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _PageIndicators({
    required this.templates,
    required this.currentPage,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast =
        isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(templates.length, (index) {
            final isActive = currentPage == index;
            return GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 12 : 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? accent
                      : isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  templates[index].name,
                  style: TextStyle(
                    color: isActive
                        ? accentContrast
                        : isDark
                            ? Colors.white70
                            : Colors.black54,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool isSharing;
  final bool isSaving;
  final VoidCallback onInstagram;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const _ActionButtons({
    required this.isSharing,
    required this.isSaving,
    required this.onInstagram,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _ShareButton(
                  onPressed: onInstagram,
                  icon: Icons.camera_alt_rounded,
                  label: 'Instagram',
                  isPrimary: true,
                  isLoading: isSharing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShareButton(
                  onPressed: onShare,
                  icon: Icons.share_rounded,
                  label: 'Share',
                  isPrimary: false,
                  isLoading: isSharing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ShareButton(
                  onPressed: onSave,
                  icon: Icons.save_alt_rounded,
                  label: 'Save Only',
                  isPrimary: false,
                  isLoading: isSaving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;

  const _ShareButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast =
        isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: accentContrast,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(accentContrast),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(textColor),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
    );
  }
}
