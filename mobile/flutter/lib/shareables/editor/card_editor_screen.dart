/// The Canva-style editor for an editable share card ([CardDoc]).
///
/// Open with [CardEditorScreen.open]; it returns the edited [CardDoc] (or
/// null if cancelled). Every element is tap-selectable, drag-to-move,
/// pinch-to-scale-and-rotate, with a contextual panel for restyling and a
/// toolbar for adding elements. Undo/redo throughout.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/share_service.dart';
import '../doc/card_doc.dart';
import '../doc/card_doc_bindings.dart';
import '../doc/card_doc_renderer.dart';
import '../grade.dart';
import '../doc/card_palette.dart';
import '../share_compose_screen.dart';
import '../shareable_catalog.dart';
import '../shareable_data.dart';
import '../stock_backgrounds.dart';
import '../widgets/food_image.dart';
import 'ai_share_sheet.dart';
import 'card_editor_controller.dart';
import 'card_video_export_screen.dart';
import 'wrapped_scenes_export_screen.dart';
import '../../widgets/glass_sheet.dart';

/// Volt-lime — the redesign signature accent (proofs.html). First swatch in
/// the palette panel and the default the Studio nudges users toward.
const Color _kVoltLime = Color(0xFFD8FF3A);

/// The editor's selection-chrome accent (kept neutral so it never clashes
/// with a card whose own accent is volt-lime).
const Color _kEditorAccent = Color(0xFF3B82F6);

class CardEditorScreen extends StatefulWidget {
  final CardDoc initialDoc;
  final Shareable data;
  final bool showWatermark;
  final double textScale;

  const CardEditorScreen({
    super.key,
    required this.initialDoc,
    required this.data,
    this.showWatermark = true,
    this.textScale = 1.0,
  });

  /// Opens the editor full-screen; resolves to the edited [CardDoc], or null.
  static Future<CardDoc?> open(
    BuildContext context, {
    required CardDoc doc,
    required Shareable data,
    bool showWatermark = true,
    double textScale = 1.0,
  }) {
    return Navigator.of(context, rootNavigator: true).push<CardDoc>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CardEditorScreen(
          initialDoc: doc,
          data: data,
          showWatermark: showWatermark,
          textScale: textScale,
        ),
      ),
    );
  }

  /// Photo-first entry: builds the default editable card for `data.kind`,
  /// applies the [compose]-chosen canvas (a picked photo, a stock asset, or
  /// the preset's own background for the no-photo escape), and opens the
  /// editor with Story / Save / Share built in. Returns the edited [CardDoc]
  /// if the user tapped Done (so callers can persist a "recent"), else null.
  static Future<CardDoc?> openForShare(
    BuildContext context, {
    required Shareable data,
    required ComposeResult compose,
    ShareableTemplate? initialTemplate,
    bool showWatermark = true,
    double textScale = 1.0,
  }) {
    final doc = _buildComposedDoc(data, compose, initialTemplate);
    return Navigator.of(context, rootNavigator: true).push<CardDoc>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CardEditorScreen(
          initialDoc: doc,
          data: data,
          showWatermark: showWatermark,
          textScale: textScale,
        ),
      ),
    );
  }

  /// Resolves the default editable template for the kind, builds its doc, then
  /// overlays the compose-chosen background. No-photo keeps the preset's own
  /// background; photo/stock swap in a full-bleed photo background.
  static CardDoc _buildComposedDoc(
    Shareable data,
    ComposeResult compose,
    ShareableTemplate? initialTemplate,
  ) {
    final available =
        ShareableCatalog.availableFor(data).where((s) => s.isEditable).toList();
    ShareableTemplateSpec? pick;
    for (final t in [
      initialTemplate,
      ShareableCatalog.defaultTemplateForKind(data.kind),
    ]) {
      if (t == null) continue;
      final m = available.where((s) => s.template == t);
      if (m.isNotEmpty) {
        pick = m.first;
        break;
      }
    }
    pick ??= available.isNotEmpty ? available.first : null;
    final aspect = data.aspect;
    final base = pick?.docBuilder?.call(data, aspect) ??
        CardDoc(
          aspect: aspect,
          elements: const [],
          accentColor: data.accentColor,
        );
    switch (compose.mode) {
      case ComposeMode.noPhoto:
        return base;
      case ComposeMode.stock:
        return base.copyWith(
          background: CardBackground(
            kind: CardBackgroundKind.photo,
            photo: CardPhotoRef(staticPath: compose.assetOrPath),
            photoFit: BoxFit.cover,
          ),
        );
      case ComposeMode.photo:
        return base.copyWith(
          background: CardBackground(
            kind: CardBackgroundKind.photo,
            photo: CardPhotoRef(staticPath: compose.assetOrPath),
            photoFit: BoxFit.cover,
          ),
        );
    }
  }

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

/// The two element-adding trays (Gravl parity): full layouts vs single
/// stat "stickers". `none` collapses both while an element is selected (its
/// context panel takes over).
enum _Tray { custom, templates, none }

class _CardEditorScreenState extends State<CardEditorScreen> {
  late final CardEditorController _c = CardEditorController(widget.initialDoc);

  /// Snapshots the rendered card (only) for Story / Save / Share.
  final GlobalKey _captureKey = GlobalKey();

  /// Which add-tray is open under the canvas. Custom leads (one-tap stickers).
  _Tray _tray = _Tray.custom;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChange);
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _c.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _close() async {
    if (_c.canUndo) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your edits to this card will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _c.selected;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0F),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: _EditorCanvas(
                controller: _c,
                data: widget.data,
                showWatermark: widget.showWatermark,
                textScale: widget.textScale,
                captureKey: _captureKey,
              ),
            ),
            // Editing an element → its context panel takes over the trays.
            // Cap + scroll so a tall context panel can never overflow on a
            // small device (iPhone SE) once the action bar is stacked below.
            if (selected != null)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.32,
                ),
                child: SingleChildScrollView(
                  child: _BottomArea(controller: _c),
                ),
              )
            else ...[
              _trayContent(),
              _traySwitcher(),
            ],
            _actionBar(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Trays (Custom / Templates) ───────────────────

  /// The Custom ↔ Templates segmented switcher (Gravl's two trays).
  Widget _traySwitcher() {
    Widget seg(String label, IconData icon, _Tray tray) {
      final selected = _tray == tray;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _tray = tray);
          },
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? Colors.white : Colors.white54),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF14161B),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: Row(
        children: [
          seg('Custom', Icons.auto_awesome_mosaic_rounded, _Tray.custom),
          seg('Templates', Icons.dashboard_rounded, _Tray.templates),
        ],
      ),
    );
  }

  Widget _trayContent() {
    switch (_tray) {
      case _Tray.custom:
        return _CustomTray(controller: _c, data: widget.data);
      case _Tray.templates:
        return _TemplatesTray(controller: _c, data: widget.data);
      case _Tray.none:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────── Bottom action bar ────────────────────────────

  /// Story / Save / Share — the terminal actions. Story snaps to 9:16 and
  /// hands Instagram Stories; Save writes to the gallery; Share opens the
  /// system sheet. All reuse [ShareService] + the editor's own capture.
  Widget _actionBar() {
    Widget action(String label, IconData icon, VoidCallback onTap) {
      return Expanded(
        child: TextButton(
          onPressed: _busy ? null : onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22,
                  color: _busy ? Colors.white24 : Colors.white),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _busy ? Colors.white24 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF101216),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            action('Story', Icons.add_to_home_screen_rounded, _onStory),
            action('Save', Icons.download_rounded, _onSave),
            action('Sticker', Icons.auto_fix_high_rounded, _onSticker),
            action('Share', Icons.ios_share_rounded, _onShare),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Capture + share ──────────────────────────────

  /// Snapshots the rendered card at the design resolution for the given aspect.
  Future<Uint8List?> _capture(ShareableAspect aspect) async {
    try {
      _c.deselect();
      // Let the deselect + any pending layout settle before snapshotting.
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || boundary.size.isEmpty) return null;
      final scale = aspect.size.width / boundary.size.width;
      final image = await boundary.toImage(pixelRatio: scale.clamp(0.5, 6.0));
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ [CardEditor] capture failed: $e');
      return null;
    }
  }

  Future<void> _onStory() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      // Stories require 9:16 — snap the doc, capture, restore.
      final prev = _c.doc.aspect;
      if (prev != ShareableAspect.story) {
        _c.setAspect(ShareableAspect.story);
        await WidgetsBinding.instance.endOfFrame;
      }
      final bytes = await _capture(ShareableAspect.story);
      if (prev != ShareableAspect.story && mounted) _c.setAspect(prev);
      if (bytes == null) {
        _toast('Could not render — try again');
        return;
      }
      final r = await ShareService.shareToInstagramStories(bytes);
      if (r.success) {
        await ShareService.saveToGallery(bytes);
        if (mounted) Navigator.of(context).pop(_c.doc);
      } else if (r.error != null) {
        _toast('Could not open Instagram');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onSave() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final bytes = await _capture(_c.doc.aspect);
      if (bytes == null) {
        _toast('Could not render — try again');
        return;
      }
      final r = await ShareService.saveToGallery(bytes);
      if (mounted) {
        if (r.success) {
          _toast('Saved to device');
          Navigator.of(context).pop(_c.doc);
        } else {
          _toast(r.error ?? 'Failed to save');
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onShare() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final bytes = await _capture(_c.doc.aspect);
      if (bytes == null) {
        _toast('Could not render — try again');
        return;
      }
      await ShareService.shareGeneric(bytes, caption: 'My ${widget.data.title}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// F6 — transparent-PNG "cutout" sticker export. Strips the card background
  /// to nothing, captures (the PNG keeps alpha), restores, then shares the
  /// transparent sticker so the user can drop it onto any photo / story.
  Future<void> _onSticker() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final bytes = await _c.withTransparentBackground(
        () => _capture(_c.doc.aspect),
      );
      if (bytes == null) {
        _toast('Could not render — try again');
        return;
      }
      await ShareService.shareGeneric(
        bytes,
        caption: 'My ${widget.data.title}',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Widget _topBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFF14161B),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: _close,
          ),
          IconButton(
            tooltip: 'Variations',
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
            onPressed: _openVariations,
          ),
          IconButton(
            tooltip: 'Palette',
            icon: const Icon(Icons.palette_rounded, color: Colors.white),
            onPressed: _openPalette,
          ),
          IconButton(
            tooltip: 'Background',
            icon: const Icon(Icons.gradient_rounded, color: Colors.white),
            onPressed: _editBackground,
          ),
          IconButton(
            tooltip: 'Layers',
            icon: const Icon(Icons.layers_rounded, color: Colors.white),
            onPressed: _openLayers,
          ),
          // F1/F2 — cost-gated AI touches (restyle photo + insight line). Each
          // fires only on an explicit tap inside the sheet.
          IconButton(
            tooltip: 'AI',
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            onPressed: _openAiSheet,
          ),
          IconButton(
            tooltip: 'Export as video',
            icon: const Icon(Icons.movie_creation_rounded, color: Colors.white),
            onPressed: () => CardVideoExportScreen.open(
              context,
              doc: _c.doc,
              data: widget.data,
            ),
          ),
          // F13 — Wrapped per-scene export (only for Wrapped-kind shares).
          if (widget.data.kind == ShareableKind.wrapped)
            IconButton(
              tooltip: 'Wrapped scenes',
              icon: const Icon(Icons.view_carousel_rounded,
                  color: Colors.white),
              onPressed: () => WrappedScenesExportScreen.open(
                context,
                data: widget.data,
                showWatermark: widget.showWatermark,
              ),
            ),
          // Aspect "magic resize" — cycles 9:16 / 4:5 / 1:1, re-fitting
          // every element's layout to the new canvas.
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              const order = ShareableAspect.values;
              _c.setAspect(
                order[(order.indexOf(_c.doc.aspect) + 1) % order.length],
              );
            },
            child: Text(
              _c.doc.aspect.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Undo',
            icon: Icon(Icons.undo_rounded,
                color: _c.canUndo ? Colors.white : Colors.white24),
            onPressed: _c.canUndo
                ? () {
                    HapticFeedback.selectionClick();
                    _c.undo();
                  }
                : null,
          ),
          IconButton(
            tooltip: 'Redo',
            icon: Icon(Icons.redo_rounded,
                color: _c.canRedo ? Colors.white : Colors.white24),
            onPressed: _c.canRedo
                ? () {
                    HapticFeedback.selectionClick();
                    _c.redo();
                  }
                : null,
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_c.doc),
            child: const Text('Done'),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// F1/F2 — open the AI touches sheet. The restyle target is the doc's
  /// current photo background (the compose-chosen photo); null when the card
  /// has a gradient/solid background, in which case the sheet disables restyle
  /// with a note and still offers the insight line.
  void _openAiSheet() {
    HapticFeedback.selectionClick();
    final bg = _c.doc.background;
    final photo = (bg.kind == CardBackgroundKind.photo ||
            bg.kind == CardBackgroundKind.blurredPhoto)
        ? bg.photo?.staticPath
        : null;
    AiShareSheet.show(
      context,
      controller: _c,
      data: widget.data,
      photoPathOrUrl: photo,
    );
  }

  void _openVariations() {
    HapticFeedback.selectionClick();
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        opaque: true,
        child: _VariationsSheet(controller: _c, data: widget.data),
      ),
    );
  }

  void _openPalette() {
    HapticFeedback.selectionClick();
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        opaque: true,
        child: _PaletteSheet(controller: _c),
      ),
    );
  }

  void _editBackground() {
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        opaque: true,
        child: _BackgroundSheet(controller: _c, data: widget.data),
      ),
    );
  }

  void _openLayers() {
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        opaque: true,
        child: _LayersSheet(controller: _c),
      ),
    );
  }
}

