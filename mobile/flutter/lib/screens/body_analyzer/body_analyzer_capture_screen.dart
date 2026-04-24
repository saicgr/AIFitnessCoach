import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/progress_photos.dart';
import '../../data/repositories/body_analyzer_repository.dart';
import '../../data/repositories/progress_photos_repository.dart';
import '../../data/services/api_client.dart';

/// Capture (or re-select) up to 4 progress photos and kick off the
/// Body Analyzer run. The photos MUST already exist in the user's
/// progress-photo library — this screen is a selector, not a camera
/// capture flow (that flow already lives in progress_screen.dart).
class BodyAnalyzerCaptureScreen extends ConsumerStatefulWidget {
  const BodyAnalyzerCaptureScreen({super.key});

  @override
  ConsumerState<BodyAnalyzerCaptureScreen> createState() =>
      _BodyAnalyzerCaptureScreenState();
}

class _BodyAnalyzerCaptureScreenState
    extends ConsumerState<BodyAnalyzerCaptureScreen> {
  List<ProgressPhoto> _photos = [];
  final Map<PhotoViewType, ProgressPhoto> _picked = {};
  bool _loadingLibrary = true;
  bool _analyzing = false;
  bool _includeMeasurements = true;
  bool _alsoExtract = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLibrary());
  }

  Future<void> _loadLibrary() async {
    setState(() {
      _loadingLibrary = true;
      _error = null;
    });
    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) {
        setState(() => _error = 'Sign in to use Body Analyzer.');
        return;
      }
      final repo = ref.read(progressPhotosRepositoryProvider);
      final result = await repo.getPhotos(userId: userId);
      if (mounted) setState(() => _photos = result);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loadingLibrary = false);
    }
  }

  void _togglePick(ProgressPhoto photo) {
    final v = photo.viewTypeEnum;
    setState(() {
      if (_picked[v]?.id == photo.id) {
        _picked.remove(v);
      } else {
        _picked[v] = photo;
      }
    });
  }

  Future<void> _analyze() async {
    if (_picked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one photo.')),
      );
      return;
    }
    setState(() => _analyzing = true);
    try {
      final repo = ref.read(bodyAnalyzerRepositoryProvider);
      final ids = _picked.values.map((p) => p.id).toList();
      final res = await repo.analyze(
        photoIds: ids,
        includeMeasurements: _includeMeasurements,
      );
      if (_alsoExtract) {
        try {
          await repo.extractMeasurements(photoIds: ids);
        } catch (_) {
          // Non-blocking — main analysis already persisted.
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(res.snapshot);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analyze failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final byView = <PhotoViewType, List<ProgressPhoto>>{};
    for (final p in _photos) {
      byView.putIfAbsent(p.viewTypeEnum, () => []).add(p);
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('Pick photos')),
      body: SafeArea(
        child: _loadingLibrary
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, style: TextStyle(color: textMuted)),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Pick one photo per view. Gemini fuses them with your '
                        'latest body measurements for the most accurate read.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final v in [
                        PhotoViewType.front,
                        PhotoViewType.back,
                        PhotoViewType.sideLeft,
                        PhotoViewType.sideRight,
                      ]) ...[
                        _viewSection(
                          v,
                          byView[v] ?? const [],
                          textPrimary,
                          textMuted,
                          isDark,
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 4),
                      SwitchListTile.adaptive(
                        value: _includeMeasurements,
                        onChanged: (v) =>
                            setState(() => _includeMeasurements = v),
                        title: Text(
                          'Use my stored measurements',
                          style: TextStyle(color: textPrimary, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Fuses height/weight/body-fat and tape values into the analysis.',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        value: _alsoExtract,
                        onChanged: (v) => setState(() => _alsoExtract = v),
                        title: Text(
                          'Also estimate tape measurements from the photos',
                          style: TextStyle(color: textPrimary, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Auto-logs waist / chest / hip / neck values with a '
                          'photo_estimate flag.',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _analyzing || _picked.isEmpty ? null : _analyze,
              icon: _analyzing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.analytics_outlined),
              label: Text(_analyzing
                  ? 'Analyzing…'
                  : 'Analyze (${_picked.length} photo${_picked.length == 1 ? '' : 's'})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB24BF3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewSection(
    PhotoViewType view,
    List<ProgressPhoto> photos,
    Color primary,
    Color muted,
    bool isDark,
  ) {
    final label = switch (view) {
      PhotoViewType.front => 'Front',
      PhotoViewType.back => 'Back',
      PhotoViewType.sideLeft => 'Side (left)',
      PhotoViewType.sideRight => 'Side (right)',
      _ => 'Other',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: muted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          Text('No $label photos yet — capture one from Progress.',
              style: TextStyle(color: muted, fontSize: 12)),
        if (photos.isNotEmpty)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = photos[i];
                final selected = _picked[view]?.id == p.id;
                return GestureDetector(
                  onTap: () => _togglePick(p),
                  child: Container(
                    width: 72,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFB24BF3)
                            : Colors.transparent,
                        width: 2,
                      ),
                      image: p.photoUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(p.photoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: isDark
                          ? AppColors.elevated
                          : AppColorsLight.elevated,
                    ),
                    child: selected
                        ? Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFB24BF3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  size: 12, color: Colors.white),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
