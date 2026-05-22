import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../doc/card_doc.dart';
import '../doc/card_doc_renderer.dart';
import '../shareable_data.dart';

/// Exports an editable share card ([CardDoc]) as a short animated MP4.
///
/// The clip plays a staggered ENTRANCE animation — the card's elements
/// fade + slide into place one after another — then holds the finished card
/// before looping. Each frame is captured from a [RepaintBoundary] via
/// `boundary.toImage` and encoded with [FlutterQuickVideoEncoder], the
/// OS-native encoder (no ffmpeg binary). Mirrors the proven capture / encode /
/// save / share path of `food_montage_screen.dart`.
class CardVideoExportScreen extends StatefulWidget {
  final CardDoc doc;
  final Shareable data;

  const CardVideoExportScreen({
    super.key,
    required this.doc,
    required this.data,
  });

  static Future<void> open(
    BuildContext context, {
    required CardDoc doc,
    required Shareable data,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CardVideoExportScreen(doc: doc, data: data),
      ),
    );
  }

  @override
  State<CardVideoExportScreen> createState() => _CardVideoExportScreenState();
}

enum _Phase { idle, working, done, error }

class _CardVideoExportScreenState extends State<CardVideoExportScreen> {
  // 720×1280 keeps per-frame RGBA at ~3.7MB — story quality, encodes fast.
  // The card is rendered at its design size then fitted into this 9:16 frame.
  static const int _w = 720;
  static const int _h = 1280;
  static const int _fps = 30;

  // ~1.3s of staggered entrance, then ~1.1s hold ≈ 2.4s total.
  static const int _introFrames = 39; // 1.3s @ 30fps
  static const int _holdFrames = 33; // 1.1s @ 30fps
  static int get _totalFrames => _introFrames + _holdFrames;

  /// Per-element entrance occupies this fraction of the intro window; the
  /// remaining time is the stagger budget spread across the element list.
  static const double _perElementSpan = 0.55;

  /// The single capture boundary — re-rendered every frame at the animation
  /// progress for that frame, then captured.
  final GlobalKey _captureKey = GlobalKey();

  _Phase _phase = _Phase.idle;
  double _progress = 0;

  /// Animation progress (0..1) currently painted into the capture boundary.
  double _renderT = 0;

  String? _videoPath;
  VideoPlayerController? _preview;
  String _error = '';

  /// Visible (non-hidden) elements in paint order — the ones that animate.
  late final List<CardElement> _animElements;

  @override
  void initState() {
    super.initState();
    _animElements =
        widget.doc.elements.where((e) => !e.hidden).toList(growable: false);
  }

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  // ─────────────────────────── Animation math ──────────────────────────────

  /// Eased ease-out-cubic — fast in, gentle settle.
  static double _easeOutCubic(double x) {
    final c = (1.0 - x).clamp(0.0, 1.0);
    return 1.0 - c * c * c;
  }

  /// Per-element entrance progress (0..1) at global animation time [t].
  ///
  /// Element [i] of [count] starts after its own staggered delay and ramps
  /// over [_perElementSpan] of the intro window. The result is eased.
  double _elementProgress(int i, int count, double t) {
    if (count <= 1) return _easeOutCubic(t);
    // Stagger budget = the part of the timeline not consumed by one element's
    // own span. Each element's start is spread evenly across that budget.
    final staggerBudget = (1.0 - _perElementSpan).clamp(0.0, 1.0);
    final start = (i / (count - 1)) * staggerBudget;
    final raw = ((t - start) / _perElementSpan).clamp(0.0, 1.0);
    return _easeOutCubic(raw);
  }

  /// Builds a [CardDoc] snapshot for animation time [t] by adjusting each
  /// visible element's opacity (fade-in) and position (slide-up). At t=1 the
  /// returned doc is identical to the source doc, so the hold frames show the
  /// final card exactly as designed.
  CardDoc _docAt(double t) {
    if (t >= 1.0) return widget.doc;
    final count = _animElements.length;
    if (count == 0) return widget.doc;

    // Map each animated element id to its index for fast lookup.
    final indexOf = <String, int>{};
    for (var i = 0; i < count; i++) {
      indexOf[_animElements[i].id] = i;
    }

    // Slide distance in fractional canvas units (≈6% of canvas height),
    // travelled from below into the element's resting position.
    const slide = 0.06;

    final next = <CardElement>[];
    for (final el in widget.doc.elements) {
      if (el.hidden) {
        next.add(el);
        continue;
      }
      final i = indexOf[el.id];
      if (i == null) {
        next.add(el);
        continue;
      }
      final p = _elementProgress(i, count, t);
      if (p >= 1.0) {
        next.add(el);
        continue;
      }
      final dy = (1.0 - p) * slide;
      final tf = el.transform;
      next.add(
        el.copyWith(
          opacity: (el.opacity * p).clamp(0.0, 1.0),
          transform: tf.copyWith(
            position: Offset(tf.position.dx, tf.position.dy + dy),
          ),
        ),
      );
    }
    return widget.doc.copyWith(elements: next);
  }