// ─────────────────────────── Canvas geometry ──────────────────────────────

/// Maps between the card's fractional design space and on-screen pixels.
class _CanvasGeometry {
  final Size cardDesign; // 1080 x ...
  final double scale; // design px -> screen px
  final Offset origin; // top-left of the rendered card on screen

  const _CanvasGeometry(this.cardDesign, this.scale, this.origin);

  Size get screenCardSize =>
      Size(cardDesign.width * scale, cardDesign.height * scale);

  /// Element rect (fractional) -> on-screen Rect (unrotated).
  Rect rectFor(ElementTransform t) {
    final w = t.size.width * cardDesign.width * scale;
    final h = t.size.height * cardDesign.height * scale;
    final cx = origin.dx + t.position.dx * cardDesign.width * scale;
    final cy = origin.dy + t.position.dy * cardDesign.height * scale;
    return Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
  }

  /// A screen-px delta -> a fractional position delta.
  Offset fracDelta(Offset screenDelta) => Offset(
        screenDelta.dx / (cardDesign.width * scale),
        screenDelta.dy / (cardDesign.height * scale),
      );
}

// ─────────────────────────── Canvas ────────────────────────────────────────

class _EditorCanvas extends StatelessWidget {
  final CardEditorController controller;
  final Shareable data;
  final bool showWatermark;
  final double textScale;

  /// Wraps the rendered card (only) so the editor can snapshot the design at
  /// full resolution for Story / Save / Share — never the selection chrome.
  final GlobalKey captureKey;

  const _EditorCanvas({
    required this.controller,
    required this.data,
    required this.showWatermark,
    required this.textScale,
    required this.captureKey,
  });

  @override
  Widget build(BuildContext context) {
    final doc = controller.doc;
    final design = doc.aspect.size;
    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = 16.0;
        final availW = constraints.maxWidth - pad * 2;
        final availH = constraints.maxHeight - pad * 2;
        final scale =
            math.min(availW / design.width, availH / design.height);
        final cardW = design.width * scale;
        final cardH = design.height * scale;
        final origin = Offset(
          (constraints.maxWidth - cardW) / 2,
          (constraints.maxHeight - cardH) / 2,
        );
        final geo = _CanvasGeometry(design, scale, origin);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.deselect,
          child: Stack(
            children: [
              // The card itself — the one render path, scaled to fit.
              Positioned(
                left: origin.dx,
                top: origin.dy,
                width: cardW,
                height: cardH,
                child: RepaintBoundary(
                  key: captureKey,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: CardDocRenderer(
                      doc: doc,
                      data: data,
                      showWatermark: showWatermark,
                      textScale: textScale,
                    ),
                  ),
                ),
              ),
              // One transparent gesture box per element (front-most wins).
              for (final element in doc.elements)
                if (!element.hidden && !element.locked)
                  _ElementGestureBox(
                    controller: controller,
                    element: element,
                    geo: geo,
                  ),
              // Selection chrome — drawn last, never part of the card.
              if (controller.selected != null)
                _SelectionOverlay(
                  controller: controller,
                  element: controller.selected!,
                  geo: geo,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A transparent, rotated hit box over one element — taps select it, a
/// scale gesture moves / scales / rotates it.
class _ElementGestureBox extends StatefulWidget {
  final CardEditorController controller;
  final CardElement element;
  final _CanvasGeometry geo;

  const _ElementGestureBox({
    required this.controller,
    required this.element,
    required this.geo,
  });

  @override
  State<_ElementGestureBox> createState() => _ElementGestureBoxState();
}

class _ElementGestureBoxState extends State<_ElementGestureBox> {
  late Offset _basePos;
  late Size _baseSize;
  late double _baseRotation;
  Offset _accum = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final el = widget.element;
    final rect = widget.geo.rectFor(el.transform);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Transform.rotate(
        angle: el.transform.rotation,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.controller.select(el.id);
          },
          onScaleStart: (_) {
            widget.controller.select(el.id);
            widget.controller.beginGesture();
            final t = widget.controller.doc.elementById(el.id)!.transform;
            _basePos = t.position;
            _baseSize = t.size;
            _baseRotation = t.rotation;
            _accum = Offset.zero;
          },
          onScaleUpdate: (d) {
            _accum += d.focalPointDelta;
            final frac = widget.geo.fracDelta(_accum);
            final s = d.scale;
            widget.controller.updateElementLive(
              el.id,
              (e) => e.copyWith(
                transform: e.transform.copyWith(
                  position: Offset(
                    (_basePos.dx + frac.dx).clamp(0.0, 1.0),
                    (_basePos.dy + frac.dy).clamp(0.0, 1.0),
                  ),
                  size: Size(
                    (_baseSize.width * s).clamp(0.04, 1.4),
                    (_baseSize.height * s).clamp(0.02, 1.4),
                  ),
                  rotation: _baseRotation + d.rotation,
                ),
              ),
            );
          },
          onScaleEnd: (_) => widget.controller.endGesture(),
        ),
      ),
    );
  }
}

// ─────────────────────────── Selection overlay ────────────────────────────

class _SelectionOverlay extends StatefulWidget {
  final CardEditorController controller;
  final CardElement element;
  final _CanvasGeometry geo;

  const _SelectionOverlay({
    required this.controller,
    required this.element,
    required this.geo,
  });

  @override
  State<_SelectionOverlay> createState() => _SelectionOverlayState();
}

class _SelectionOverlayState extends State<_SelectionOverlay> {
  late Offset _baseCenterScreen;

