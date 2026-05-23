/// The Canva-style editor for an editable share card ([CardDoc]).
///
/// Open with [CardEditorScreen.open]; it returns the edited [CardDoc] (or
/// null if cancelled). Every element is tap-selectable, drag-to-move,
/// pinch-to-scale-and-rotate, with a contextual panel for restyling and a
/// toolbar for adding elements. Undo/redo throughout.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../doc/card_doc.dart';
import '../doc/card_doc_renderer.dart';
import '../doc/card_palette.dart';
import '../shareable_data.dart';
import 'card_editor_controller.dart';
import 'card_video_export_screen.dart';
import '../../widgets/glass_sheet.dart';

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

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  late final CardEditorController _c = CardEditorController(widget.initialDoc);

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
              ),
            ),
            _BottomArea(controller: _c),
          ],
        ),
      ),
    );
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
            tooltip: 'Background',
            icon: const Icon(Icons.gradient_rounded, color: Colors.white),
            onPressed: _editBackground,
          ),
          IconButton(
            tooltip: 'Layers',
            icon: const Icon(Icons.layers_rounded, color: Colors.white),
            onPressed: _openLayers,
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

  const _EditorCanvas({
    required this.controller,
    required this.data,
    required this.showWatermark,
    required this.textScale,
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

// ─────────────────────────── Chart controls ───────────────────────────────

class _ChartControls extends StatelessWidget {
  final CardEditorController controller;
  final ChartProps props;
  const _ChartControls({required this.controller, required this.props});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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

  /// Colours extracted from the user's meal photo (the AI palette assist).
  List<Color> _photoPalette = const [];

  @override
  void initState() {
    super.initState();
    _loadPalette();
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
