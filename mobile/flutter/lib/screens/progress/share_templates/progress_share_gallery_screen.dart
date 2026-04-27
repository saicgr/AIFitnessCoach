import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/share_service.dart';
import '../../../utils/image_capture_utils.dart';
import '../../../widgets/pill_app_bar.dart';
import 'progress_share_data.dart';
import 'progress_share_templates.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Gallery-style screen that shows every viral template at once so the
/// user can pick visually. Per user feedback (feedback_share_gallery_viral_templates):
/// all templates visible together, no blind-swipe carousel.
class ProgressShareGalleryScreen extends StatefulWidget {
  final ProgressShareData data;
  final String ctaText;
  /// If provided, opens directly into the preview for this template and
  /// skips the gallery grid. Used by the "Templates" strip thumbnails so
  /// tapping jumps straight to full-screen.
  final ProgressTemplateKind? initialKind;

  const ProgressShareGalleryScreen({
    super.key,
    required this.data,
    this.ctaText = 'START NOW',
    this.initialKind,
  });

  @override
  State<ProgressShareGalleryScreen> createState() => _ProgressShareGalleryScreenState();
}

class _ProgressShareGalleryScreenState extends State<ProgressShareGalleryScreen> {
  final Map<ProgressTemplateKind, GlobalKey> _captureKeys = {
    for (final k in ProgressTemplateKind.values) k: GlobalKey(),
  };
  bool _showWatermark = true;

