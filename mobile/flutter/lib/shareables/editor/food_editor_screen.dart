import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/share_service.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/food_image.dart';
import '../widgets/macro_viz.dart';
import 'editor_layer.dart';
import 'giphy_picker.dart';

/// Full-screen layer editor for a share — a fixed background with
/// draggable / resizable / rotatable layers on top (macro viz, custom
/// text, emoji stickers, score badge, date, watermark).
///
/// The background is either the raw food photo (legacy) OR, when
/// [canvasBackground] is supplied, the share sheet's currently-selected
/// TEMPLATE rendered as a card — so any template (Rings, Numbers, Pie …)
/// can be customized with layers, not just photos.
///
/// Launched from the `ShareableSheet` "Customize" action. Self-contained:
/// it captures its own canvas and shares via [ShareService].
class FoodEditorScreen extends StatefulWidget {
  final Shareable data;

  /// When provided, the editor canvas is this widget (the selected share
  /// template rendered as a card) instead of the raw food photo.
  final Widget? canvasBackground;

  /// Aspect to lock the canvas to (chosen in the share sheet). When
  /// [canvasBackground] is set the in-editor aspect toggle is hidden —
  /// the template was already rendered at this aspect.
  final ShareableAspect? canvasAspect;

  const FoodEditorScreen({
    super.key,
    required this.data,
    this.canvasBackground,
    this.canvasAspect,
  });

  static Future<void> open(
    BuildContext context,
    Shareable data, {
    Widget? canvasBackground,
    ShareableAspect? canvasAspect,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FoodEditorScreen(
          data: data,
          canvasBackground: canvasBackground,
          canvasAspect: canvasAspect,
        ),
      ),
    );
  }

  @override
  State<FoodEditorScreen> createState() => _FoodEditorScreenState();
}

class _FoodEditorScreenState extends State<FoodEditorScreen> {
  final GlobalKey _captureKey = GlobalKey();
  final List<EditorLayer> _layers = [];
  String? _selectedId;
  ShareableAspect _aspect = ShareableAspect.story;
  bool _busy = false;
  int _seq = 0;

  /// A camera-roll photo the user picked inside the editor — overrides the
  /// share's own photo (lets a text/barcode log become a photo share).
  String? _photoOverride;

  // Per-gesture snapshot.
  Offset _basePos = Offset.zero;
  double _baseScale = 1;
  double _baseRotation = 0;
  Offset _dragAccum = Offset.zero;

  @override
  void initState() {
    super.initState();
    _aspect = widget.canvasAspect ??
        (widget.data.aspect == ShareableAspect.story
            ? ShareableAspect.story
            : widget.data.aspect);
    // Seed default layers ONLY in raw-photo mode. When customizing a
    // template the card already shows the title + macros, so seeding the
    // same things again would just duplicate them.
    if (widget.canvasBackground == null) {
      _layers.add(EditorLayer(
        id: _id(),
        kind: EditorLayerKind.macroViz,
        position: const Offset(0.74, 0.80),
        macroStyle: MacroVizStyle.coin,
      ));
      final title = widget.data.title.trim();
      if (title.isNotEmpty) {
        _layers.add(EditorLayer(
          id: _id(),
          kind: EditorLayerKind.text,
          position: const Offset(0.5, 0.16),
          text: title,
          fontIndex: 1,
        ));
      }
    }
  }

  String _id() => 'L${_seq++}';

  EditorLayer? get _selected {
    for (final l in _layers) {
      if (l.id == _selectedId) return l;
    }
    return null;
  }

  void _mutateSelected(EditorLayer Function(EditorLayer) f) {
    final i = _layers.indexWhere((l) => l.id == _selectedId);
    if (i < 0) return;
    setState(() => _layers[i] = f(_layers[i]));
  }

