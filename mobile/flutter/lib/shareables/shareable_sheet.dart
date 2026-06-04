import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../core/constants/app_colors.dart';
import '../l10n/generated/app_localizations.dart';
import '../data/providers/cosmetics_provider.dart';
import '../data/services/share_service.dart';
import '../utils/image_capture_utils.dart';
import '../widgets/glass_sheet.dart';
import 'recent_templates_store.dart';
import 'share_settings_store.dart';
import 'shareable_canvas.dart';
import 'shareable_catalog.dart';
import 'doc/card_doc.dart';
import 'editor/card_editor_screen.dart';
import 'editor/food_montage_screen.dart';
import 'shareable_data.dart';
import 'widgets/share_link_pill.dart';
import 'widgets/template_view.dart';
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

/// Which secondary-control panel is currently expanded under the preview.
/// `none` keeps the options strip collapsed (0px) — the default state.
enum _ShareTool { none, ratio, background, style, watermark, photo }

class _ShareableSheetState extends ConsumerState<ShareableSheet> {
  late ShareableAspect _aspect;
  late ShareableCategory _category;
  late ShareableTemplate _template;
  bool _showWatermark = true;

  /// One-tap photo on/off — when false the card's food photo is stripped
  /// (`CardDoc.withoutPhoto()`), for users who want a data-only card.
  bool _showPhoto = true;

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
  /// PNGs that read boldly at full output resolution. Adjusted via the
  /// Style tool's slider (1.0×–2.0×) and persisted across shares.
  double _textScale = 1.5;

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

  /// Capture boundary wrapping the live preview's full-resolution card.
  /// A single key (not per-template): the preview always renders the
  /// current `_template` at `_aspect`, so the export pipeline snapshots it
  /// directly — independent of the gallery, whose thumbnails are now a
  /// fixed shape and no longer the capture source.
  final GlobalKey _previewCaptureKey = GlobalKey();

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

  /// Whether the live preview pane is expanded to the full card (default)
  /// or collapsed to a slim bar. The preview is a FIXED-height region, so
  /// expanding/collapsing it — and switching aspect ratio — never reflows
  /// the gallery below.
  bool _previewExpanded = true;

  /// The expanded secondary-control panel. `none` keeps the options strip
  /// at 0px (the default) so the preview and gallery sit adjacent.
  _ShareTool _activeTool = _ShareTool.none;

  /// The user's customized card document, returned from the Customize
  /// editor. When set (and for the matching template) the preview, gallery
  /// tile and capture render this instead of the preset. Cleared whenever
  /// the user switches template.
  CardDoc? _editedDoc;

  @override
  void initState() {
    super.initState();
    _aspect = widget.data.aspect;
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
    // Restore the user's last-used visual settings (aspect / background /
    // text scale / watermark). Async — applies once SharedPreferences
    // resolves; until then the initState defaults render.
    _loadShareSettings();
  }

  /// Restore the persisted visual settings (see [ShareSettingsStore]).
  Future<void> _loadShareSettings() async {
    final saved = await ShareSettingsStore.load();
    if (saved == null || !mounted) return;
    setState(() {
      _aspect = saved.aspect;
      _background = saved.background;
      _textScale = saved.textScale;
      _showWatermark = saved.showWatermark;
      _showPhoto = saved.showPhoto;
    });
  }

