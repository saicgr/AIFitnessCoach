import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/share_service.dart';
import '../../../utils/image_capture_utils.dart';
import '../../../widgets/glass_sheet.dart';
import '../share_templates/_report_common.dart';
import '../share_templates/report_classic_template.dart';
import '../share_templates/report_minimal_template.dart';
import '../share_templates/report_newspaper_template.dart';
import '../share_templates/report_receipt_template.dart';
import '../share_templates/report_stat_grid_template.dart';
import '../share_templates/report_trading_card_template.dart';
import '../share_templates/report_wrapped_template.dart';

// Re-export the data types so callers only have to import this file.
export '../share_templates/_report_common.dart'
    show ReportShareData, ReportHighlight, ReportType;

/// Unified share sheet for every Report screen in the app.
///
/// Renders 7 gallery templates wrapped in `InstagramStoryWrapper` + captured
/// via `ImageCaptureUtils.captureWidgetWithSize()`. Every template owns a
/// `RepaintBoundary` so off-screen captures stay snappy.
///
/// Usage:
///
///   ReportShareSheet.show(context, data: ReportShareData(
///     reportType: ReportType.personalRecords,
///     title: 'Personal Records',
///     periodLabel: 'APR 2026',
///     primaryStats: {...},
///     highlights: [...],
///     accentColor: AccentColorScope.of(context).getColor(isDark),
///     userDisplayName: user.displayName,
///     deepLinkUrl: null, // omitted in this release → no "Copy link" button
///   ));
class ReportShareSheet extends ConsumerStatefulWidget {
  final ReportShareData data;

  const ReportShareSheet._({required this.data});

  /// Entry point — pops a bottom sheet styled to match the app's glass sheets.
  static Future<void> show(
    BuildContext context, {
    required ReportShareData data,
  }) async {
    await showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (_) => ReportShareSheet._(data: data),
    );
  }

  @override
  ConsumerState<ReportShareSheet> createState() => _ReportShareSheetState();
}

