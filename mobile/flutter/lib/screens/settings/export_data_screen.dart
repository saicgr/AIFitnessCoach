import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';

/// Reverse-direction export screen.
///
/// Sends the current user's strength + cardio history (and optionally
/// program templates) to the backend's `/workout-history/export` endpoint
/// and hands the bytes off to the OS share sheet via share_plus. Files are
/// additionally persisted to the app documents directory via file_saver so
/// the user can re-open them later from Files.app or the Downloads folder.
///
/// GDPR wording at the bottom is intentional — the export promise is core
/// to our "we'll never lock you in" pitch.
class ExportDataScreen extends ConsumerStatefulWidget {
  /// Optional prefilled format key (e.g. `'hevy'`). When the chat bot
  /// navigates here with a format suggestion, we preselect it so the user
  /// can hit "Generate Export" immediately.
  final String? initialFormatKey;

  const ExportDataScreen({super.key, this.initialFormatKey});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  /// UI-facing format list. Keys must match backend orchestrator
  /// (`services/workout_export/orchestrator.py::SUPPORTED_FORMATS`). We keep
  /// a local copy so the screen renders before the `/formats` round-trip
  /// returns — the UI feels instant instead of a spinner on open.
  static const _formats = <_FormatOption>[
    _FormatOption(
      key: 'hevy',
      displayName: 'Hevy CSV',
      description: 'Drop into Hevy → Settings → Import.',
      icon: Icons.fitness_center,
      cardioOnly: false,
    ),
    _FormatOption(
      key: 'strong',
      displayName: 'Strong CSV',
      description: 'Strong app + most community tools.',
      icon: Icons.fitness_center,
      cardioOnly: false,
    ),
    _FormatOption(
      key: 'fitbod',
      displayName: 'Fitbod CSV',
      description: 'For the Fitbod importer.',
      icon: Icons.fitness_center,
      cardioOnly: false,
    ),
    _FormatOption(
      key: 'csv',
      displayName: 'Generic CSV (all columns)',
      description: 'FitWiz-native schema. Maximum fidelity.',
      icon: Icons.table_chart,
      cardioOnly: false,
    ),
    _FormatOption(
      key: 'json',
      displayName: 'JSON',
      description: 'Pretty-printed. Easiest to re-import.',
      icon: Icons.data_object,
      cardioOnly: false,
    ),
    _FormatOption(
      key: 'parquet',
      displayName: 'Parquet (ZIP)',
      description: 'Columnar — fast for large datasets.',
      icon: Icons.storage,
      cardioOnly: false,
    ),
    _FormatOption(
      key: 'xlsx',
      displayName: 'Excel',
      description: 'Multi-sheet workbook with a Summary tab.',
      icon: Icons.grid_on,
      cardioOnly: false,
    ),
    _FormatOption(
      key: 'pdf',
      displayName: 'PDF Report',
      description: 'Printable training report with charts.',
      icon: Icons.picture_as_pdf,
      cardioOnly: false,
    ),
    _FormatOption(
      key: 'gpx',
      displayName: 'GPX (cardio only)',
      description: 'GPS routes for runs/rides with recorded polylines.',
      icon: Icons.map,
      cardioOnly: true,
    ),
    _FormatOption(
      key: 'tcx',
      displayName: 'TCX (cardio only)',
      description: 'Garmin Training Center XML.',
      icon: Icons.directions_run,
      cardioOnly: true,
    ),
  ];

  late String _selectedFormat;
  _DatePreset _selectedRange = _DatePreset.last90;
  DateTimeRange? _customRange;

