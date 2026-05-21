import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../core/constants/app_colors.dart';
import '../data/providers/cosmetics_provider.dart';
import '../data/services/share_service.dart';
import '../utils/image_capture_utils.dart';
import '../widgets/glass_sheet.dart';
import 'recent_templates_store.dart';
import 'shareable_canvas.dart';
import 'shareable_catalog.dart';
import 'editor/food_editor_screen.dart';
import 'editor/food_montage_screen.dart';
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

enum _GallerySort {
  defaultOrder('Default'),
  recents('Recents'),
  favorites('Favorites');

  final String label;
  const _GallerySort(this.label);
}

class _ShareableSheetState extends ConsumerState<ShareableSheet> {
  late ShareableAspect _aspect;
  late ShareableCategory _category;
  late ShareableTemplate _template;
  bool _showWatermark = true;

  /// Canvas background mode — themed (default) / dark / light / transparent.
  /// Read by every template's [ShareableCanvas] via the [ShareSurface]
  /// inherited widget the preview + gallery wrap their builds in.
  ShareBackground _background = ShareBackground.themed;

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

  /// User-picked clip for [ShareBackground.video]. The captured card is a
  /// transparent sticker; Instagram composites this video behind it. Only
  /// the preview pane plays it (one controller — gallery tiles don't).
  String? _videoPath;
  VideoPlayerController? _videoController;

  /// One capture key per template — keys are stable across rebuilds so
  /// the laid-out RenderRepaintBoundary persists.
  late final Map<ShareableTemplate, GlobalKey> _captureKeys;

  /// Resolves once every network food photo has been pre-decoded. The
  /// capture path awaits this so `toImage` snapshots the real photo, not a
  /// half-loaded blank. Null when the share carries no network food images.
  Future<void>? _warmImagesFuture;

  /// Recently-used template IDs (most recent first, max 5). Loaded from
  /// SharedPreferences on init, updated on every template selection.
  /// Drives the `RECENT` badge in the thumbnail strip + lets the sheet
  /// preselect the user's last-picked template on open.
  List<String> _recentTemplateIds = const [];

  /// Gallery sort affordance — surfaces in `_galleryHeaderRow`. "Recents"
  /// floats most-recently-shared templates to the top, "Favorites" floats
  /// the user's pinned favorites. Default keeps the catalog order.
  _GallerySort _gallerySort = _GallerySort.defaultOrder;

