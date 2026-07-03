/// Equipment-snap flow (Issue #1, Task #6).
///
/// Point camera at a gym machine → upload → backend Vision classifies +
/// canonicalizes → ranked exercise matches. User taps Swap/Add to mutate the
/// active workout. Unmatched cases fall through into the existing Import
/// Exercise flow with the snapped image pre-attached.
///
/// Used from both [showExerciseSwapSheet] and [showExerciseAddSheet] via the
/// floating "Snap equipment" FAB.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../exercises/import_exercise_screen.dart';
import 'snapped_equipment_section.dart' show invalidateSnappedEquipmentCache;
import '../../../services/equipment_snap_offline_queue.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Mode the snap flow is invoked in. Drives copy + post-confirm action.
enum SnapMode { swap, add, identify }

/// Which capture source the flow opens with. [camera] auto-launches the
/// camera (the at-the-gym path); [gallery] opens the photo picker directly
/// (the importing-photos-taken-earlier path — multi-select in identify mode).
enum SnapSource { camera, gallery }

/// Shows the snap-equipment flow as a full-screen route.
///
/// Returns the updated [Workout] when a swap/add succeeded, or null when the
/// user cancelled / nothing was confirmed.
Future<Workout?> showEquipmentSnapFlow(
  BuildContext context,
  WidgetRef ref, {
  required SnapMode mode,
  String? workoutId,
  String? replacingExerciseId,
  String? replacingExerciseName,
  String? previewId,
  Duration? activeSetTimer,
  SnapSource initialSource = SnapSource.camera,
}) async {
  return await Navigator.of(context).push<Workout>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => EquipmentSnapFlow(
        mode: mode,
        workoutId: workoutId,
        replacingExerciseId: replacingExerciseId,
        replacingExerciseName: replacingExerciseName,
        previewId: previewId,
        activeSetTimer: activeSetTimer,
        initialSource: initialSource,
      ),
    ),
  );
}

class EquipmentSnapFlow extends ConsumerStatefulWidget {
  final SnapMode mode;
  final String? workoutId;
  final String? replacingExerciseId;
  final String? replacingExerciseName;
  final String? previewId;
  final Duration? activeSetTimer;
  final SnapSource initialSource;

  const EquipmentSnapFlow({
    super.key,
    required this.mode,
    this.workoutId,
    this.replacingExerciseId,
    this.replacingExerciseName,
    this.previewId,
    this.activeSetTimer,
    this.initialSource = SnapSource.camera,
  });

  @override
  ConsumerState<EquipmentSnapFlow> createState() => _EquipmentSnapFlowState();
}

enum _Step {
  capturing,
  // Source chooser — shown when the user cancels the auto-launched camera
  // (e.g. they're not at the gym and want to import an existing photo).
  chooser,
  uploading,
  classifying,
  result,
  error,
  blurWarning,
  // Multi-photo import (identify mode only): sequential per-photo
  // classification with progress, then an aggregate summary.
  batchProcessing,
  batchSummary,
}

/// Per-photo outcome of a multi-photo identify batch.
class _BatchItem {
  final Uint8List bytes;
  final String? canonical; // human-readable when identified
  final String status; // identified | unidentified | limit | queued
  const _BatchItem({required this.bytes, this.canonical, required this.status});
}

/// Laplacian-variance threshold below which we warn the user the photo is
/// likely too blurry to classify. Empirically tuned: phone-camera "sharp"
/// shots score 200-2000+, "soft hand-shake" scores 30-90, and outright
/// motion blur scores <20. We pick 80 as the cutoff so legitimate
/// dim-gym shots still get through.
const double _kBlurVarianceThreshold = 80.0;

