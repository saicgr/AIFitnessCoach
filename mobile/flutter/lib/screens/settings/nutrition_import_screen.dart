import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/providers/source_import_activity_provider.dart';
import '../../data/repositories/measurements_repository.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/health_service.dart';
import 'widgets/nutrition_import_preview_sheet.dart';

/// Free, no-paywall flow for importing nutrition history from another app.
///
/// Wires to the backend contract:
///   1. POST /nutrition/import           (multipart) → {job_id, status}
///   2. GET  /nutrition/import/{job}     → poll to preview_ready
///   3. POST /nutrition/import/{job}/commit  → poll to done
///
/// CSV sources (MyFitnessPal / MacroFactor / Cronometer) pick a file via
/// [FilePicker]. Apple Health reads daily nutrition rows off-device through
/// [HealthService] and ships them as a JSON-encoded array.
class NutritionImportScreen extends ConsumerStatefulWidget {
  const NutritionImportScreen({super.key, this.initialSourceId});

  /// When set (e.g. deep-linked from the optional onboarding step), the
  /// matching source's import flow auto-starts on open — the user lands
  /// straight on the file picker / Health read instead of the picker grid.
  final String? initialSourceId;

  @override
  ConsumerState<NutritionImportScreen> createState() =>
      _NutritionImportScreenState();
}

/// Each card in the source picker.
class _ImportSource {
  const _ImportSource({
    required this.id,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isHealth,
  });

  final String id; // backend `source`
  final String label;
  final String hint; // 1-line "how to export"
  final IconData icon;
  final bool isHealth;
}

const _kSources = <_ImportSource>[
  _ImportSource(
    id: 'myfitnesspal',
    label: 'MyFitnessPal',
    hint: 'Web → Settings → Export Data → email yourself the CSV',
    icon: Icons.local_dining_outlined,
    isHealth: false,
  ),
  _ImportSource(
    id: 'macrofactor',
    label: 'MacroFactor',
    hint: 'App → Settings → Export Data → Nutrition CSV',
    icon: Icons.insights_outlined,
    isHealth: false,
  ),
  _ImportSource(
    id: 'cronometer',
    label: 'Cronometer',
    hint: 'Web → Account → Export Data → Daily Nutrition CSV',
    icon: Icons.pie_chart_outline,
    isHealth: false,
  ),
  _ImportSource(
    id: 'apple_health',
    label: 'Apple Health',
    hint: 'Reads logged nutrition straight from Health, no export needed',
    icon: Icons.favorite_outline,
    isHealth: true,
  ),
];

enum _Phase { idle, working, done }

class _NutritionImportScreenState extends ConsumerState<NutritionImportScreen> {
  _Phase _phase = _Phase.idle;
  String _statusMessage = '';
  Map<String, dynamic>? _result; // result block on success
  String? _error;

