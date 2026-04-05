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

part 'export_dialog_part_export_data_dialog.dart';


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
