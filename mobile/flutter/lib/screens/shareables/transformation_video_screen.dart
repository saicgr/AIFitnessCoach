import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/providers/user_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/repositories/slideshow_repository.dart';
import '../../widgets/design_system/section_header.dart';

/// Server-rendered transformation video — turns a span of the user's photos
/// (workout selfies / progress photos / food photos) into a 9:16 MP4 montage.
///
/// Flow (feedback_instant_feel_ai_generation): pick a date range → an
/// optimistic "rendering…" card paints immediately → the backend render job is
/// polled → a looping preview with Save / Share. No mock/fallback: a render
/// error surfaces a real message + retry.
class TransformationVideoScreen extends ConsumerStatefulWidget {
  final SlideshowSource source;

  const TransformationVideoScreen({super.key, required this.source});

  @override
  ConsumerState<TransformationVideoScreen> createState() =>
      _TransformationVideoScreenState();
}

enum _Phase { setup, rendering, done, error }

/// A selectable date-range preset.
class _RangePreset {
  final String label;
  final Duration? lookback; // null = all time
  const _RangePreset(this.label, this.lookback);
}

const _presets = <_RangePreset>[
  _RangePreset('Last 30 days', Duration(days: 30)),
  _RangePreset('Last 90 days', Duration(days: 90)),
  _RangePreset('Last 6 months', Duration(days: 182)),
  _RangePreset('Last year', Duration(days: 365)),
  _RangePreset('All time', null),
];

class _TransformationVideoScreenState
    extends ConsumerState<TransformationVideoScreen> {
  _Phase _phase = _Phase.setup;
  int _presetIndex = 3; // default: last year — the classic transformation span
  String _style = 'kenburns';
  String? _error;

  VideoPlayerController? _preview;
  String? _videoPath;

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.source) {
      case SlideshowSource.food:
        return 'Food Transformation';
      case SlideshowSource.progressPhotos:
        return 'Transformation Video';
      case SlideshowSource.workoutPhotos:
        return 'Workout Transformation';
    }
  }

  String get _blurb {
    switch (widget.source) {
      case SlideshowSource.food:
        return 'Turn your logged meals into a montage of how your plate evolved.';
      case SlideshowSource.progressPhotos:
        return 'Stitch your progress photos into a date-ordered transformation reel.';
      case SlideshowSource.workoutPhotos:
        return 'Stitch your gym photos into a date-ordered transformation reel.';
    }
  }

  Future<void> _render() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      setState(() {
        _phase = _Phase.error;
        _error = 'Please sign in to render a video.';
      });
      return;
    }

    setState(() {
      _phase = _Phase.rendering;
      _error = null;
    });

    final repo = ref.read(slideshowRepositoryProvider);
    final preset = _presets[_presetIndex];
    final dateFrom =
        preset.lookback == null ? null : DateTime.now().subtract(preset.lookback!);

    try {
      final job = await repo.renderAndAwait(
        userId: userId,
        enqueue: () => repo.createMontage(
          userId: userId,
          source: widget.source,
          dateFrom: dateFrom,
          style: _style,
        ),
      );

      final url = job.resultUrl;
      if (url == null) {
        throw Exception('Render finished without a video URL');
      }

      // Download the presigned MP4 to a temp file so video_player + Save/Share
      // work against a local path.
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/transformation_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await Dio().download(url, path);

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('No ') && msg.contains('photos')) {
      return 'No photos found for this range. Add some photos first, then try again.';
    }
    if (msg.contains('timed out')) {
      return 'The render is taking longer than expected. Please try again.';
    }
    return 'Could not build your video — please try again.';
  }

  Future<void> _save() async {
    final path = _videoPath;
    if (path == null) return;
    try {
      await Gal.putVideo(path, album: 'Zealova');
      _toast('Saved to gallery');
    } catch (_) {
      _toast('Save failed');
    }
  }

  Future<void> _share() async {
    final path = _videoPath;
    if (path == null) return;
    try {
      await Share.shareXFiles([XFile(path)], text: 'My transformation');
    } catch (_) {
      _toast('Share failed');
    }
  }

  void _reset() {
    _preview?.dispose();
    setState(() {
      _preview = null;
      _videoPath = null;
      _phase = _Phase.setup;
      _error = null;
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final accent = c.accent;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.setup => _buildSetup(c, accent),
          _Phase.rendering => _buildRendering(c, accent),
          _Phase.done => _buildDone(c, accent),
          _Phase.error => _buildError(c, accent),
        },
      ),
    );
  }

  Widget _buildSetup(ThemeColors c, Color accent) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.85), accent.withValues(alpha: 0.35)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.movie_creation_outlined, size: 64, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _blurb,
          style: TextStyle(fontSize: 15, height: 1.4, color: c.textPrimary),
        ),
        const SectionHeader(label: 'Date range'),
        ...List.generate(_presets.length, (i) {
          final p = _presets[i];
          final selected = i == _presetIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _presetIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? accent.withValues(alpha: 0.12) : c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? accent : c.cardBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: selected ? accent : c.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SectionHeader(label: 'Motion'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _styleChip(c, accent, 'kenburns', 'Ken Burns'),
              const SizedBox(width: 10),
              _styleChip(c, accent, 'flat', 'Crossfade'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _render,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'Create video',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _styleChip(ThemeColors c, Color accent, String value, String label) {
    final selected = _style == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _style = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : c.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? accent : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // Optimistic "rendering…" card — paints instantly so generation feels alive.
  Widget _buildRendering(ThemeColors c, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.55),
                      accent.withValues(alpha: 0.18),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Building your video…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stitching your photos in order',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone(ThemeColors c, Color accent) {
    final ctrl = _preview;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ctrl != null && ctrl.value.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
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
                child: OutlinedButton.icon(
                  onPressed: _save,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _share,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _reset,
            child: Text('Make another', style: TextStyle(color: c.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeColors c, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: c.textMuted),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.4, color: c.textPrimary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