  static const _pollInterval = Duration(milliseconds: 1200);
  static const _pollTimeout = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    // Deep-link: auto-start the requested source once the first frame is up
    // (so file-picker / Health prompts have a mounted context to attach to).
    final sourceId = widget.initialSourceId;
    if (sourceId != null) {
      final match =
          _kSources.where((s) => s.id == sourceId).cast<_ImportSource?>();
      final source = match.isEmpty ? null : match.first;
      if (source != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startImport(source);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import nutrition'),
        centerTitle: true,
      ),
      body: switch (_phase) {
        _Phase.working => _buildWorking(accent, textSecondary),
        _Phase.done => _buildDone(accent, textPrimary, textSecondary),
        _Phase.idle => _buildPicker(
            accent, isDark, textPrimary, textSecondary, textMuted),
      },
    );
  }

  // -- Source picker --------------------------------------------------------

  Widget _buildPicker(
    Color accent,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'Bring your food log from another app. We\'ll match your meals to '
          'dates and keep everything you\'ve already tracked.',
          style: TextStyle(fontSize: 14, height: 1.4, color: textSecondary),
        ),
        const SizedBox(height: 20),
        for (final source in _kSources) ...[
          _SourceCard(
            source: source,
            accent: accent,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            onTap: () => _startImport(source),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.lock_open_rounded, size: 14, color: textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Free for everyone. No subscription required.',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -- Working (parsing / committing) --------------------------------------

  Widget _buildWorking(Color accent, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: accent),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // -- Done (success / error) ----------------------------------------------

  Widget _buildDone(Color accent, Color textPrimary, Color textSecondary) {
    final err = _error;
    if (err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error, size: 56),
              const SizedBox(height: 16),
              Text(
                'Import failed',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                err,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => setState(() {
                  _phase = _Phase.idle;
                  _error = null;
                }),
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final lines = _summaryLines(_result ?? const {});

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
            const SizedBox(height: 16),
            Text(
              'All set',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              lines.isEmpty ? 'Nothing new to import.' : lines.join('  ·  '),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    _phase = _Phase.idle;
                    _result = null;
                  }),
                  child: const Text('Import another'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -- Flow -----------------------------------------------------------------

  Future<void> _startImport(_ImportSource source) async {
    HapticService.light();
    final apiClient = ref.read(apiClientProvider);
    // Captured up-front so the tail of the flow (commit + poll to done) can
    // finish headlessly after this screen is popped — the Imports screen's
    // activity banner keeps showing live progress and flips to the result.
    final activity = ref.read(sourceImportActivityProvider.notifier);
    final container = ProviderScope.containerOf(context, listen: false);
    final userId = await apiClient.getUserId();
    if (userId == null) {
      _showSnack('Please sign in to import data.');
      return;
    }

    // Build the multipart payload for this source.
    FormData formData;
    try {
      if (source.isHealth) {
        formData = await _buildHealthFormData(userId);
      } else {
        final picked = await _pickFile();
        if (picked == null) return; // user cancelled
        formData = FormData.fromMap({
          'user_id': userId,
          'source': source.id,
          'file': MultipartFile.fromBytes(picked.bytes, filename: picked.name),
        });
      }
    } on _NoHealthDataException {
      _showSnack('No nutrition data found in Apple Health to import.');
      return;
    } catch (e) {
      debugPrint('❌ [NutritionImport] payload build failed: $e');
      _showSnack('Could not read the file. Please try again.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _phase = _Phase.working;
      _statusMessage = 'Reading your ${source.label} data…';
      _result = null;
      _error = null;
    });
    activity.start(
      sourceId: source.id,
      sourceLabel: source.label,
      message: 'Reading your ${source.label} data…',
    );

    try {
      // 1. Kick off the async parse job.
      final startResp = await apiClient.post<Map<String, dynamic>>(
        '/nutrition/import',
        data: formData,
      );
      final jobId = startResp.data?['job_id']?.toString();
      if (jobId == null || jobId.isEmpty) {
        throw Exception('Server did not return a job id.');
      }

      // 2. Poll until the preview is ready.
      final preview = await _pollUntil(
        apiClient,
        jobId,
        userId,
        target: 'preview_ready',
      );
      final previewJson = (preview['preview'] as Map?)?.cast<String, dynamic>();
      if (previewJson == null) {
        throw Exception('No preview produced for this file.');
      }
      final parsed = NutritionImportPreview.fromJson(previewJson);

      if (!mounted) {
        // User left before the preview — nothing was committed.
        activity.cancel();
        return;
      }
      // Drop back to idle behind the modal so a cancel returns to the picker.
      setState(() => _phase = _Phase.idle);
      activity.progress('Waiting for your review…');

      // 3. Show the preview sheet and collect the user's choices.
      final choice = await showNutritionImportPreviewSheet(
        context: context,
        preview: parsed,
        sourceLabel: source.label,
      );
      if (choice == null) {
        activity.cancel();
        return; // cancelled
      }

      if (mounted) {
        setState(() {
          _phase = _Phase.working;
          _statusMessage = 'Importing your meals…';
        });
      }
      activity.progress('Importing your meals…');

      // 4. Commit, then poll to done. Runs to completion even if this
      // screen is popped — the activity banner carries the outcome.
      await apiClient.post<Map<String, dynamic>>(
        '/nutrition/import/$jobId/commit',
        data: {
          'user_id': userId,
          'overlap_strategy': choice.overlapStrategy,
          'include_weight': choice.includeWeight,
        },
      );
      final finished = await _pollUntil(
        apiClient,
        jobId,
        userId,
        target: 'done',
      );

      final result =
          (finished['result'] as Map?)?.cast<String, dynamic>() ?? const {};

      // 5. Refresh anything that renders the imported dates.
      _invalidateForRange(
        container,
        parsed.dateRangeLo,
        parsed.dateRangeHi,
        weightImported: _asInt(result['weight_imported']) > 0,
      );
      activity.succeed(_summaryLines(result));

      if (!mounted) return;
      setState(() {
        _phase = _Phase.done;
        _result = result;
      });
    } on _ImportFailure catch (e) {
      activity.fail(e.message);
      if (!mounted) return;
      setState(() {
        _phase = _Phase.done;
        _error = e.message;
      });
    } catch (e) {
      debugPrint('❌ [NutritionImport] $e');
      final friendly = _friendlyError(e);
      activity.fail(friendly);
      if (!mounted) return;
      setState(() {
        _phase = _Phase.done;
        _error = friendly;
      });
    }
  }

  Future<({Uint8List bytes, String name})?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) throw Exception('Could not read file bytes');
    return (bytes: bytes, name: file.name);
  }

  Future<FormData> _buildHealthFormData(String userId) async {
    // Reads daily nutrition aggregates (+ weight) straight from HealthKit;
    // returns [] on Android (that platform's path is CSV import). Rows look
    // like {date:'YYYY-MM-DD', calories, protein_g, carbs_g, fat_g, weight_kg?}.
    final rows = await HealthService().readDailyNutritionFromHealth(daysBack: 365);
    if (rows.isEmpty) throw const _NoHealthDataException();
    return FormData.fromMap({
      'user_id': userId,
      'source': 'apple_health',
      'apple_health_json': jsonEncode(rows),
    });
  }

  /// Poll `GET /nutrition/import/{job}` until [target] (or `done`) is reached.
  /// Throws [_ImportFailure] on a server-reported error, or [TimeoutException]
  /// once [_pollTimeout] elapses.
  Future<Map<String, dynamic>> _pollUntil(
    ApiClient apiClient,
    String jobId,
    String userId, {
    required String target,
  }) async {
    final deadline = DateTime.now().add(_pollTimeout);
    while (true) {
      final resp = await apiClient.get<Map<String, dynamic>>(
        '/nutrition/import/$jobId',
        queryParameters: {'user_id': userId},
      );
      final body = resp.data ?? const {};
      final status = body['status']?.toString() ?? '';
      if (status == 'error') {
        throw _ImportFailure(
          body['error']?.toString() ?? 'The import could not be completed.',
        );
      }
      if (status == target || status == 'done') return body;
      if (DateTime.now().isAfter(deadline)) {
        throw _ImportFailure(
          'This is taking longer than expected. Please try again.',
        );
      }
      await Future<void>.delayed(_pollInterval);
    }
  }

  /// Invalidate every per-date nutrition provider in the imported range plus
  /// the singleton meta provider so freshly imported dates render. Weight
  /// imports additionally refresh the measurements/trends caches.
  ///
  /// Takes the [ProviderContainer] (captured at flow start) instead of `ref`
  /// because the commit tail may finish after this screen is disposed.
  void _invalidateForRange(
    ProviderContainer container,
    String? lo,
    String? hi, {
    required bool weightImported,
  }) {
    container.invalidate(nutritionMetaProvider);

    final start = _parseDate(lo);
    final end = _parseDate(hi) ?? start;
    if (start != null && end != null) {
      // Guard against an inverted or absurd range.
      final from = start.isBefore(end) ? start : end;
      final to = start.isBefore(end) ? end : start;
      var cursor = from;
      var guard = 0;
      while (!cursor.isAfter(to) && guard < 1000) {
        container.invalidate(dailyNutritionProvider(_dateKey(cursor)));
        cursor = cursor.add(const Duration(days: 1));
        guard++;
      }
    } else {
      // No range — refresh today at least.
      container.invalidate(dailyNutritionProvider(todayNutritionKey()));
    }

    if (weightImported) {
      container.invalidate(measurementsProvider);
    }
  }

  // -- Helpers --------------------------------------------------------------

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final detail = e.response?.data;
      if (detail is Map && detail['detail'] != null) {
        return detail['detail'].toString();
      }
      return 'Network error. Please check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  /// Human-readable summary lines for a commit `result` block. Shared by
  /// the in-screen done state and the Imports screen's activity banner.
  static List<String> _summaryLines(Map<String, dynamic> result) {
    final imported = _asInt(result['imported']);
    final skipped = _asInt(result['skipped']);
    final replaced = _asInt(result['replaced']);
    final failed = _asInt(result['failed']);
    final weightImported = _asInt(result['weight_imported']);
    return <String>[
      if (imported > 0) '$imported ${imported == 1 ? 'day' : 'days'} imported',
      if (replaced > 0) '$replaced replaced',
      if (skipped > 0) '$skipped skipped',
      if (weightImported > 0)
        '$weightImported weight ${weightImported == 1 ? 'entry' : 'entries'}',
      if (failed > 0) '$failed failed',
    ];
  }

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static String _dateKey(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

/// Thrown when the server reports the job failed, carrying a user-facing
/// message.
class _ImportFailure implements Exception {
  const _ImportFailure(this.message);
  final String message;
  @override
  String toString() => 'ImportFailure: $message';
}

/// Sentinel for "Apple Health returned no nutrition rows".
class _NoHealthDataException implements Exception {
  const _NoHealthDataException();
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.accent,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  final _ImportSource source;
  final Color accent;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(source.icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      source.hint,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