/// Compute a Laplacian-of-Gaussian-like blur metric on the captured frame.
///
/// We approximate the standard `cv2.Laplacian(gray).var()` heuristic by:
///  1. Decoding the JPEG into RGB pixels (downscaling to ≤320px max edge so
///     the math stays under ~30ms even on older Android).
///  2. Converting to luminance (BT.601).
///  3. Applying a 3×3 Laplacian kernel (`[[0,1,0],[1,-4,1],[0,1,0]]`).
///  4. Returning the variance of the kernel response.
///
/// Returns null if decoding fails — caller treats null as "skip the gate"
/// (we never want to block legitimate edge cases).
double? _computeBlurVariance(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    // Downscale: blur math is scale-invariant enough for this gate.
    final scale = decoded.width > decoded.height
        ? 320 / decoded.width
        : 320 / decoded.height;
    final small = scale < 1.0
        ? img.copyResize(decoded,
            width: (decoded.width * scale).round(),
            height: (decoded.height * scale).round(),
            interpolation: img.Interpolation.average)
        : decoded;

    final w = small.width;
    final h = small.height;
    if (w < 3 || h < 3) return null;

    // Pre-compute luminance buffer (Float64 mean+sumSq).
    final lum = Float64List(w * h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = small.getPixel(x, y);
        // BT.601 luma — fine for blur estimation.
        lum[y * w + x] =
            0.299 * p.r.toDouble() + 0.587 * p.g.toDouble() + 0.114 * p.b.toDouble();
      }
    }

    // Apply 3x3 Laplacian, accumulate mean + variance in a single pass.
    final responses = Float64List((w - 2) * (h - 2));
    int idx = 0;
    double sum = 0;
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final c = lum[y * w + x];
        final t = lum[(y - 1) * w + x];
        final b = lum[(y + 1) * w + x];
        final l = lum[y * w + (x - 1)];
        final r = lum[y * w + (x + 1)];
        final v = (t + b + l + r) - 4.0 * c;
        responses[idx++] = v;
        sum += v;
      }
    }
    if (idx == 0) return null;
    final mean = sum / idx;
    double sq = 0;
    for (int i = 0; i < idx; i++) {
      final d = responses[i] - mean;
      sq += d * d;
    }
    return sq / idx;
  } catch (e) {
    debugPrint('⚠️ [SnapFlow] blur metric failed: $e');
    return null;
  }
}

