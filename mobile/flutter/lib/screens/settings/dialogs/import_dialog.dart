import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../widgets/widgets.dart';

/// Shows the import data dialog.
void showImportDialog(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      title: Row(
        children: [
          Icon(Icons.file_upload_outlined, color: AppColors.purple, size: 24),
          const SizedBox(width: 12),
          Text(
            'Import Data',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will replace your current data',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a previously exported ZIP file to restore your data. The import will use whatever data is available in the file.',
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
        ],
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
          onPressed: () async {
            Navigator.pop(context);
            await _importData(context, ref);
          },
          child: Text(
            'Select File',
            style: TextStyle(color: AppColors.purple),
          ),
        ),
      ],
    ),
  );
}

Future<void> _importData(BuildContext context, WidgetRef ref) async {
  try {
    // Pick ZIP file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return; // User cancelled
    }

    final file = result.files.first;
    if (file.bytes == null) {
      throw Exception('Could not read file');
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
          title: Row(
            children: [
              Icon(Icons.file_upload_outlined, color: AppColors.purple, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Import Data',
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: ${file.name}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                ),
              ),
              Text(
                'Size: ${(file.size / 1024).toStringAsFixed(1)} KB',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will import:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DialogBulletPoint(
                text: 'Workouts & exercise plans',
                color: AppColors.purple,
                isDark: isDark,
              ),
              DialogBulletPoint(
                text: 'Performance history (weights, reps)',
                color: AppColors.purple,
                isDark: isDark,
              ),
              DialogBulletPoint(
                text: 'Personal records',
                color: AppColors.purple,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              Text(
                'New data will be added alongside your existing data.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Import',
                style: TextStyle(color: AppColors.purple),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.purple),
        ),
      );
    }

    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();

    if (userId == null) {
      throw Exception('User not found');
    }

    // Create multipart form data
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      ),
    });

    // Call backend to import user data
    final response = await apiClient.dio.post(
      '${ApiConstants.users}/$userId/import',
      data: formData,
    );

    // Close loading dialog
    if (context.mounted) Navigator.pop(context);

    if (response.statusCode == 200 && response.data != null) {
      final imported = response.data['imported'] as Map<String, dynamic>?;
      final summary =
          imported?.entries.where((e) => (e.value as int) > 0).map((e) => '${e.key}: ${e.value}').join('\n') ??
              'Data imported';

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Import Successful',
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Imported:\n$summary',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: TextStyle(color: AppColors.success),
                  ),
                ),
              ],
            );
          },
        );
      }
    } else {
      throw Exception('Failed to import data');
    }
  } catch (e) {
    // Close any open dialogs
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