  @override
  Widget build(BuildContext context) {
    final el = widget.element;
    final rect = widget.geo.rectFor(el.transform);
    const accent = Color(0xFF3B82F6);
    const handle = 26.0;

    return Positioned(
      left: rect.left - handle / 2,
      top: rect.top - handle / 2 - 34,
      width: rect.width + handle,
      height: rect.height + handle + 34,
      child: IgnorePointer(
        ignoring: false,
        child: SizedBox(
          width: rect.width + handle,
          height: rect.height + handle + 34,
          child: Stack(
            children: [
              // Bounding box (rotated with the element).
              Positioned(
                left: handle / 2,
                top: handle / 2 + 34,
                width: rect.width,
                height: rect.height,
                child: Transform.rotate(
                  angle: el.transform.rotation,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: accent, width: 1.6),
                      ),
                    ),
                  ),
                ),
              ),
              // Rotate handle (top-center).
              Positioned(
                left: (rect.width + handle) / 2 - handle / 2,
                top: 0,
                width: handle,
                height: handle,
                child: _RoundHandle(
                  icon: Icons.rotate_right_rounded,
                  color: accent,
                  onStart: _begin,
                  onUpdate: (global) {
                    final v = global - _baseCenterScreen;
                    final angle = math.atan2(v.dy, v.dx) + math.pi / 2;
                    widget.controller.updateElementLive(
                      el.id,
                      (e) => e.copyWith(
                        transform: e.transform.copyWith(rotation: angle),
                      ),
                    );
                  },
                  onEnd: widget.controller.endGesture,
                ),
              ),
              // Resize handle (bottom-right corner).
              Positioned(
                right: 0,
                bottom: 0,
                width: handle,
                height: handle,
                child: _RoundHandle(
                  icon: Icons.open_in_full_rounded,
                  color: accent,
                  onStart: _begin,
                  onUpdate: (global) {
                    final v = global - _baseCenterScreen;
                    // Half-diagonal in screen px -> fractional size.
                    final halfW = v.dx.abs().clamp(8.0, 4000.0);
                    final halfH = v.dy.abs().clamp(8.0, 4000.0);
                    final design = widget.geo.cardDesign;
                    final sc = widget.geo.scale;
                    widget.controller.updateElementLive(
                      el.id,
                      (e) => e.copyWith(
                        transform: e.transform.copyWith(
                          size: Size(
                            (halfW * 2 / (design.width * sc)).clamp(0.04, 1.4),
                            (halfH * 2 / (design.height * sc))
                                .clamp(0.02, 1.4),
                          ),
                        ),
                      ),
                    );
                  },
                  onEnd: widget.controller.endGesture,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _begin() {
    _baseCenterScreen = widget.geo.rectFor(widget.element.transform).center;
    widget.controller.beginGesture();
  }
}

/// A small circular drag handle that reports global-position drags.
class _RoundHandle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;

  const _RoundHandle({
    required this.icon,
    required this.color,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onStart(),
      onPanUpdate: (d) => onUpdate(d.globalPosition),
      onPanEnd: (_) => onEnd(),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(icon, size: 13, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────── Bottom area ──────────────────────────────────

/// The contextual panel (an element is selected) or the add-element toolbar.
class _BottomArea extends StatelessWidget {
  final CardEditorController controller;
  const _BottomArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = controller.selected;
    return Container(
      color: const Color(0xFF14161B),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: selected == null
          ? _Toolbar(controller: controller)
          : _ContextPanel(controller: controller, element: selected),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final CardEditorController controller;
  const _Toolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _toolBtn('Text', Icons.text_fields_rounded,
              () => _add(CardElementType.text)),
          _toolBtn('Photo', Icons.image_rounded,
              () => _add(CardElementType.photo)),
          _toolBtn('Macros', Icons.donut_large_rounded,
              () => _add(CardElementType.chart)),
          _toolBtn('Shape', Icons.category_rounded,
              () => _add(CardElementType.shape)),
          _toolBtn('Sticker', Icons.emoji_emotions_rounded,
              () => _add(CardElementType.icon)),
          _toolBtn('Score', Icons.workspace_premium_rounded,
              () => _add(CardElementType.badge)),
          _toolBtn('Date', Icons.calendar_today_rounded,
              () => _add(CardElementType.dateStamp)),
          _toolBtn('Logo', Icons.branding_watermark_rounded,
              () => _add(CardElementType.watermark)),
        ],
      ),
    );
  }

  void _add(CardElementType type) {
    HapticFeedback.selectionClick();
    controller.addElement(
      CardElement(
        id: CardDoc.newId(),
        type: type,
        transform: const ElementTransform(
          position: Offset(0.5, 0.45),
          size: Size(0.5, 0.16),
        ),
        props: ElementProps.defaultFor(type),
      ),
    );
  }

  Widget _toolBtn(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Custom tray (stickers) ───────────────────────

/// One sticker preset — a labelled, one-tap element add.
class _StickerPreset {
  final String label;
  final IconData icon;
  final CardElement Function() build;
  const _StickerPreset(this.label, this.icon, this.build);
}

/// Gravl's "Custom" tray — one-tap stat stickers dropped onto the chosen
/// photo. Kind-aware: workout shares get workout stickers (big number,
/// exercise list, week bars, HR-zone hexagon, date marker), food shares get
/// food stickers (calorie number, macro rings, plate, protein hero, what-I-ate
/// chips, nutrition label, food-photo coin). Shared stickers (text, photo,
/// emoji, logo, perspective text) appear for every kind.
class _CustomTray extends StatelessWidget {
  final CardEditorController controller;
  final Shareable data;
  const _CustomTray({required this.controller, required this.data});

  bool get _isFood =>
      data.kind == ShareableKind.foodLog ||
      data.kind == ShareableKind.nutrition;

  static ElementTransform _t(
          {Offset pos = const Offset(0.5, 0.45),
          Size size = const Size(0.5, 0.16)}) =>
      ElementTransform(position: pos, size: size);

  CardElement _el(CardElementType type, ElementProps props,
          {ElementTransform? transform}) =>
      CardElement(
        id: CardDoc.newId(),
        type: type,
        transform: transform ?? _t(),
        props: props,
      );

  List<_StickerPreset> _presets() {
    final accent = data.accentColor;
    final shared = <_StickerPreset>[
      _StickerPreset('Text', Icons.text_fields_rounded,
          () => _el(CardElementType.text, const TextProps(literal: 'Text'))),
      _StickerPreset('Marker', Icons.format_color_text_rounded, () {
        // Gravl "marker" date variant — highlighted text block.
        return _el(
          CardElementType.text,
          TextProps(
            literal: 'HIGHLIGHT',
            fontSize: 56,
            color: Colors.black,
            allCaps: true,
            highlightColor: accent,
          ),
          transform: _t(pos: const Offset(0.5, 0.3), size: const Size(0.6, 0.1)),
        );
      }),
      _StickerPreset('Photo', Icons.image_rounded,
          () => _el(CardElementType.photo, const PhotoProps())),
      _StickerPreset('Emoji', Icons.emoji_emotions_rounded,
          () => _el(CardElementType.icon, const IconProps())),
      _StickerPreset('Date', Icons.calendar_today_rounded,
          () => _el(CardElementType.dateStamp, const DateStampProps())),
      _StickerPreset('Logo', Icons.branding_watermark_rounded,
          () => _el(CardElementType.watermark, const WatermarkProps())),
    ];

    if (_isFood) {
      return [
        _StickerPreset('Calories', Icons.local_fire_department_rounded, () {
          return _el(
            CardElementType.text,
            TextProps(
              literal: '0',
              binding: const DataBinding(BindingSource.calories),
              fontSize: 140,
              color: accent,
              align: TextAlign.center,
              suffix: ' kcal',
            ),
            transform:
                _t(pos: const Offset(0.5, 0.4), size: const Size(0.8, 0.2)),
          );
        }),
        _StickerPreset('Macro rings', Icons.donut_large_rounded,
            () => _el(CardElementType.chart, const ChartProps())),
        _StickerPreset(
            'Macro trio',
            Icons.blur_circular_rounded,
            () => _el(CardElementType.ringTrio, const RingTrioProps(),
                transform:
                    _t(pos: const Offset(0.5, 0.5), size: const Size(0.8, 0.3)))),
        _StickerPreset('Protein hero', Icons.fitness_center_rounded, () {
          return _el(
            CardElementType.text,
            TextProps(
              literal: '0',
              binding: const DataBinding(BindingSource.proteinG),
              fontSize: 120,
              color: accent,
              align: TextAlign.center,
              prefix: '',
              suffix: 'g protein',
            ),
            transform:
                _t(pos: const Offset(0.5, 0.42), size: const Size(0.85, 0.22)),
          );
        }),
        _StickerPreset('What I ate', Icons.restaurant_menu_rounded,
            () => _el(CardElementType.chipGroup, const ChipGroupProps())),
        _StickerPreset(
            'Nutrition label',
            Icons.receipt_long_rounded,
            () => _el(CardElementType.table, const TableProps(),
                transform:
                    _t(pos: const Offset(0.5, 0.5), size: const Size(0.7, 0.4)))),
        _StickerPreset('Food coin', Icons.album_rounded, () {
          return _el(
            CardElementType.ringStat,
            RingStatProps(
              centerBinding: const DataBinding(BindingSource.calories),
              label: 'KCAL',
              ringColor: accent,
            ),
            transform:
                _t(pos: const Offset(0.5, 0.45), size: const Size(0.5, 0.28)),
          );
        }),
        _StickerPreset('Score', Icons.workspace_premium_rounded,
            () => _el(CardElementType.badge, const BadgeProps())),
        // F10 — meal letter grade sticker. The letter is derived
        // deterministically from the meal's health score; drop it big.
        _StickerPreset('Grade', Icons.grade_rounded, () {
          final grade = letterGrade(data.healthScore ?? 6);
          return _el(
            CardElementType.text,
            TextProps(
              literal: grade.letter,
              fontIndex: CardFontIx.display,
              fontSize: 300,
              color: grade.color,
              align: TextAlign.center,
              maxLines: 1,
            ),
            transform:
                _t(pos: const Offset(0.5, 0.45), size: const Size(0.7, 0.3)),
          );
        }),
        _StickerPreset('Add yours', Icons.add_box_rounded,
            () => _addYoursSticker(accent, 'Add your meal')),
        ...shared,
      ];
    }

    // Workout (and every non-food kind).
    return [
      _StickerPreset('Big number', Icons.tag_rounded, () {
        return _el(
          CardElementType.text,
          TextProps(
            literal: data.heroValue != null ? '${data.heroValue}' : '0',
            binding: const DataBinding(BindingSource.heroString),
            fontSize: 150,
            color: accent,
            align: TextAlign.center,
          ),
          transform:
              _t(pos: const Offset(0.5, 0.4), size: const Size(0.85, 0.22)),
        );
      }),
      _StickerPreset(
          'Exercises',
          Icons.format_list_bulleted_rounded,
          () => _el(CardElementType.repeater, const RepeaterProps(),
              transform:
                  _t(pos: const Offset(0.5, 0.5), size: const Size(0.8, 0.4)))),
      _StickerPreset(
          'Week bars',
          Icons.bar_chart_rounded,
          () => _el(CardElementType.gridHeatmap, const GridHeatmapProps(),
              transform:
                  _t(pos: const Offset(0.5, 0.5), size: const Size(0.8, 0.25)))),
      _StickerPreset('Stat strip', Icons.grid_view_rounded,
          () => _el(CardElementType.statGrid, const StatGridProps(),
              transform:
                  _t(pos: const Offset(0.5, 0.6), size: const Size(0.85, 0.2)))),
      _StickerPreset('HR zone', Icons.favorite_rounded, () {
        // The one Gravl Custom format we were missing — an idle HR-zone
        // hexagon (RingStatProps with hexagon:true).
        return _el(
          CardElementType.ringStat,
          RingStatProps(
            hexagon: true,
            centerValue: 'Z3',
            label: 'HR ZONE',
            ringColor: accent,
          ),
          transform:
              _t(pos: const Offset(0.5, 0.45), size: const Size(0.5, 0.3)),
        );
      }),
      _StickerPreset('Calendar', Icons.calendar_month_rounded,
          () => _el(CardElementType.gridHeatmap, const GridHeatmapProps(),
              transform:
                  _t(pos: const Offset(0.5, 0.55), size: const Size(0.8, 0.3)))),
      _StickerPreset('Score', Icons.workspace_premium_rounded,
          () => _el(CardElementType.badge, const BadgeProps())),
      _StickerPreset('Add yours', Icons.add_box_rounded,
          () => _addYoursSticker(accent, 'Add your lift')),
      ...shared,
    ];
  }

  /// A single "Add Yours"-style prompt chip — a highlighted, pill-tinted text
  /// block the user drops to seed an Instagram Add-Yours chain. One element so
  /// it works as a Custom-tray sticker (F6).
  CardElement _addYoursSticker(Color accent, String prompt) => _el(
        CardElementType.text,
        TextProps(
          literal: '➕  $prompt',
          fontIndex: CardFontIx.cond,
          fontSize: 40,
          color: const Color(0xFF111111),
          align: TextAlign.center,
          highlightColor: Colors.white,
          maxLines: 1,
        ),
        transform: _t(pos: const Offset(0.5, 0.2), size: const Size(0.8, 0.1)),
      );

  @override
  Widget build(BuildContext context) {
    final presets = _presets();
    return Container(
      height: 86,
      color: const Color(0xFF14161B),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        itemBuilder: (_, i) {
          final p = presets[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 72,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  controller.addElement(p.build());
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p.icon, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      p.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────── Templates tray ───────────────────────────────

/// Gravl's "Templates" tray — the kind-filtered [ShareableCatalog] gallery as
/// an inline horizontal strip. Tapping one rebuilds the whole [CardDoc] from
/// that template's `docBuilder` (one undo step), preserving the chosen photo
/// background.
class _TemplatesTray extends StatelessWidget {
  final CardEditorController controller;
  final Shareable data;
  const _TemplatesTray({required this.controller, required this.data});

  List<ShareableTemplateSpec> _specs() => ShareableCatalog.availableFor(data)
      .where((s) => s.docBuilder != null)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final specs = _specs();
    final aspect = controller.doc.aspect;
    final currentPreset = controller.doc.presetId;
    // Preserve the user's chosen photo background across a template swap.
    final bg = controller.doc.background;
    final keepPhoto = bg.kind == CardBackgroundKind.photo ||
        bg.kind == CardBackgroundKind.blurredPhoto;
    if (specs.isEmpty) {
      return Container(
        height: 86,
        color: const Color(0xFF14161B),
        alignment: Alignment.center,
        child: const Text('No other layouts for this share',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
      );
    }
    return Container(
      height: 132,
      color: const Color(0xFF14161B),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: specs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final spec = specs[i];
          final selected = spec.template.name == currentPreset;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              var next = spec.docBuilder!(data, aspect);
              if (keepPhoto) next = next.copyWith(background: bg);
              controller.swapDoc(next);
            },
            child: SizedBox(
              width: 78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected ? _kVoltLime : Colors.white12,
                            width: selected ? 2.4 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: aspect.size.width,
                            height: aspect.size.height,
                            child: Directionality(
                              textDirection:
                                  Directionality.maybeOf(context) ??
                                      TextDirection.ltr,
                              child: CardDocRenderer(
                                doc: keepPhoto
                                    ? spec
                                        .docBuilder!(data, aspect)
                                        .copyWith(background: bg)
                                    : spec.docBuilder!(data, aspect),
                                data: data,
                                showWatermark: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    spec.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? _kVoltLime : Colors.white70,
                      fontSize: 10.5,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Per-element editing controls. Text gets full controls; every type gets
/// the common opacity / layer / duplicate / delete row.
class _ContextPanel extends StatelessWidget {
  final CardEditorController controller;
  final CardElement element;
  const _ContextPanel({required this.controller, required this.element});

  @override
  Widget build(BuildContext context) {
    final props = element.props;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (props is TextProps)
          _TextControls(controller: controller, props: props),
        if (props is ChartProps)
          _ChartControls(controller: controller, props: props),
        if (props is PhotoProps)
          _PhotoControls(controller: controller, props: props),
        if (props is ShapeProps)
          _ShapeControls(controller: controller, props: props),
        if (props is BadgeProps)
          _BadgeControls(controller: controller, props: props),
        if (props is DateStampProps)
          _DateStampControls(controller: controller, props: props),
        if (props is IconProps)
          _IconControls(controller: controller, props: props),
        if (props is ImageProps)
          _ImageControls(controller: controller, props: props),
        if (props is DividerProps)
          _DividerControls(controller: controller, props: props),
        if (props is FrameProps)
          _FrameControls(controller: controller, props: props),
        if (props is TextureProps)
          _TextureControls(controller: controller, props: props),
        if (props is QrProps)
          _QrControls(controller: controller, props: props),
        if (props is ChipGroupProps)
          _ChipGroupControls(controller: controller, props: props),
        if (props is TableProps)
          _TableControls(controller: controller, props: props),
        if (props is RepeaterProps)
          _RepeaterControls(controller: controller, props: props),
        if (props is ChatBubbleProps)
          _ChatBubbleControls(controller: controller, props: props),
        if (props is AvatarRowProps)
          _AvatarRowControls(controller: controller, props: props),
        if (props is ScrubberProps)
          _ScrubberControls(controller: controller, props: props),
        if (props is RingStatProps)
          _RingStatControls(controller: controller, props: props),
        if (props is RingTrioProps)
          _RingTrioControls(controller: controller, props: props),
        if (props is StatGridProps)
          _StatGridControls(controller: controller, props: props),
        if (props is GridHeatmapProps)
          _GridHeatmapControls(controller: controller, props: props),
        if (props is RatingStarsProps)
          _RatingStarsControls(controller: controller, props: props),
        if (props is BarcodeProps)
          _BarcodeControls(controller: controller, props: props),
        if (props is PerforationProps)
          _PerforationControls(controller: controller, props: props),
        _opacityRow(),
        const SizedBox(height: 4),
        _commonRow(context),
      ],
    );
  }

  Widget _opacityRow() {
    return Row(
      children: [
        const SizedBox(width: 4),
        const Icon(Icons.opacity_rounded, size: 15, color: Colors.white54),
        const SizedBox(width: 6),
        const Text('Opacity',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        Expanded(
          child: Slider(
            value: element.opacity.clamp(0.0, 1.0),
            onChanged: (v) => controller
                .updateSelected((e) => e.copyWith(opacity: v)),
          ),
        ),
      ],
    );
  }

  Widget _commonRow(BuildContext context) {
    Widget btn(IconData icon, String label, VoidCallback onTap,
        {Color? color}) {
      return TextButton(
        onPressed: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? Colors.white),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color ?? Colors.white70, fontSize: 10)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          btn(Icons.flip_to_front_rounded, 'Front',
              controller.bringSelectedToFront),
          btn(Icons.flip_to_back_rounded, 'Back',
              controller.sendSelectedToBack),
          // 3D perspective (B2) — cube sheet of Flat / Left / Right / Floor.
          btn(Icons.view_in_ar_rounded, 'Perspective',
              () => _openPerspective(context)),
          btn(Icons.copy_rounded, 'Duplicate', controller.duplicateSelected),
          btn(
            element.locked ? Icons.lock_rounded : Icons.lock_open_rounded,
            element.locked ? 'Locked' : 'Lock',
            () => controller.toggleLocked(element.id),
          ),
          btn(
            element.hidden
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            element.hidden ? 'Hidden' : 'Visible',
            () => controller.toggleHidden(element.id),
          ),
          btn(Icons.delete_outline_rounded, 'Delete',
              controller.deleteSelected,
              color: const Color(0xFFFF6B6B)),
          btn(Icons.check_rounded, 'Done', controller.deselect,
              color: const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  /// Cube "Perspective" sheet (B2) — tilts the selected element on a faux-3D
  /// wall/floor plane.
  void _openPerspective(BuildContext context) {
    final current = element.transform.perspective;
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        opaque: true,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Perspective',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final p in CardPerspective.values)
                      ChoiceChip(
                        label: Text(_perspectiveLabel(p)),
                        selected: current == p,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          controller.updateSelected(
                            (e) => e.copyWith(
                              transform:
                                  e.transform.copyWith(perspective: p),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Text controls ────────────────────────────────

class _TextControls extends StatelessWidget {
  final CardEditorController controller;
  final TextProps props;
  const _TextControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            TextButton.icon(
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit text'),
              onPressed: () => _editText(context),
            ),
            const Spacer(),
            Text('Size', style: TextStyle(color: Colors.white54, fontSize: 12)),
            SizedBox(
              width: 160,
              child: Slider(
                value: props.fontSize.clamp(12, 320),
                min: 12,
                max: 320,
                onChanged: (v) => controller.updateSelected(
                  (e) => e.copyWith(props: props.copyWith(fontSize: v)),
                ),
              ),
            ),
          ],
        ),
        // Font presets.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < kCardFonts.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(kCardFonts[i].label),
                    selected: props.fontIndex == i,
                    onSelected: (_) => controller.updateSelected(
                      (e) => e.copyWith(props: props.copyWith(fontIndex: i)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Colour swatches.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in _kTextColors)
                GestureDetector(
                  onTap: () => controller.updateSelected(
                    (e) => e.copyWith(props: props.copyWith(color: c)),
                  ),
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: props.color == c
                            ? const Color(0xFF3B82F6)
                            : Colors.white24,
                        width: props.color == c ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Marker / highlight (B4) — a per-line block painted behind the glyphs
        // (Gravl's "marker" date variant). First chip clears it.
        Row(
          children: [
            const Text('Marker',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => controller.updateSelected(
                        (e) => e.copyWith(
                            props: props.copyWith(clearHighlight: true)),
                      ),
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: props.highlightColor == null
                                ? const Color(0xFF3B82F6)
                                : Colors.white24,
                            width: props.highlightColor == null ? 3 : 1,
                          ),
                        ),
                        child: const Icon(Icons.format_color_reset_rounded,
                            size: 15, color: Colors.white54),
                      ),
                    ),
                    for (final c in _kTextColors.where((c) => c != Colors.white))
                      GestureDetector(
                        onTap: () => controller.updateSelected(
                          (e) =>
                              e.copyWith(props: props.copyWith(highlightColor: c)),
                        ),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: props.highlightColor == c
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white24,
                              width: props.highlightColor == c ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editText(BuildContext context) async {
    final ctrl = TextEditingController(text: props.literal);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit text'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Type here…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    // Editing detaches the element from its data binding — user text wins.
    controller.updateSelected(
      (e) => e.copyWith(
        props: props.copyWith(literal: result, binding: DataBinding.none),
      ),
    );
  }
}

const List<Color> _kTextColors = [
  Color(0xFFFFFFFF),
  Color(0xFF111111),
  Color(0xFFFFD23F),
  Color(0xFFFF6B6B),
  Color(0xFF06B6D4),
  Color(0xFFA855F7),
  Color(0xFF22C55E),
  Color(0xFFF97316),
];

/// Short UI label for a [PhotoFilter] (✨ effects row + background filter row).
String _photoFilterLabel(PhotoFilter f) {
  switch (f) {
    case PhotoFilter.original:
      return 'Original';
    case PhotoFilter.darker:
      return 'Darker';
    case PhotoFilter.bw:
      return 'B&W';
    case PhotoFilter.warm:
      return 'Warm';
    case PhotoFilter.cool:
      return 'Cool';
    case PhotoFilter.fade:
      return 'Fade';
  }
}

/// Short UI label for a [CardPerspective] (cube "Perspective" sheet).
String _perspectiveLabel(CardPerspective p) {
  switch (p) {
    case CardPerspective.flat:
      return 'Flat';
    case CardPerspective.leftWall:
      return 'Left wall';
    case CardPerspective.rightWall:
      return 'Right wall';
    case CardPerspective.floor:
      return 'Floor';
  }
}

// ─────────────────────────── Chart controls ───────────────────────────────

class _ChartControls extends StatelessWidget {
  final CardEditorController controller;
  final ChartProps props;
  const _ChartControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final k in ChartKind.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(k.name),
                    selected: props.kind == k,
                    onSelected: (_) => controller.updateSelected(
                      (e) => e.copyWith(props: props.copyWith(kind: k)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (props.kind == ChartKind.macro)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final style in MacroVizStyle.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text(style.name),
                      selected: props.macroStyle == style,
                      onSelected: (_) => controller.updateSelected(
                        (e) => e.copyWith(props: props.copyWith(macroStyle: style)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────── Photo controls ───────────────────────────────

class _PhotoControls extends StatelessWidget {
  final CardEditorController controller;
  final PhotoProps props;
  const _PhotoControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            TextButton.icon(
              icon: const Icon(Icons.image_rounded, size: 16),
              label: const Text('Replace photo'),
              onPressed: _replacePhoto,
            ),
            const Spacer(),
            const Text('Fit',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Cover'),
              selected: props.fit == BoxFit.cover,
              onSelected: (_) => controller.updateSelected(
                (e) => e.copyWith(props: props.copyWith(fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(width: 4),
            ChoiceChip(
              label: const Text('Contain'),
              selected: props.fit == BoxFit.contain,
              onSelected: (_) => controller.updateSelected(
                (e) => e.copyWith(props: props.copyWith(fit: BoxFit.contain)),
              ),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final mask in PhotoMask.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(mask.name),
                    selected: props.mask == mask,
                    onSelected: (_) => controller.updateSelected(
                      (e) => e.copyWith(props: props.copyWith(mask: mask)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // ✨ Photo effects (B1) — Original / Darker / B&W / Warm / Cool / Fade.
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 15, color: Colors.white54),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in PhotoFilter.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text(_photoFilterLabel(f)),
                          selected: props.filter == f,
                          onSelected: (_) => controller.updateSelected(
                            (e) => e.copyWith(props: props.copyWith(filter: f)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _replacePhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2160,
        maxHeight: 2160,
        imageQuality: 92,
      );
      if (picked == null) return;
      controller.updateSelected(
        (e) => e.copyWith(
          props: props.copyWith(
            source: props.source.copyWith(staticPath: picked.path),
          ),
        ),
      );
    } catch (_) {
      /* picker cancelled / unavailable */
    }
  }
}

// ─────────────────────────── Shape controls ───────────────────────────────

class _ShapeControls extends StatelessWidget {
  final CardEditorController controller;
  final ShapeProps props;
  const _ShapeControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final kind in ShapeKind.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(kind.name),
                    selected: props.shape == kind,
                    onSelected: (_) => controller.updateSelected(
                      (e) => e.copyWith(props: props.copyWith(shape: kind)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in _kTextColors)
                GestureDetector(
                  onTap: () => controller.updateSelected(
                    (e) => e.copyWith(
                      props: props.copyWith(fillColor: c, clearGradient: true),
                    ),
                  ),
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: props.fillColor == c
                            ? const Color(0xFF3B82F6)
                            : Colors.white24,
                        width: props.fillColor == c ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Shared inspector bits ────────────────────────

/// A single-field text-edit dialog used by the value inspectors. Returns the
/// new value, or null on cancel.
Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String initial,
  String hint = 'Type here…',
}) async {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

/// A compact horizontal colour-swatch row shared by the value inspectors.
class _SwatchRow extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onPick;
  const _SwatchRow({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in _kTextColors)
            GestureDetector(
              onTap: () => onPick(c),
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected.toARGB32() == c.toARGB32()
                        ? _kEditorAccent
                        : Colors.white24,
                    width: selected.toARGB32() == c.toARGB32() ? 3 : 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _editRow(BuildContext context,
    {required String label, required VoidCallback onTap}) {
  return Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      icon: const Icon(Icons.edit_rounded, size: 16),
      label: Text(label),
      onPressed: onTap,
    ),
  );
}

// ─────────────────────────── Badge controls ───────────────────────────────

class _BadgeControls extends StatelessWidget {
  final CardEditorController controller;
  final BadgeProps props;
  const _BadgeControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _editRow(context,
                label: 'Edit value', onTap: () => _edit(context, value: true)),
            _editRow(context,
                label: 'Edit label',
                onTap: () => _edit(context, value: false)),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in BadgeShape.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(s.name),
                    selected: props.shape == s,
                    onSelected: (_) => controller.updateSelected(
                      (e) => e.copyWith(props: props.copyWith(shape: s)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, {required bool value}) async {
    final r = await _promptText(
      context,
      title: value ? 'Badge value' : 'Badge label',
      initial: value ? props.valueLiteral : props.label,
    );
    if (r == null) return;
    controller.updateSelected((e) => e.copyWith(
          props: value
              // Editing the value detaches it from its data binding.
              ? props.copyWith(
                  valueLiteral: r,
                  valueBinding: DataBinding.none,
                )
              : props.copyWith(label: r),
        ));
  }
}

// ─────────────────────────── Date-stamp controls ──────────────────────────

class _DateStampControls extends StatelessWidget {
  final CardEditorController controller;
  final DateStampProps props;
  const _DateStampControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _editRow(context, label: 'Edit text', onTap: () => _edit(context)),
            const Spacer(),
            const Text('Pill',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Switch.adaptive(
              value: props.pill,
              onChanged: (v) => controller.updateSelected(
                (e) => e.copyWith(props: props.copyWith(pill: v)),
              ),
            ),
          ],
        ),
        _SwatchRow(
          selected: props.color,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(color: c)),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    final r = await _promptText(
      context,
      title: 'Date / label',
      initial: props.literal,
      hint: 'Leave blank to use the log date',
    );
    if (r == null) return;
    controller.updateSelected((e) => e.copyWith(
          props: props.copyWith(
            literal: r,
            // A non-empty literal wins over the bound period label.
            binding: r.isEmpty
                ? const DataBinding(BindingSource.periodLabel)
                : DataBinding.none,
          ),
        ));
  }
}

// ─────────────────────────── Icon / sticker controls ──────────────────────

class _IconControls extends StatelessWidget {
  final CardEditorController controller;
  final IconProps props;
  const _IconControls({required this.controller, required this.props});

  static const List<String> _emojis = [
    '✨', '🔥', '💪', '🏆', '⚡', '🎯', '🚀', '💯', '🥇', '❤️', '😤', '🧠',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final e in _emojis)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(e, style: const TextStyle(fontSize: 18)),
                    selected: props.isEmoji && props.emoji == e,
                    onSelected: (_) => controller.updateSelected(
                      (el) => el.copyWith(
                        // Switching to an emoji clears any icon codepoint.
                        props: const IconProps().copyWith(
                          emoji: e,
                          color: props.color,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _SwatchRow(
          selected: props.color,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(color: c)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Image / GIF controls ─────────────────────────

class _ImageControls extends StatelessWidget {
  final CardEditorController controller;
  final ImageProps props;
  const _ImageControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return _editRow(context,
        label: props.url.isEmpty ? 'Set image URL' : 'Edit image URL',
        onTap: () async {
      final r = await _promptText(
        context,
        title: 'Image URL',
        initial: props.url,
        hint: 'https://…',
      );
      if (r == null) return;
      controller.updateSelected(
        (e) => e.copyWith(props: props.copyWith(url: r)),
      );
    });
  }
}

// ─────────────────────────── Divider controls ─────────────────────────────

class _DividerControls extends StatelessWidget {
  final CardEditorController controller;
  final DividerProps props;
  const _DividerControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in DividerStyle.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(s.name),
                    selected: props.style == s,
                    onSelected: (_) => controller.updateSelected(
                      (e) => e.copyWith(props: props.copyWith(style: s)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _SwatchRow(
          selected: props.color,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(color: c)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Frame controls ───────────────────────────────

class _FrameControls extends StatelessWidget {
  final CardEditorController controller;
  final FrameProps props;
  const _FrameControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in FrameStyle.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(s.name),
                    selected: props.style == s,
                    onSelected: (_) => controller.updateSelected(
                      (e) => e.copyWith(props: props.copyWith(style: s)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _SwatchRow(
          selected: props.color,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(color: c)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Texture controls ─────────────────────────────

class _TextureControls extends StatelessWidget {
  final CardEditorController controller;
  final TextureProps props;
  const _TextureControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final k in TextureKind.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(k.name),
                    selected: props.kind == k,
                    onSelected: (_) => controller.updateSelected(
                      (e) => e.copyWith(props: props.copyWith(kind: k)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Intensity',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Expanded(
              child: Slider(
                value: props.intensity.clamp(0.0, 1.0),
                onChanged: (v) => controller.updateSelected(
                  (e) => e.copyWith(props: props.copyWith(intensity: v)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────── QR controls ──────────────────────────────────

class _QrControls extends StatelessWidget {
  final CardEditorController controller;
  final QrProps props;
  const _QrControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return _editRow(context,
        label: props.data.isEmpty ? 'Set QR link' : 'Edit QR link',
        onTap: () async {
      final r = await _promptText(
        context,
        title: 'QR code link',
        initial: props.data,
        hint: 'https://zealova.com/…',
      );
      if (r == null) return;
      controller.updateSelected(
        (e) => e.copyWith(props: props.copyWith(data: r)),
      );
    });
  }
}

// ─────────────────────────── Chip-group controls ──────────────────────────

class _ChipGroupControls extends StatelessWidget {
  final CardEditorController controller;
  final ChipGroupProps props;
  const _ChipGroupControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _editRow(context, label: 'Edit chips', onTap: () => _edit(context)),
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Max',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Expanded(
              child: Slider(
                value: props.maxItems.clamp(1, 12).toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label: '${props.maxItems}',
                onChanged: (v) => controller.updateSelected(
                  (e) => e.copyWith(props: props.copyWith(maxItems: v.round())),
                ),
              ),
            ),
          ],
        ),
        _SwatchRow(
          selected: props.textColor,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(textColor: c)),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    final r = await _promptText(
      context,
      title: 'Chips (comma-separated)',
      initial: props.literalItems.join(', '),
      hint: 'e.g. Bench, Squat, Deadlift',
    );
    if (r == null) return;
    final items = r
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    controller.updateSelected((e) => e.copyWith(
          props: props.copyWith(
            literalItems: items,
            // Literal chips detach from any data binding.
            itemsBinding: DataBinding.none,
          ),
        ));
  }
}

// ─────────────────────────── Table controls ───────────────────────────────

class _TableControls extends StatelessWidget {
  final CardEditorController controller;
  final TableProps props;
  const _TableControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _editRow(context, label: 'Edit rows', onTap: () => _edit(context)),
        _SwatchRow(
          selected: props.textColor,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(textColor: c)),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    // One `label: value` row per line.
    final initial =
        props.rows.map((r) => '${r.isNotEmpty ? r[0] : ''}: '
            '${r.length > 1 ? r[1] : ''}').join('\n');
    final ctrl = TextEditingController(text: initial);
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Table rows'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'One per line:\nProtein: 32g\nCarbs: 40g',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (r == null) return;
    final rows = <List<String>>[];
    for (final line in r.split('\n')) {
      if (line.trim().isEmpty) continue;
      final i = line.indexOf(':');
      if (i < 0) {
        rows.add([line.trim(), '']);
      } else {
        rows.add([line.substring(0, i).trim(), line.substring(i + 1).trim()]);
      }
    }
    controller.updateSelected(
      (e) => e.copyWith(props: props.copyWith(rows: rows)),
    );
  }
}

// ─────────────────────────── Repeater (list) controls ─────────────────────

class _RepeaterControls extends StatelessWidget {
  final CardEditorController controller;
  final RepeaterProps props;
  const _RepeaterControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    // The repeater is data-bound (food items / exercises) — there's no free
    // text to edit, but the user can tune how many rows and the toggles.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Rows',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Expanded(
              child: Slider(
                value: props.maxItems.clamp(1, 12).toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label: '${props.maxItems}',
                onChanged: (v) => controller.updateSelected(
                  (e) => e.copyWith(props: props.copyWith(maxItems: v.round())),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _toggle('Amount', props.showAmount,
                (v) => props.copyWith(showAmount: v)),
            _toggle('Calories', props.showCalories,
                (v) => props.copyWith(showCalories: v)),
            if (props.exerciseMode)
              _toggle('Image', props.showImage,
                  (v) => props.copyWith(showImage: v)),
          ],
        ),
      ],
    );
  }

  Widget _toggle(
      String label, bool value, RepeaterProps Function(bool) build) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FilterChip(
        label: Text(label),
        selected: value,
        onSelected: (v) => controller.updateSelected(
          (e) => e.copyWith(props: build(v)),
        ),
      ),
    );
  }
}

// ─────────────────────────── Chat-bubble controls ─────────────────────────

class _ChatBubbleControls extends StatelessWidget {
  final CardEditorController controller;
  final ChatBubbleProps props;
  const _ChatBubbleControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _editRow(context,
                label: 'Edit message', onTap: () => _editText(context)),
            _editRow(context,
                label: 'Edit name', onTap: () => _editSender(context)),
          ],
        ),
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Side',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 8),
            for (final s in ChatSide.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(s.name),
                  selected: props.side == s,
                  onSelected: (_) => controller.updateSelected(
                    (e) => e.copyWith(props: props.copyWith(side: s)),
                  ),
                ),
              ),
          ],
        ),
        _SwatchRow(
          selected: props.tint,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(tint: c)),
          ),
        ),
      ],
    );
  }

  Future<void> _editText(BuildContext context) async {
    final r = await _promptText(context,
        title: 'Message', initial: props.text, hint: 'Type the message…');
    if (r == null) return;
    controller.updateSelected((e) => e.copyWith(
          props: props.copyWith(text: r, textBinding: DataBinding.none),
        ));
  }

  Future<void> _editSender(BuildContext context) async {
    final r = await _promptText(context,
        title: 'Sender name',
        initial: props.sender,
        hint: 'Leave blank to hide');
    if (r == null) return;
    controller.updateSelected((e) => e.copyWith(
          props: props.copyWith(sender: r, senderBinding: DataBinding.none),
        ));
  }
}

// ─────────────────────────── Avatar-row controls ──────────────────────────

class _AvatarRowControls extends StatelessWidget {
  final CardEditorController controller;
  final AvatarRowProps props;
  const _AvatarRowControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _editRow(context,
                label: 'Edit handle', onTap: () => _editHandle(context)),
            _editRow(context,
                label: 'Edit subtitle', onTap: () => _editSub(context)),
          ],
        ),
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Verified',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Switch.adaptive(
              value: props.verified,
              onChanged: (v) => controller.updateSelected(
                (e) => e.copyWith(props: props.copyWith(verified: v)),
              ),
            ),
          ],
        ),
        _SwatchRow(
          selected: props.textColor,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(textColor: c)),
          ),
        ),
      ],
    );
  }

  Future<void> _editHandle(BuildContext context) async {
    final r = await _promptText(context,
        title: 'Handle', initial: props.handle, hint: '@yourhandle');
    if (r == null) return;
    controller.updateSelected((e) => e.copyWith(
          props: props.copyWith(handle: r, handleBinding: DataBinding.none),
        ));
  }

  Future<void> _editSub(BuildContext context) async {
    final r = await _promptText(context,
        title: 'Subtitle',
        initial: props.sub,
        hint: 'e.g. 1,204 followers');
    if (r == null) return;
    controller.updateSelected((e) => e.copyWith(
          props: props.copyWith(sub: r, subBinding: DataBinding.none),
        ));
  }
}

// ─────────────────────────── Scrubber controls ────────────────────────────

class _ScrubberControls extends StatelessWidget {
  final CardEditorController controller;
  final ScrubberProps props;
  const _ScrubberControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _editRow(context,
                label: 'Elapsed', onTap: () => _editLeft(context)),
            _editRow(context,
                label: 'Total', onTap: () => _editRight(context)),
          ],
        ),
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Progress',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Expanded(
              child: Slider(
                value: props.progress.clamp(0.0, 1.0),
                onChanged: (v) => controller.updateSelected(
                  (e) => e.copyWith(props: props.copyWith(progress: v)),
                ),
              ),
            ),
          ],
        ),
        _SwatchRow(
          selected: props.fillColor,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(fillColor: c)),
          ),
        ),
      ],
    );
  }

  Future<void> _editLeft(BuildContext context) async {
    final r = await _promptText(context,
        title: 'Elapsed time', initial: props.leftLabel, hint: '1:23');
    if (r == null) return;
    controller.updateSelected(
      (e) => e.copyWith(props: props.copyWith(leftLabel: r)),
    );
  }

  Future<void> _editRight(BuildContext context) async {
    final r = await _promptText(context,
        title: 'Total time', initial: props.rightLabel, hint: '3:05');
    if (r == null) return;
    controller.updateSelected(
      (e) => e.copyWith(props: props.copyWith(rightLabel: r)),
    );
  }
}

// ─────────────────────────── Ring-stat controls ───────────────────────────

class _RingStatControls extends StatelessWidget {
  final CardEditorController controller;
  final RingStatProps props;
  const _RingStatControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _editRow(context,
                label: 'Edit value', onTap: () => _editValue(context)),
            _editRow(context,
                label: 'Edit label', onTap: () => _editLabel(context)),
          ],
        ),
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Fill',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Expanded(
              child: Slider(
                value: props.progress.clamp(0.0, 1.0),
                onChanged: (v) => controller.updateSelected(
                  (e) => e.copyWith(
                    // Adjusting the slider detaches from any data binding.
                    props: props.copyWith(
                        progress: v, valueBinding: DataBinding.none),
                  ),
                ),
              ),
            ),
          ],
        ),
        _SwatchRow(
          selected: props.ringColor,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(ringColor: c)),
          ),
        ),
      ],
    );
  }

