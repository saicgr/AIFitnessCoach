import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../widgets/widgets.dart';

/// Export time range options.
enum ExportTimeRange {
  lastMonth,
  last3Months,
  last6Months,
  lastYear,
  allTime,
  custom,
}

/// Export format options.
enum ExportFormat {
  csvZip,
  plainText,
  json,
  excel,
  parquet,
}

/// Shows the export data dialog.
void showExportDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => _ExportDataDialog(
      onExport: (startDate, endDate, format) async {
        Navigator.pop(context);
        if (format == ExportFormat.plainText) {
          await _exportDataAsText(context, ref, startDate: startDate, endDate: endDate);
        } else if (format == ExportFormat.json || format == ExportFormat.excel || format == ExportFormat.parquet) {
          await _exportDataWithFormat(context, ref, format: format, startDate: startDate, endDate: endDate);
        } else {
          await _exportData(context, ref, startDate: startDate, endDate: endDate);
        }
      },
    ),
  );
}

Future<void> _exportData(
  BuildContext context,
  WidgetRef ref, {
  String? startDate,
  String? endDate,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final navigator = Navigator.of(context);
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // Show loading dialog with message
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.cyan),
          const SizedBox(height: 16),
          Text(
            'Exporting your data...',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ],
      ),
    ),
  );

  bool dialogDismissed = false;

  void dismissDialog() {
    if (!dialogDismissed) {
      dialogDismissed = true;
      navigator.pop();
    }
  }

  try {
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();

    if (userId == null) {
      throw Exception('User not found');
    }

    // Build query parameters for date filter
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    // Call backend to export user data (returns ZIP file bytes)
    final response = await apiClient.dio.get(
      '${ApiConstants.users}/$userId/export$queryString',
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Close loading dialog FIRST
    dismissDialog();

    // Handle error responses
    if (response.statusCode == 404) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('User data not found. Please try logging out and back in.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    } else if (response.statusCode != 200) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Server error: ${response.statusCode}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (response.data != null) {
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final filePath = '${tempDir.path}/fitness_data_$timestamp.zip';
      final file = File(filePath);
      await file.writeAsBytes(response.data as List<int>);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'FitWiz Data Export',
        text: 'My fitness data exported on $timestamp',
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Data exported successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('No data received from server'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } on DioException catch (e) {
    dismissDialog();

    String errorMessage = 'Export failed';
    if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Export timed out. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'No internet connection';
    } else if (e.response?.statusCode == 404) {
      errorMessage = 'User data not found';
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: AppColors.error,
      ),
    );
  } catch (e) {
    dismissDialog();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Export failed: ${e.toString()}'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

Future<void> _exportDataAsText(
  BuildContext context,
  WidgetRef ref, {
  String? startDate,
  String? endDate,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final navigator = Navigator.of(context);
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // Show loading dialog with message
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.cyan),
          const SizedBox(height: 16),
          Text(
            'Exporting your data as text...',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ],
      ),
    ),
  );

  bool dialogDismissed = false;

  void dismissDialog() {
    if (!dialogDismissed) {
      dialogDismissed = true;
      navigator.pop();
    }
  }

  try {
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();

    if (userId == null) {
      throw Exception('User not found');
    }

    // Build query parameters for date filter
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    // Call backend to export user data as text (returns plain text)
    final response = await apiClient.dio.get(
      '${ApiConstants.users}/$userId/export-text$queryString',
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Close loading dialog FIRST
    dismissDialog();

    // Handle error responses
    if (response.statusCode == 404) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('User data not found. Please try logging out and back in.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    } else if (response.statusCode != 200) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Server error: ${response.statusCode}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (response.data != null) {
      final textContent = response.data as String;

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final filePath = '${tempDir.path}/fitness_data_$timestamp.txt';
      final file = File(filePath);
      await file.writeAsString(textContent);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'FitWiz Data Export',
        text: 'My fitness data exported on $timestamp',
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Data exported as text successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('No data received from server'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } on DioException catch (e) {
    dismissDialog();

    String errorMessage = 'Export failed';
    if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Export timed out. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'No internet connection';
    } else if (e.response?.statusCode == 404) {
      errorMessage = 'User data not found';
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: AppColors.error,
      ),
    );
  } catch (e) {
    dismissDialog();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Export failed: ${e.toString()}'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

Future<void> _exportDataWithFormat(
  BuildContext context,
  WidgetRef ref, {
  required ExportFormat format,
  String? startDate,
  String? endDate,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final navigator = Navigator.of(context);
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // Map format to backend query param and file extension
  final String formatParam;
  final String fileExtension;
  final ResponseType responseType;
  switch (format) {
    case ExportFormat.json:
      formatParam = 'json';
      fileExtension = '.json';
      responseType = ResponseType.plain;
    case ExportFormat.excel:
      formatParam = 'xlsx';
      fileExtension = '.xlsx';
      responseType = ResponseType.bytes;
    case ExportFormat.parquet:
      formatParam = 'parquet';
      fileExtension = '.parquet';
      responseType = ResponseType.bytes;
    default:
      return;
  }

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.cyan),
          const SizedBox(height: 16),
          Text(
            'Exporting your data...',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ],
      ),
    ),
  );

  bool dialogDismissed = false;

  void dismissDialog() {
    if (!dialogDismissed) {
      dialogDismissed = true;
      navigator.pop();
    }
  }

  try {
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();

    if (userId == null) {
      throw Exception('User not found');
    }

    // Build query parameters
    final queryParams = <String, String>{'format': formatParam};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final queryString = '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    final response = await apiClient.dio.get(
      '${ApiConstants.users}/$userId/export$queryString',
      options: Options(
        responseType: responseType,
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dismissDialog();

    if (response.statusCode == 404) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('User data not found. Please try logging out and back in.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    } else if (response.statusCode != 200) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Server error: ${response.statusCode}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (response.data != null) {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final filePath = '${tempDir.path}/fitness_data_$timestamp$fileExtension';
      final file = File(filePath);

      if (format == ExportFormat.json) {
        await file.writeAsString(response.data as String);
      } else {
        await file.writeAsBytes(response.data as List<int>);
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'FitWiz Data Export',
        text: 'My fitness data exported on $timestamp',
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Data exported successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('No data received from server'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } on DioException catch (e) {
    dismissDialog();

    String errorMessage = 'Export failed';
    if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Export timed out. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'No internet connection';
    } else if (e.response?.statusCode == 404) {
      errorMessage = 'User data not found';
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: AppColors.error,
      ),
    );
  } catch (e) {
    dismissDialog();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Export failed: ${e.toString()}'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

class _ExportDataDialog extends StatefulWidget {
  final Future<void> Function(String? startDate, String? endDate, ExportFormat format) onExport;

  const _ExportDataDialog({required this.onExport});

  @override
  State<_ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<_ExportDataDialog> {
  ExportTimeRange _selectedRange = ExportTimeRange.allTime;
  ExportFormat _selectedFormat = ExportFormat.csvZip;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  String _getTimeRangeLabel(ExportTimeRange range) {
    switch (range) {
      case ExportTimeRange.lastMonth:
        return 'Last 1 month';
      case ExportTimeRange.last3Months:
        return 'Last 3 months';
      case ExportTimeRange.last6Months:
        return 'Last 6 months';
      case ExportTimeRange.lastYear:
        return 'Last year';
      case ExportTimeRange.allTime:
        return 'All time';
      case ExportTimeRange.custom:
        return 'Custom range';
    }
  }

  (String?, String?) _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedRange) {
      case ExportTimeRange.lastMonth:
        final start = DateTime(today.year, today.month - 1, today.day);
        return (_formatDate(start), _formatDate(today));
      case ExportTimeRange.last3Months:
        final start = DateTime(today.year, today.month - 3, today.day);
        return (_formatDate(start), _formatDate(today));
      case ExportTimeRange.last6Months:
        final start = DateTime(today.year, today.month - 6, today.day);
        return (_formatDate(start), _formatDate(today));
      case ExportTimeRange.lastYear:
        final start = DateTime(today.year - 1, today.month, today.day);
        return (_formatDate(start), _formatDate(today));
      case ExportTimeRange.allTime:
        return (null, null);
      case ExportTimeRange.custom:
        return (
          _customStartDate != null ? _formatDate(_customStartDate!) : null,
          _customEndDate != null ? _formatDate(_customEndDate!) : null,
        );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialDate = isStart
        ? (_customStartDate ?? DateTime.now().subtract(const Duration(days: 30)))
        : (_customEndDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.cyan,
              onPrimary: Colors.white,
              surface: isDark ? AppColors.elevated : AppColorsLight.elevated,
              onSurface: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStartDate = picked;
          if (_customEndDate != null && _customEndDate!.isBefore(picked)) {
            _customEndDate = picked;
          }
        } else {
          _customEndDate = picked;
          if (_customStartDate != null && _customStartDate!.isAfter(picked)) {
            _customStartDate = picked;
          }
        }
      });
    }
  }

  void _showFormatInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Text(
          'Export Info',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data categories & columns
              Text('Exported Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.cyan)),
              const SizedBox(height: 8),
              _dataCategory('Profile', 'name, email, fitness_level, goals, equipment, height, weight, age, gender', isDark),
              _dataCategory('Body Metrics', 'date, weight, waist, hip, neck, body_fat, heart_rate, blood_pressure', isDark),
              _dataCategory('Workouts', 'id, name, type, difficulty, scheduled_date, is_completed, duration, exercises', isDark),
              _dataCategory('Workout Logs', 'id, workout_id, name, completed_at, total_time, total_sets, total_reps', isDark),
              _dataCategory('Exercise Sets', 'log_id, exercise_name, set_number, reps, weight, rpe, is_completed, notes', isDark),
              _dataCategory('Strength Records', 'exercise_name, weight, reps, estimated_1rm, achieved_at, is_pr', isDark),
              _dataCategory('Achievements', 'name, type, tier, earned_at, trigger_value', isDark),
              _dataCategory('Streaks', 'type, current_streak, longest_streak, last_activity, start_date', isDark),
              const SizedBox(height: 14),

              // Formats
              Text('Formats', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.cyan)),
              const SizedBox(height: 8),
              _formatInfoRow(Icons.folder_zip_outlined, 'CSV/ZIP',
                  'Comma-separated values in a ZIP archive. Opens in Excel, Google Sheets, or any spreadsheet app.', isDark),
              const SizedBox(height: 10),
              _formatInfoRow(Icons.description_outlined, 'Plain Text',
                  'Human-readable formatted text file with workout details.', isDark),
              const SizedBox(height: 10),
              _formatInfoRow(Icons.code, 'JSON',
                  'Structured data format. Best for developers or importing into other apps.', isDark),
              const SizedBox(height: 10),
              _formatInfoRow(Icons.table_chart_outlined, 'Excel',
                  'Native Excel workbook (.xlsx). One sheet per data category. Opens directly in Microsoft Excel.', isDark),
              const SizedBox(height: 10),
              _formatInfoRow(Icons.storage_outlined, 'Parquet',
                  'Columnar storage format. One file per data category in a ZIP. Used in Python/Pandas, R, Spark.', isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.cyan)),
          ),
        ],
      ),
    );
  }

  Widget _dataCategory(String name, String columns, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          )),
          const SizedBox(height: 2),
          Text(columns, style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            fontFamily: 'monospace',
            height: 1.4,
          )),
        ],
      ),
    );
  }

  Widget _formatInfoRow(IconData icon, String name, String description, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.cyan),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      title: Row(
        children: [
          Icon(Icons.file_download_outlined, color: AppColors.cyan, size: 24),
          const SizedBox(width: 12),
          Text(
            'Export Data',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Range',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Quick filter chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExportTimeRange.values.map((range) {
                final isSelected = _selectedRange == range;
                return ChoiceChip(
                  label: Text(
                    _getTimeRangeLabel(range),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedRange = range);
                    }
                  },
                  selectedColor: AppColors.cyan,
                  backgroundColor: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),

            // Custom date pickers
            if (_selectedRange == ExportTimeRange.custom) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DatePickerButton(
                      label: 'Start',
                      date: _customStartDate,
                      onTap: () => _selectDate(context, true),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DatePickerButton(
                      label: 'End',
                      date: _customEndDate,
                      onTap: () => _selectDate(context, false),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Export format selector
            Row(
              children: [
                Text(
                  'Export Format',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showFormatInfo(context),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Format selection chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_zip_outlined,
                        size: 16,
                        color: _selectedFormat == ExportFormat.csvZip
                            ? Colors.white
                            : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'CSV/ZIP',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedFormat == ExportFormat.csvZip
                              ? Colors.white
                              : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  selected: _selectedFormat == ExportFormat.csvZip,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFormat = ExportFormat.csvZip);
                    }
                  },
                  selectedColor: AppColors.cyan,
                  backgroundColor: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide.none,
                ),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: _selectedFormat == ExportFormat.plainText
                            ? Colors.white
                            : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Plain Text',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedFormat == ExportFormat.plainText
                              ? Colors.white
                              : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  selected: _selectedFormat == ExportFormat.plainText,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFormat = ExportFormat.plainText);
                    }
                  },
                  selectedColor: AppColors.cyan,
                  backgroundColor: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide.none,
                ),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.code,
                        size: 16,
                        color: _selectedFormat == ExportFormat.json
                            ? Colors.white
                            : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'JSON',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedFormat == ExportFormat.json
                              ? Colors.white
                              : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  selected: _selectedFormat == ExportFormat.json,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFormat = ExportFormat.json);
                    }
                  },
                  selectedColor: AppColors.cyan,
                  backgroundColor: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide.none,
                ),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 16,
                        color: _selectedFormat == ExportFormat.excel
                            ? Colors.white
                            : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Excel',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedFormat == ExportFormat.excel
                              ? Colors.white
                              : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  selected: _selectedFormat == ExportFormat.excel,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFormat = ExportFormat.excel);
                    }
                  },
                  selectedColor: AppColors.cyan,
                  backgroundColor: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide.none,
                ),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storage_outlined,
                        size: 16,
                        color: _selectedFormat == ExportFormat.parquet
                            ? Colors.white
                            : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Parquet',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedFormat == ExportFormat.parquet
                              ? Colors.white
                              : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  selected: _selectedFormat == ExportFormat.parquet,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFormat = ExportFormat.parquet);
                    }
                  },
                  selectedColor: AppColors.cyan,
                  backgroundColor: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'Data to export:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DialogBulletPoint(
              text: 'Workout history and progress',
              color: AppColors.cyan,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'Personal records',
              color: AppColors.cyan,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'Body measurements',
              color: AppColors.cyan,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'Profile settings (always included)',
              color: AppColors.cyan,
              isDark: isDark,
            ),

            const SizedBox(height: 12),
            Text(
              _selectedFormat == ExportFormat.csvZip
                  ? 'Your data will be exported as a ZIP file containing CSV files.'
                  : _selectedFormat == ExportFormat.plainText
                      ? 'Your data will be exported as a readable plain text file.'
                      : _selectedFormat == ExportFormat.json
                          ? 'Your data will be exported as a JSON file.'
                          : _selectedFormat == ExportFormat.excel
                              ? 'Your data will be exported as an Excel workbook (.xlsx).'
                              : 'Your data will be exported as a Parquet file in a ZIP archive.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            final (startDate, endDate) = _getDateRange();
            widget.onExport(startDate, endDate, _selectedFormat);
          },
          child: Text(
            'Export',
            style: TextStyle(color: AppColors.cyan),
          ),
        ),
      ],
    );
  }
}
