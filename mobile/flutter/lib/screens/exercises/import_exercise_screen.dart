/// AI Exercise Importer screen.
///
/// 3-tab segmented flow: Photo / Video / Describe. Each tab runs its own
/// pipeline:
///   - Photo: pick → presign → upload → POST /import (sync) → preview sheet
///   - Video: pick → presign → upload → POST /import (async job_id) →
///     poll every 2s → preview sheet
///   - Describe: text → POST /import (sync) → preview sheet
///
/// The preview sheet (see `import_exercise_preview_sheet.dart`) lets the user
/// edit every extracted field before saving. "Discard" deletes the auto-saved
/// row; "Save" PATCHes the edits.
///
/// Dart-only (no code generation, no build_runner).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/custom_exercises_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/exercise_import.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/custom_exercise_repository.dart';
import '../../data/services/api_client.dart';
import 'import_exercise_preview_sheet.dart';

/// Public entry. Pushes the importer as a full screen route. When the user
/// successfully saves, the created/edited exercise flows back via Navigator
/// pop value so callers (e.g. the swap sheet) can refresh state.
Future<bool> showImportExerciseScreen(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const ImportExerciseScreen()),
  );
  return result == true;
}

enum _ImportTab { photo, video, describe }

class ImportExerciseScreen extends ConsumerStatefulWidget {
  const ImportExerciseScreen({super.key});

  @override
  ConsumerState<ImportExerciseScreen> createState() =>
      _ImportExerciseScreenState();
}

class _ImportExerciseScreenState extends ConsumerState<ImportExerciseScreen> {
  _ImportTab _tab = _ImportTab.photo;

  // --- Photo ----------------------------------------------------------------
  File? _photoFile;
  final TextEditingController _photoHintCtrl = TextEditingController();

  // --- Video ----------------------------------------------------------------
  File? _videoFile;
  VideoPlayerController? _videoCtrl;
  final TextEditingController _videoHintCtrl = TextEditingController();

  // --- Describe -------------------------------------------------------------
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _describeHintCtrl = TextEditingController();

  // --- Shared submission state ---------------------------------------------
  bool _isSubmitting = false;
  String? _error;
  String _videoProgressMessage =
      'Analyzing your form... this takes about 20 seconds';
  Timer? _pollTimer;
  int _pollAttempts = 0;

  // Hard cap at ~90s (45 polls * 2s) so a wedged job doesn't spin forever.
  static const int _maxPollAttempts = 45;

  // Max allowed video length. Plan says 5-10s target, 10s max.
  static const int _maxVideoSeconds = 10;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _photoHintCtrl.dispose();
    _videoHintCtrl.dispose();
    _describeHintCtrl.dispose();
    _descriptionCtrl.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Import exercise',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSegmentedControl(isDark, accent, textPrimary, textMuted),
            if (_error != null) _buildErrorBanner(_error!, isDark),
            Expanded(
              child: AbsorbPointer(
                absorbing: _isSubmitting,
                child: IndexedStack(
                  index: _tab.index,
                  children: [
                    _buildPhotoTab(isDark, accent, textPrimary, textMuted),
                    _buildVideoTab(isDark, accent, textPrimary, textMuted),
                    _buildDescribeTab(isDark, accent, textPrimary, textMuted),
                  ],
                ),
              ),
            ),
            _buildSubmitBar(isDark, accent),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Segmented control
  // ===========================================================================