  /// Persist the current visual settings so the next share opens with the
  /// same look. Fire-and-forget — called from every control's handler.
  void _persistShareSettings() {
    // ignore: unawaited_futures
    ShareSettingsStore.save(ShareSettings(
      aspect: _aspect,
      background: _background,
      textScale: _textScale,
      showWatermark: _showWatermark,
      showPhoto: _showPhoto,
    ));
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

  /// Fixed aspect of every gallery thumbnail (4:5 — Instagram portrait).
  /// Deliberately independent of the selected export `_aspect` so picking
  /// a ratio never changes the gallery's row height (user requirement:
  /// "gallery shows >= 2 rows irrespective of the ratio").
  static const double _kGalleryThumbRatio = 4 / 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final showLinkPill =
        widget.data.kind == ShareableKind.workoutComplete &&
            widget.onGenerateShareLink != null;

    return GlassSheet(
      maxHeightFraction: 0.92,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // `constraints.maxHeight` is the room GlassSheet hands the body
          // (sheet height minus drag handle + bottom safe-area pad). Budget
          // it so the gallery ALWAYS keeps >= 2 thumbnail rows, then give
          // the preview the remainder (clamped). Because the preview height
          // is decided HERE, switching aspect ratio never reflows anything.
          final previewH = _resolvePreviewHeight(constraints.maxHeight);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(context),
              // Preview + its right-gutter tool rail (Ratio/Background/
              // Style). Fixed height — ratio changes only restyle the card.
              _previewSection(accent, isDark, previewH),
              // Options strip for whichever tool is open — 0px when none,
              // so by default the preview and gallery sit adjacent.
              _toolOptionsPanel(accent, isDark),
              if (_background == ShareBackground.video) _videoRow(accent),
              if (_isPhotoTemplate) _photoUploadRow(accent),
              // Gallery filter (category pills).
              _galleryHeader(accent, isDark),
              if (showLinkPill)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: ShareLinkPill(
                    url: _shareLink,
                    isGenerating: _generatingLink,
                    onGenerate: _onGenerateLink,
                  ),
                ),
              // The template gallery + the action bar that FLOATS over its
              // bottom — the gallery scrolls behind the frosted bar, so the
              // bar reads as real glass instead of a pinned white panel.
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _gallery()),
                    // Near-full-width floating bar.
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 10,
                      child: _floatingActionBar(isDark),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Height for the expanded preview region. Reserves >= 2 rows of gallery
  /// thumbnails that stay VISIBLE above the floating action bar, plus all
  /// chrome that will actually render (incl. the conditional video / photo
  /// / share-link rows), and hands the preview the remainder, clamped.
  /// Returns 0 when collapsed (the slim bar sizes itself).
  double _resolvePreviewHeight(double sheetBodyHeight) {
    if (!_previewExpanded) return 0;
    final w = MediaQuery.of(context).size.width;
    // Mirror `_gallery()` geometry: 3 columns, fixed 4:5 thumbnails.
    const cols = 3;
    const spacing = 8.0;
    const hPad = 12.0;
    final tileW = (w - hPad * 2 - spacing * (cols - 1)) / cols;
    final tileH = tileW / _kGalleryThumbRatio;
    // 2 rows + the inter-row gap + the GridView's own top padding.
    final twoRows = tileH * 2 + spacing + 12;
    // The action bar FLOATS over the gallery's bottom — reserve its
    // footprint so 2 thumbnail rows stay clear ABOVE it.
    const floatingBarReserve = 88.0;

    // Always-present chrome.
    var chrome = 56.0 /*header*/ + 48.0 /*gallery header*/;
    // Conditional rows that DO take Column space above the gallery.
    if (_background == ShareBackground.video) {
      chrome += 54; // video-picker row
    }
    if (_isPhotoTemplate) {
      chrome += 54; // photo-upload row
    }
    if (widget.data.kind == ShareableKind.workoutComplete &&
        widget.onGenerateShareLink != null) {
      chrome += 58; // share-link pill
    }

    final budget = sheetBodyHeight - chrome - twoRows - floatingBarReserve;
    // Floor low enough that, on a normal phone, a single conditional row
    // can be absorbed by shrinking the preview rather than the gallery.
    return budget.clamp(120.0, 320.0);
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
        _persistShareSettings();
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

  /// Spec for the currently-selected template, or null if it vanished
  /// from the catalog (defensive).
  ShareableTemplateSpec? _currentSpec() => ShareableCatalog.all()
      .cast<ShareableTemplateSpec?>()
      .firstWhere((s) => s?.template == _template, orElse: () => null);

  /// Selects a template, discarding any in-progress customization (the
  /// `_editedDoc` belongs to the previously-selected template).
  void _selectTemplate(ShareableTemplate t) {
    if (_template == t) return;
    setState(() {
      _template = t;
      _editedDoc = null;
    });
  }

  /// Opens the Canva-style card editor on the selected template's editable
  /// document; the returned customized document becomes `_editedDoc`.
  Future<void> _openCardEditor() async {
    final spec = _currentSpec();
    final docBuilder = spec?.docBuilder;
    if (docBuilder == null) return;
    HapticFeedback.selectionClick();
    final startDoc = _editedDoc ?? docBuilder(_currentData, _aspect);
    final edited = await CardEditorScreen.open(
      context,
      doc: startDoc,
      data: _currentData,
      showWatermark: _showWatermark,
      textScale: _textScale,
    );
    if (edited != null && mounted) {
      setState(() => _editedDoc = edited);
    }
  }

  /// Live preview of the selected template. Fixed-height region so that
  /// switching aspect ratio (or collapsing it) never reflows the gallery.
  /// Expanded → the card + a vertical tool rail in the right gutter.
  /// Collapsed → a slim bar with a mini render + inline tool icons.
  Widget _previewSection(Color accent, bool isDark, double previewH) {
    final spec = _currentSpec();
    if (spec == null) return const SizedBox.shrink();
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: _previewExpanded
          ? _expandedPreview(spec, accent, isDark, previewH)
          : _collapsedPreviewBar(spec, accent, isDark),
    );
  }

