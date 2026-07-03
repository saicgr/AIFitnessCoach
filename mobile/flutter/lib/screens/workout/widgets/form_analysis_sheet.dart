/// Form Analysis Sheet
///
/// The in-workout / standalone AI form-analysis flow:
///   entry → Record New Video / Choose from Library → pick → upload (presign +
///   S3) → submit `form_analysis` job → optimistic "uploaded, analyzing" state
///   → poll → render [FormAnalysisGaugeCard] with the clip playable inline.
///
/// `exerciseName` is passed when known (the in-workout Form pill) and omitted
/// for the standalone Form Check quick action — the analyzer auto-identifies
/// the movement in that case.
///
/// No mock / fallback: on poll timeout or job failure the sheet shows an honest
/// retry, it never fabricates a score.
library;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' show DioException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/repositories/form_analysis_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import 'form_analysis_gauge_card.dart';

/// Show the Form Analysis sheet. [exerciseName] is optional — when null the AI
/// auto-detects the movement (standalone Form Check entry).
Future<void> showFormAnalysisSheet(
  BuildContext context, {
  String? exerciseName,
  String? exerciseId,
}) {
  return showGlassSheet(
    context: context,
    builder: (_) => GlassSheet(
      showHandle: true,
      child: FormAnalysisSheet(
        exerciseName: exerciseName,
        exerciseId: exerciseId,
      ),
    ),
  );
}

enum _FormFlowStage { entry, uploading, analyzing, result, error }

class FormAnalysisSheet extends ConsumerStatefulWidget {
  final String? exerciseName;

  /// Canonical exercise id when launched from a specific exercise (active
  /// workout / library). Persisted with the analysis so history binds to the
  /// exact exercise (not a fuzzy name match) — see C3 persistence.
  final String? exerciseId;

  const FormAnalysisSheet({super.key, this.exerciseName, this.exerciseId});

  @override
  ConsumerState<FormAnalysisSheet> createState() => _FormAnalysisSheetState();
}

class _FormAnalysisSheetState extends ConsumerState<FormAnalysisSheet> {
  final _picker = ImagePicker();

  // Editable, optional exercise name — pre-filled from the launching context.
  // Clearing it lets the AI auto-detect the movement.
  late final TextEditingController _exerciseController = TextEditingController(
    text: widget.exerciseName ?? '',
  );

  _FormFlowStage _stage = _FormFlowStage.entry;
  double _uploadProgress = 0; // 0..1 during the S3 PUT
  String? _errorMessage;
  // True when the failure was the backend's premium gate (HTTP 402) — the
  // error view then renders an Upgrade CTA instead of a pointless "Try
  // again" (which would just 402 again).
  bool _premiumGated = false;
  Map<String, dynamic>? _result;
  DateTime? _analyzedAt;

  // Inline playback of the just-uploaded local clip.
  VideoPlayerController? _videoController;

  Timer? _pollTimer;
  bool _disposed = false;

  // Elapsed-seconds ticker for the analyzing stage — drives the honest staged
  // labels ("Watching your reps…" → "Scoring your form…") so the wait reads
  // as forward motion instead of a frozen spinner.
  Timer? _stageTicker;
  int _analyzeElapsed = 0;

  static const List<({int at, String label})> _analyzeStages = [
    (at: 0, label: 'Queued for analysis…'),
    (at: 8, label: 'Watching your reps…'),
    (at: 22, label: 'Measuring tempo & range…'),
    (at: 45, label: 'Scoring your form…'),
  ];

  String get _analyzeStageLabel {
    var label = _analyzeStages.first.label;
    for (final s in _analyzeStages) {
      if (_analyzeElapsed >= s.at) label = s.label;
    }
    return label;
  }