class _EquipmentSnapFlowState extends ConsumerState<EquipmentSnapFlow>
    with AutomaticKeepAliveClientMixin {
  // App-backgrounded recovery (edge case 3): keep state alive across rebuilds.
  @override
  bool get wantKeepAlive => true;

  _Step _step = _Step.capturing;
  String? _errorMessage;
  // Surfaced for debug/telemetry; intentionally not in the UI to keep the
  // warning step uncluttered.
  // ignore: unused_field
  double? _blurVariance;

  // Capture
  final ImagePicker _picker = ImagePicker();
  Uint8List? _capturedBytes;

  // Backend response
  Map<String, dynamic>? _result;

  // Multi-photo identify batch (gallery import).
  static const int _kMaxBatchPhotos = 6;
  final List<_BatchItem> _batchResults = [];
  int _batchTotal = 0;
  int _batchProgress = 0;
  // Set when a daily-cap (402/429) or offline break stopped the batch early.
  String? _batchNote;

  // ---------------------------------------------------------------------------
  // Capture
  // ---------------------------------------------------------------------------

  Future<void> _pickFromCamera() async {
    if (mounted && _step != _Step.capturing) {
      setState(() => _step = _Step.capturing);
    }
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        // Downscale to ≤1280px max edge before upload (network + cost).
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked == null) {
        // User cancelled the camera — offer the gallery instead of
        // closing the whole flow (they may be importing photos taken
        // at the gym earlier). Cancel on the chooser exits.
        if (mounted) setState(() => _step = _Step.chooser);
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _capturedBytes = bytes);
      await _gateBlurThenUpload(bytes);
    } on PlatformException catch (e) {
      // Edge case 1: permission denied. Fall through to gallery.
      debugPrint('⚠️ [SnapFlow] Camera failed: $e — falling back to gallery');
      await _pickFromGallery();
    } catch (e, st) {
      debugPrint('❌ [SnapFlow] Camera error: $e\n$st');
      _setError('Could not open the camera. Try again or use Photos.');
    }
  }

  Future<void> _pickFromGallery() async {
    if (mounted && _step != _Step.capturing) {
      setState(() => _step = _Step.capturing);
    }
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked == null) {
        // Cancelled the picker — back to the chooser rather than
        // stranding the screen on the capturing spinner.
        if (mounted) setState(() => _step = _Step.chooser);
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _capturedBytes = bytes);
      await _gateBlurThenUpload(bytes);
    } catch (e, st) {
      debugPrint('❌ [SnapFlow] Gallery error: $e\n$st');
      _setError('Could not load that photo. Please try another.');
    }
  }

  /// Multi-photo gallery import — identify mode only. Each photo is a
  /// separate `/equipment/snap` call (the server records identified
  /// equipment per call), so a batch is just a sequential loop with
  /// progress and an aggregate summary at the end.
  Future<void> _pickFromGalleryMulti() async {
    assert(widget.mode == SnapMode.identify);
    if (mounted && _step != _Step.capturing) {
      setState(() => _step = _Step.capturing);
    }
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked.isEmpty) {
        if (mounted) setState(() => _step = _Step.chooser);
        return;
      }
      if (picked.length == 1) {
        // Single selection → identical to the existing single-photo path
        // (keeps the blur gate + disambiguation UI).
        final bytes = await picked.first.readAsBytes();
        if (!mounted) return;
        setState(() => _capturedBytes = bytes);
        await _gateBlurThenUpload(bytes);
        return;
      }
      final batch = <Uint8List>[];
      for (final x in picked.take(_kMaxBatchPhotos)) {
        batch.add(await x.readAsBytes());
      }
      if (!mounted) return;
      if (picked.length > _kMaxBatchPhotos) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Processing the first $_kMaxBatchPhotos photos — import the rest after.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      await _runBatch(batch);
    } catch (e, st) {
      debugPrint('❌ [SnapFlow] Multi-gallery error: $e\n$st');
      _setError('Could not load those photos. Please try again.');
    }
  }

  Future<void> _runBatch(List<Uint8List> photos) async {
    _batchResults.clear();
    _batchNote = null;
    _batchTotal = photos.length;
    final api = ref.read(apiClientProvider);

    for (var i = 0; i < photos.length; i++) {
      final bytes = photos[i];
      if (!mounted) return;
      setState(() {
        _batchProgress = i + 1;
        _step = _Step.batchProcessing;
      });
      try {
        final formData = FormData.fromMap({
          'image': MultipartFile.fromBytes(
            bytes,
            filename: 'import_$i.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
          'mode': widget.mode.name,
        });
        final resp = await api.post(
          '${ApiConstants.apiBaseUrl}/equipment/snap',
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        );
        final data = resp.data;
        final matched = data is Map && data['matched'] == true;
        final canonical =
            data is Map ? data['equipment_canonical_name'] as String? : null;
        _batchResults.add(_BatchItem(
          bytes: bytes,
          canonical: matched && canonical != null
              ? _humanCanonical(canonical)
              : null,
          status: matched ? 'identified' : 'unidentified',
        ));
        invalidateSnappedEquipmentCache();
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 402 || status == 429) {
          // Daily snap cap — stop burning the remaining photos.
          for (final rest in photos.skip(i)) {
            _batchResults
                .add(_BatchItem(bytes: rest, status: 'limit'));
          }
          _batchNote = status == 402
              ? "You've used your free snaps for today — the remaining photos weren't processed. Upgrade to keep going."
              : "You've hit today's snap limit — the remaining photos weren't processed.";
          break;
        }
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          // Offline mid-batch: enqueue this + remaining photos for the
          // existing auto-retry-on-reconnect queue.
          final queue = ref.read(equipmentSnapOfflineQueueProvider);
          for (final rest in photos.skip(i)) {
            queue.enqueue(QueuedSnap(
              id: '${DateTime.now().microsecondsSinceEpoch}_${_batchResults.length}',
              imageBytes: rest,
              contentType: 'image/jpeg',
              mode: widget.mode.name,
              workoutId: widget.workoutId,
              replacingExerciseId: widget.replacingExerciseId,
              queuedAt: DateTime.now(),
            ));
            _batchResults.add(_BatchItem(bytes: rest, status: 'queued'));
          }
          _batchNote =
              "You went offline — the remaining photos are saved and will be identified when you're back online.";
          break;
        }
        debugPrint('❌ [SnapFlow] batch photo ${i + 1} failed: $status');
        _batchResults.add(_BatchItem(bytes: bytes, status: 'unidentified'));
      } catch (e) {
        debugPrint('❌ [SnapFlow] batch photo ${i + 1} error: $e');
        _batchResults.add(_BatchItem(bytes: bytes, status: 'unidentified'));
      }
    }

    if (!mounted) return;
    setState(() => _step = _Step.batchSummary);
  }

  // ---------------------------------------------------------------------------
  // Client-side blur gate (Issue #1, Task #6 deferred item 2)
  // ---------------------------------------------------------------------------

  /// Compute a Laplacian-variance blur score and short-circuit to a warning
  /// step if the photo is below threshold. The user can still override with
  /// "Use anyway" — we never *block*, only nudge, since dim-light gym shots
  /// can legitimately score low.
  Future<void> _gateBlurThenUpload(Uint8List bytes) async {
    // Run the metric off the UI thread.
    final variance = await compute(_computeBlurVariance, bytes);
    if (!mounted) return;
    _blurVariance = variance;
    if (variance != null && variance < _kBlurVarianceThreshold) {
      debugPrint(
          '⚠️ [SnapFlow] Blur gate triggered: variance=$variance < $_kBlurVarianceThreshold');
      setState(() => _step = _Step.blurWarning);
      return;
    }
    await _uploadAndClassify(bytes);
  }

  // ---------------------------------------------------------------------------
  // Upload + classify
  // ---------------------------------------------------------------------------

  Future<void> _uploadAndClassify(Uint8List bytes) async {
    setState(() => _step = _Step.uploading);
    try {
      final api = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: 'snap.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
        'mode': widget.mode.name,
        if (widget.workoutId != null) 'workout_id': widget.workoutId,
        if (widget.replacingExerciseId != null)
          'replacing_exercise_id': widget.replacingExerciseId,
      });

      setState(() => _step = _Step.classifying);

      final resp = await api.post(
        '${ApiConstants.apiBaseUrl}/equipment/snap',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          // Vision + Gemini extraction can take 5-15s.
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (resp.statusCode != 200 || resp.data is! Map) {
        throw 'Unexpected response (${resp.statusCode})';
      }
      if (!mounted) return;
      // Bust the Snapped-tab cache so a subsequent open shows this new row.
      invalidateSnappedEquipmentCache();
      setState(() {
        _result = Map<String, dynamic>.from(resp.data as Map);
        _step = _Step.result;
      });
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = (e.response?.data is Map)
          ? (e.response!.data as Map)['detail']
          : null;
      if (status == 402) {
        _setError("You've used your free snaps for today. Upgrade to keep going.");
        return;
      }
      if (status == 429) {
        _setError("You've hit today's snap limit. Try again tomorrow.");
        return;
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        // Offline: enqueue the captured bytes so we retry automatically on
        // reconnect. The user gets a notification with the result rather
        // than losing their snap.
        if (_capturedBytes != null) {
          ref.read(equipmentSnapOfflineQueueProvider).enqueue(QueuedSnap(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                imageBytes: _capturedBytes!,
                contentType: 'image/jpeg',
                mode: widget.mode.name,
                workoutId: widget.workoutId,
                replacingExerciseId: widget.replacingExerciseId,
                queuedAt: DateTime.now(),
              ));
          if (mounted) {
            setState(() {
              _errorMessage =
                  "You're offline. We saved your snap and will identify it when you're back online.";
              _step = _Step.error;
            });
          }
          return;
        }
        _setError("You're offline. Connect and try again.");
        return;
      }
      debugPrint('❌ [SnapFlow] /equipment/snap failed: $status detail=$detail');
      _setError('Could not identify the equipment. Please try again.');
    } catch (e, st) {
      debugPrint('❌ [SnapFlow] Snap error: $e\n$st');
      _setError('Something went wrong. Please try again.');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _errorMessage = msg;
      _step = _Step.error;
    });
  }

  // ---------------------------------------------------------------------------
  // Confirmation actions
  // ---------------------------------------------------------------------------

  Future<void> _confirmMatch(Map<String, dynamic> match) async {
    final exerciseName = (match['name'] as String?) ?? '';
    final exerciseId = (match['id'] as String?) ?? '';
    final canonical =
        (_result?['equipment_canonical_name'] as String?) ?? '';
    if (exerciseName.isEmpty) return;

    // Edge case: cardio swap (treadmill / bike). Confirm with the user that
    // the swap will replace sets/reps with a duration target.
    final isCardio = const {'treadmill', 'elliptical', 'rowing_machine',
                            'stationary_bike', 'spin_bike', 'recumbent_bike'}
        .contains(canonical);
    if (isCardio && widget.mode == SnapMode.swap) {
      final ok = await _confirmDialog(
        title: AppLocalizations.of(context).equipmentSnapFlowReplaceWithCardio,
        body: AppLocalizations.of(context).equipmentSnapFlowThisWillSwapSets,
      );
      if (ok != true) return;
    }

    if (!mounted) return;
    final repo = ref.read(workoutRepositoryProvider);

    if (widget.mode == SnapMode.swap) {
      if (widget.workoutId == null || widget.replacingExerciseName == null) {
        _setError('Cannot swap without a workout context.');
        return;
      }
      final (workout, err) = await repo.swapExercise(
        workoutId: widget.workoutId!,
        oldExerciseName: widget.replacingExerciseName!,
        newExerciseName: exerciseName,
        swapSource: 'equipment_snap',
        previewId: widget.previewId,
      );
      if (err != null) {
        _setError(err);
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(workout);
    } else if (widget.mode == SnapMode.add) {
      if (widget.workoutId == null) {
        _setError('Cannot add without a workout context.');
        return;
      }
      final workout = await repo.addExercise(
        workoutId: widget.workoutId!,
        exerciseName: exerciseName,
        exerciseId: exerciseId.isNotEmpty ? exerciseId : null,
        previewId: widget.previewId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(workout);
    } else {
      // identify mode: just close.
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _confirmDialog({required String title, required String body}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).buttonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).onboardingContinueButton),
          ),
        ],
      ),
    );
  }

  Future<void> _fallbackToImport() async {
    final hint = (_result?['raw_name'] as String?) ?? '';
    if (!mounted) return;
    Navigator.of(context).pop();
    await showImportExerciseScreen(
      context,
      prefilledImageBytes: _capturedBytes,
      prefilledNameHint: hint,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Auto-launch the requested source as soon as the route mounts:
    // camera for the at-the-gym path, photo picker for imports.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialSource == SnapSource.gallery) {
        widget.mode == SnapMode.identify
            ? _pickFromGalleryMulti()
            : _pickFromGallery();
      } else {
        _pickFromCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          _titleForMode(),
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (widget.activeSetTimer != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: _SetTimerPill(remaining: widget.activeSetTimer!),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildStepBody(isDark),
      ),
    );
  }

  String _titleForMode() {
    switch (widget.mode) {
      case SnapMode.swap:
        return 'Snap to swap';
      case SnapMode.add:
        return 'Snap to add';
      case SnapMode.identify:
        return 'Identify equipment';
    }
  }

  Widget _buildStepBody(bool isDark) {
    switch (_step) {
      case _Step.capturing:
        return const Center(child: CircularProgressIndicator());
      case _Step.chooser:
        return _buildChooser();
      case _Step.uploading:
        return const _LoadingView(message: 'Uploading photo…');
      case _Step.classifying:
        return const _LoadingView(message: 'Identifying equipment…');
      case _Step.result:
        return _buildResult(isDark);
      case _Step.error:
        return _buildError();
      case _Step.blurWarning:
        return _buildBlurWarning();
      case _Step.batchProcessing:
        return _LoadingView(
            message:
                'Identifying photo $_batchProgress of $_batchTotal…');
      case _Step.batchSummary:
        return _buildBatchSummary();
    }
  }

  /// Aggregate result of a multi-photo import — per-photo thumbnail +
  /// outcome, plus any early-stop note (daily cap / offline).
  Widget _buildBatchSummary() {
    final identified =
        _batchResults.where((b) => b.status == 'identified').length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          identified > 0
              ? 'Identified $identified of $_batchTotal photos'
              : 'No equipment identified',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          identified > 0
              ? 'Your equipment list has been updated.'
              : 'Try clearer photos, or pick your equipment manually.',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        for (final item in _batchResults)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    item.bytes,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    switch (item.status) {
                      'identified' => item.canonical ?? 'Identified',
                      'limit' => 'Not processed — snap limit',
                      'queued' => 'Saved — will identify when online',
                      _ => 'Not identified',
                    },
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: item.status == 'identified'
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: item.status == 'identified'
                          ? null
                          : Colors.grey,
                    ),
                  ),
                ),
                Icon(
                  switch (item.status) {
                    'identified' => Icons.check_circle,
                    'queued' => Icons.schedule,
                    _ => Icons.help_outline,
                  },
                  size: 20,
                  color: item.status == 'identified'
                      ? const Color(0xFF22C55E)
                      : Colors.grey,
                ),
              ],
            ),
          ),
        if (_batchNote != null) ...[
          const SizedBox(height: 4),
          Text(
            _batchNote!,
            style: const TextStyle(
                fontSize: 13, color: Colors.grey, height: 1.4),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.photo_library_rounded),
          onPressed: _pickFromGalleryMulti,
          label: const Text('Import more photos'),
        ),
      ],
    );
  }

  /// Source chooser — reached by cancelling the camera. Lets the user
  /// import an existing photo (e.g. gym pics taken earlier) instead of
  /// forcing a live capture.
  Widget _buildChooser() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.photo_camera_back_rounded, size: 48),
          const SizedBox(height: 14),
          const Text(
            'Add a photo of your equipment',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.mode == SnapMode.identify
                ? 'Snap it now, or import photos you already have.'
                : 'Snap it now, or import a photo you already have.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.camera_alt),
            onPressed: _pickFromCamera,
            label: const Text('Take photo'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_library_rounded),
            onPressed: widget.mode == SnapMode.identify
                ? _pickFromGalleryMulti
                : _pickFromGallery,
            label: const Text('Choose from Photos'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).buttonCancel),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurWarning() {
    final bytes = _capturedBytes;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          const SizedBox(height: 18),
          const Icon(Icons.blur_on, size: 40),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).equipmentSnapFlowLooksABitBlurry,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Hold steady or move to better light, then retake. '
              "If the gym is just dim, you can still upload.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
          ),
          const SizedBox(height: 22),
          // Wrap so iPhone SE doesn't overflow the action row.
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                onPressed: _pickFromCamera,
                label: Text(AppLocalizations.of(context).equipmentSnapFlowRetake),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_rounded),
                onPressed: widget.mode == SnapMode.identify
                    ? _pickFromGalleryMulti
                    : _pickFromGallery,
                label: const Text('Photos'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.cloud_upload),
                onPressed: () {
                  if (_capturedBytes != null) {
                    _uploadAndClassify(_capturedBytes!);
                  }
                },
                label: Text(AppLocalizations.of(context).equipmentSnapFlowUseAnyway),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? AppLocalizations.of(context).equipmentSnapFlowSomethingWentWrong,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context).buttonCancel),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_rounded),
                onPressed: widget.mode == SnapMode.identify
                    ? _pickFromGalleryMulti
                    : _pickFromGallery,
                label: const Text('Photos'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.camera_alt),
                onPressed: _pickFromCamera,
                label: Text(AppLocalizations.of(context).workoutReviewTryAgain),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult(bool isDark) {
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    final matched = result['matched'] == true;
    if (!matched) {
      final reason = result['unmatched_reason'] as String? ?? 'unknown';
      return _buildUnmatched(reason);
    }

    final canonical =
        (result['equipment_canonical_name'] as String?) ?? 'equipment';
    final disambiguate = result['disambiguate'] == true;
    final matches = (result['matches'] as List? ?? [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    if (matches.isEmpty) {
      return _buildUnmatched('no_matches');
    }

    return ListView(
      // Use Wrap-friendly spacing so iPhone SE width (320pt) doesn't overflow
      // — see memory `feedback_no_overflow_adaptive_screens`.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          disambiguate
              ? AppLocalizations.of(context).equipmentSnapFlowWhichOneIsIt
              : 'Found ${_humanCanonical(canonical)}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          disambiguate
              ? AppLocalizations.of(context).equipmentSnapFlowWeReNot100
              : 'Tap an exercise to ${_actionVerb()}.',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        for (final m in matches.take(5)) _MatchCard(
          match: m,
          fallbackImageBytes: _capturedBytes,
          actionLabel: _actionVerb(),
          onTap: () => _confirmMatch(m),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _fallbackToImport,
          icon: const Icon(Icons.edit),
          label: Text(AppLocalizations.of(context).equipmentSnapFlowNotTheseDescribeInstead),
        ),
      ],
    );
  }

  Widget _buildUnmatched(String reason) {
    final copy = switch (reason) {
      'not_equipment' =>
          "That doesn't look like gym equipment. Try a clearer photo.",
      'low_confidence' => "We couldn't identify the machine confidently.",
      'no_canonical' => "We don't have that machine in our library yet.",
      _ => "We couldn't match this image.",
    };
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 56),
          const SizedBox(height: 16),
          Text(copy, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                onPressed: _pickFromCamera,
                label: Text(AppLocalizations.of(context).equipmentSnapFlowRetake),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_rounded),
                onPressed: widget.mode == SnapMode.identify
                    ? _pickFromGalleryMulti
                    : _pickFromGallery,
                label: const Text('Photos'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.edit),
                onPressed: _fallbackToImport,
                label: Text(AppLocalizations.of(context).equipmentSnapFlowDescribeInstead),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _actionVerb() {
    switch (widget.mode) {
      case SnapMode.swap:
        return 'Swap';
      case SnapMode.add:
        return 'Add';
      case SnapMode.identify:
        return 'View';
    }
  }

  String _humanCanonical(String c) =>
      c.replaceAll('_', ' ').replaceFirstMapped(
            RegExp(r'^.'),
            (m) => m.group(0)!.toUpperCase(),
          );
}

