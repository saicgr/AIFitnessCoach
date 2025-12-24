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

/// Shows the export data dialog.
void showExportDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => _ExportDataDialog(
      onExport: (startDate, endDate) async {
        Navigator.pop(context);
        await _exportData(context, ref, startDate: startDate, endDate: endDate);
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
        subject: 'AI Fitness Coach Data Export',
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
  final Future<void> Function(String? startDate, String? endDate) onExport;

  const _ExportDataDialog({required this.onExport});

  @override
  State<_ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<_ExportDataDialog> {
  ExportTimeRange _selectedRange = ExportTimeRange.allTime;
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
              'Your data will be exported as a ZIP file.',
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
            widget.onExport(startDate, endDate);
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
