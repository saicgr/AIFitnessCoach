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

import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/food_image.dart';
import '../widgets/macro_viz.dart';

/// Builds a montage video from a meal/day's food photos — a branded intro
/// card then each photo as a held slide — and exports it as an MP4 via
/// [FlutterQuickVideoEncoder] (the OS-native encoder, no ffmpeg binary).
class FoodMontageScreen extends StatefulWidget {
  final Shareable data;

  const FoodMontageScreen({super.key, required this.data});

  static Future<void> open(BuildContext context, Shareable data) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FoodMontageScreen(data: data),
      ),
    );
  }

  @override
  State<FoodMontageScreen> createState() => _FoodMontageScreenState();
}

enum _Phase { idle, working, done, error }

class _FoodMontageScreenState extends State<FoodMontageScreen> {
  // 720×1280 keeps per-frame RGBA at ~3.7MB — story quality, encodes fast.
  static const int _w = 720;
  static const int _h = 1280;
  static const int _fps = 24;
  static const int _introFrames = 40; // ~1.7s
  static const int _photoFrames = 53; // ~2.2s

  late final List<String> _photos;
  late final List<GlobalKey> _keys;
  _Phase _phase = _Phase.idle;
  double _progress = 0;
  String? _videoPath;
  VideoPlayerController? _preview;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _photos = (widget.data.foodImageUrls ?? const <String>[])
        .where((u) => u.trim().isNotEmpty)
        .take(8)
        .toList();
    // Slide 0 = intro card, then one slide per photo.
    _keys = List.generate(_photos.length + 1, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  int get _slideCount => _keys.length;

  Future<void> _create() async {
    setState(() {
      _phase = _Phase.working;
      _progress = 0;
    });
    try {
      // 1) Capture every slide to a raw-RGBA frame.
      await WidgetsBinding.instance.endOfFrame;
      final frames = <Uint8List>[];
      for (var i = 0; i < _slideCount; i++) {
        final boundary = _keys[i].currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) throw StateError('slide $i not ready');
        final image = await boundary.toImage(pixelRatio: 1.0);
        final bytes =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        if (bytes == null) throw StateError('slide $i capture failed');
        frames.add(bytes.buffer.asUint8List());
        setState(() => _progress = (i + 1) / _slideCount * 0.30);
      }

      // 2) Encode — hold each slide for its frame count.
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/food_montage_${DateTime.now().millisecondsSinceEpoch}.mp4';
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
      final total = _introFrames + (_slideCount - 1) * _photoFrames;
      var done = 0;
      for (var i = 0; i < frames.length; i++) {
        final hold = i == 0 ? _introFrames : _photoFrames;
        for (var f = 0; f < hold; f++) {
          await FlutterQuickVideoEncoder.appendVideoFrame(frames[i]);
          done++;
          if (done % 6 == 0) {
            setState(() => _progress = 0.30 + (done / total) * 0.66);
          }
        }
      }
      await FlutterQuickVideoEncoder.finish();

      // 3) Preview.
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
      debugPrint('❌ [FoodMontage] $e');
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
      await Share.shareXFiles([XFile(path)], text: 'My meals');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050608),
        foregroundColor: Colors.white,
        title: const Text('Montage video'),
      ),
      body: Stack(
        children: [
          // Slide builders — kept in the tree at full 720×1280 so every
          // RepaintBoundary lays out + paints and can be captured. An
          // opaque layer + the UI sit on top, fully hiding them.
          ..._slideBuilders(),
          const Positioned.fill(
            child: ColoredBox(color: Color(0xFF050608)),
          ),
          Positioned.fill(child: _body()),
        ],
      ),
    );
  }

  List<Widget> _slideBuilders() {
    return [
      for (var i = 0; i < _slideCount; i++)
        Positioned(
          left: 0,
          top: 0,
          child: SizedBox(
            width: _w.toDouble(),
            height: _h.toDouble(),
            child: RepaintBoundary(
              key: _keys[i],
              child: _MontageSlide(
                data: widget.data,
                photoUrl: i == 0 ? null : _photos[i - 1],
                index: i,
                photoCount: _photos.length,
                isIntro: i == 0,
              ),
            ),
          ),
        ),
    ];
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
                Text(_error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
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
            const Icon(Icons.movie_creation_rounded,
                color: Colors.white, size: 56),
            const SizedBox(height: 16),
            Text(
              'Turn ${_photos.length} food photo'
              '${_photos.length == 1 ? '' : 's'} into a montage video',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'A branded intro card, then each meal as a slide.',
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
            _progress < 0.30
                ? 'Rendering slides…'
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

/// One montage slide rendered at 720×1280 — an intro card or a photo slide.
class _MontageSlide extends StatelessWidget {
  final Shareable data;
  final String? photoUrl;
  final int index;
  final int photoCount;
  final bool isIntro;

  const _MontageSlide({
    required this.data,
    required this.photoUrl,
    required this.index,
    required this.photoCount,
    required this.isIntro,
  });

  @override
  Widget build(BuildContext context) {
    return isIntro ? _intro() : _photoSlide();
  }

  Widget _intro() {
    final accent = data.accentColor;
    final nutrition = data.nutrition ?? const ShareableNutrition();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF0B1020), accent, 0.22)!,
            const Color(0xFF05060A),
          ],
        ),
      ),
      padding: const EdgeInsets.all(64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (data.mealLabel?.trim().isNotEmpty ?? false)
                ? data.mealLabel!.trim().toUpperCase()
                : 'WHAT I ATE',
            style: TextStyle(
                color: accent,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 4),
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5),
          ),
          if (data.periodLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              data.periodLabel,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 24,
                  fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 48),
          Center(
            child: MacroViz(
              nutrition: nutrition,
              style: MacroVizStyle.appleRings,
              accentColor: accent,
              scale: 1.6,
            ),
          ),
          const Spacer(),
          const Center(
            child: AppWatermark(textColor: Colors.white, fontSize: 22),
          ),
        ],
      ),
    );
  }

  Widget _photoSlide() {
    return Stack(
      fit: StackFit.expand,
      children: [
        FoodImage(
          url: photoUrl,
          fit: BoxFit.cover,
          fallbackBuilder: () => ColoredBox(
            color: Color.lerp(data.accentColor, Colors.black, 0.6)!,
          ),
        ),
        // Bottom scrim for caption legibility.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0xCC000000)],
            ),
          ),
        ),
        // Slide counter.
        Positioned(
          top: 44,
          right: 44,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$index / $photoCount',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
        // Caption.
        Positioned(
          left: 48,
          right: 48,
          bottom: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1),
              ),
              const SizedBox(height: 16),
              const AppWatermark(textColor: Colors.white, fontSize: 20),
            ],
          ),
        ),
      ],
    );
  }
}