  Widget _buildSegmentedControl(
    bool isDark,
    Color accent,
    Color textPrimary,
    Color textMuted,
  ) {
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final tab in _ImportTab.values)
              Expanded(
                child: _SegmentButton(
                  label: _labelFor(tab),
                  icon: _iconFor(tab),
                  selected: _tab == tab,
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _tab = tab),
                  accent: accent,
                  textMuted: textMuted,
                  textPrimary: textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _labelFor(_ImportTab t) {
    switch (t) {
      case _ImportTab.photo:
        return 'Photo';
      case _ImportTab.video:
        return 'Video';
      case _ImportTab.describe:
        return 'Describe';
    }
  }

  IconData _iconFor(_ImportTab t) {
    switch (t) {
      case _ImportTab.photo:
        return Icons.photo_camera_rounded;
      case _ImportTab.video:
        return Icons.videocam_rounded;
      case _ImportTab.describe:
        return Icons.edit_note_rounded;
    }
  }

  // ===========================================================================
  // Photo tab
  // ===========================================================================

  Widget _buildPhotoTab(
    bool isDark,
    Color accent,
    Color textPrimary,
    Color textMuted,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IntroCard(
            accent: accent,
            isDark: isDark,
            icon: Icons.photo_camera_outlined,
            title: 'Snap it, we\'ll extract it',
            body:
                'Take or pick a clear photo of a machine, setup, or posture. '
                'Gemini Vision will infer the exercise name, muscles, '
                'equipment, and instructions.',
          ),
          const SizedBox(height: 16),
          if (_photoFile != null)
            _PhotoPreview(file: _photoFile!, onClear: _clearPhoto, accent: accent)
          else
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Take photo',
                    accent: accent,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.photo_library_outlined,
                    label: 'From gallery',
                    accent: accent,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          _HintField(
            controller: _photoHintCtrl,
            isDark: isDark,
            hint: 'Exercise name hint (optional)',
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (xfile == null) return;
      if (!mounted) return;
      setState(() {
        _photoFile = File(xfile.path);
        _error = null;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ImportExercise] pickImage error: $e');
      _setError('Could not open photo picker. Check permissions and try again.');
    }
  }

  void _clearPhoto() {
    setState(() => _photoFile = null);
  }

  // ===========================================================================
  // Video tab
  // ===========================================================================

  Widget _buildVideoTab(
    bool isDark,
    Color accent,
    Color textPrimary,
    Color textMuted,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IntroCard(
            accent: accent,
            isDark: isDark,
            icon: Icons.videocam_outlined,
            title: 'Record a 5-10s clip',
            body:
                'Short form-check style. We\'ll extract 3 keyframes, classify '
                'the motion, and build the structured exercise. Analysis '
                'takes ~20 seconds.',
          ),
          const SizedBox(height: 16),
          if (_videoFile != null)
            _VideoPreview(
              controller: _videoCtrl,
              onClear: _clearVideo,
              accent: accent,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.videocam_outlined,
                    label: 'Record video',
                    accent: accent,
                    onTap: () => _pickVideo(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.video_library_outlined,
                    label: 'From library',
                    accent: accent,
                    onTap: () => _pickVideo(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          _HintField(
            controller: _videoHintCtrl,
            isDark: isDark,
            hint: 'Exercise name hint (optional)',
          ),
          if (_isSubmitting && _tab == _ImportTab.video) ...[
            const SizedBox(height: 20),
            _AsyncProgressCard(
              accent: accent,
              message: _videoProgressMessage,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: _maxVideoSeconds),
      );
      if (xfile == null) return;
      final file = File(xfile.path);

      // Re-validate locally: some platforms don't honour maxDuration.
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final durSec = controller.value.duration.inSeconds;
      if (durSec > _maxVideoSeconds) {
        await controller.dispose();
        _setError(
          'Video is ${durSec}s — please keep it under $_maxVideoSeconds seconds.',
        );
        return;
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      // Dispose any previous controller before swapping.
      await _videoCtrl?.dispose();
      setState(() {
        _videoFile = file;
        _videoCtrl = controller;
        _error = null;
      });
      await controller.setLooping(true);
      await controller.play();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ImportExercise] pickVideo error: $e');
      _setError('Could not load that video. Try a shorter, standard-format clip.');
    }
  }

  Future<void> _clearVideo() async {
    await _videoCtrl?.dispose();
    if (!mounted) return;
    setState(() {
      _videoFile = null;
      _videoCtrl = null;
    });
  }

  // ===========================================================================
  // Describe tab
  // ===========================================================================

  Widget _buildDescribeTab(
    bool isDark,
    Color accent,
    Color textPrimary,
    Color textMuted,
  ) {
    final fill = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IntroCard(
            accent: accent,
            isDark: isDark,
            icon: Icons.edit_note_outlined,
            title: 'Describe the exercise',
            body:
                'Type a one-sentence description. Gemini will infer muscles, '
                'equipment, difficulty, and step-by-step instructions.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionCtrl,
            minLines: 8,
            maxLines: 12,
            style: TextStyle(color: textPrimary, fontSize: 15, height: 1.4),
            decoration: InputDecoration(
              hintText:
                  "e.g., 'Seated cable row with neutral grip, targeting mid back and rear delts'",
              hintStyle: TextStyle(color: textMuted, fontSize: 14),
              filled: true,
              fillColor: fill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 16),
          _HintField(
            controller: _describeHintCtrl,
            isDark: isDark,
            hint: 'Exercise name hint (optional)',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Submit bar
  // ===========================================================================

  Widget _buildSubmitBar(bool isDark, Color accent) {
    final enabled = _isCurrentTabReady() && !_isSubmitting;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: enabled ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: accent.withOpacity(0.35),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.auto_awesome, size: 20),
            label: Text(
              _isSubmitting ? 'Working...' : 'Import with AI',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isCurrentTabReady() {
    switch (_tab) {
      case _ImportTab.photo:
        return _photoFile != null;
      case _ImportTab.video:
        return _videoFile != null;
      case _ImportTab.describe:
        return _descriptionCtrl.text.trim().length >= 10;
    }
  }

  // ===========================================================================
  // Submission pipeline
  // ===========================================================================

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      switch (_tab) {
        case _ImportTab.photo:
          await _submitPhoto();
          break;
        case _ImportTab.video:
          await _submitVideo();
          break;
        case _ImportTab.describe:
          await _submitText();
          break;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ImportExercise] submit error: $e');
      _setError(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitPhoto() async {
    final file = _photoFile;
    if (file == null) return;
    final s3Key = await _uploadMedia(
      file: file,
      contentType: 'image/jpeg',
    );
    final userId = await _requireUserId();
    final hint = _photoHintCtrl.text.trim();
    final result = await ref.read(customExerciseRepositoryProvider).importFromPhoto(
          userId: userId,
          s3Key: s3Key,
          userHint: hint.isEmpty ? null : hint,
        );
    await _handleSyncResult(result);
  }

  Future<void> _submitVideo() async {
    final file = _videoFile;
    if (file == null) return;
    final s3Key = await _uploadMedia(
      file: file,
      contentType: 'video/mp4',
    );
    final userId = await _requireUserId();
    final hint = _videoHintCtrl.text.trim();
    final result = await ref.read(customExerciseRepositoryProvider).importFromVideo(
          userId: userId,
          s3Key: s3Key,
          userHint: hint.isEmpty ? null : hint,
        );
    if (result.isComplete && result.exercise != null) {
      await _handleSyncResult(result);
      return;
    }
    if (result.isAsync && result.jobId != null) {
      await _pollVideoJob(result.jobId!);
      return;
    }
    throw Exception('Unexpected import response (video)');
  }

  Future<void> _submitText() async {
    final raw = _descriptionCtrl.text.trim();
    if (raw.isEmpty) return;
    final userId = await _requireUserId();
    final hint = _describeHintCtrl.text.trim();
    final result = await ref.read(customExerciseRepositoryProvider).importFromText(
          userId: userId,
          rawText: raw,
          userHint: hint.isEmpty ? null : hint,
        );
    await _handleSyncResult(result);
  }

  /// Upload a file via chat presign → S3 PUT. Returns the s3_key which the
  /// backend will resolve into a signed URL during extraction.
  Future<String> _uploadMedia({
    required File file,
    required String contentType,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final size = await file.length();
    final filename = file.path.split('/').last;
    if (kDebugMode) {
      debugPrint(
          '🔍 [ImportExercise] Presigning $filename ($contentType, $size bytes)');
    }
    // "image" / "video" discriminator for the backend presign endpoint.
    final mediaType = contentType.startsWith('video') ? 'video' : 'image';
    final presign = await chatRepo.getPresignedUrl(
      filename: filename,
      contentType: contentType,
      mediaType: mediaType,
      expectedSizeBytes: size,
    );
    final url = presign['upload_url'] as String? ?? presign['url'] as String?;
    final fields = presign['fields'] as Map?;
    final s3Key = presign['s3_key'] as String?;
    if (url == null || s3Key == null) {
      throw Exception('Malformed presign response');
    }
    await chatRepo.uploadToS3(
      presignedUrl: url,
      fields: fields?.map((k, v) => MapEntry(k.toString(), v)),
      file: file,
      contentType: contentType,
    );
    return s3Key;
  }

  Future<void> _pollVideoJob(String jobId) async {
    _pollAttempts = 0;
    final repo = ref.read(customExerciseRepositoryProvider);
    final completer = Completer<ImportJobStatus>();
    if (kDebugMode) {
      debugPrint('🤖 [ImportExercise] Polling video job $jobId');
    }
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.completeError(StateError('cancelled'));
        }
        return;
      }
      _pollAttempts++;
      try {
        final status = await repo.pollImportJob(jobId);
        if (mounted) {
          setState(() {
            _videoProgressMessage = _progressMessageFor(status, _pollAttempts);
          });
        }
        if (status.isTerminal) {
          timer.cancel();
          if (!completer.isCompleted) completer.complete(status);
        } else if (_pollAttempts >= _maxPollAttempts) {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.completeError(
              Exception(
                'Analysis is taking longer than expected. Please try again.',
              ),
            );
          }
        }
      } catch (e) {
        timer.cancel();
        if (!completer.isCompleted) completer.completeError(e);
      }
    });

    final status = await completer.future;
    if (status.isFailed) {
      throw Exception(status.errorMessage ??
          'Analysis failed. Try a clearer, well-lit clip.');
    }
    if (status.exercise == null) {
      throw Exception('Analysis completed but no exercise returned.');
    }
    final wrapped = ImportExerciseResult.complete(
      exercise: status.exercise!,
      ragIndexed: status.ragIndexed,
      duplicate: status.duplicate,
    );
    await _handleSyncResult(wrapped);
  }

  String _progressMessageFor(ImportJobStatus status, int attempts) {
    if (status.status == 'processing') {
      return 'Analyzing keyframes... ${attempts * 2}s elapsed';
    }
    if (status.status == 'pending') {
      return 'Queued — starting analysis...';
    }
    return 'Analyzing your form... this takes about 20 seconds';
  }

  Future<void> _handleSyncResult(ImportExerciseResult result) async {
    final exercise = result.exercise;
    if (exercise == null) {
      throw Exception('Import returned no exercise.');
    }
    // Refresh the provider list so the exercise shows up everywhere.
    // ignore: unawaited_futures
    ref.read(customExercisesProvider.notifier).refresh();

    if (!mounted) return;
    final saved = await showImportExercisePreviewSheet(
      context,
      ref,
      exercise: exercise,
      duplicate: result.duplicate,
      ragIndexed: result.ragIndexed,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    }
    // If the user discarded, stay on the screen so they can try again.
  }

  Future<String> _requireUserId() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('You need to be signed in to import exercises.');
    }
    return userId;
  }

  // ===========================================================================
  // Error UX
  // ===========================================================================

  Widget _buildErrorBanner(String message, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('signed in')) return 'You need to be signed in.';
    if (msg.contains('429')) {
      return 'Too many requests — wait a minute and try again.';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'Session expired. Please sign in again.';
    }
    if (msg.contains('413')) {
      return 'File too large. Try a shorter clip or smaller image.';
    }
    if (msg.contains('timeout') ||
        msg.contains('Timeout') ||
        msg.contains('SocketException') ||
        msg.contains('Network')) {
      return 'Network issue. Check your connection and try again.';
    }
    if (msg.contains('longer than expected')) {
      return 'Analysis is taking longer than expected. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() => _error = msg);
  }
}

// ===========================================================================
// Small reusable widgets (kept private so they don't leak into the library).
// ===========================================================================

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color accent;
  final Color textMuted;
  final Color textPrimary;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.accent,
    required this.textMuted,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final IconData icon;
  final String title;
  final String body;

  const _IntroCard({
    required this.accent,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: accent),
        label: Text(
          label,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accent.withOpacity(0.55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _HintField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String hint;

  const _HintField({
    required this.controller,
    required this.isDark,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return TextField(
      controller: controller,
      style: TextStyle(color: textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final File file;
  final VoidCallback onClear;
  final Color accent;
  const _PhotoPreview({
    required this.file,
    required this.onClear,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final VideoPlayerController? controller;
  final VoidCallback onClear;
  final Color accent;
  const _VideoPreview({
    required this.controller,
    required this.onClear,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null || !c.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio == 0 ? 4 / 3 : c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${c.value.duration.inSeconds}s',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}

class _AsyncProgressCard extends StatelessWidget {
  final Color accent;
  final String message;
  const _AsyncProgressCard({required this.accent, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