  Future<void> _editValue(BuildContext context) async {
    final r = await _promptText(context,
        title: 'Center value', initial: props.centerValue, hint: 'e.g. 72%');
    if (r == null) return;
    controller.updateSelected((e) => e.copyWith(
          props:
              props.copyWith(centerValue: r, centerBinding: DataBinding.none),
        ));
  }

  Future<void> _editLabel(BuildContext context) async {
    final r = await _promptText(context,
        title: 'Label', initial: props.label, hint: 'e.g. GOAL');
    if (r == null) return;
    controller.updateSelected(
      (e) => e.copyWith(props: props.copyWith(label: r)),
    );
  }
}

// ─────────────────────────── Ring-trio controls ───────────────────────────

class _RingTrioControls extends StatelessWidget {
  final CardEditorController controller;
  final RingTrioProps props;
  const _RingTrioControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    Widget ringSlider(
        String label, double value, RingTrioProps Function(double) build) {
      return Row(
        children: [
          const SizedBox(width: 4),
          SizedBox(
            width: 54,
            child: Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: (v) => controller.updateSelected(
                (e) => e.copyWith(props: build(v)),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ringSlider(
            'Outer', props.outer, (v) => props.copyWith(outer: v)),
        ringSlider(
            'Middle', props.middle, (v) => props.copyWith(middle: v)),
        ringSlider(
            'Inner', props.inner, (v) => props.copyWith(inner: v)),
      ],
    );
  }
}

// ─────────────────────────── Stat-grid controls ───────────────────────────

class _StatGridControls extends StatelessWidget {
  final CardEditorController controller;
  final StatGridProps props;
  const _StatGridControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _editRow(context, label: 'Edit tiles', onTap: () => _edit(context)),
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Columns',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Expanded(
              child: Slider(
                value: props.columns.clamp(1, 4).toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                label: '${props.columns}',
                onChanged: (v) => controller.updateSelected(
                  (e) => e.copyWith(props: props.copyWith(columns: v.round())),
                ),
              ),
            ),
          ],
        ),
        _SwatchRow(
          selected: props.valueColor,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(valueColor: c)),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    // One `value: label` tile per line.
    final initial = props.tiles
        .map((t) => '${t.isNotEmpty ? t[0] : ''}: '
            '${t.length > 1 ? t[1] : ''}')
        .join('\n');
    final ctrl = TextEditingController(text: initial);
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stat tiles'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'One per line:\n12: WORKOUTS\n7: PRs',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (r == null) return;
    final tiles = <List<String>>[];
    for (final line in r.split('\n')) {
      if (line.trim().isEmpty) continue;
      final i = line.indexOf(':');
      if (i < 0) {
        tiles.add([line.trim(), '']);
      } else {
        tiles.add([line.substring(0, i).trim(), line.substring(i + 1).trim()]);
      }
    }
    controller.updateSelected(
      (e) => e.copyWith(props: props.copyWith(tiles: tiles)),
    );
  }
}

