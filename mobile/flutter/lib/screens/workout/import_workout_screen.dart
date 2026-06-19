/// AI Workout Importer.
///
/// Photo/Screenshot / Describe / Video → AI extracts a structured workout →
/// the user reviews/edits it → saved into their Custom workouts
/// (`generation_method='ai_import'`). Mirrors the exercise importer
/// (`import_exercise_screen.dart`) and uses the same presign → S3 upload.
///
/// Dart-only (no codegen).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/workout_import.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/workout_import_service.dart';

/// Public entry — pushes the importer full-screen. Resolves to the saved
/// workout id (or null if the user backed out).
Future<String?> showImportWorkoutScreen(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const ImportWorkoutScreen()),
  );
}

enum _Tab { photo, describe, video }

class ImportWorkoutScreen extends ConsumerStatefulWidget {
  const ImportWorkoutScreen({super.key});

  @override
  ConsumerState<ImportWorkoutScreen> createState() =>
      _ImportWorkoutScreenState();
}

class _ImportWorkoutScreenState extends ConsumerState<ImportWorkoutScreen> {
  _Tab _tab = _Tab.photo;

  File? _photo;
  File? _video;
  final _textCtrl = TextEditingController();
  final _hintCtrl = TextEditingController();

  bool _busy = false;
  String? _error;
  String _progress = 'Reading your workout…';

  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const int _maxPolls = 45;
  static const int _maxVideoSeconds = 30;

  /// Extracted workout under review (null = still on the input step).
  ImportedWorkout? _review;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ submit

  bool get _ready {
    switch (_tab) {
      case _Tab.photo:
        return _photo != null;
      case _Tab.describe:
        return _textCtrl.text.trim().length >= 10;
      case _Tab.video:
        return _video != null;
    }
  }