  @override
  void initState() {
    super.initState();
    _aspect = widget.data.aspect;
    _captureKeys = {
      for (final spec in ShareableCatalog.all()) spec.template: GlobalKey(),
    };
    // Pre-decode network food photos so the first capture isn't blank.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _warmFoodImages();
    });
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

    // Async-load recents and, when no explicit override is supplied,
    // prefer the user's last-picked template if it's still available.
    // Falls through to the existing pick when the recents list is empty
    // or stale.
    _loadRecents(
      respectExplicit: wantedExplicit != null,
      available: available,
    );
  }

  Future<void> _loadRecents({
    required bool respectExplicit,
    required List<ShareableTemplateSpec> available,
  }) async {
    final ids = await RecentTemplatesStore.load();
    if (!mounted) return;
    if (respectExplicit || ids.isEmpty) {
      // Just store the list for the badge UI; don't override the pick.
      setState(() => _recentTemplateIds = ids);
      return;
    }
    // Walk the recents list in order; first one available for current
    // data wins. If none match, leave the existing pick alone.
    ShareableTemplateSpec? recentPick;
    for (final id in ids) {
      final match = available.where((s) => s.template.name == id);
      if (match.isNotEmpty) {
        recentPick = match.first;
        break;
      }
    }
    setState(() {
      _recentTemplateIds = ids;
      if (recentPick != null) {
        _category = recentPick.category.effective;
        _template = recentPick.template;
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _recordTemplateUsed(ShareableTemplate t) {
    // Local optimistic update so the badge re-paints instantly.
    final next = <String>[
      t.name,
      ..._recentTemplateIds.where((id) => id != t.name),
    ].take(5).toList();
    setState(() => _recentTemplateIds = next);
    // Persist async (fire-and-forget — non-fatal on failure).
    RecentTemplatesStore.recordUsed(t.name);
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
          // Preview moved to the TOP so the user sees their current pick
          // first; all configuration controls (watermark, font, aspect,
          // category, photo) sit below it. This frees ~80-120px for the
          // gallery `Expanded` below to render one extra row of thumbnails.
          _previewPane(accent, isDark),
          // Watermark + font size merged into one inline row. Wins ~48px
          // of vertical space vs the previous two-row layout.
          _inlineControlsRow(accent),
          _backgroundRow(accent, isDark),
          if (_background == ShareBackground.video) _videoRow(accent),
          if (_isPhotoTemplate) _photoUploadRow(accent),
          NestedPillSelector(
            data: _currentData,
            aspect: _aspect,
            category: _category,
            template: _template,
            ownsCosmetic: _ownsElite,
            recentTemplateIds: _recentTemplateIds,
            showWatermark: _showWatermark,
            onAspectChanged: (a) => setState(() => _aspect = a),
            onCategoryChanged: (c) {
              setState(() {
                _category = c;
                final inCat = ShareableCatalog.templatesInCategory(
                  _currentData,
                  c,
                  ownsCosmetic: _ownsElite,
                );
                if (inCat.isNotEmpty) {
                  _template = inCat.first.template;
                }
              });
              // NOTE: _recordTemplateUsed intentionally NOT called here.
              // Browsing categories must not mark templates as RECENT —
              // user complaint: "clicking everything is showing as recent".
              // RECENT is now stamped only on actual share-success
              // (_onShareInstagram / _onShareGeneric / _onSave / _onPreviewTapped).
            },
            onTemplateChanged: (t) {
              setState(() => _template = t);
              // Same — only stamp on share success, not on browse tap.
            },
          ),
          _galleryHeaderRow(accent, isDark),
          Expanded(child: _gallery()),
          if (showLinkPill)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ShareLinkPill(
                url: _shareLink,
                isGenerating: _generatingLink,
                onGenerate: _onGenerateLink,
              ),
            ),
          if (widget.data.kind == ShareableKind.foodLog)
            _customizeRow(accent),
          _actionRow(accent, isDark),
          // Bottom spacer — use the device safe-area inset, but never less
          // than 8px (older devices report padding.bottom == 0 and the
          // action buttons would otherwise touch the screen edge).
          SizedBox(
            height: MediaQuery.of(context).padding.bottom > 8
                ? MediaQuery.of(context).padding.bottom
                : 8,
          ),
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

  /// Merged watermark toggle + font-size stepper on a single row. Replaces
  /// the previous two-row layout (watermark above, font size below) so the
  /// gallery `Expanded` below the controls gets a full extra row of space.
  Widget _inlineControlsRow(Color accent) {
    final canShrink = _textScale > _textScaleStops.first;
    final canGrow = _textScale < _textScaleStops.last;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          // Watermark — compact: icon + adaptive switch. The text label is
          // dropped to fit the row; semantic label preserved for screen
          // readers via Semantics + Tooltip for the long-press hint.
          Tooltip(
            message: 'Show watermark',
            child: Semantics(
              label: 'Show watermark',
              toggled: _showWatermark,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.branding_watermark_rounded,
                    size: 18,
                    color: _showWatermark ? accent : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Switch.adaptive(
                    value: _showWatermark,
                    onChanged: (v) {
                      HapticFeedback.lightImpact();
                      setState(() => _showWatermark = v);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            ),
          ),
          const Spacer(),
          // Font size stepper.
          Icon(Icons.format_size_rounded, size: 18, color: accent),
          const SizedBox(width: 4),
          Semantics(
            label: 'Decrease font size',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Smaller',
              onPressed: !canShrink
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      final i = _textScaleStops.indexOf(_textScale);
                      setState(() {
                        _textScale = _textScaleStops[
                            (i - 1).clamp(0, _textScaleStops.length - 1)];
                      });
                    },
              icon: const Icon(Icons.remove_rounded, size: 18),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${(_textScale * 100).round()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Semantics(
            label: 'Increase font size',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Larger',
              onPressed: !canGrow
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      final i = _textScaleStops.indexOf(_textScale);
                      setState(() {
                        _textScale = _textScaleStops[
                            (i + 1).clamp(0, _textScaleStops.length - 1)];
                      });
                    },
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// Background-mode selector — Themed / Dark / Light / Transparent.
  /// Mirrors Hevy's background picker. Themed keeps each template's
  /// signature gradient; Light/Transparent inset the template as a rounded
  /// card; Transparent exports an alpha PNG you can drop onto a photo or
  /// story as a sticker. Uses a [Wrap] so the four chips never overflow on
  /// a narrow phone.
  Widget _backgroundRow(Color accent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final mode in ShareBackground.values)
            _bgChip(mode, accent, isDark),
        ],
      ),
    );
  }

  Widget _bgChip(ShareBackground mode, Color accent, bool isDark) {
    final selected = _background == mode;
    final mutedBorder =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.14);
    final fg = selected
        ? accent
        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _background = mode);
        // Selecting Video with no clip yet jumps straight to the picker.
        if (mode == ShareBackground.video && _videoPath == null) {
          _pickVideo();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isDark ? 0.16 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : mutedBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BgSwatch(mode: mode, accent: accent),
            const SizedBox(width: 6),
            Text(
              mode.label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
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
    // Theme-aware: previously hardcoded `Colors.white70` text on
    // `Colors.white.withValues(alpha:0.06)` background was invisible against
    // light bg in light mode (user complaint: "I do not see the texts and
    // same with before and after").
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unpickedFg = isDark
        ? Colors.white70
        : Colors.black.withValues(alpha: 0.75);
    final unpickedBorder = isDark
        ? Colors.white24
        : Colors.black.withValues(alpha: 0.18);
    final unpickedBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    return Material(
      color: picked
          ? accent.withValues(alpha: isDark ? 0.18 : 0.12)
          : unpickedBg,
      shape: StadiumBorder(
        side: BorderSide(
          color: picked ? accent : unpickedBorder,
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
                color: picked ? accent : unpickedFg,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  picked ? '$label · selected' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: picked ? accent : unpickedFg,
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

  Future<void> _pickVideo() async {
    HapticFeedback.lightImpact();
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked == null || !mounted) return;
      await _videoController?.dispose();
      final controller = VideoPlayerController.file(File(picked.path));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _videoPath = picked.path;
        _videoController = controller;
      });
    } catch (e) {
      debugPrint('❌ [ShareableSheet] video pick failed: $e');
      if (mounted) _toast('Couldn\'t open that video');
    }
  }

  void _clearVideo() {
    _videoController?.dispose();
    setState(() {
      _videoController = null;
      _videoPath = null;
    });
  }

  /// Video-background picker row — shown only while the Video background
  /// mode is active. Reuses the photo-chip styling.
  Widget _videoRow(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _photoChip(
            accent: accent,
            label: _videoPath == null ? 'Choose video background' : 'Video',
            path: _videoPath,
            onPick: _pickVideo,
            onClear: _clearVideo,
          ),
        ],
      ),
    );
  }

  /// **Vertical scrollable gallery** — every available template renders as
  /// a real preview tile in a ListView, all visible at once via scrolling.
  /// Replaces the previous `IndexedStack` carousel pattern that only showed
  /// one template at a time and required pill navigation to switch.
  ///
  /// Per project memory `feedback_share_gallery_viral_templates.md`:
  ///   "Share UIs — use a gallery (all visible at once), not a carousel.
  ///    Default to 15+ viral formats."
  ///
  /// Each tile keeps the same `RepaintBoundary(key: _captureKeys[template])`
  /// wrapper so the capture pipeline (which keys by template enum) keeps
  /// working — the keyed boundary just lives inside a tile in the list
  /// instead of inside an IndexedStack child. Because every tile is in the
  /// tree AND visible (vs the old Offstage trick), the white-screen-on-
  /// first-capture bug is also gone — RepaintBoundaries always have real
  /// pixels.
  ///
  /// The tile that matches `_template` gets an accent border + ~1.04x scale
  /// so the user sees clearly which one the action buttons (Instagram /
  /// Share / Save) will target.
  /// Live preview of the currently-selected template at the active
  /// aspect ratio. Sits above the gallery — tapping any tile in the
  /// gallery updates this pane (and vice-versa). Replaces the old
  /// horizontal subcategory thumbnail strip, which duplicated the
  /// gallery and gave no real preview affordance.
  Widget _previewPane(Color accent, bool isDark) {
    final spec = ShareableCatalog.all()
        .cast<ShareableTemplateSpec?>()
        .firstWhere((s) => s?.template == _template, orElse: () => null);
    if (spec == null) return const SizedBox.shrink();
    final designSize = _aspect.size;
    final ratio = _aspect.ratio; // width / height
    // Cap the preview height so the gallery still has room. Tall 9:16
    // aspect uses ~38% of the sheet, square/4:5 uses less.
    final mq = MediaQuery.of(context);
    final maxH = mq.size.height * (ratio < 0.7 ? 0.32 : 0.26);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: AspectRatio(
            aspectRatio: ratio,
            child: GestureDetector(
              onTap: _onPreviewTapped,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video background — only the preview plays the clip;
                    // the captured sticker stays transparent so Instagram
                    // composites the real video behind it.
                    if (_background == ShareBackground.video &&
                        _videoController != null &&
                        _videoController!.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: designSize.width,
                        height: designSize.height,
                        child: MediaQuery(
                          data: mq.copyWith(
                            textScaler: TextScaler.linear(_textScale),
                          ),
                          child: ShareSurface(
                            background: _background,
                            child:
                                spec.builder(_currentData, _showWatermark),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Row above the gallery — count of available templates + a Sort
  /// dropdown (Default / Recents / Favorites). Mirrors the
  /// progress_share_gallery_screen.dart layout the user referenced.
  Widget _galleryHeaderRow(Color accent, bool isDark) {
    final inCategory = ShareableCatalog.templatesInCategory(
      _currentData,
      _category,
      ownsCosmetic: _ownsElite,
    );
    final textMuted = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            '${inCategory.length} viral formats',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          PopupMenuButton<_GallerySort>(
            initialValue: _gallerySort,
            tooltip: 'Sort',
            position: PopupMenuPosition.under,
            onSelected: (v) => setState(() => _gallerySort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _GallerySort.defaultOrder,
                child: Text('Default'),
              ),
              PopupMenuItem(
                value: _GallerySort.recents,
                child: Text('Recents first'),
              ),
              PopupMenuItem(
                value: _GallerySort.favorites,
                child: Text('Favorites first'),
              ),
            ],
            child: Row(
              children: [
                Icon(Icons.sort_rounded, size: 16, color: textMuted),
                const SizedBox(width: 4),
                Text(
                  _gallerySort.label,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                Icon(Icons.arrow_drop_down_rounded, size: 18, color: textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gallery() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Gallery RESPECTS the category pill at the bottom — narrows to the
    // currently-selected category so the scrollable list stays manageable
    // (Cards: ~6 / Editorial: ~7 / Rich: ~8 / etc) instead of dumping all
    // 30+ templates in one stream. The aspect-ratio pill still controls
    // the canvas size globally. Recently-used templates float to the top
    // of whichever category they belong to so the user re-finds them fast.
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
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final inCategory = ShareableCatalog.templatesInCategory(
      _currentData,
      _category,
      ownsCosmetic: _ownsElite,
    );
    // Sort honors the gallery sort dropdown:
    //   Default  → catalog order
    //   Recents  → recently-shared first, then catalog order
    //   Favorites→ same as Recents until we wire a real favorites store
    //              (catalog has no favorite flag yet; using recents is a
    //              meaningful proxy and avoids leaving the affordance dead).
    final recentSet = _recentTemplateIds.toSet();
    List<ShareableTemplateSpec> sorted;
    if (_gallerySort == _GallerySort.defaultOrder) {
      sorted = inCategory;
    } else {
      sorted = <ShareableTemplateSpec>[
        ...inCategory.where((s) => recentSet.contains(s.template.name)),
        ...inCategory.where((s) => !recentSet.contains(s.template.name)),
      ];
    }
    final renderList = sorted.isEmpty ? available : sorted;

    final accent = _currentData.accentColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 4-column grid matches the onboarding `workout_showcase_screen.dart`
          // demo layout — a true gallery where the user sees a row of
          // previews at a glance instead of two giant scrollable tiles.
          // Per-tile zoom button (top-right) opens the full-screen preview
          // viewer; tapping the tile body just selects it as the active
          // template (the one the action buttons target).
          final designSize = _aspect.size;
          final ratio = _aspect.ratio; // width / height
          const cols = 4;
          const spacing = 8.0;
          final tileW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
          final tileH = tileW / ratio;

          return GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              // Add a hair of headroom for the RECENT badge / label so the
              // tile content doesn't clip.
              childAspectRatio: ratio * 0.97,
            ),
            itemCount: renderList.length,
            itemBuilder: (ctx, i) {
              final spec = renderList[i];
              final isActive = spec.template == _template;
              final isRecent = recentSet.contains(spec.template.name);
              final tileScale = isActive ? 1.0 : 0.96;
              return Padding(
                padding: EdgeInsets.zero,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _template = spec.template);
                  },
                  // Long-press = expand to full-screen preview viewer
                  // (replaces the previous tap-to-zoom corner button).
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _template = spec.template);
                    _onPreviewTapped();
                  },
                  child: AnimatedScale(
                    scale: tileScale,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isActive
                              ? accent
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06)),
                          width: isActive ? 2.4 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: tileW,
                        height: tileH,
                        child: Stack(
                          children: [
                            FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: designSize.width,
                                height: designSize.height,
                                child: MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    textScaler: TextScaler.linear(_textScale),
                                  ),
                                  child: ShareSurface(
                                    background: _background,
                                    child: RepaintBoundary(
                                      key: _captureKeys[spec.template],
                                      child: spec.builder(
                                          _currentData, _showWatermark),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Template-name label — sized down for the
                            // 4-up grid so it doesn't crowd the preview.
                            Positioned(
                              left: 4,
                              right: 4,
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  spec.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            // RECENT pill — top-left to leave the top-right
                            // corner free for the zoom affordance.
                            if (isRecent)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '•',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            // Zoom icon — top-right. Tap = expand THIS tile
                            // (without committing it as the action target).
                            // Discoverable affordance the user explicitly asked
                            // for in the gallery review (#5).
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _template = spec.template);
                                  _onPreviewTapped();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.zoom_out_map_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Food-share extras: the layer editor (draggable text / stickers / GIFs /
  /// macro overlays on the photo) and, when the share has 2+ photos, a
  /// montage-video export.
  Widget _customizeRow(Color accent) {
    final photoCount = widget.data.foodImageUrls?.length ?? 0;
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(44),
      foregroundColor: accent,
      side: BorderSide(color: accent.withValues(alpha: 0.5)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => FoodEditorScreen.open(context, _currentData),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Customize'),
              style: style,
            ),
          ),
          if (photoCount >= 2) ...[
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    FoodMontageScreen.open(context, _currentData),
                icon: const Icon(Icons.movie_creation_rounded, size: 18),
                label: const Text('Video'),
                style: style,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionRow(Color accent, bool isDark) {
    // Tightened vertical padding: was (8, 8); now (4, 0). The bottom
    // safe-area SizedBox already handles the home-indicator gap, so this
    // padding shouldn't add another ~16px on top.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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
    // Video mode needs a clip before there's anything to share.
    if (_background == ShareBackground.video && _videoPath == null) {
      _toast('Choose a video background first');
      return;
    }
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
      final isVideo =
          _background == ShareBackground.video && _videoPath != null;
      final ShareResult result;
      if (isVideo) {
        // `captured` is a transparent sticker (video canvas mode); the
        // clip becomes the story background, composited by Instagram.
        result = await ShareService.shareVideoToInstagramStories(
          videoPath: _videoPath!,
          stickerBytes: captured,
        );
      } else {
        result = await ShareService.shareToInstagramStories(captured);
      }
      if (result.success) {
        // A still card is also dropped in the gallery; a video-mode capture
        // is just a transparent sticker, so skip the gallery copy there.
        if (!isVideo) await ShareService.saveToGallery(captured);
        // Only mark as RECENT after a SUCCESSFUL share — not on browse tap.
        _recordTemplateUsed(_template);
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
      // Mark RECENT on successful generic share too.
      _recordTemplateUsed(_template);
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
          // Mark RECENT on successful save-to-gallery (saving counts as
          // intentional use, same as Instagram or generic share).
          _recordTemplateUsed(_template);
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
    // In video mode the card renders as a transparent sticker (Instagram
    // composites the clip behind it). A plain Save / system-share wants a
    // finished still though — so capture those on a solid dark surface
    // instead of handing back a transparent PNG.
    if (_background == ShareBackground.video) {
      final prev = _background;
      setState(() => _background = ShareBackground.dark);
      await WidgetsBinding.instance.endOfFrame;
      final bytes = await _captureForAspect(_aspect);
      if (mounted) setState(() => _background = prev);
      return bytes;
    }
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

  /// Pre-decode every network food photo referenced by the payload so the
  /// `RepaintBoundary.toImage` snapshot captures the actual image rather
  /// than a half-loaded blank (`toImage` paints only decoded pixels).
  void _warmFoodImages() {
    final urls = <String>{
      ...?widget.data.foodImageUrls,
      if (widget.data.customPhotoPath != null) widget.data.customPhotoPath!,
      if (widget.data.heroImageUrl != null) widget.data.heroImageUrl!,
    }.where((u) => u.startsWith('http')).toList();
    if (urls.isEmpty) return;
    _warmImagesFuture = Future.wait(
      urls.map(
        (u) => precacheImage(NetworkImage(u), context).catchError((_) {}),
      ),
    );
  }

  Future<Uint8List?> _captureKey(GlobalKey key, ShareableAspect aspect) async {
    try {
      // Make sure network food photos are decoded before snapshotting —
      // `toImage` captures painted pixels only.
      if (_warmImagesFuture != null) {
        await _warmImagesFuture;
      }
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
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

/// 16×16 swatch previewing a [ShareBackground] mode inside a picker chip.
class _BgSwatch extends StatelessWidget {
  final ShareBackground mode;
  final Color accent;

  const _BgSwatch({required this.mode, required this.accent});

  @override
  Widget build(BuildContext context) {
    const size = 16.0;
    final radius = BorderRadius.circular(5);
    switch (mode) {
      case ShareBackground.themed:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, Color.lerp(accent, Colors.black, 0.55)!],
            ),
          ),
        );
      case ShareBackground.dark:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: const Color(0xFF0B0B0D),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
        );
      case ShareBackground.light:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: const Color(0xFFF4F5F7),
            border: Border.all(color: Colors.black.withValues(alpha: 0.20)),
          ),
        );
      case ShareBackground.transparent:
        return ClipRRect(
          borderRadius: radius,
          child: CustomPaint(
            size: const Size(size, size),
            painter: _CheckerPainter(),
          ),
        );
      case ShareBackground.video:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: const Color(0xFF0B0B0D),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            size: 11,
            color: Colors.white,
          ),
        );
    }
  }
}

/// 2×2 checkerboard — the universal "transparent" affordance.
class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFE8E8E8);
    final dark = Paint()..color = const Color(0xFF9AA0A6);
    final c = size.width / 2;
    canvas.drawRect(Offset.zero & size, light);
    canvas.drawRect(Rect.fromLTWH(0, 0, c, c), dark);
    canvas.drawRect(Rect.fromLTWH(c, c, c, c), dark);
  }

  @override
  bool shouldRepaint(_CheckerPainter oldDelegate) => false;
}

// Keep this referenced so analyzer doesn't drop the import — capture sizes
// stay aligned with `ShareableAspect.size`.
// ignore: unused_element
final _kSizeRef = ImageCaptureUtils.captureSizeForAspectTag;
// ignore: unused_element
final _kCanvasRef = ShareableCanvas.neutralCharcoal;