  // ─────────────────────────── layer add / edit ──────────────────────────
  void _addLayer(EditorLayerKind kind) {
    HapticFeedback.selectionClick();
    final layer = EditorLayer(
      id: _id(),
      kind: kind,
      position: Offset(0.5, 0.42 + (_layers.length % 4) * 0.04),
      text: kind == EditorLayerKind.emoji ? kEditorEmojis.first : '',
    );
    setState(() {
      _layers.add(layer);
      _selectedId = layer.id;
    });
    if (kind == EditorLayerKind.text) _editText(layer);
    if (kind == EditorLayerKind.emoji) _pickEmoji(layer);
  }

  Future<void> _editText(EditorLayer layer) async {
    final controller = TextEditingController(text: layer.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15171C),
        title: const Text('Text', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Type anything…',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final i = _layers.indexWhere((l) => l.id == layer.id);
    if (i < 0) return;
    if (result.trim().isEmpty) {
      setState(() => _layers.removeAt(i));
    } else {
      setState(() => _layers[i] = _layers[i].copyWith(text: result.trim()));
    }
  }

  Future<void> _pickEmoji(EditorLayer layer) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF15171C),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in kEditorEmojis)
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, e),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    final i = _layers.indexWhere((l) => l.id == layer.id);
    if (i >= 0) {
      setState(() => _layers[i] = _layers[i].copyWith(text: picked));
    }
  }

  Future<void> _pickGif() async {
    final url = await GiphyPicker.pick(context);
    if (url == null || !mounted) return;
    final layer = EditorLayer(
      id: _id(),
      kind: EditorLayerKind.gif,
      position: Offset(0.5, 0.42 + (_layers.length % 4) * 0.04),
      gifUrl: url,
    );
    setState(() {
      _layers.add(layer);
      _selectedId = layer.id;
    });
  }

  void _deleteSelected() {
    HapticFeedback.lightImpact();
    setState(() {
      _layers.removeWhere((l) => l.id == _selectedId);
      _selectedId = null;
    });
  }

  // ─────────────────────────── capture / share ───────────────────────────
  Future<void> _share() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _selectedId = null; // never capture selection chrome
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || boundary.size.isEmpty) {
        _toast('Could not render — try again');
        return;
      }
      final scale = _aspect.size.width / boundary.size.width;
      final image = await boundary.toImage(pixelRatio: scale);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        _toast('Could not render — try again');
        return;
      }
      final png = bytes.buffer.asUint8List();
      if (!mounted) return;
      final action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF15171C),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetAction(ctx, 'instagram', Icons.camera_alt_rounded,
                  'Instagram Stories'),
              _sheetAction(ctx, 'share', Icons.share_rounded, 'Share to…'),
              _sheetAction(ctx, 'save', Icons.save_alt_rounded,
                  'Save to gallery'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (action == null) return;
      switch (action) {
        case 'instagram':
          final r = await ShareService.shareToInstagramStories(png);
          if (r.success) await ShareService.saveToGallery(png);
          break;
        case 'share':
          await ShareService.shareGeneric(png, caption: 'My meal');
          break;
        case 'save':
          final r = await ShareService.saveToGallery(png);
          if (mounted) {
            _toast(r.success ? 'Saved to gallery' : 'Save failed');
          }
          break;
      }
    } catch (e) {
      debugPrint('❌ [FoodEditor] share failed: $e');
      _toast('Something went wrong');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _sheetAction(
      BuildContext ctx, String value, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────────── build ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AspectRatio(
                    aspectRatio: _aspect.ratio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: RepaintBoundary(
                        key: _captureKey,
                        child: _canvas(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _toolbar(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          // Aspect toggle only in raw-photo mode — when customizing a
          // template the aspect is fixed (set in the share sheet).
          if (widget.canvasBackground == null) ...[
            IconButton(
              tooltip: 'Aspect ratio',
              icon:
                  const Icon(Icons.aspect_ratio_rounded, color: Colors.white),
              onPressed: () {
                HapticFeedback.selectionClick();
                const order = ShareableAspect.values;
                setState(() => _aspect =
                    order[(order.indexOf(_aspect) + 1) % order.length]);
              },
            ),
            const SizedBox(width: 4),
          ],
          FilledButton.icon(
            onPressed: _busy ? null : _share,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Share'),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Future<void> _changePhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2160,
        maxHeight: 2160,
        imageQuality: 92,
      );
      if (picked == null || !mounted) return;
      setState(() => _photoOverride = picked.path);
    } catch (e) {
      debugPrint('❌ [FoodEditor] photo pick failed: $e');
      _toast('Could not open photo library');
    }
  }

  Widget _canvas() {
    final photoUrl = _photoOverride ??
        (widget.data.foodImageUrls?.isNotEmpty == true
            ? widget.data.foodImageUrls!.first
            : widget.data.customPhotoPath);
    final accent = widget.data.accentColor;
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        return GestureDetector(
          onTap: () => setState(() => _selectedId = null),
          child: Stack(
            children: [
              // Background — the selected TEMPLATE card when customizing a
              // template, otherwise the raw food photo / accent gradient.
              Positioned.fill(
                child: widget.canvasBackground ??
                    FoodImage(
                      url: photoUrl,
                      fit: BoxFit.cover,
                      fallbackBuilder: () => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(accent, Colors.black, 0.35)!,
                              Color.lerp(accent, Colors.black, 0.78)!,
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
              for (final layer in _layers) _positioned(layer, size),
            ],
          ),
        );
      },
    );
  }

  Widget _positioned(EditorLayer layer, Size size) {
    final selected = layer.id == _selectedId;
    return Positioned(
      left: layer.position.dx * size.width,
      top: layer.position.dy * size.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: () => setState(() => _selectedId = layer.id),
          onScaleStart: (d) {
            setState(() => _selectedId = layer.id);
            _basePos = layer.position;
            _baseScale = layer.scale;
            _baseRotation = layer.rotation;
            _dragAccum = Offset.zero;
          },
          onScaleUpdate: (d) {
            _dragAccum += d.focalPointDelta;
            _mutateSelected((l) => l.copyWith(
                  position: Offset(
                    (_basePos.dx + _dragAccum.dx / size.width)
                        .clamp(0.0, 1.0),
                    (_basePos.dy + _dragAccum.dy / size.height)
                        .clamp(0.0, 1.0),
                  ),
                  scale: (_baseScale * d.scale).clamp(0.3, 5.0),
                  rotation: _baseRotation + d.rotation,
                ));
          },
          child: Transform.rotate(
            angle: layer.rotation,
            child: Transform.scale(
              scale: layer.scale,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: selected
                    ? BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 1.4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: _layerContent(layer),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _layerContent(EditorLayer layer) {
    switch (layer.kind) {
      case EditorLayerKind.macroViz:
        return MacroViz(
          nutrition: widget.data.nutrition ?? const ShareableNutrition(),
          style: layer.macroStyle,
          accentColor: widget.data.accentColor,
          glass: true,
          healthScore: widget.data.healthScore,
        );
      case EditorLayerKind.text:
        return Text(
          layer.text.isEmpty ? 'Tap to edit' : layer.text,
          textAlign: TextAlign.center,
          style: kEditorFonts[layer.fontIndex].style.copyWith(
            color: layer.color,
            fontSize: 30,
            shadows: const [
              Shadow(color: Color(0x99000000), blurRadius: 8),
            ],
          ),
        );
      case EditorLayerKind.emoji:
        return Text(layer.text, style: const TextStyle(fontSize: 64));
      case EditorLayerKind.gif:
        // Animated GIF — animates live in the editor; a static-image
        // capture snapshots the current frame.
        return SizedBox(
          width: 160,
          child: Image.network(
            layer.gifUrl,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(
              width: 160,
              height: 110,
              alignment: Alignment.center,
              color: const Color(0x66000000),
              child: const Icon(Icons.gif_box_rounded,
                  color: Colors.white54, size: 36),
            ),
          ),
        );
      case EditorLayerKind.scoreBadge:
        final score = widget.data.healthScore ?? 0;
        return Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.data.accentColor,
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1)),
              const Text('/ 10',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        );
      case EditorLayerKind.dateStamp:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.data.periodLabel.isEmpty
                ? 'Today'
                : widget.data.periodLabel,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
        );
      case EditorLayerKind.watermark:
        return const AppWatermark(textColor: Colors.white, fontSize: 15);
    }
  }

  // ─────────────────────────────── toolbar ───────────────────────────────
  Widget _toolbar() {
    final sel = _selected;
    return Container(
      color: const Color(0xFF101216),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sel != null) _contextPanel(sel),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "Photo" swaps the background photo — only meaningful in
                // raw-photo mode; a template card is the background when
                // customizing a template.
                if (widget.canvasBackground == null)
                  _toolBtn('Photo', Icons.image_rounded, _changePhoto),
                _toolBtn('Text', Icons.text_fields_rounded,
                    () => _addLayer(EditorLayerKind.text)),
                _toolBtn('Sticker', Icons.emoji_emotions_rounded,
                    () => _addLayer(EditorLayerKind.emoji)),
                _toolBtn('GIF', Icons.gif_box_rounded, _pickGif),
                _toolBtn('Macros', Icons.donut_large_rounded,
                    () => _addLayer(EditorLayerKind.macroViz)),
                _toolBtn('Score', Icons.star_rounded,
                    () => _addLayer(EditorLayerKind.scoreBadge)),
                _toolBtn('Date', Icons.calendar_today_rounded,
                    () => _addLayer(EditorLayerKind.dateStamp)),
                _toolBtn('Logo', Icons.branding_watermark_rounded,
                    () => _addLayer(EditorLayerKind.watermark)),
              ],
            ),
          ),
        ],
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
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _contextPanel(EditorLayer sel) {
    final children = <Widget>[];
    if (sel.kind == EditorLayerKind.text) {
      children.add(IconButton(
        tooltip: 'Edit text',
        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
        onPressed: () => _editText(sel),
      ));
      for (var i = 0; i < kEditorFonts.length; i++) {
        children.add(_chip(
          kEditorFonts[i].label,
          selected: sel.fontIndex == i,
          onTap: () => _mutateSelected((l) => l.copyWith(fontIndex: i)),
        ));
      }
      for (final col in _kTextColors) {
        children.add(GestureDetector(
          onTap: () => _mutateSelected((l) => l.copyWith(color: col)),
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: col,
              shape: BoxShape.circle,
              border: Border.all(
                color: sel.color == col ? Colors.white : Colors.white24,
                width: sel.color == col ? 2.5 : 1,
              ),
            ),
          ),
        ));
      }
    } else if (sel.kind == EditorLayerKind.macroViz) {
      for (final style in MacroVizStyle.values) {
        children.add(_chip(
          style.name,
          selected: sel.macroStyle == style,
          onTap: () => _mutateSelected((l) => l.copyWith(macroStyle: style)),
        ));
      }
    } else if (sel.kind == EditorLayerKind.emoji) {
      children.add(IconButton(
        tooltip: 'Change sticker',
        icon: const Icon(Icons.grid_view_rounded,
            color: Colors.white, size: 20),
        onPressed: () => _pickEmoji(sel),
      ));
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: children),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFFF6B6B)),
            onPressed: _deleteSelected,
          ),
        ],
      ),
    );
  }

  Widget _chip(String label,
      {required bool selected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? widget.data.accentColor.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? widget.data.accentColor
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

const List<Color> _kTextColors = [
  Colors.white,
  Color(0xFF111111),
  Color(0xFFFFD23F),
  Color(0xFFFF6B6B),
  Color(0xFF06B6D4),
  Color(0xFFA855F7),
  Color(0xFF22C55E),
  Color(0xFFF97316),
];