class _ReportShareSheetState extends ConsumerState<ReportShareSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSharing = false;
  bool _isSaving = false;
  bool _showWatermark = true;

  // One capture key per gallery template — see _TemplateSpec list.
  late final List<GlobalKey> _captureKeys;
  late final List<_TemplateSpec> _templates;

  @override
  void initState() {
    super.initState();
    _templates = _buildTemplates();
    _captureKeys = List.generate(_templates.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Ordered list of templates rendered in the gallery. Order is also the
  /// order of the bottom chip strip.
  List<_TemplateSpec> _buildTemplates() {
    return [
      _TemplateSpec(
        name: 'Classic',
        gradient: _accentBackdrop(0),
        builder: (d, w) => ReportClassicTemplate(data: d, showWatermark: w),
      ),
      _TemplateSpec(
        name: 'Wrapped',
        gradient: _accentBackdrop(1),
        builder: (d, w) => ReportWrappedTemplate(data: d, showWatermark: w),
      ),
      _TemplateSpec(
        name: 'Card',
        gradient: const [
          Color(0xFF05050A),
          Color(0xFF0A0A14),
          Color(0xFF05050A),
        ],
        builder: (d, w) =>
            ReportTradingCardTemplate(data: d, showWatermark: w),
      ),
      _TemplateSpec(
        name: 'Grid',
        gradient: _accentBackdrop(2),
        builder: (d, w) => ReportStatGridTemplate(data: d, showWatermark: w),
      ),
      _TemplateSpec(
        name: 'Receipt',
        gradient: const [
          Color(0xFF0F0F10),
          Color(0xFF1A1A1C),
          Color(0xFF0F0F10),
        ],
        builder: (d, w) => ReportReceiptTemplate(data: d, showWatermark: w),
      ),
      _TemplateSpec(
        name: 'News',
        gradient: const [
          Color(0xFF2A251C),
          Color(0xFF1F1B14),
          Color(0xFF2A251C),
        ],
        builder: (d, w) => ReportNewspaperTemplate(data: d, showWatermark: w),
      ),
      _TemplateSpec(
        name: 'Minimal',
        gradient: const [
          Color(0xFF0A0A0A),
          Color(0xFF050505),
          Color(0xFF000000),
        ],
        builder: (d, w) => ReportMinimalTemplate(data: d, showWatermark: w),
      ),
    ];
  }

  // Derive three accent-tinted backdrops so each template reads slightly
  // different even when they share the accent gradient pattern.
  List<Color> _accentBackdrop(int seed) {
    final a = widget.data.accentColor;
    switch (seed) {
      case 0:
        return [
          Color.lerp(a, Colors.black, 0.4)!,
          Color.lerp(a, Colors.black, 0.7)!,
          const Color(0xFF05050A),
        ];
      case 1:
        return [a, Color.lerp(a, Colors.black, 0.5)!, const Color(0xFF050505)];
      case 2:
      default:
        return [
          Color.lerp(a, Colors.black, 0.5)!,
          Color.lerp(a, Colors.black, 0.8)!,
          const Color(0xFF030308),
        ];
    }
  }

  Future<Uint8List?> _captureCurrentTemplate() async {
    return await ImageCaptureUtils.captureWidgetWithSize(
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
        await ShareService.saveToGallery(bytes);
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
        caption: 'My FitWiz ${widget.data.title} — ${widget.data.periodLabel}',
        subject: '${widget.data.title} — ${widget.data.periodLabel}',
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
      final saveResult = await ShareService.saveToGallery(bytes);
      if (!saveResult.success) {
        _showError(saveResult.error ?? 'Failed to save image');
        return;
      }
      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Saved to device!');
      }
    } catch (e) {
      _showError('Failed to save: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _copyLink() async {
    final url = widget.data.deepLinkUrl;
    // Guard — the button is only rendered when non-null, but keep the runtime
    // check so hot-reload or future callers can't silently swallow a null.
    if (url == null || url.isEmpty) return;
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) _showSuccess('Link copied to clipboard');
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
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final hasDeepLink =
        widget.data.deepLinkUrl != null && widget.data.deepLinkUrl!.isNotEmpty;

    return GlassSheet(
      maxHeightFraction: 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
                Text(
                  'Share ${widget.data.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Watermark toggle row.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.branding_watermark_rounded,
                  size: 18,
                  color: _showWatermark ? accent : Colors.grey,
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
                  activeTrackColor: accent,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
          ),
          // Template carousel.
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _templates.length,
              onPageChanged: (index) {
                HapticFeedback.selectionClick();
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final spec = _templates[index];
                return Center(
                  child: CapturableWidget(
                    captureKey: _captureKeys[index],
                    child: InstagramStoryWrapper(
                      backgroundGradient: spec.gradient,
                      child: spec.builder(widget.data, _showWatermark),
                    ),
                  ),
                );
              },
            ),
          ),
          // Template chip strip — horizontally scrollable for 7 templates.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_templates.length, (index) {
                  final isActive = _currentPage == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 12 : 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? accent
                            : (isDark
                                ? Colors.white12
                                : Colors.black.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _templates[index].name,
                        style: TextStyle(
                          color: isActive
                              ? (isDark
                                  ? AppColors.accentContrast
                                  : AppColorsLight.accentContrast)
                              : (isDark ? Colors.white70 : Colors.black54),
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Action buttons.
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              4,
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
                        onPressed: _shareToInstagram,
                        icon: Icons.camera_alt_rounded,
                        label: 'Instagram',
                        isPrimary: true,
                        isLoading: _isSharing,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ShareButton(
                        onPressed: _shareGeneric,
                        icon: Icons.share_rounded,
                        label: 'Share',
                        isPrimary: false,
                        isLoading: _isSharing,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ShareButton(
                        onPressed: _saveToGallery,
                        icon: Icons.save_alt_rounded,
                        label: 'Save',
                        isPrimary: false,
                        isLoading: _isSaving,
                      ),
                    ),
                    if (hasDeepLink) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ShareButton(
                          onPressed: _copyLink,
                          icon: Icons.link_rounded,
                          label: 'Copy link',
                          isPrimary: false,
                          isLoading: false,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of callable buttons at the bottom of the sheet.
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

    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? accentContrast : accent,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? accent
              : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
          foregroundColor: isPrimary
              ? accentContrast
              : (isDark ? Colors.white : Colors.black87),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}

/// Gallery entry — name, InstagramStoryWrapper background gradient, and a
/// builder that returns the template configured with current payload data.
class _TemplateSpec {
  final String name;
  final List<Color> gradient;
  final Widget Function(ReportShareData data, bool showWatermark) builder;

  const _TemplateSpec({
    required this.name,
    required this.gradient,
    required this.builder,
  });
}
