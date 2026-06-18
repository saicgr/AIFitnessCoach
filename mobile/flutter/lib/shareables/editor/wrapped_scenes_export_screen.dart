/// **F13 — Wrapped per-scene export screen.**
///
/// Renders a [Shareable]'s Wrapped as a horizontally-swipeable deck of 9:16
/// scene cards (see `templates/wrapped_scenes.dart`) and lets the user Save or
/// Share the currently-visible scene as its own PNG. Deterministic — every
/// scene is a pre-built [CardDoc], no AI, no network.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../data/services/share_service.dart';
import '../doc/card_doc_renderer.dart';
import '../shareable_data.dart';
import '../templates/wrapped_scenes.dart';

class WrappedScenesExportScreen extends StatefulWidget {
  final Shareable data;
  final bool showWatermark;

  const WrappedScenesExportScreen({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static Future<void> open(
    BuildContext context, {
    required Shareable data,
    bool showWatermark = true,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WrappedScenesExportScreen(
          data: data,
          showWatermark: showWatermark,
        ),
      ),
    );
  }

  @override
  State<WrappedScenesExportScreen> createState() =>
      _WrappedScenesExportScreenState();
}

class _WrappedScenesExportScreenState
    extends State<WrappedScenesExportScreen> {
  late final List<WrappedScene> _scenes = buildWrappedScenes(widget.data);
  late final List<GlobalKey> _keys =
      List.generate(_scenes.length, (_) => GlobalKey());
  final PageController _page = PageController(viewportFraction: 0.82);
  int _index = 0;
  bool _busy = false;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<Uint8List?> _capture(int i) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _keys[i].currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.size.isEmpty) return null;
      final scale = ShareableAspect.story.size.width / boundary.size.width;
      final image = await boundary.toImage(pixelRatio: scale.clamp(0.5, 6.0));
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ [WrappedScenes] capture failed: $e');
      return null;
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final bytes = await _capture(_index);
      if (bytes == null) {
        _toast('Could not render — try again');
        return;
      }
      final r = await ShareService.saveToGallery(bytes);
      if (mounted) _toast(r.success ? 'Saved to device' : (r.error ?? 'Failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final bytes = await _capture(_index);
      if (bytes == null) {
        _toast('Could not render — try again');
        return;
      }
      await ShareService.shareGeneric(bytes, caption: 'My Wrapped');
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

  @override
  Widget build(BuildContext context) {
    if (_scenes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0C0F),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text(
            'Not enough data for a Wrapped yet.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0F),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _scenes.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final scene = _scenes[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: ShareableAspect.story.ratio,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: RepaintBoundary(
                                  key: _keys[i],
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: CardDocRenderer(
                                      doc: scene.doc,
                                      data: widget.data,
                                      showWatermark: widget.showWatermark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          scene.label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _dots(),
            _actionBar(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Wrapped · ${_index + 1}/${_scenes.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _dots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _scenes.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _index ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionBar() {
    Widget action(String label, IconData icon, VoidCallback onTap) {
      return Expanded(
        child: TextButton(
          onPressed: _busy ? null : onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22, color: _busy ? Colors.white24 : Colors.white),
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
            action('Save scene', Icons.download_rounded, _save),
            action('Share scene', Icons.ios_share_rounded, _share),
          ],
        ),
      ),
    );
  }
}
