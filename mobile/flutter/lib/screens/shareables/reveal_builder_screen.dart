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
import '../../data/models/progress_photos.dart';
import '../../data/repositories/progress_photos_repository.dart';
import '../../data/repositories/slideshow_repository.dart';
import '../../shareables/widgets/food_image.dart';
import '../../widgets/design_system/section_header.dart';

/// F9 + F4 — animated reveal-video builders.
///
///  - **F9 count-up reveal** — a number ticks 0 → final (PR / volume / streak;
///    food: calories / protein) over a chosen backdrop.
///  - **F4 before/after reveal** — two progress photos wipe/fade with one
///    caption line.
///
/// Both call the existing server-side slideshow endpoints
/// (`SlideshowRepository.createCountUp` / `createBeforeAfter`) — no per-frame
/// AI. Optimistic "rendering…" → poll → preview with Save / Share. No
/// mock/fallback: a render error surfaces a real message + retry.
enum RevealMode { countUp, beforeAfter }

class RevealBuilderScreen extends ConsumerStatefulWidget {
  final RevealMode mode;

  const RevealBuilderScreen({super.key, required this.mode});

  @override
  ConsumerState<RevealBuilderScreen> createState() =>
      _RevealBuilderScreenState();
}

enum _Phase { setup, rendering, done, error }

/// A count-up metric the user can reveal. [source] tells the server which photo
/// pool (if any) to use as a backdrop.
class _Metric {
  final String label;
  final String unit;
  final SlideshowSource source;
  const _Metric(this.label, this.unit, this.source);
}

const _metrics = <_Metric>[
  _Metric('Personal Record', 'lbs', SlideshowSource.workoutPhotos),
  _Metric('Total Volume', 'lbs', SlideshowSource.workoutPhotos),
  _Metric('Day Streak', 'days', SlideshowSource.workoutPhotos),
  _Metric('Calories', 'kcal', SlideshowSource.food),
  _Metric('Protein', 'g', SlideshowSource.food),
];

class _RevealBuilderScreenState extends ConsumerState<RevealBuilderScreen> {
  _Phase _phase = _Phase.setup;
  String? _error;

  // Count-up state.
  int _metricIndex = 0;
  final TextEditingController _valueCtrl = TextEditingController();

  // Before/after state.
  List<ProgressPhoto> _photos = const [];
  bool _loadingPhotos = false;
  ProgressPhoto? _before;
  ProgressPhoto? _after;
  final TextEditingController _captionCtrl = TextEditingController();

  VideoPlayerController? _preview;
  String? _videoPath;

  @override
  void initState() {
    super.initState();
    if (widget.mode == RevealMode.beforeAfter) _loadPhotos();
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _captionCtrl.dispose();
    _preview?.dispose();
    super.dispose();
  }

  String get _title =>
      widget.mode == RevealMode.countUp ? 'Count-up Reveal' : 'Before / After';