  Future<void> _submit() async {
    if (_busy || !_ready) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final svc = ref.read(workoutImportServiceProvider);
    final hint = _hintCtrl.text.trim();
    try {
      WorkoutImportResult result;
      switch (_tab) {
        case _Tab.photo:
          final s3 = await svc.uploadMedia(
              file: _photo!, contentType: 'image/jpeg');
          result = await svc.importFromPhoto(s3Key: s3, userHint: hint);
          break;
        case _Tab.describe:
          result = await svc.importFromText(
              rawText: _textCtrl.text.trim(), userHint: hint);
          break;
        case _Tab.video:
          final s3 = await svc.uploadMedia(
              file: _video!, contentType: 'video/mp4');
          result = await svc.importFromVideo(s3Key: s3, userHint: hint);
          break;
      }
      if (result.isComplete) {
        _enterReview(result.workout!);
      } else if (result.isAsync) {
        await _poll(result.jobId!);
      } else {
        throw Exception('Unexpected response');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ImportWorkout] $e');
      _setError(_friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _poll(String jobId) async {
    _pollAttempts = 0;
    final svc = ref.read(workoutImportServiceProvider);
    final completer = Completer<WorkoutImportJobStatus>();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        if (!completer.isCompleted) completer.completeError(StateError('gone'));
        return;
      }
      _pollAttempts++;
      try {
        final s = await svc.pollImportJob(jobId);
        if (mounted) {
          setState(() => _progress = 'Analyzing video… ${_pollAttempts * 2}s');
        }
        if (s.isTerminal) {
          timer.cancel();
          if (!completer.isCompleted) completer.complete(s);
        } else if (_pollAttempts >= _maxPolls) {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.completeError(
                Exception('Taking longer than expected. Try again.'));
          }
        }
      } catch (e) {
        timer.cancel();
        if (!completer.isCompleted) completer.completeError(e);
      }
    });
    final status = await completer.future;
    if (status.isFailed || status.workout == null) {
      throw Exception(status.errorMessage ?? 'Could not read that video.');
    }
    _enterReview(status.workout!);
  }

  void _enterReview(ImportedWorkout w) {
    if (!mounted) return;
    setState(() => _review = w);
  }

  Future<void> _save() async {
    final review = _review;
    if (review == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref.read(workoutImportServiceProvider).save(workout: review);
      // Refresh so the new workout shows in the Custom pill immediately.
      // ignore: unawaited_futures
      ref.read(workoutsProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } catch (e) {
      _setError(_friendly(e));
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          _review == null ? 'Import workout' : 'Review workout',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _review == null
            ? _buildInput(isDark, accent, textPrimary)
            : _buildReview(isDark, accent, textPrimary),
      ),
    );
  }

  Widget _buildInput(bool isDark, Color accent, Color textPrimary) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final fill = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return Column(
      children: [
        // Segmented control
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            decoration:
                BoxDecoration(color: fill, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                for (final t in _Tab.values)
                  Expanded(
                    child: GestureDetector(
                      onTap: _busy ? null : () => setState(() => _tab = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _tab == t ? accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_iconFor(t),
                                size: 16,
                                color: _tab == t ? Colors.white : textPrimary),
                            const SizedBox(width: 6),
                            Text(
                              _labelFor(t),
                              style: TextStyle(
                                color: _tab == t ? Colors.white : textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
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
        ),
        if (_error != null) _errorBanner(_error!),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _intro(accent, isDark),
                const SizedBox(height: 16),
                if (_tab == _Tab.photo)
                  _mediaPicker(
                    accent: accent,
                    file: _photo,
                    isVideo: false,
                    onPick: _pickPhoto,
                    onClear: () => setState(() => _photo = null),
                  )
                else if (_tab == _Tab.video)
                  _mediaPicker(
                    accent: accent,
                    file: _video,
                    isVideo: true,
                    onPick: _pickVideo,
                    onClear: () => setState(() => _video = null),
                  )
                else
                  TextField(
                    controller: _textCtrl,
                    minLines: 6,
                    maxLines: 12,
                    style: TextStyle(color: textPrimary, fontSize: 15, height: 1.4),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Paste a workout, e.g.\n"Push day: Bench 4x8, Incline DB 3x10, '
                          'Dips 3x12, Lateral raise 3x15"',
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      filled: true,
                      fillColor: fill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                const SizedBox(height: 14),
                TextField(
                  controller: _hintCtrl,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Workout name hint (optional)',
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
                ),
                if (_busy) ...[
                  const SizedBox(height: 18),
                  _progressCard(accent),
                ],
              ],
            ),
          ),
        ),
        _submitBar(accent, label: 'Import with AI', onTap: _submit, enabled: _ready),
      ],
    );
  }

  Widget _buildReview(bool isDark, Color accent, Color textPrimary) {
    final review = _review!;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final fill = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return Column(
      children: [
        if (_error != null) _errorBanner(_error!),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              TextField(
                controller: TextEditingController(text: review.name)
                  ..selection =
                      TextSelection.collapsed(offset: review.name.length),
                style: TextStyle(
                    color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                onChanged: (v) => _review = review.copyWith(name: v),
                decoration: InputDecoration(
                  labelText: 'Workout name',
                  filled: true,
                  fillColor: fill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${review.exercises.length} EXERCISES • ${review.workoutType.toUpperCase()} • ${review.estimatedDurationMinutes} MIN',
                style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...List.generate(review.exercises.length, (i) {
                final ex = review.exercises[i];
                final reps = ex.reps != null ? '${ex.reps}' : (ex.durationSeconds != null ? '${ex.durationSeconds}s' : '—');
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ex.name,
                                style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('${ex.sets} × $reps'
                                '${ex.muscleGroup != null ? '  •  ${ex.muscleGroup}' : ''}',
                                style:
                                    TextStyle(color: textMuted, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: textMuted),
                        onPressed: () {
                          final next = [...review.exercises]..removeAt(i);
                          setState(() => _review = review.copyWith(exercises: next));
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        _submitBar(accent,
            label: 'Save to my workouts',
            onTap: review.exercises.isEmpty ? null : _save,
            enabled: review.exercises.isNotEmpty),
      ],
    );
  }

  // ------------------------------------------------------------------ pieces

  Widget _intro(Color accent, bool isDark) {
    final fill = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    String body;
    switch (_tab) {
      case _Tab.photo:
        body = 'Screenshot a workout from anywhere — another app, a note, a '
            'whiteboard. AI reads the exercises, sets, and reps.';
        break;
      case _Tab.describe:
        body = 'Type or paste a workout in plain English. AI structures it into '
            'exercises with sets and reps.';
        break;
      case _Tab.video:
        body = 'Pick a short clip (≤${_maxVideoSeconds}s). AI extracts the '
            'movements into a structured workout. Takes ~20s.';
        break;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Import with AI',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(body,
                    style:
                        TextStyle(color: textMuted, fontSize: 13, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaPicker({
    required Color accent,
    required File? file,
    required bool isVideo,
    required Future<void> Function(ImageSource) onPick,
    required VoidCallback onClear,
  }) {
    if (file != null && !isVideo) {
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
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }
    if (file != null && isVideo) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.videocam_rounded, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(file.path.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close_rounded, color: accent),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _picker(accent, isVideo ? Icons.videocam_outlined : Icons.camera_alt_outlined,
              isVideo ? 'Record' : 'Camera', () => onPick(ImageSource.camera)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _picker(accent, Icons.photo_library_outlined, 'Gallery',
              () => onPick(ImageSource.gallery)),
        ),
      ],
    );
  }

  Widget _picker(Color accent, IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: accent),
        label: Text(label,
            style: TextStyle(
                color: accent, fontWeight: FontWeight.w600, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accent.withValues(alpha: 0.55)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _progressCard(Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(accent)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_progress,
                style: TextStyle(
                    color: accent, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _submitBar(Color accent,
      {required String label, required VoidCallback? onTap, required bool enabled}) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: (enabled && !_busy) ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: accent.withValues(alpha: 0.35),
              disabledForegroundColor: Colors.white70,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                : const Icon(Icons.auto_awesome, size: 20),
            label: Text(_busy ? 'Working…' : label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ pickers

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: source, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      if (x == null) return;
      if (!mounted) return;
      setState(() {
        _photo = File(x.path);
        _error = null;
      });
    } catch (e) {
      _setError('Could not open the photo picker.');
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final x = await ImagePicker().pickVideo(
          source: source, maxDuration: const Duration(seconds: _maxVideoSeconds));
      if (x == null) return;
      if (!mounted) return;
      setState(() {
        _video = File(x.path);
        _error = null;
      });
    } catch (e) {
      _setError('Could not load that video.');
    }
  }

  String _labelFor(_Tab t) {
    switch (t) {
      case _Tab.photo:
        return 'Photo';
      case _Tab.describe:
        return 'Describe';
      case _Tab.video:
        return 'Video';
    }
  }

  IconData _iconFor(_Tab t) {
    switch (t) {
      case _Tab.photo:
        return Icons.photo_camera_rounded;
      case _Tab.describe:
        return Icons.edit_note_rounded;
      case _Tab.video:
        return Icons.videocam_rounded;
    }
  }

  String _friendly(Object e) {
    final m = e.toString();
    if (m.contains('signed in')) return 'You need to be signed in.';
    if (m.contains('429')) return 'Too many requests — wait a minute.';
    if (m.contains('401') || m.contains('403')) return 'Session expired. Sign in again.';
    if (m.contains('413')) return 'File too large. Try a smaller image/clip.';
    if (m.contains('longer than expected')) return 'Taking longer than expected. Try again.';
    if (m.contains('Network') || m.contains('SocketException') || m.contains('timeout')) {
      return 'Network issue. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() => _error = msg);
  }
}