// ─────────────────────────── Heatmap controls ─────────────────────────────

class _GridHeatmapControls extends StatelessWidget {
  final CardEditorController controller;
  final GridHeatmapProps props;
  const _GridHeatmapControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Columns',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Expanded(
              child: Slider(
                value: props.columns.clamp(4, 20).toDouble(),
                min: 4,
                max: 20,
                divisions: 16,
                label: '${props.columns}',
                onChanged: (v) => controller.updateSelected(
                  (e) => e.copyWith(props: props.copyWith(columns: v.round())),
                ),
              ),
            ),
          ],
        ),
        _SwatchRow(
          selected: props.cellColor,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(cellColor: c)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Rating-stars controls ────────────────────────

class _RatingStarsControls extends StatelessWidget {
  final CardEditorController controller;
  final RatingStarsProps props;
  const _RatingStarsControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Rating',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Expanded(
              child: Slider(
                value: props.rating.clamp(0.0, props.count.toDouble()),
                min: 0,
                max: props.count.toDouble(),
                divisions: props.count * 2,
                label: props.rating.toStringAsFixed(1),
                onChanged: (v) => controller.updateSelected(
                  (e) => e.copyWith(props: props.copyWith(rating: v)),
                ),
              ),
            ),
          ],
        ),
        _SwatchRow(
          selected: props.filledColor,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(filledColor: c)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Barcode controls ─────────────────────────────

class _BarcodeControls extends StatelessWidget {
  final CardEditorController controller;
  final BarcodeProps props;
  const _BarcodeControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _editRow(context,
                label: 'Edit code', onTap: () => _editData(context)),
            _editRow(context,
                label: 'Edit caption', onTap: () => _editCaption(context)),
          ],
        ),
        _SwatchRow(
          selected: props.barColor,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(barColor: c)),
          ),
        ),
      ],
    );
  }

  Future<void> _editData(BuildContext context) async {
    final r = await _promptText(context,
        title: 'Barcode value',
        initial: props.data,
        hint: 'Drives the stripe pattern');
    if (r == null) return;
    controller.updateSelected(
      (e) => e.copyWith(props: props.copyWith(data: r)),
    );
  }

  Future<void> _editCaption(BuildContext context) async {
    final r = await _promptText(context,
        title: 'Caption',
        initial: props.caption,
        hint: 'Leave blank to hide');
    if (r == null) return;
    controller.updateSelected((e) => e.copyWith(
          props: props.copyWith(
            caption: r,
            captionBinding: DataBinding.none,
            showCaption: r.trim().isNotEmpty,
          ),
        ));
  }
}