  /// Renders the selected template's card at its full design size, scaled
  /// with a `FittedBox` to whatever box the caller gives it. The card is
  /// wrapped in the single capture `RepaintBoundary` — so the export
  /// pipeline always snapshots this, at full resolution, regardless of how
  /// small the preview is displayed.
  Widget _previewCard(ShareableTemplateSpec spec, MediaQueryData mq) {
    final designSize = _aspect.size;
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: RepaintBoundary(
        key: _previewCaptureKey,
        child: SizedBox(
          width: designSize.width,
          height: designSize.height,
          // Off-screen capture path (RepaintBoundary.toImage) renders the
          // tree without an inherited Directionality from MaterialApp,
          // which throws "No TextDirection found" for every Text widget in
          // the template (Spotlight / Plate / Editorial). Explicit wrap.
          child: Directionality(
            textDirection:
                Directionality.maybeOf(context) ?? TextDirection.ltr,
            child: MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(_textScale)),
              child: ShareSurface(
                background: _background,
                // TemplateView renders a migrated template via the
                // editable CardDocRenderer (and the user's edits via
                // `overrideDoc`), falling back to the legacy builder for
                // un-migrated templates.
                child: TemplateView(
                  spec: spec,
                  data: _currentData,
                  aspect: _aspect,
                  showWatermark: _showWatermark,
                  showPhoto: _showPhoto,
                  textScale: _textScale,
                  overrideDoc:
                      spec.template == _template ? _editedDoc : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  /// Slim collapsed preview — a live mini card + the template name + the
  /// 3 tool icons + an expand affordance.
  Widget _collapsedPreviewBar(
      ShareableTemplateSpec spec, Color accent, bool isDark) {
    final mq = MediaQuery.of(context);
    final ratio = _aspect.ratio; // width / height
    const thumbH = 54.0;
    final thumbW = thumbH * ratio;
    void expand() {
      HapticFeedback.selectionClick();
      setState(() => _previewExpanded = true);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: expand,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: thumbW,
                  height: thumbH,
                  color: Colors.black,
                  child: _previewCard(spec, mq),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: expand,
                child: Text(
                  spec.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Tool icons stay reachable even while collapsed.
            _toolButton(_ShareTool.ratio, accent, isDark),
            _toolButton(_ShareTool.background, accent, isDark),
            _toolButton(_ShareTool.style, accent, isDark),
            const SizedBox(width: 2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: expand,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.unfold_more_rounded, size: 16, color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Expanded preview — a fixed-height region: the card centered, with the
  /// 3-tool rail docked in the right gutter (mirrored by an empty left
  /// gutter so the card stays centered). Height is fixed by the caller, so
  /// changing aspect ratio only restyles the card silhouette.
  Widget _expandedPreview(ShareableTemplateSpec spec, Color accent,
      bool isDark, double previewH) {
    final ratio = _aspect.ratio; // width / height
    final mq = MediaQuery.of(context);
    const railWidth = 48.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SizedBox(
        height: previewH,
        child: Row(
          children: [
            // Empty left gutter — mirrors the rail to keep the card centered.
            const SizedBox(width: railWidth),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: _previewCardFrame(spec, accent, isDark, mq),
                ),
              ),
            ),
            SizedBox(
              width: railWidth,
              child: Center(child: _toolRail(accent, isDark)),
            ),
          ],
        ),
      ),
    );
  }

  /// The bordered card frame inside the expanded preview — video backdrop
  /// (if any), the live card, and the collapse chip.
  Widget _previewCardFrame(ShareableTemplateSpec spec, Color accent,
      bool isDark, MediaQueryData mq) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
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
          // Video background — only the preview plays the clip; the
          // captured sticker stays transparent so Instagram composites the
          // real video behind it.
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
          GestureDetector(
            onTap: _onPreviewTapped,
            child: _previewCard(spec, mq),
          ),
          // Collapse chip — folds the preview into the slim bar.
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _previewExpanded = false);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.unfold_less_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Secondary-control tools ──────────────────────────────────────────
  // Ratio / Background / Style are tucked into a 3-icon rail in the
  // preview's right gutter (or inline in the collapsed bar). Tapping one
  // opens its options in `_toolOptionsPanel` below the preview; tapping it
  // again — or picking the same tool — closes the panel.

  /// Vertical 3-icon tool rail for the expanded preview's right gutter.
  Widget _toolRail(Color accent, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _toolButton(_ShareTool.ratio, accent, isDark),
        _toolButton(_ShareTool.background, accent, isDark),
        _toolButton(_ShareTool.style, accent, isDark),
        _toolButton(_ShareTool.watermark, accent, isDark),
        _toolButton(_ShareTool.photo, accent, isDark),
      ],
    );
  }

  /// One tool button. Ratio is a one-tap CYCLE (9:16 → 4:5 → 1:1 → …) and
  /// shows the current ratio as text — no panel. Background and Style open
  /// their options panel. Active panel tool = accent fill.
  Widget _toolButton(_ShareTool tool, Color accent, bool isDark) {
    // watermark + photo are one-tap toggles — "active" = the toggle is ON.
    final isToggle = tool == _ShareTool.watermark || tool == _ShareTool.photo;
    final active = isToggle
        ? (tool == _ShareTool.watermark ? _showWatermark : _showPhoto)
        : _activeTool == tool;
    final (IconData icon, String label) = switch (tool) {
      _ShareTool.ratio => (Icons.aspect_ratio_rounded, 'Tap to cycle ratio'),
      _ShareTool.background => (Icons.gradient_rounded, 'Background'),
      _ShareTool.style => (Icons.text_fields_rounded, 'Text & watermark'),
      _ShareTool.watermark => (
          _showWatermark
              ? Icons.branding_watermark_rounded
              : Icons.branding_watermark_outlined,
          _showWatermark ? 'Watermark on' : 'Watermark off',
        ),
      _ShareTool.photo => (
          _showPhoto ? Icons.image_rounded : Icons.hide_image_rounded,
          _showPhoto ? 'Photo on' : 'Photo off',
        ),
      _ShareTool.none => (Icons.tune_rounded, ''),
    };
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final restFg =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.78);
    return Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          if (tool == _ShareTool.ratio) {
            // Cycle the aspect in place — no options panel.
            setState(() {
              final order = ShareableAspect.values;
              _aspect =
                  order[(order.indexOf(_aspect) + 1) % order.length];
            });
            _persistShareSettings();
          } else if (tool == _ShareTool.watermark) {
            setState(() => _showWatermark = !_showWatermark);
            _persistShareSettings();
          } else if (tool == _ShareTool.photo) {
            setState(() => _showPhoto = !_showPhoto);
            _persistShareSettings();
          } else {
            setState(() => _activeTool = active ? _ShareTool.none : tool);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 38,
          height: 38,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: active
                ? accent
                : (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: tool == _ShareTool.ratio
              ? Text(
                  _aspect.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active ? onAccent : restFg,
                  ),
                )
              : Icon(icon, size: 18, color: active ? onAccent : restFg),
        ),
      ),
    );
  }

  /// Inline options strip for the open tool — 0px when `_activeTool` is
  /// `none`, so by default the preview and gallery sit adjacent.
  Widget _toolOptionsPanel(Color accent, bool isDark) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: _activeTool == _ShareTool.none
          ? const SizedBox(width: double.infinity, height: 0)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 2, 12, 2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                ),
              ),
              // Ratio / watermark / photo never open a panel (they act on
              // tap) — those cases exist only for switch exhaustiveness.
              child: switch (_activeTool) {
                _ShareTool.background => _backgroundOptions(accent, isDark),
                _ShareTool.style => _styleOptions(accent, isDark),
                _ShareTool.ratio ||
                _ShareTool.watermark ||
                _ShareTool.photo ||
                _ShareTool.none =>
                  const SizedBox.shrink(),
              },
            ),
    );
  }

  /// Background-mode options — reuses the existing `_bgChip` chips.
  Widget _backgroundOptions(Color accent, bool isDark) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in ShareBackground.values)
          _bgChip(mode, accent, isDark),
      ],
    );
  }

  /// Style options — the (now clearly labeled) watermark switch and the
  /// text-size slider. Both persist on change.
  Widget _styleOptions(Color accent, bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.branding_watermark_rounded,
                size: 18,
                color: _showWatermark ? accent : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Show ${Branding.appName} watermark',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            Switch.adaptive(
              value: _showWatermark,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _showWatermark = v);
                _persistShareSettings();
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeTrackColor: _switchTrackColor(accent),
              activeThumbColor: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.format_size_rounded, size: 18, color: accent),
            const SizedBox(width: 10),
            Text(
              'Text size',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Expanded(
              child: Slider(
                value: _textScale,
                min: 1.0,
                max: 2.0,
                divisions: 10,
                activeColor: accent,
                label: '${(_textScale * 100).round()}%',
                onChanged: (v) => setState(() => _textScale = v),
                onChangeEnd: (_) => _persistShareSettings(),
              ),
            ),
            SizedBox(
              width: 46,
              child: Text(
                '${(_textScale * 100).round()}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// One category pill — built equal-width (`Expanded`) so every category
  /// fits on a single row regardless of count or screen size. The label is
  /// in a scale-down `FittedBox`, so the longest name ("Editorial") shrinks
  /// to fit its slot rather than wrapping or clipping.
  Widget _categoryPill(ShareableCategory c, Color accent, bool isDark) {
    final selected = c == _category;
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final restBg = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: isDark ? 0.10 : 0.06);
    final restFg = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: isDark ? 0.85 : 0.72);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _selectCategory(c);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? accent : restBg,
          borderRadius: BorderRadius.circular(17),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            c.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? onAccent : restFg,
            ),
          ),
        ),
      ),
    );
  }

  /// Switch the active template category and land on its first template.
  void _selectCategory(ShareableCategory c) {
    setState(() {
      _category = c;
      final inCat = ShareableCatalog.templatesInCategory(
        _currentData,
        c,
        ownsCosmetic: _ownsElite,
      );
      if (inCat.isNotEmpty) _template = inCat.first.template;
      _editedDoc = null;
    });
    // RECENT is stamped only on share-success, never on browse — see
    // _onShareInstagram / _onShareGeneric / _onSave / _onPreviewTapped.
  }

  /// Gallery header — the category filter. Every category sits on ONE row
  /// as an equal-width pill (`Row` of `Expanded`s), so nothing wraps to a
  /// second line or scrolls off. The Sort control is NOT here — it floats
  /// over the gallery's top-right corner (see `_sortFloatingButton`).
  Widget _galleryHeader(Color accent, bool isDark) {
    final categories = ShareableCatalog.categoriesFor(
      _currentData,
      ownsCosmetic: _ownsElite,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _categoryPill(categories[i], accent, isDark)),
          ],
        ],
      ),
    );
  }

  /// Compact floating Sort control — hovers over the gallery's top-right
  /// corner (a rounded, shadowed pill) so the category row keeps the full
  /// width. Tapping it opens the sort menu.
  Widget _sortFloatingButton(bool isDark) {
    final fg = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.82);
    return PopupMenuButton<_GallerySort>(
      initialValue: _gallerySort,
      tooltip: AppLocalizations.of(context).shareableGallerySortTooltip,
      position: PopupMenuPosition.under,
      onSelected: (v) => setState(() => _gallerySort = v),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _GallerySort.defaultOrder,
          child: Text(AppLocalizations.of(context).shareableGallerySortDefault),
        ),
        PopupMenuItem(
          value: _GallerySort.recents,
          child: Text(AppLocalizations.of(context).shareableGallerySortRecents),
        ),
        PopupMenuItem(
          value: _GallerySort.favorites,
          child: Text(AppLocalizations.of(context).shareableGallerySortFavorites),
        ),
      ],
      // Glassmorphic, not a solid white pill — a real `BackdropFilter`
      // frosts the gallery thumbnails behind it. Shadow lives on an outer
      // Container so the ClipRRect doesn't clip it away.
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.18),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: isDark ? 0.42 : 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort_rounded, size: 15, color: fg),
                  const SizedBox(width: 5),
                  Text(
                    _gallerySort.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, size: 16, color: fg),
                ],
              ),
            ),
          ),
        ),
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
      child: Stack(
        children: [
          LayoutBuilder(
        builder: (context, constraints) {
          // 3-column grid of FIXED 4:5 thumbnails. 3 (not 4) columns so
          // each tile — and the template artwork inside it — is ~38%
          // bigger and more legible. The thumbnail shape is fixed (not the
          // selected export ratio) so the gallery's row height never
          // changes when the user switches 9:16 / 4:5 / 1:1, and >= 2 rows
          // always fit (see `_resolvePreviewHeight`).
          const designSize = Size(1080, 1350); // fixed 4:5 thumbnail
          const cols = 3;
          const spacing = 8.0;
          final tileW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
          final tileH = tileW / _kGalleryThumbRatio;

          return GridView.builder(
            // Bottom padding clears the floating action bar so the last
            // row can scroll fully into view above it.
            padding: const EdgeInsets.only(top: 8, bottom: 84),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: _kGalleryThumbRatio,
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
                    _selectTemplate(spec.template);
                  },
                  // Long-press = expand to full-screen preview viewer
                  // (replaces the previous tap-to-zoom corner button).
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    _selectTemplate(spec.template);
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
                                // Same Directionality guard as the main
                                // preview card — the grid renders
                                // TemplateView dozens of times off-route
                                // and each one needs an explicit
                                // TextDirection.
                                child: Directionality(
                                  textDirection: Directionality.maybeOf(
                                          context) ??
                                      TextDirection.ltr,
                                  child: MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    textScaler: TextScaler.linear(_textScale),
                                  ),
                                  // Thumbnails are display-only — the
                                  // export pipeline captures the preview's
                                  // own RepaintBoundary, not these tiles.
                                  child: ShareSurface(
                                    background: _background,
                                    child: TemplateView(
                                      spec: spec,
                                      data: _currentData,
                                      aspect: _aspect,
                                      showWatermark: _showWatermark,
                                      showPhoto: _showPhoto,
                                      textScale: _textScale,
                                    ),
                                  ),
                                ),
                                ),
                              ),
                            ),
                            // Template-name label — the text the user
                            // actually reads to pick. Kept clearly legible
                            // (the card art inside the thumbnail is small
                            // by nature; the name is what must read well).
                            Positioned(
                              left: 5,
                              right: 5,
                              bottom: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  spec.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
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
                            // (Per-tile zoom button removed — it cluttered
                            // every tile and collided with the floating
                            // Sort control. Full-screen preview is still
                            // reachable: tap the main preview, or
                            // long-press a tile.)
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
          // Floating Sort control — hovers over the gallery's top-right.
          Positioned(
            top: 4,
            right: 2,
            child: _sortFloatingButton(isDark),
          ),
        ],
      ),
    );
  }

  /// Instagram's brand gradient — used to paint the glyph (via a
  /// ShaderMask) so the logo reads in the real Instagram colors instead
  /// of a flat monochrome mark.
  static const _instagramGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color(0xFFFEDA75), // warm yellow
      Color(0xFFFA7E1E), // orange
      Color(0xFFD62976), // magenta
      Color(0xFF962FBF), // purple
      Color(0xFF4F5BD5), // indigo
    ],
  );

  /// The single FLOATING action bar — one UNIFORM frosted-glass capsule
  /// that hovers over the gallery's bottom (the gallery scrolls behind it,
  /// so the `BackdropFilter` frosts real content). Styled after iOS 26
  /// Liquid Glass / One UI 8.5 floating bars.
  ///
  /// Every action is the SAME button — an icon over a label — on one
  /// uniform glass surface. No contrasting slab, no nested pill. Instagram
  /// simply leads: it is first and carries the full-colour brand glyph,
  /// which draws the eye without breaking the bar into two zones. The bar
  /// is content-width, centered, and capped to the screen so it can't
  /// overflow.
  Widget _floatingActionBar(bool isDark) {
    final isFood = widget.data.kind == ShareableKind.foodLog;
    final photoCount = widget.data.foodImageUrls?.length ?? 0;
    final busy = _isCapturing;
    final fg = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.88);
    const barHeight = 66.0;

    final actions = <Widget>[
      // Instagram leads — the brand glyph painted with the real Instagram
      // gradient. Slightly larger glyph than the rest for a touch of lead.
      _barAction(
        label: 'Instagram',
        fg: fg,
        onTap: busy ? null : _onShareInstagram,
        iconBuilder: (size) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: _instagramGradient.createShader,
          child: FaIcon(FontAwesomeIcons.instagram,
              size: size, color: Colors.white),
        ),
      ),
      // Customize — opens the Canva-style card editor on the selected
      // template's editable document, so every element (title, macros,
      // chips, photo, score …) can be moved / restyled / edited. Shown only
      // for templates migrated to the editable-card engine.
      if (_currentSpec()?.isEditable ?? false)
        _barAction(
          label: 'Customize',
          icon: Icons.tune_rounded,
          fg: fg,
          onTap: _openCardEditor,
        ),
      if (isFood && photoCount >= 2)
        _barAction(
          label: 'Video',
          icon: Icons.movie_creation_rounded,
          fg: fg,
          onTap: () => FoodMontageScreen.open(context, _currentData),
        ),
      _barAction(
        label: 'Share',
        icon: Icons.ios_share_rounded,
        fg: fg,
        onTap: busy ? null : _onShareGeneric,
      ),
      _barAction(
        label: 'Save',
        icon: Icons.download_rounded,
        fg: fg,
        onTap: busy ? null : _onSave,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(barHeight / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(barHeight / 2),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              // Translucent so the frosted gallery shows through — a
              // glass bar, not a white panel.
              color: (isDark ? Colors.black : Colors.white)
                  .withValues(alpha: isDark ? 0.42 : 0.62),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.14),
              ),
            ),
            // Equal-width buttons spread across the full bar width.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final a in actions) Expanded(child: a),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One uniform action button in the floating bar — an icon over a small
  /// label. Pass [icon] for a plain glyph, or [iconBuilder] for a custom
  /// one (e.g. the gradient-painted Instagram mark).
  Widget _barAction({
    required String label,
    required Color fg,
    required VoidCallback? onTap,
    IconData? icon,
    Widget Function(double size)? iconBuilder,
  }) {
    final enabled = onTap != null;
    final color = enabled ? fg : fg.withValues(alpha: 0.4);
    Widget glyph = iconBuilder != null
        ? iconBuilder(22)
        : Icon(icon, size: 20, color: color);
    if (!enabled) glyph = Opacity(opacity: 0.45, child: glyph);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        // Width comes from the bar's Expanded; height from its stretch.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 26, child: Center(child: glyph)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
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
      final bytes = await _captureKey(_previewCaptureKey, aspect);
      if (mounted) setState(() => _aspect = prev);
      return bytes;
    }
    return _captureKey(_previewCaptureKey, aspect);
  }

  /// Pre-decode every network food photo referenced by the payload so the
  /// `RepaintBoundary.toImage` snapshot captures the actual image rather
  /// than a half-loaded blank (`toImage` paints only decoded pixels).
  void _warmFoodImages() {
    final urls = <String>{
      ...?widget.data.foodImageUrls,
      if (widget.data.customPhotoPath != null) widget.data.customPhotoPath!,
      if (widget.data.heroImageUrl != null) widget.data.heroImageUrl!,
      // Plan-grid (Week / Month) thumbnails — decode every day's exercise
      // illustration before the first capture so the day cells aren't blank
      // in the saved PNG (`toImage` paints only decoded pixels).
      for (final day in (widget.data.planDays ?? const <SharablePlanDay>[]))
        for (final ex in day.exercises)
          if (ex.imageUrl != null) ex.imageUrl!,
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
