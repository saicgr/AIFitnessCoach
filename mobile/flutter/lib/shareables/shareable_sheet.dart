import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../data/providers/cosmetics_provider.dart';
import '../data/services/share_service.dart';
import '../utils/image_capture_utils.dart';
import '../widgets/glass_sheet.dart';
import 'shareable_canvas.dart';
import 'shareable_catalog.dart';
import 'shareable_data.dart';
import 'widgets/nested_pill_selector.dart';
import 'widgets/share_link_pill.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// THE unified share sheet. Every entry point in the app delegates to this
/// (Reports & Insights, Stats & Scores, Workout completion, Insights, Weekly
/// summary, Strength, Wrapped). Carries one `Shareable` payload built by
/// the appropriate adapter in `lib/shareables/adapters/`.
///
/// Behaviors specifically called out by the user:
///  - Eager-built gallery in a `Stack` + `Offstage` so capture never hits a
///    0×0 boundary (kills the "tap preview → grey/white screen" bug).
///  - 3-tier nested pill selector: aspect / subcategory / category.
///  - Disabled subcategory pills greyed (no fake data, no `--` placeholders).
///  - Single neutral charcoal canvas wrapper — per-template visuals come
///    from inside the template, not from arbitrary blue/orange tints.
class ShareableSheet extends ConsumerStatefulWidget {
  final Shareable data;
  final Future<String?> Function()? onGenerateShareLink;

  /// When provided, the sheet opens with this template pre-selected (and
  /// its category as the active pill) instead of the registry's first
  /// available template. Surface-specific entry points (weight log →
  /// Weight Trend, workout completion → Workout, etc.) use this so the
  /// gallery lands on the most relevant asset for where the user came
  /// from. Falls back to the first available template if the requested
  /// one isn't available for the current data.
  final ShareableTemplate? initialTemplate;

  const ShareableSheet._({
    required this.data,
    this.onGenerateShareLink,
    this.initialTemplate,
  });

  static Future<void> show(
    BuildContext context, {
    required Shareable data,
    Future<String?> Function()? onGenerateShareLink,
    ShareableTemplate? initialTemplate,
  }) async {
    await showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (_) => ShareableSheet._(
        data: data,
        onGenerateShareLink: onGenerateShareLink,
        initialTemplate: initialTemplate,
      ),
    );
  }

  @override
  ConsumerState<ShareableSheet> createState() => _ShareableSheetState();
}

class _ShareableSheetState extends ConsumerState<ShareableSheet> {
  late ShareableAspect _aspect;
  late ShareableCategory _category;
  late ShareableTemplate _template;
  bool _showWatermark = true;
  bool _isCapturing = false;
  String? _shareLink;
  bool _generatingLink = false;

  /// Text scaler applied to every Text inside the templates via a
  /// MediaQuery override. Default 1.5 — combined with the per-aspect
  /// `bodyFontMultiplier` baked into every template, this produces saved
  /// PNGs that read boldly at full output resolution without users
  /// having to crank the slider. Range 1.0×–2.0× in 6 stops; users
  /// who want minimal aesthetics can step down.
  double _textScale = 1.5;
  static const List<double> _textScaleStops = [
    1.0,
    1.2,
    1.4,
    1.6,
    1.8,
    2.0,
  ];

  /// Local state for user-uploaded backdrop photos. Photo-category
  /// templates render these full-bleed under a darkening scrim. Other
  /// templates simply ignore them.
  String? _customPhotoPath;
  String? _customPhotoPathSecondary;
  final ImagePicker _picker = ImagePicker();

  /// One capture key per template — keys are stable across rebuilds so
  /// the laid-out RenderRepaintBoundary persists.
  late final Map<ShareableTemplate, GlobalKey> _captureKeys;

  @override
  void initState() {
    super.initState();
    _aspect = widget.data.aspect;
    _captureKeys = {
      for (final spec in ShareableCatalog.all()) spec.template: GlobalKey(),
    };
    final available =
        ShareableCatalog.availableFor(widget.data, ownsCosmetic: _ownsElite);
    if (available.isEmpty) {
      // Defensive — adapter should already have returned null in this case
      // (entry point shows snackbar).
      _category = ShareableCategory.classic;
      _template = ShareableTemplate.minimal;
      return;
    }
    // Auto-select the template based on (in priority order):
    //   1. Caller-supplied initialTemplate (explicit override).
    //   2. Catalog's canonical hero template for `data.kind` — so weight
    //      log lands on Weight Trend, a finished workout lands on
    //      Workout Details, a streak share lands on Streak Fire, etc.,
    //      without callers needing to know which template fits.
    //   3. The registry's first available entry as the final fallback.
    final wantedExplicit = widget.initialTemplate;
    final wantedDefault =
        ShareableCatalog.defaultTemplateForKind(widget.data.kind);
    ShareableTemplateSpec? matched(ShareableTemplate? t) => t == null
        ? null
        : available
            .where((s) => s.template == t)
            .cast<ShareableTemplateSpec?>()
            .firstWhere((_) => true, orElse: () => null);
    final pick = matched(wantedExplicit) ??
        matched(wantedDefault) ??
        available.first;
    _category = pick.category.effective;
    _template = pick.template;
  }