  // 2s poll. Cap must exceed the real server ceiling: when the Vertex/GCS
  // path is unavailable the backend falls back to the Gemini Files API
  // (download + re-upload + inference), which regularly runs past 60s for a
  // ~20MB clip — a 60s cap made those successful jobs look like failures.
  static const _pollInterval = Duration(seconds: 2);
  static const _pollCap = Duration(seconds: 180);

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _stageTicker?.cancel();
    _videoController?.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  Future<void> _pickAndRun(ImageSource source) async {
    HapticService.light();
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30),
      );
      if (picked == null || _disposed) return; // user cancelled
      final file = File(picked.path);
      _initLocalPlayer(file);
      await _upload(file);
    } catch (e) {
      _fail("Couldn't pick that video. Please try again.");
    }
  }

  Future<void> _initLocalPlayer(File file) async {
    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }
      controller.setLooping(true);
      controller.setVolume(0);
      controller.play();
      if (mounted) setState(() => _videoController = controller);
    } catch (_) {
      // Inline preview is best-effort; the gauge still renders without it.
    }
  }

  Future<void> _upload(File file) async {
    if (_disposed) return;
    setState(() {
      _stage = _FormFlowStage.uploading;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    final repo = ref.read(formAnalysisRepositoryProvider);
    try {
      final s3Key = await repo.uploadVideo(
        file,
        onProgress: (sent, total) {
          if (!_disposed && total > 0 && mounted) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );

      // Edited (optional) name; clearing it → null → AI auto-detects.
      final typedName = _exerciseController.text.trim();
      final jobId = await repo.submitFormAnalysis(
        s3Key: s3Key,
        exerciseName: typedName.isEmpty ? null : typedName,
        exerciseId: widget.exerciseId,
        // Bind the analysis to the gym that was active when it was recorded so
        // history is scoped per user / per gym / per exercise (C3).
        gymProfileId: ref.read(activeGymProfileIdProvider),
      );

      if (_disposed) return;
      // Optimistic "uploaded — analyzing" state; the user can keep working out.
      setState(() {
        _stage = _FormFlowStage.analyzing;
        _analyzeElapsed = 0;
      });
      _stageTicker?.cancel();
      _stageTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_disposed || _stage != _FormFlowStage.analyzing) {
          _stageTicker?.cancel();
          return;
        }
        if (mounted) setState(() => _analyzeElapsed++);
      });
      HapticService.medium();
      _startPolling(jobId);
    } catch (e) {
      _fail(_friendlyError(e), premiumGated: _isPremiumGate(e));
    }
  }

  /// True when the backend rejected the request with its premium paywall
  /// (HTTP 402 from `check_premium_gate`).
  bool _isPremiumGate(Object e) =>
      e is DioException && e.response?.statusCode == 402;

  void _startPolling(String jobId) {
    final repo = ref.read(formAnalysisRepositoryProvider);
    final deadline = DateTime.now().add(_pollCap);

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (DateTime.now().isAfter(deadline)) {
        timer.cancel();
        _fail(
          'Analysis is taking longer than usual. Your video was uploaded — '
          'check back in a moment.',
        );
        return;
      }
      try {
        final status = await repo.pollJob(jobId);
        if (_disposed) return;
        if (status.status == 'completed') {
          timer.cancel();
          final result = status.resultJson;
          if (result == null || result.isEmpty) {
            _fail(
              "Analysis finished but returned no result. Please try again.",
            );
            return;
          }
          HapticService.success();
          setState(() {
            _result = result;
            _analyzedAt = DateTime.now();
            _stage = _FormFlowStage.result;
          });
        } else if (status.status == 'failed' || status.status == 'cancelled') {
          timer.cancel();
          _fail(
            status.errorMessage?.trim().isNotEmpty == true
                ? status.errorMessage!
                : "We couldn't analyze that clip. Try a clear side-on video of one set.",
          );
        }
        // pending / in_progress → keep polling
      } catch (e) {
        // Transient poll error — keep trying until the deadline.
      }
    });
  }

  void _fail(String message, {bool premiumGated = false}) {
    if (_disposed) return;
    _pollTimer?.cancel();
    HapticService.error();
    if (mounted) {
      setState(() {
        _stage = _FormFlowStage.error;
        _errorMessage = message;
        _premiumGated = premiumGated;
      });
    }
  }

  void _reset() {
    _pollTimer?.cancel();
    _videoController?.dispose();
    _videoController = null;
    if (mounted) {
      setState(() {
        _stage = _FormFlowStage.entry;
        _result = null;
        _errorMessage = null;
        _premiumGated = false;
        _uploadProgress = 0;
      });
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('402') || s.toLowerCase().contains('premium')) {
      return 'Form analysis is a Premium feature. Upgrade to analyze your form.';
    }
    return 'Upload failed. Please check your connection and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final accent = AccentColorScope.of(context).getColor(colors.isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(colors, accent),
            const SizedBox(height: 16),
            switch (_stage) {
              _FormFlowStage.entry => _entryView(colors, accent),
              _FormFlowStage.uploading => _uploadingView(colors, accent),
              _FormFlowStage.analyzing => _analyzingView(colors, accent),
              _FormFlowStage.result => _resultView(colors),
              _FormFlowStage.error => _errorView(colors, accent),
            },
          ],
        ),
      ),
    );
  }

  Widget _header(ThemeColors colors, Color accent) {
    final title = widget.exerciseName != null
        ? 'Form check · ${widget.exerciseName}'
        : 'AI Form Check';
    return Row(
      children: [
        Icon(Icons.sports_gymnastics_rounded, color: accent, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // --- Entry -------------------------------------------------------------

  Widget _entryView(ThemeColors colors, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.exerciseName != null
              ? 'Record one clean set from the side and our AI scores your form, tempo, and range of motion.'
              : 'Record or upload a set from the side — the AI auto-detects the exercise and scores your form.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // Editable, optional exercise name — pre-filled from context (e.g.
        // "Push-ups"). Correct it, or clear it to let the AI auto-detect.
        TextField(
          controller: _exerciseController,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Exercise (optional)',
            hintText: 'AI auto-detects if left blank',
            labelStyle: TextStyle(fontSize: 12.5, color: colors.textMuted),
            hintStyle: TextStyle(fontSize: 12.5, color: colors.textMuted),
            prefixIcon: Icon(
              Icons.fitness_center_rounded,
              size: 18,
              color: colors.textMuted,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _exerciseController,
              builder: (_, value, __) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colors.textMuted,
                      ),
                      onPressed: () => _exerciseController.clear(),
                    ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _entryButton(
          colors,
          accent,
          icon: Icons.videocam_rounded,
          label: 'Record New Video',
          filled: true,
          onTap: () => _pickAndRun(ImageSource.camera),
        ),
        const SizedBox(height: 10),
        _entryButton(
          colors,
          accent,
          icon: Icons.video_library_rounded,
          label: 'Choose from Library',
          filled: false,
          onTap: () => _pickAndRun(ImageSource.gallery),
        ),
        const SizedBox(height: 14),
        Text(
          'Tip: a side-on angle of a single rep range works best.',
          style: TextStyle(fontSize: 11.5, color: colors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _entryButton(
    ThemeColors colors,
    Color accent, {
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? accent : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled ? null : Border.all(color: colors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: filled ? Colors.white : colors.textPrimary,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Uploading ---------------------------------------------------------

  Widget _uploadingView(ThemeColors colors, Color accent) {
    // Once the bytes are fully sent there's still a 1-3s finalize window
    // (S3 completes the PUT + the job-submit POST round-trips). A full solid
    // bar under "Uploading…" reads as done-but-stuck — flip to an
    // indeterminate bar + "Starting analysis…" so the motion never stops.
    final finalizing = _uploadProgress >= 0.995;
    final pct = (_uploadProgress * 100).clamp(0, 100).toInt();
    return Column(
      children: [
        if (_videoController != null && _videoController!.value.isInitialized)
          _inlinePreview(),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: finalizing
                ? null
                : (_uploadProgress > 0 ? _uploadProgress : null),
            minHeight: 6,
            backgroundColor: colors.cardBorder,
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            finalizing
                ? 'Starting analysis…'
                : 'Uploading your video…  $pct%',
            key: ValueKey<bool>(finalizing),
            style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
          ),
        ),
      ],
    );
  }

  // --- Analyzing (optimistic) -------------------------------------------

  Widget _analyzingView(ThemeColors colors, Color accent) {
    return Column(
      children: [
        if (_videoController != null && _videoController!.value.isInitialized)
          _inlinePreview(),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: colors.isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video uploaded',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Text(
                        _analyzeStageLabel,
                        key: ValueKey<String>(_analyzeStageLabel),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Usually takes about a minute. We'll notify you when it's ready — feel free to keep training.",
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            HapticService.light();
            Navigator.of(context).maybePop();
          },
          child: Text(
            'Keep training',
            style: TextStyle(color: accent, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // --- Result ------------------------------------------------------------

  Widget _resultView(ThemeColors colors) {
    Widget? player;
    if (_videoController != null && _videoController!.value.isInitialized) {
      player = AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio == 0
            ? 9 / 16
            : _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormAnalysisGaugeCard(
          result: _result!,
          videoPlayer: player,
          analyzedAt: _analyzedAt,
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: _reset, child: const Text('Analyze another')),
      ],
    );
  }

  // --- Error -------------------------------------------------------------

  Widget _errorView(ThemeColors colors, Color accent) {
    // Premium gate (402) — not an error: render an upgrade prompt with a
    // paywall CTA. "Try again" would just hit the same 402.
    if (_premiumGated) return _premiumGateView(colors, accent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: colors.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage ?? 'Something went wrong. Please try again.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Material(
          color: accent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _reset,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  'Try again',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _premiumGateView(ThemeColors colors, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: colors.isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.workspace_premium_rounded, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Form Check is a Premium feature',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade to get expert scoring of your form, tempo, and '
                      'range of motion on any exercise.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Material(
          color: accent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              HapticService.light();
              // Close the sheet first so the paywall isn't stacked under it.
              Navigator.of(context).pop();
              context.push('/paywall-pricing');
            },
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(
            'Maybe later',
            style: TextStyle(color: colors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _inlinePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio == 0
            ? 9 / 16
            : _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }
}