// ===========================================================================
// Subwidgets
// ===========================================================================

class _LoadingView extends StatelessWidget {
  final String message;
  const _LoadingView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(message),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final Uint8List? fallbackImageBytes;
  final String actionLabel;
  final VoidCallback onTap;
  const _MatchCard({
    required this.match,
    required this.fallbackImageBytes,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final name = (match['name'] as String?) ?? '';
    final imageUrl = match['image_url'] as String?;
    final primaryMuscle = (match['primary_muscle'] as String?) ?? '';
    final badge = match['badge'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surface.withValues(alpha: 0.6)
                : AppColorsLight.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              // Thumbnail: server image_url, else snapped photo (edge case 8).
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _fallbackThumb(fallbackImageBytes))
                      : _fallbackThumb(fallbackImageBytes),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    if (primaryMuscle.isNotEmpty)
                      Text(
                        primaryMuscle,
                        style: const TextStyle(
                          fontSize: 12, color: Colors.grey,
                        ),
                      ),
                    if (badge != null && badge.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackThumb(Uint8List? bytes) {
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.fitness_center, size: 24, color: Colors.white),
    );
  }
}

class _SetTimerPill extends StatelessWidget {
  final Duration remaining;
  const _SetTimerPill({required this.remaining});
  @override
  Widget build(BuildContext context) {
    final m = remaining.inMinutes;
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Set: $m:$s',
        style: const TextStyle(
          color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