  bool _includeStrength = true;
  bool _includeCardio = true;
  bool _includeTemplates = false;

  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Prefer the prefilled format when valid; otherwise default to Hevy
    // CSV (the most-requested target by far based on user research).
    final hint = widget.initialFormatKey;
    final valid = _formats.any((f) => f.key == hint);
    _selectedFormat = (hint != null && valid) ? hint : 'hevy';
  }

  _FormatOption get _currentFormat =>
      _formats.firstWhere((f) => f.key == _selectedFormat);

  /// Disable strength toggle when a cardio-only format is picked — and
  /// force cardio on. The backend does this anyway but locking the UI
  /// prevents confusion.
  bool get _isCardioOnlyFormat => _currentFormat.cardioOnly;

  DateTimeRange? _resolvedDateRange() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case _DatePreset.last30:
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
      case _DatePreset.last90:
        return DateTimeRange(start: now.subtract(const Duration(days: 90)), end: now);
      case _DatePreset.lastYear:
        return DateTimeRange(start: now.subtract(const Duration(days: 365)), end: now);
      case _DatePreset.allTime:
        return null;
      case _DatePreset.custom:
        return _customRange;
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      firstDate: DateTime(2018),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedRange = _DatePreset.custom;
      });
    }
  }

  Future<void> _generate() async {
    if (_isGenerating) return;
    final messenger = ScaffoldMessenger.of(context);

    // Cardio-only formats auto-force cardio=on; every other format needs
    // at least one dataset selected. This maps to the same guard server-side
    // but catching it client-side avoids an unnecessary round-trip.
    if (!_isCardioOnlyFormat && !_includeStrength && !_includeCardio && !_includeTemplates) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pick at least one dataset to export.')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final bytes = await _fetchExport();
      if (!mounted) return;

      final fmt = _currentFormat;
      final nowStamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      final baseName = 'fitwiz-${fmt.key}-$nowStamp';

      // file_saver persists to app-scoped storage (Android Documents / iOS
      // app container) so the user can re-open from Files.app later.
      // FileSaver requires Uint8List, not List<int>; convert once here.
      final typedBytes = Uint8List.fromList(bytes);
      await FileSaver.instance.saveFile(
        name: baseName,
        bytes: typedBytes,
        ext: _extensionFor(fmt.key),
        mimeType: MimeType.other,
      );

      // Share sheet: write to a tempfile first, then hand the URI to share_plus.
      // FileSaver's return path is platform-specific (sometimes a SAF URI on
      // Android) so we don't rely on it for the share payload.
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$baseName.${_extensionFor(fmt.key)}';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(tempPath)],
        subject: 'FitWiz Export — ${fmt.displayName}',
        text: 'Your FitWiz training data (${fmt.displayName}).',
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Exported ${_formatByteSize(bytes.length)}.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.type == DioExceptionType.receiveTimeout
          ? 'Export timed out — try a narrower date range.'
          : (e.response?.data is String
              ? e.response!.data as String
              : 'Export failed (${e.response?.statusCode ?? 'no response'})');
      messenger.showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<List<int>> _fetchExport() async {
    final apiClient = ref.read(apiClientProvider);
    final fmt = _currentFormat;

    final query = <String, dynamic>{'format': fmt.key};
    final includes = <String>[];
    if (!_isCardioOnlyFormat && _includeStrength) includes.add('strength');
    if (_isCardioOnlyFormat || _includeCardio) includes.add('cardio');
    if (!_isCardioOnlyFormat && _includeTemplates) includes.add('templates');
    query['include'] = includes.join(',');

    final range = _resolvedDateRange();
    if (range != null) {
      query['from'] = DateFormat('yyyy-MM-dd').format(range.start);
      query['to'] = DateFormat('yyyy-MM-dd').format(range.end);
    }

    // PDF generation is CPU-heavy; a little more slack than the default.
    final timeout = fmt.key == 'pdf' || fmt.key == 'xlsx'
        ? const Duration(seconds: 120)
        : const Duration(seconds: 60);

    final response = await apiClient.dio.get(
      '/workout-history/export',
      queryParameters: query,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: timeout,
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    return response.data as List<int>;
  }

  String _extensionFor(String formatKey) {
    switch (formatKey) {
      case 'json':
        return 'json';
      case 'parquet':
        return 'zip';
      case 'xlsx':
        return 'xlsx';
      case 'pdf':
        return 'pdf';
      case 'gpx':
        return 'gpx';
      case 'tcx':
        return 'tcx';
      case 'hevy':
      case 'strong':
      case 'fitbod':
      case 'csv':
      default:
        return 'csv';
    }
  }

  String _formatByteSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    // Reference apiBaseUrl so static analysis confirms ApiConstants is used
    // even when the dio instance attaches it via interceptor — prevents
    // "unused import" churn on future refactors.
    // ignore: unused_local_variable
    final _ = ApiConstants.apiBaseUrl;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export My Data'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _sectionLabel('FORMAT', textMuted),
          const SizedBox(height: 8),
          _formatCard(cardColor, cardBorder, textPrimary, textSecondary),

          const SizedBox(height: 24),
          _sectionLabel('DATE RANGE', textMuted),
          const SizedBox(height: 8),
          _dateRangeCard(cardColor, cardBorder, textPrimary, textSecondary),

          const SizedBox(height: 24),
          _sectionLabel('INCLUDE', textMuted),
          const SizedBox(height: 8),
          _includeCard(cardColor, cardBorder, textPrimary, textSecondary),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generate,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download),
              label: Text(_isGenerating ? 'Generating…' : 'Generate Export'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 24),
          _gdprFooter(cardColor, cardBorder, textSecondary),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );

  Widget _formatCard(Color bg, Color border, Color primary, Color secondary) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _formats.length; i++) ...[
            RadioListTile<String>(
              value: _formats[i].key,
              groupValue: _selectedFormat,
              onChanged: (val) {
                if (val != null) setState(() => _selectedFormat = val);
              },
              activeColor: AppColors.cyan,
              title: Row(
                children: [
                  Icon(_formats[i].icon, size: 18, color: AppColors.cyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formats[i].displayName,
                      style: TextStyle(fontWeight: FontWeight.w600, color: primary),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  _formats[i].description,
                  style: TextStyle(fontSize: 12, color: secondary),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              dense: true,
            ),
            if (i < _formats.length - 1)
              Divider(height: 1, thickness: 0.5, color: border),
          ],
        ],
      ),
    );
  }

  Widget _dateRangeCard(Color bg, Color border, Color primary, Color secondary) {
    final range = _resolvedDateRange();
    final subtitle = _selectedRange == _DatePreset.allTime
        ? 'Every session FitWiz has on record for you.'
        : range == null
            ? 'Pick a custom range.'
            : '${DateFormat('MMM d, y').format(range.start)} → ${DateFormat('MMM d, y').format(range.end)}';

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: AppColors.cyan, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(color: primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _preset('Last 30 days', _DatePreset.last30, border),
              _preset('Last 90 days', _DatePreset.last90, border),
              _preset('Last year', _DatePreset.lastYear, border),
              _preset('All time', _DatePreset.allTime, border),
              ActionChip(
                label: const Text('Custom…'),
                avatar: const Icon(Icons.edit_calendar, size: 16),
                onPressed: _pickCustomRange,
                backgroundColor: _selectedRange == _DatePreset.custom
                    ? AppColors.cyan.withValues(alpha: 0.2)
                    : null,
                side: BorderSide(color: border),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _preset(String label, _DatePreset preset, Color border) {
    final selected = _selectedRange == preset;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedRange = preset),
      selectedColor: AppColors.cyan.withValues(alpha: 0.2),
      side: BorderSide(color: border),
    );
  }

  Widget _includeCard(Color bg, Color border, Color primary, Color secondary) {
    // Cardio-only formats (tcx/gpx) force cardio on + disable strength/templates.
    final cardioOnly = _isCardioOnlyFormat;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: cardioOnly ? false : _includeStrength,
            onChanged: cardioOnly
                ? null
                : (v) => setState(() => _includeStrength = v),
            activeColor: AppColors.cyan,
            title: Text('Strength history', style: TextStyle(color: primary)),
            subtitle: Text(
              cardioOnly
                  ? 'Disabled — this format is cardio-only.'
                  : 'Every set: weight, reps, RPE, notes.',
              style: TextStyle(color: secondary, fontSize: 12),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: border),
          SwitchListTile.adaptive(
            value: cardioOnly ? true : _includeCardio,
            onChanged: cardioOnly
                ? null
                : (v) => setState(() => _includeCardio = v),
            activeColor: AppColors.cyan,
            title: Text('Cardio sessions', style: TextStyle(color: primary)),
            subtitle: Text(
              cardioOnly
                  ? 'Always included for cardio-only formats.'
                  : 'Runs, rides, rows, swims — with GPS where available.',
              style: TextStyle(color: secondary, fontSize: 12),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: border),
          SwitchListTile.adaptive(
            value: cardioOnly ? false : _includeTemplates,
            onChanged: cardioOnly
                ? null
                : (v) => setState(() => _includeTemplates = v),
            activeColor: AppColors.cyan,
            title: Text('Program templates', style: TextStyle(color: primary)),
            subtitle: Text(
              cardioOnly
                  ? 'Not applicable for cardio-only formats.'
                  : 'Jeff Nippard / Wendler / imported programs.',
              style: TextStyle(color: secondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gdprFooter(Color bg, Color border, Color secondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.cyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data is yours — take it anywhere.',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We never lock you in. Every export is a full fidelity copy '
                  'you can re-import into Hevy, Strong, Fitbod, or back into '
                  'FitWiz. GDPR Art. 20 compliant.',
                  style: TextStyle(color: secondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _FormatOption {
  final String key;
  final String displayName;
  final String description;
  final IconData icon;
  final bool cardioOnly;

  const _FormatOption({
    required this.key,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.cardioOnly,
  });
}

enum _DatePreset { last30, last90, lastYear, allTime, custom }