// ─────────────────────────── Perforation controls ─────────────────────────

class _PerforationControls extends StatelessWidget {
  final CardEditorController controller;
  final PerforationProps props;
  const _PerforationControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final ed in PerforationEdge.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(ed.name),
                    selected: props.edge == ed,
                    onSelected: (_) => controller.updateSelected(
                      (e) => e.copyWith(props: props.copyWith(edge: ed)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 4),
            const Text('Notches',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Switch.adaptive(
              value: props.showNotches,
              onChanged: (v) => controller.updateSelected(
                (e) => e.copyWith(props: props.copyWith(showNotches: v)),
              ),
            ),
          ],
        ),
        _SwatchRow(
          selected: props.color,
          onPick: (c) => controller.updateSelected(
            (e) => e.copyWith(props: props.copyWith(color: c)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Background sheet ──────────────────────────────

class _BackgroundSheet extends StatefulWidget {
  final CardEditorController controller;
  final Shareable data;
  const _BackgroundSheet({required this.controller, required this.data});

  @override
  State<_BackgroundSheet> createState() => _BackgroundSheetState();
}

class _BackgroundSheetState extends State<_BackgroundSheet> {
  static const List<Color> _solids = [
    Color(0xFF0D1117), Color(0xFF15171C), Color(0xFF1C2128),
    Color(0xFFFFFFFF), Color(0xFFF4EFE6), Color(0xFF111111),
    Color(0xFF4F5BD5), Color(0xFFD62976), Color(0xFFFA7E1E),
    Color(0xFF16A34A), Color(0xFF6B7280), Color(0xFFF59E0B),
  ];

  static const List<List<Color>> _gradients = [
    [Color(0xFF4F5BD5), Color(0xFFD62976)],
    [Color(0xFFFA7E1E), Color(0xFFD62976)],
    [Color(0xFF0D1117), Color(0xFF1C2128)],
    [Color(0xFF16A34A), Color(0xFF0D1117)],
    [Color(0xFFF59E0B), Color(0xFF7C2D12)],
    [Color(0xFF6366F1), Color(0xFF0D1117)],
  ];

  /// Bundled background packs — drawn from the shared
  /// [kStockBackgroundPacks] registry (`stock_backgrounds.dart`) so the
  /// compose screen and this sheet stay in sync. Applying one sets a photo
  /// [CardBackground] whose `staticPath` is the asset.

  /// Colours extracted from the user's meal photo (the AI palette assist).
  List<Color> _photoPalette = const [];

  @override
  void initState() {
    super.initState();
    _loadPalette();
  }

  /// Applies a bundled-asset background image.
  void _setAssetPhoto(String assetPath, {bool blurred = false}) {
    widget.controller.setBackground(
      CardBackground(
        kind: blurred
            ? CardBackgroundKind.blurredPhoto
            : CardBackgroundKind.photo,
        photo: CardPhotoRef(staticPath: assetPath),
        photoFit: BoxFit.cover,
      ),
    );
  }

  /// Binds the background to THIS log's own photo — hero image for a workout,
  /// the first food photo for a meal. Re-renders live against the payload.
  void _setLogPhoto(BindingSource source) {
    widget.controller.setBackground(
      CardBackground(
        kind: CardBackgroundKind.photo,
        photo: CardPhotoRef(binding: DataBinding(source)),
        photoFit: BoxFit.cover,
      ),
    );
  }

  /// The log-photo source available for this payload (hero for workouts,
  /// food photo for meals), or null when the log carries no photo.
  BindingSource? get _logPhotoSource {
    final d = widget.data;
    if (d.heroImageUrl != null && d.heroImageUrl!.isNotEmpty) {
      return BindingSource.heroImageUrl;
    }
    final foods = d.foodImageUrls;
    if (foods != null && foods.isNotEmpty) return BindingSource.foodImageUrl;
    if (d.customPhotoPath != null && d.customPhotoPath!.isNotEmpty) {
      return BindingSource.customPhotoPath;
    }
    return null;
  }

  Future<void> _loadPalette() async {
    final urls = widget.data.foodImageUrls;
    final source = (urls != null && urls.isNotEmpty)
        ? urls.first
        : widget.data.customPhotoPath;
    if (source == null || source.isEmpty) return;
    final palette = await extractCardPalette(source);
    if (mounted) setState(() => _photoPalette = palette);
  }

  void _setSolid(Color c) => widget.controller.setBackground(
        CardBackground(kind: CardBackgroundKind.solid, colors: [c]),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Background',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  // ✨ Photo effects (B1) for a photo/stock background.
                  if (widget.controller.doc.background.kind ==
                          CardBackgroundKind.photo ||
                      widget.controller.doc.background.kind ==
                          CardBackgroundKind.blurredPhoto) ...[
                    const SizedBox(height: 12),
                    const Text('Photo effect',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in PhotoFilter.values)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: ChoiceChip(
                                label: Text(_photoFilterLabel(f)),
                                selected:
                                    widget.controller.doc.background.filter ==
                                        f,
                                onSelected: (_) =>
                                    widget.controller.setBackground(
                                  widget.controller.doc.background
                                      .copyWith(filter: f),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (_photoPalette.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('From your photo',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in _photoPalette)
                          _swatch(gradient: [c, c], onTap: () => _setSolid(c)),
                        _swatch(
                          gradient: _photoPalette.length >= 2
                              ? [_photoPalette[0], _photoPalette[1]]
                              : [_photoPalette.first, _photoPalette.first],
                          onTap: () => widget.controller.setBackground(
                            CardBackground(
                              kind: CardBackgroundKind.linearGradient,
                              colors: _photoPalette.length >= 2
                                  ? [_photoPalette[0], _photoPalette[1]]
                                  : [_photoPalette.first, _photoPalette.first],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // ── This log's own photo ──
                  if (_logPhotoSource != null) ...[
                    const SizedBox(height: 14),
                    const Text("This log's photo",
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _logPhotoTile(blurred: false),
                        const SizedBox(width: 10),
                        _logPhotoTile(blurred: true),
                      ],
                    ),
                  ],
                  // ── Bundled background packs ──
                  for (final pack in kStockBackgroundPacks) ...[
                    const SizedBox(height: 14),
                    Text(pack.name,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pack.assets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) =>
                            _packTile(pack.assets[i]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('Solid',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in _solids)
                        _swatch(gradient: [c, c], onTap: () => _setSolid(c)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Gradient',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final g in _gradients)
                        _swatch(
                          gradient: g,
                          onTap: () => widget.controller.setBackground(
                            CardBackground(
                              kind: CardBackgroundKind.linearGradient,
                              colors: g,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _swatch({required List<Color> gradient, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                gradient.length >= 2 ? gradient : [...gradient, ...gradient],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
      ),
    );
  }

  /// One bundled-pack thumbnail. Highlights when the current background uses
  /// this asset.
  Widget _packTile(String assetPath) {
    final bg = widget.controller.doc.background;
    final selected = (bg.kind == CardBackgroundKind.photo ||
            bg.kind == CardBackgroundKind.blurredPhoto) &&
        bg.photo?.staticPath == assetPath;
    return GestureDetector(
      onTap: () => _setAssetPhoto(assetPath),
      onLongPress: () => _setAssetPhoto(assetPath, blurred: true),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 64,
          height: 84,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? _kVoltLime : Colors.white24,
              width: selected ? 2.4 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFF1C2128),
              child: Icon(Icons.image_rounded,
                  color: Colors.white24, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  /// The "this log's photo" tile (sharp or blurred). Renders the bound photo
  /// live via the same FoodImage path the card uses.
  Widget _logPhotoTile({required bool blurred}) {
    final source = _logPhotoSource;
    if (source == null) return const SizedBox.shrink();
    final url = resolvePhotoUrl(CardPhotoRef(binding: DataBinding(source)),
        widget.data);
    final bg = widget.controller.doc.background;
    final selected = bg.photo?.binding.source == source &&
        bg.photo?.staticPath == null &&
        ((blurred && bg.kind == CardBackgroundKind.blurredPhoto) ||
            (!blurred && bg.kind == CardBackgroundKind.photo));
    return GestureDetector(
      onTap: () {
        if (blurred) {
          widget.controller.setBackground(
            CardBackground(
              kind: CardBackgroundKind.blurredPhoto,
              photo: CardPhotoRef(binding: DataBinding(source)),
              photoFit: BoxFit.cover,
            ),
          );
        } else {
          _setLogPhoto(source);
        }
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 64,
              height: 84,
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? _kVoltLime : Colors.white24,
                  width: selected ? 2.4 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: blurred
                  ? ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: FoodImage(url: url, fit: BoxFit.cover),
                    )
                  : FoodImage(url: url, fit: BoxFit.cover),
            ),
          ),
          if (blurred)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('Blur',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Variations browser ───────────────────────────

/// The phone-customizer "Variations" gallery: every editable template that
/// fits the current [Shareable.kind], rendered as a live thumbnail. Tapping
/// one rebuilds the whole [CardDoc] from that template's `docBuilder` (one
/// undo step). Keeps the current aspect so the layout reflows in place.
class _VariationsSheet extends StatelessWidget {
  final CardEditorController controller;
  final Shareable data;
  const _VariationsSheet({required this.controller, required this.data});

  /// Editable templates available for this payload, in catalog order.
  List<ShareableTemplateSpec> _specs() => ShareableCatalog.availableFor(data)
      .where((s) => s.docBuilder != null)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final specs = _specs();
    final aspect = controller.doc.aspect;
    final currentPreset = controller.doc.presetId;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Variations',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                Spacer(),
                Text('tap to switch template',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            if (specs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No other layouts for this share',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: specs.length,
                  itemBuilder: (context, i) {
                    final spec = specs[i];
                    final selected = spec.template.name == currentPreset;
                    return _VariationTile(
                      spec: spec,
                      data: data,
                      aspect: aspect,
                      selected: selected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        // Build at the editor's current aspect so the swap
                        // lands in the same ratio the user is editing in.
                        final next = spec.docBuilder!(data, aspect);
                        controller.swapDoc(next);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VariationTile extends StatelessWidget {
  final ShareableTemplateSpec spec;
  final Shareable data;
  final ShareableAspect aspect;
  final bool selected;
  final VoidCallback onTap;

  const _VariationTile({
    required this.spec,
    required this.data,
    required this.aspect,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build the preset once for the thumbnail. Cheap value objects; a single
    // render at thumbnail scale.
    final doc = spec.docBuilder!(data, aspect);
    final design = aspect.size;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? _kVoltLime : Colors.white12,
                    width: selected ? 2.4 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: design.width,
                    height: design.height,
                    child: Directionality(
                      textDirection:
                          Directionality.maybeOf(context) ?? TextDirection.ltr,
                      child: CardDocRenderer(
                        doc: doc,
                        data: data,
                        // Thumbnails never show the watermark — keeps the
                        // gallery clean and avoids 60 tiny logos.
                        showWatermark: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            spec.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _kVoltLime : Colors.white70,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Palette / accent panel ───────────────────────

/// A swatch sheet that recolors the whole card's accent
/// ([CardDoc.accentColor]). Volt-lime leads (the redesign signature); the
/// rest are a curated editorial spread.
class _PaletteSheet extends StatelessWidget {
  final CardEditorController controller;
  const _PaletteSheet({required this.controller});

  static const List<Color> _accents = [
    _kVoltLime, // signature
    Color(0xFFF97316), // orange (legacy default)
    Color(0xFFFF2D55), // hot red
    Color(0xFFFF6B6B), // coral
    Color(0xFFFFD23F), // amber
    Color(0xFF34D399), // mint
    Color(0xFF22C55E), // green
    Color(0xFF06B6D4), // cyan
    Color(0xFF3B82F6), // blue
    Color(0xFF6366F1), // indigo
    Color(0xFFA855F7), // violet
    Color(0xFFEC4899), // magenta
    Color(0xFFFFFFFF), // white
    Color(0xFF9CA3AF), // steel
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final current = controller.doc.accentColor;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Accent',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Recolors charts, scores and accent text',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final c in _accents)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          controller.setAccentColor(c);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: current.toARGB32() == c.toARGB32()
                                  ? Colors.white
                                  : Colors.white24,
                              width: current.toARGB32() == c.toARGB32() ? 3 : 1,
                            ),
                          ),
                          child: current.toARGB32() == c.toARGB32()
                              ? Icon(Icons.check_rounded,
                                  size: 22,
                                  color: ThemeData.estimateBrightnessForColor(
                                              c) ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Layers sheet ─────────────────────────────────

class _LayersSheet extends StatelessWidget {
  final CardEditorController controller;
  const _LayersSheet({required this.controller});

  static (IconData, String) _meta(CardElementType t) {
    switch (t) {
      case CardElementType.text:
        return (Icons.text_fields_rounded, 'Text');
      case CardElementType.photo:
        return (Icons.image_rounded, 'Photo');
      case CardElementType.chart:
        return (Icons.donut_large_rounded, 'Macros');
      case CardElementType.scrim:
        return (Icons.gradient_rounded, 'Scrim');
      case CardElementType.shape:
        return (Icons.category_rounded, 'Shape');
      case CardElementType.divider:
        return (Icons.horizontal_rule_rounded, 'Divider');
      case CardElementType.badge:
        return (Icons.workspace_premium_rounded, 'Badge');
      case CardElementType.chipGroup:
        return (Icons.label_rounded, 'Chips');
      case CardElementType.icon:
        return (Icons.emoji_emotions_rounded, 'Sticker');
      case CardElementType.image:
        return (Icons.gif_box_rounded, 'Image');
      case CardElementType.watermark:
        return (Icons.branding_watermark_rounded, 'Logo');
      case CardElementType.dateStamp:
        return (Icons.calendar_today_rounded, 'Date');
      case CardElementType.repeater:
        return (Icons.list_rounded, 'List');
      case CardElementType.table:
        return (Icons.table_rows_rounded, 'Table');
      case CardElementType.frame:
        return (Icons.crop_square_rounded, 'Frame');
      case CardElementType.qr:
        return (Icons.qr_code_2_rounded, 'QR');
      case CardElementType.texture:
        return (Icons.grain_rounded, 'Texture');
      case CardElementType.chatBubble:
        return (Icons.chat_bubble_rounded, 'Bubble');
      case CardElementType.avatarRow:
        return (Icons.account_circle_rounded, 'Avatar');
      case CardElementType.scrubber:
        return (Icons.graphic_eq_rounded, 'Scrubber');
      case CardElementType.ringStat:
        return (Icons.donut_small_rounded, 'Ring');
      case CardElementType.ringTrio:
        return (Icons.track_changes_rounded, 'Rings');
      case CardElementType.statGrid:
        return (Icons.grid_view_rounded, 'Stat grid');
      case CardElementType.gridHeatmap:
        return (Icons.calendar_view_month_rounded, 'Heatmap');
      case CardElementType.ratingStars:
        return (Icons.star_rounded, 'Stars');
      case CardElementType.barcode:
        return (Icons.view_week_rounded, 'Barcode');
      case CardElementType.perforation:
        return (Icons.more_horiz_rounded, 'Perforation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final elements = controller.doc.elements;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Text('Layers',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      Spacer(),
                      Text('drag to reorder',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: true,
                    itemCount: elements.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) newIndex -= 1;
                      controller.moveElement(elements[oldIndex].id, newIndex);
                    },
                    itemBuilder: (context, i) {
                      final el = elements[i];
                      final (icon, label) = _meta(el.type);
                      final selected = el.id == controller.selectedId;
                      return ListTile(
                        key: ValueKey(el.id),
                        dense: true,
                        leading: Icon(icon,
                            color: selected
                                ? const Color(0xFF3B82F6)
                                : Colors.white70,
                            size: 20),
                        title: Text(label,
                            style: TextStyle(
                                color: selected
                                    ? const Color(0xFF3B82F6)
                                    : Colors.white,
                                fontSize: 14)),
                        onTap: () {
                          controller.select(el.id);
                          Navigator.of(context).pop();
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                el.hidden
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 18,
                                color: Colors.white54,
                              ),
                              onPressed: () => controller.toggleHidden(el.id),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                el.locked
                                    ? Icons.lock_rounded
                                    : Icons.lock_open_rounded,
                                size: 18,
                                color: Colors.white54,
                              ),
                              onPressed: () => controller.toggleLocked(el.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