  @override
  void initState() {
    super.initState();
    final kind = widget.initialKind;
    if (kind != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openPreview(kind);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PillAppBar(
        title: 'Share Your Transformation',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          PillAppBarAction(
            icon: _showWatermark ? Icons.branding_watermark_rounded : Icons.branding_watermark_outlined,
            onTap: () => setState(() => _showWatermark = !_showWatermark),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text('${ProgressTemplateKind.values.length} viral formats', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface,
            )),
            const Spacer(),
            Text('tap to open', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 9 / 16,
            ),
            itemCount: ProgressTemplateKind.values.length,
            itemBuilder: (_, i) {
              final kind = ProgressTemplateKind.values[i];
              return _GalleryTile(
                kind: kind,
                captureKey: _captureKeys[kind]!,
                template: _buildTemplate(kind, _showWatermark),
                onTap: () => _openPreview(kind),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildTemplate(ProgressTemplateKind kind, bool watermark) {
    switch (kind) {
      case ProgressTemplateKind.igStoryCta:
        return IgStoryCtaTemplate(data: widget.data, ctaText: widget.ctaText, showWatermark: watermark);
      case ProgressTemplateKind.wrapped:
        return WrappedTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.receipt:
        return ReceiptTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.tradingCard:
        return TradingCardTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.newspaper:
        return NewspaperTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.polaroidDiary:
        return PolaroidDiaryTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.magazineCover:
        return MagazineCoverTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.retro80s:
        return Retro80sTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.neonTabloid:
        return NeonTabloidTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.swissEditorial:
        return SwissEditorialTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.achievementUnlocked:
        return AchievementUnlockedTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.calendarGrid:
        return CalendarGridTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.progressBar:
        return ProgressBarTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.tapeMeasure:
        return TapeMeasureTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.transformationTuesday:
        return TransformationTuesdayTemplate(data: widget.data, showWatermark: watermark);
      case ProgressTemplateKind.timelineRuler:
        return TimelineRulerTemplate(data: widget.data, showWatermark: watermark);
    }
  }

  void _openPreview(ProgressTemplateKind kind) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _TemplatePreviewScreen(
        kind: kind,
        data: widget.data,
        ctaText: widget.ctaText,
        initialWatermark: _showWatermark,
      ),
    ));
  }
}

class _GalleryTile extends StatelessWidget {
  final ProgressTemplateKind kind;
  final GlobalKey captureKey;
  final Widget template;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.kind,
    required this.captureKey,
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(children: [
            Positioned.fill(
              child: RepaintBoundary(
                key: captureKey,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: kProgressShareCanvas.width,
                    height: kProgressShareCanvas.height,
                    child: template,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                  ),
                ),
                child: Row(children: [
                  Text(kind.label, style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                  )),
                  const Spacer(),
                  const Icon(Icons.open_in_full_rounded, color: Colors.white70, size: 14),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Full-screen preview with capture + share actions.
class _TemplatePreviewScreen extends StatefulWidget {
  final ProgressTemplateKind kind;
  final ProgressShareData data;
  final String ctaText;
  final bool initialWatermark;

  const _TemplatePreviewScreen({
    required this.kind,
    required this.data,
    required this.ctaText,
    required this.initialWatermark,
  });

  @override
  State<_TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends State<_TemplatePreviewScreen> {
  final GlobalKey _previewKey = GlobalKey();
  bool _isBusy = false;
  late bool _watermark = widget.initialWatermark;

  @override
  Widget build(BuildContext context) {
    final template = _buildTemplate();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PillAppBar(
        title: widget.kind.label,
        onBack: () => Navigator.pop(context),
        actions: [
          PillAppBarAction(
            icon: _watermark ? Icons.branding_watermark_rounded : Icons.branding_watermark_outlined,
            onTap: () => setState(() => _watermark = !_watermark),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _previewKey,
                child: SizedBox(
                  width: kProgressShareCanvas.width,
                  height: kProgressShareCanvas.height,
                  child: template,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
          child: Row(children: [
            Expanded(child: _btn('Save', Icons.save_alt_rounded, _save, isPrimary: false)),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: _btn('Share', Icons.share_rounded, _share, isPrimary: true)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTemplate() {
    switch (widget.kind) {
      case ProgressTemplateKind.igStoryCta:
        return IgStoryCtaTemplate(data: widget.data, ctaText: widget.ctaText, showWatermark: _watermark);
      case ProgressTemplateKind.wrapped:
        return WrappedTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.receipt:
        return ReceiptTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.tradingCard:
        return TradingCardTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.newspaper:
        return NewspaperTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.polaroidDiary:
        return PolaroidDiaryTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.magazineCover:
        return MagazineCoverTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.retro80s:
        return Retro80sTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.neonTabloid:
        return NeonTabloidTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.swissEditorial:
        return SwissEditorialTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.achievementUnlocked:
        return AchievementUnlockedTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.calendarGrid:
        return CalendarGridTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.progressBar:
        return ProgressBarTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.tapeMeasure:
        return TapeMeasureTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.transformationTuesday:
        return TransformationTuesdayTemplate(data: widget.data, showWatermark: _watermark);
      case ProgressTemplateKind.timelineRuler:
        return TimelineRulerTemplate(data: widget.data, showWatermark: _watermark);
    }
  }

  Future<Uint8List?> _capture() async {
    return ImageCaptureUtils.captureWidgetWithSize(
      _previewKey,
      width: ImageCaptureUtils.instagramStoriesSize.width,
      height: ImageCaptureUtils.instagramStoriesSize.height,
      pixelRatio: 1.0,
    );
  }

  Future<void> _share() async {
    if (_isBusy) return;
    HapticFeedback.mediumImpact();
    setState(() => _isBusy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) throw Exception('capture failed');
      await ShareService.shareGeneric(bytes, caption: 'My transformation · ${Branding.appName}');
    } catch (e) {
      if (mounted) _snack('Share failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _save() async {
    if (_isBusy) return;
    HapticFeedback.mediumImpact();
    setState(() => _isBusy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) throw Exception('capture failed');
      final res = await ShareService.saveToGallery(bytes);
      if (mounted) {
        if (res.success) {
          _snack('Saved to photos');
        } else {
          _snack(res.error ?? 'Save failed', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _snack('Save failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _snack(String m, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _btn(String label, IconData icon, VoidCallback onTap, {required bool isPrimary}) {
    final style = isPrimary
        ? FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        : OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
    final content = _isBusy
        ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
          )
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]);
    return isPrimary
        ? FilledButton(onPressed: _isBusy ? null : onTap, style: style, child: content)
        : OutlinedButton(onPressed: _isBusy ? null : onTap, style: style, child: content);
  }
}