  bool get _ownsElite => ref
      .read(cosmeticsProvider.select((s) => s.ownsCosmetic('stats_card_elite')));

  Shareable get _currentData => widget.data.copyWith(
        aspect: _aspect,
        customPhotoPath: _customPhotoPath,
        customPhotoPathSecondary: _customPhotoPathSecondary,
      );

  /// True for any Photo-category template — drives the inline upload
  /// affordance visibility. Conservative default: Photo templates carry
  /// a `photo` prefix in their enum name.
  bool get _isPhotoTemplate => _template.name.startsWith('photo');

  /// True for the before/after template, which needs two slots.
  bool get _isBeforeAfter => _template == ShareableTemplate.photoBeforeAfter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final showLinkPill =
        widget.data.kind == ShareableKind.workoutComplete &&
            widget.onGenerateShareLink != null;

    return GlassSheet(
      maxHeightFraction: 0.92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context),
          _watermarkRow(accent),
          _textScaleRow(accent),
          if (_isPhotoTemplate) _photoUploadRow(accent),
          Expanded(child: _gallery()),
          NestedPillSelector(
            data: _currentData,
            aspect: _aspect,
            category: _category,
            template: _template,
            ownsCosmetic: _ownsElite,
            onAspectChanged: (a) => setState(() => _aspect = a),
            onCategoryChanged: (c) {
              setState(() {
                _category = c;
                final inCat = ShareableCatalog.templatesInCategory(
                  _currentData,
                  c,
                  ownsCosmetic: _ownsElite,
                );
                if (inCat.isNotEmpty) _template = inCat.first.template;
              });
            },
            onTemplateChanged: (t) => setState(() => _template = t),
          ),
          if (showLinkPill)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ShareLinkPill(
                url: _shareLink,
                isGenerating: _generatingLink,
                onGenerate: _onGenerateLink,
              ),
            ),
          _actionRow(accent, isDark),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Text(
              'Share ${widget.data.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// If the share's accent is near-white (white workout shareable) we'd
  /// render an invisible Switch track. Detect low-chroma colors and swap
  /// in a guaranteed-vivid fallback (cyan).
  Color _switchTrackColor(Color a) {
    final r = a.r, g = a.g, b = a.b;
    final maxC = [r, g, b].reduce((x, y) => x > y ? x : y);
    final minC = [r, g, b].reduce((x, y) => x < y ? x : y);
    final chroma = maxC - minC;
    if (chroma < 0.08) return const Color(0xFF06B6D4); // cyan fallback
    return a;
  }

  Widget _watermarkRow(Color accent) {
    return Padding(
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
            onChanged: (v) {
              HapticFeedback.lightImpact();
              setState(() => _showWatermark = v);
            },
            // When the share's accent is near-white (default workout share)
            // we'd render an invisible track. Force a vivid track and use a
            // high-contrast thumb regardless of accent.
            activeTrackColor: _switchTrackColor(accent),
            activeThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.55),
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) => Colors.white.withValues(alpha: 0.20),
            ),
          ),
        ],
      ),
    );
  }

  /// Discrete font-scale stepper — bumps every Text in the template via
  /// a MediaQuery TextScaler override. Doesn't require any per-template
  /// changes; templates that use `Text` honor the scaler automatically.
  Widget _textScaleRow(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.format_size_rounded, size: 18, color: accent),
          const SizedBox(width: 8),
          const Text('Font size',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Smaller',
            onPressed: _textScale <= _textScaleStops.first
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    final i = _textScaleStops.indexOf(_textScale);
                    setState(() {
                      _textScale = _textScaleStops[
                          (i - 1).clamp(0, _textScaleStops.length - 1)];
                    });
                  },
            icon: const Icon(Icons.remove_rounded, size: 20),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${(_textScale * 100).round()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Larger',
            onPressed: _textScale >= _textScaleStops.last
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    final i = _textScaleStops.indexOf(_textScale);
                    setState(() {
                      _textScale = _textScaleStops[
                          (i + 1).clamp(0, _textScaleStops.length - 1)];
                    });
                  },
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  /// Inline photo-upload row for Photo-category templates. Shows a single
  /// "Upload Photo" chip for most photo templates; before/after shows
  /// two slots. Once a photo is selected, the chip morphs to the
  /// filename + ✕ remove affordance.
  Widget _photoUploadRow(Color accent) {
    if (_isBeforeAfter) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: _photoChip(
                accent: accent,
                label: 'Before',
                path: _customPhotoPath,
                onPick: () => _pickPhoto(secondary: false),
                onClear: () => setState(() => _customPhotoPath = null),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _photoChip(
                accent: accent,
                label: 'After',
                path: _customPhotoPathSecondary,
                onPick: () => _pickPhoto(secondary: true),
                onClear: () =>
                    setState(() => _customPhotoPathSecondary = null),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _photoChip(
            accent: accent,
            label: 'Upload Photo',
            path: _customPhotoPath,
            onPick: () => _pickPhoto(secondary: false),
            onClear: () => setState(() => _customPhotoPath = null),
          ),
        ],
      ),
    );
  }

  Widget _photoChip({
    required Color accent,
    required String label,
    required String? path,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final picked = path != null && path.isNotEmpty;
    return Material(
      color: picked
          ? accent.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.06),
      shape: StadiumBorder(
        side: BorderSide(
          color: picked ? accent : Colors.white24,
          width: 1.2,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: picked ? null : onPick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                picked
                    ? Icons.check_circle_rounded
                    : Icons.photo_camera_outlined,
                size: 16,
                color: picked ? accent : Colors.white70,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  picked ? '$label · selected' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: picked ? accent : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (picked) ...[
                const SizedBox(width: 6),
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onClear();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto({required bool secondary}) async {
    HapticFeedback.lightImpact();
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2160,
        maxHeight: 2160,
        imageQuality: 92,
      );
      if (picked == null || !mounted) return;
      setState(() {
        if (secondary) {
          _customPhotoPathSecondary = picked.path;
        } else {
          _customPhotoPath = picked.path;
        }
      });
    } catch (e) {
      debugPrint('❌ [ShareableSheet] photo pick failed: $e');
      if (mounted) _toast('Couldn\'t open photo library');
    }
  }

  /// **Eager build** — every available template renders into the widget
  /// tree immediately. The active one is on top via `IndexedStack`; the
  /// others sit `Offstage` but still get a layout pass, so their
  /// RepaintBoundaries are real and capture works on first tap.
  ///
  /// This is the fix for the white-screen-on-preview bug. The old sheet
  /// used `PageView.builder` which lazy-builds pages, so capturing before
  /// the page was scrolled into view returned a 0×0 boundary, then the
  /// preview dialog rendered an empty image.
  Widget _gallery() {
    final available =
        ShareableCatalog.availableFor(_currentData, ownsCosmetic: _ownsElite);
    if (available.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'Not enough data yet — try again after your next workout',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    final activeIndex =
        available.indexWhere((s) => s.template == _template).clamp(0, available.length - 1);

    return GestureDetector(
      onTap: _onPreviewTapped,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        // Templates use absolute pixel sizes (e.g. 88pt top padding,
        // 96pt hero numbers) tuned for the full output canvas (1080×
        // 1920 / 1080×1350 / 1080×1080). Rendering them at preview
        // size (~340pt wide) makes the padding eat the whole canvas,
        // overflowing the inner Column by hundreds of pixels.
        //
        // Solution: lay the IndexedStack out at its DESIGN size, then
        // scale the whole thing down with FittedBox for display. The
        // inner RepaintBoundaries see the full design size, so the
        // existing capture pipeline (pixelRatio = target/boundary)
        // still produces a crisp 1080-wide PNG with zero quality loss.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final designSize = _aspect.size; // 1080×1920 / 1080×1350 …
            final ratio = _aspect.ratio;
            var w = constraints.maxWidth;
            var h = w / ratio;
            if (h > constraints.maxHeight) {
              h = constraints.maxHeight;
              w = h * ratio;
            }
            return Center(
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  children: [
                    FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: designSize.width,
                        height: designSize.height,
                        // Apply the user-controlled font scale via a
                        // MediaQuery override. Templates pick this up
                        // automatically through their Text widgets, so
                        // no per-template plumbing is needed.
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(_textScale),
                          ),
                          child: ClipRect(
                            child: IndexedStack(
                              index: activeIndex,
                              sizing: StackFit.expand,
                              children: [
                                for (final spec in available)
                                  RepaintBoundary(
                                    key: _captureKeys[spec.template],
                                    child:
                                        spec.builder(_currentData, _showWatermark),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Maximize-to-zoom affordance — surfaces the
                    // tap-to-expand gesture so users know they can
                    // pinch-zoom the preview in a full-screen viewer.
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _onPreviewTapped,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.zoom_out_map_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _actionRow(Color accent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isCapturing ? null : _onShareInstagram,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Instagram'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: accent,
                foregroundColor:
                    isDark ? AppColors.accentContrast : AppColorsLight.accentContrast,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isCapturing ? null : _onShareGeneric,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            onPressed: _isCapturing ? null : _onSave,
            icon: const Icon(Icons.save_alt_rounded),
            tooltip: 'Save to gallery',
          ),
        ],
      ),
    );
  }

  Future<void> _onPreviewTapped() async {
    HapticFeedback.lightImpact();
    final bytes = await _captureWithGuard();
    if (!mounted || bytes == null) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (_) => _PreviewDialog(bytes: bytes),
    );
  }

  Future<void> _onShareInstagram() async {
    if (_isCapturing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isCapturing = true);
    try {
      // Stories require 9:16 — auto-snap aspect for capture.
      final captured =
          await _captureForAspect(ShareableAspect.story, recapture: true);
      if (captured == null) {
        _toast('Couldn\'t render preview — try another template');
        return;
      }
      final result = await ShareService.shareToInstagramStories(captured);
      if (result.success) {
        await ShareService.saveToGallery(captured);
        if (mounted) Navigator.pop(context);
      } else if (result.error != null) {
        _toast('Could not open Instagram');
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _onShareGeneric() async {
    if (_isCapturing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isCapturing = true);
    try {
      final bytes = await _captureWithGuard();
      if (bytes == null) {
        _toast('Couldn\'t render preview — try another template');
        return;
      }
      await ShareService.shareGeneric(
        bytes,
        caption: 'My ${Branding.appName} ${widget.data.title}',
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _onSave() async {
    if (_isCapturing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isCapturing = true);
    try {
      final bytes = await _captureWithGuard();
      if (bytes == null) {
        _toast('Couldn\'t render preview — try another template');
        return;
      }
      final result = await ShareService.saveToGallery(bytes);
      if (mounted) {
        if (result.success) {
          Navigator.pop(context);
          _toast('Saved to device');
        } else {
          _toast(result.error ?? 'Failed to save');
        }
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _onGenerateLink() async {
    if (_generatingLink || widget.onGenerateShareLink == null) return;
    setState(() => _generatingLink = true);
    try {
      final url = await widget.onGenerateShareLink!();
      if (!mounted) return;
      setState(() => _shareLink = url);
      if (url != null) {
        await Clipboard.setData(ClipboardData(text: url));
        _toast('Link copied');
      }
    } finally {
      if (mounted) setState(() => _generatingLink = false);
    }
  }

  /// Capture the active template at its current aspect. Adds a frame-await
  /// guard so the first tap doesn't hit a 0×0 boundary on a freshly-mounted
  /// template (Fix #11).
  Future<Uint8List?> _captureWithGuard() async {
    return _captureForAspect(_aspect);
  }

  Future<Uint8List?> _captureForAspect(
    ShareableAspect aspect, {
    bool recapture = false,
  }) async {
    if (recapture) {
      final prev = _aspect;
      setState(() => _aspect = aspect);
      await WidgetsBinding.instance.endOfFrame;
      final bytes = await _captureKey(_captureKeys[_template]!, aspect);
      if (mounted) setState(() => _aspect = prev);
      return bytes;
    }
    return _captureKey(_captureKeys[_template]!, aspect);
  }

  Future<Uint8List?> _captureKey(GlobalKey key, ShareableAspect aspect) async {
    try {
      // Up to 2 attempts — the first frame after a template switch may not
      // have laid out yet.
      for (var attempt = 0; attempt < 2; attempt++) {
        await WidgetsBinding.instance.endOfFrame;
        final boundary = key.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          continue;
        }
        final size = boundary.size;
        if (size.width == 0 || size.height == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          continue;
        }
        final target = aspect.size;
        final scaleX = target.width / size.width;
        final scaleY = target.height / size.height;
        final scale = scaleX < scaleY ? scaleX : scaleY;
        final image = await boundary.toImage(pixelRatio: scale);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ShareableSheet] capture failed: $e');
      return null;
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PreviewDialog extends StatelessWidget {
  final Uint8List bytes;
  const _PreviewDialog({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          // The image itself — InteractiveViewer handles pinch + drag
          // zoom (up to 5×). Tap outside the image is NOT tap-to-close
          // anymore (would hijack pinch); the explicit close button
          // below replaces that.
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
          // Pinch-to-zoom hint chip at the top.
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pinch_rounded,
                        size: 14, color: Colors.white70),
                    SizedBox(width: 6),
                    Text(
                      'Pinch to zoom · double-tap to reset',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Close button.
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep this referenced so analyzer doesn't drop the import — capture sizes
// stay aligned with `ShareableAspect.size`.
// ignore: unused_element
final _kSizeRef = ImageCaptureUtils.captureSizeForAspectTag;
// ignore: unused_element
final _kCanvasRef = ShareableCanvas.neutralCharcoal;