  Future<void> _loadPhotos() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _loadingPhotos = true);
    try {
      final photos = await ref
          .read(progressPhotosRepositoryProvider)
          .getPhotos(userId: userId);
      if (!mounted) return;
      // Oldest first so the natural before→after order is left→right.
      photos.sort((a, b) => a.takenAt.compareTo(b.takenAt));
      setState(() {
        _photos = photos;
        _before = photos.isNotEmpty ? photos.first : null;
        _after = photos.length > 1 ? photos.last : null;
        _loadingPhotos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingPhotos = false);
    }
  }

  /// The S3 storage key for a progress photo. The model exposes the full URL
  /// (`…amazonaws.com/{key}`); the slideshow endpoint wants the bare key.
  String _keyFor(ProgressPhoto p) {
    final url = p.photoUrl;
    final marker = '.amazonaws.com/';
    final i = url.indexOf(marker);
    if (i >= 0) {
      final tail = url.substring(i + marker.length);
      // Drop any presigned query string.
      final q = tail.indexOf('?');
      return q >= 0 ? tail.substring(0, q) : tail;
    }
    return url;
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

    // Validate inputs before we go optimistic.
    if (widget.mode == RevealMode.countUp) {
      final v = double.tryParse(_valueCtrl.text.trim());
      if (v == null || v <= 0) {
        _toast('Enter a number to count up to.');
        return;
      }
    } else {
      if (_before == null || _after == null) {
        _toast('Pick a before and an after photo.');
        return;
      }
      if (_before!.id == _after!.id) {
        _toast('Pick two different photos.');
        return;
      }
    }

    setState(() {
      _phase = _Phase.rendering;
      _error = null;
    });

    final repo = ref.read(slideshowRepositoryProvider);
    try {
      final job = await repo.renderAndAwait(
        userId: userId,
        enqueue: () {
          if (widget.mode == RevealMode.countUp) {
            final m = _metrics[_metricIndex];
            return repo.createCountUp(
              userId: userId,
              source: m.source,
              finalValue: double.parse(_valueCtrl.text.trim()),
              label: m.label,
              unit: m.unit,
              valueFormat: 'int',
            );
          }
          return repo.createBeforeAfter(
            userId: userId,
            source: SlideshowSource.progressPhotos,
            beforeKey: _keyFor(_before!),
            afterKey: _keyFor(_after!),
            caption: _captionCtrl.text.trim().isEmpty
                ? 'The work shows.'
                : _captionCtrl.text.trim(),
          );
        },
      );

      final url = job.resultUrl;
      if (url == null) throw Exception('Render finished without a video URL');

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/reveal_${DateTime.now().millisecondsSinceEpoch}.mp4';
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
      return 'No photos found. Add some photos first, then try again.';
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
      await Share.shareXFiles([XFile(path)], text: 'My reveal');
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
          _Phase.setup => widget.mode == RevealMode.countUp
              ? _buildCountUpSetup(c, accent)
              : _buildBeforeAfterSetup(c, accent),
          _Phase.rendering => _buildRendering(c, accent),
          _Phase.done => _buildDone(c, accent),
          _Phase.error => _buildError(c, accent),
        },
      ),
    );
  }

  // ── F9 count-up setup ──
  Widget _buildCountUpSetup(ThemeColors c, Color accent) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SizedBox(height: 8),
        Text(
          'A number ticks up from zero for the big reveal.',
          style: TextStyle(fontSize: 15, height: 1.4, color: c.textPrimary),
        ),
        const SectionHeader(label: 'Metric'),
        ...List.generate(_metrics.length, (i) {
          final m = _metrics[i];
          final selected = i == _metricIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _metricIndex = i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? accent : c.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text('${m.label}  (${m.unit})',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: c.textPrimary)),
                  ],
                ),
              ),
            ),
          );
        }),
        const SectionHeader(label: 'Count up to'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _valueCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: c.textPrimary, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'e.g. 225',
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.cardBorder),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _renderButton(accent),
      ],
    );
  }

  // ── F4 before/after setup ──
  Widget _buildBeforeAfterSetup(ThemeColors c, Color accent) {
    if (_loadingPhotos) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_photos.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined, size: 56, color: c.textMuted),
              const SizedBox(height: 16),
              Text(
                'Add at least two progress photos to build a before / after reveal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.4, color: c.textPrimary),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SizedBox(height: 8),
        Text('Pick the before and after.',
            style: TextStyle(fontSize: 15, height: 1.4, color: c.textPrimary)),
        const SectionHeader(label: 'Before'),
        _photoStrip(c, accent, isBefore: true),
        const SectionHeader(label: 'After'),
        _photoStrip(c, accent, isBefore: false),
        const SectionHeader(label: 'Caption'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _captionCtrl,
            maxLength: 60,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'The work shows.',
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.cardBorder),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _renderButton(accent),
      ],
    );
  }

  Widget _photoStrip(ThemeColors c, Color accent, {required bool isBefore}) {
    final selected = isBefore ? _before : _after;
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = _photos[i];
          final isSel = selected?.id == p.id;
          return GestureDetector(
            onTap: () => setState(() {
              if (isBefore) {
                _before = p;
              } else {
                _after = p;
              }
            }),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel ? accent : c.cardBorder,
                    width: isSel ? 2.4 : 1,
                  ),
                ),
                child: FoodImage(url: p.photoUrl, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _renderButton(Color accent) {
    return Padding(
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
          label: const Text('Create reveal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildRendering(ThemeColors c, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
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
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Building your reveal…',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
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