  // ─────────────────────────── Build the video ─────────────────────────────

  Future<void> _create() async {
    setState(() {
      _phase = _Phase.working;
      _progress = 0;
      _renderT = 0;
    });
    try {
      // 1) Render + capture every frame. The capture boundary is re-rendered
      //    at the frame's animation progress, then captured to raw RGBA.
      final frames = <Uint8List>[];
      for (var f = 0; f < _totalFrames; f++) {
        final t = f < _introFrames
            ? (f / (_introFrames - 1).clamp(1, _introFrames)).clamp(0.0, 1.0)
            : 1.0;

        // Paint this frame, then wait for it to land on screen.
        setState(() => _renderT = t);
        await WidgetsBinding.instance.endOfFrame;
        // A second settle lets image-backed elements paint deterministically.
        await WidgetsBinding.instance.endOfFrame;

        final boundary = _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) throw StateError('capture boundary not ready');
        final image = await boundary.toImage(pixelRatio: 1.0);
        final bytes =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        if (bytes == null) throw StateError('frame $f capture failed');
        frames.add(bytes.buffer.asUint8List());

        if (!mounted) return;
        setState(() => _progress = (f + 1) / _totalFrames * 0.62);
      }

      // 2) Encode the frame sequence — one encoded frame per captured frame.
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/card_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await FlutterQuickVideoEncoder.setup(
        width: _w,
        height: _h,
        fps: _fps,
        videoBitrate: 3500000,
        profileLevel: ProfileLevel.any,
        audioChannels: 0,
        audioBitrate: 0,
        sampleRate: 0,
        filepath: path,
      );
      for (var i = 0; i < frames.length; i++) {
        await FlutterQuickVideoEncoder.appendVideoFrame(frames[i]);
        if (i % 6 == 0 && mounted) {
          setState(
              () => _progress = 0.62 + (i / frames.length) * 0.36);
        }
      }
      await FlutterQuickVideoEncoder.finish();

      // 3) Loop a preview.
      final ctrl = VideoPlayerController.file(File(path));
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.play();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _videoPath = path;
        _preview = ctrl;
        _phase = _Phase.done;
        _progress = 1;
      });
    } catch (e) {
      debugPrint('❌ [CardVideoExport] $e');
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _error = 'Could not build the video — please try again.';
        });
      }
    }
  }

  Future<void> _save() async {
    final path = _videoPath;
    if (path == null) return;
    try {
      await Gal.putVideo(path, album: 'Zealova');
      _toast('Saved to gallery');
    } catch (e) {
      _toast('Save failed');
    }
  }

  Future<void> _shareVideo() async {
    final path = _videoPath;
    if (path == null) return;
    try {
      await Share.shareXFiles([XFile(path)], text: widget.data.title);
    } catch (e) {
      _toast('Share failed');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────── UI ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050608),
        foregroundColor: Colors.white,
        title: const Text('Animated video'),
      ),
      body: Stack(
        children: [
          // The capture stage — kept in the tree at full 720×1280 so the
          // RepaintBoundary lays out + paints and can be captured each frame.
          // An opaque layer + the UI sit on top, fully hiding it.
          Positioned(
            left: 0,
            top: 0,
            child: _captureStage(),
          ),
          const Positioned.fill(
            child: ColoredBox(color: Color(0xFF050608)),
          ),
          Positioned.fill(child: _body()),
        ],
      ),
    );
  }

  /// The off-screen 720×1280 capture surface. The card is rendered at its
  /// design size and `FittedBox`-fitted into the story frame, painted at the
  /// current animation progress [_renderT].
  Widget _captureStage() {
    final designSize = widget.doc.aspect.size;
    return SizedBox(
      width: _w.toDouble(),
      height: _h.toDouble(),
      child: RepaintBoundary(
        key: _captureKey,
        child: ColoredBox(
          color: const Color(0xFF050608),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: designSize.width,
                height: designSize.height,
                child: CardDocRenderer(
                  doc: _docAt(_renderT),
                  data: widget.data,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.idle:
        return _idleView();
      case _Phase.working:
        return _workingView();
      case _Phase.done:
        return _doneView();
      case _Phase.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _create,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _idleView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_rounded,
                color: Colors.white, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Turn this card into an animated video',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Each element fades and slides in, then the finished '
              'card holds — ready for stories and reels.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Create video'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              value: _progress == 0 ? null : _progress,
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _progress < 0.62
                ? 'Rendering frames…'
                : 'Encoding video… ${(_progress * 100).round()}%',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _doneView() {
    final ctrl = _preview;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: (ctrl != null && ctrl.value.isInitialized)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: ctrl.value.aspectRatio,
                        child: VideoPlayer(ctrl),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _shareVideo,
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
