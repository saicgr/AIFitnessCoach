import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/notification_service.dart';
import 'notification_test_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Preferences section
              _SectionHeader(title: 'PREFERENCES'),
              const SizedBox(height: 12),

              _SettingsCard(
                items: [
                  _SettingItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    isThemeToggle: true,
                  ),
                ],
              ).animate().fadeIn(delay: 50.ms),

              const SizedBox(height: 24),

              // Notifications section
              _SectionHeader(title: 'NOTIFICATIONS'),
              const SizedBox(height: 12),

              _NotificationsCard().animate().fadeIn(delay: 75.ms),

              const SizedBox(height: 24),

              // Support section
              _SectionHeader(title: 'SUPPORT'),
              const SizedBox(height: 12),

              _SettingsCard(
                items: [
                  _SettingItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  _SettingItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _SettingItem(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // App Info section
              _SectionHeader(title: 'APP INFO'),
              const SizedBox(height: 12),

              _SettingsCard(
                items: [
                  _SettingItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () => _showAboutDialog(context),
                  ),
                  _SettingItem(
                    icon: Icons.star_outline,
                    title: 'Rate App',
                    onTap: () {},
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // Data Management section
              _SectionHeader(title: 'DATA MANAGEMENT'),
              const SizedBox(height: 12),

              _SettingsCard(
                items: [
                  _SettingItem(
                    icon: Icons.file_download_outlined,
                    title: 'Export Data',
                    subtitle: 'Download your workout data',
                    onTap: () => _showExportDialog(context, ref),
                  ),
                  _SettingItem(
                    icon: Icons.file_upload_outlined,
                    title: 'Import Data',
                    subtitle: 'Restore from backup',
                    onTap: () => _showImportDialog(context, ref),
                  ),
                ],
              ).animate().fadeIn(delay: 175.ms),

              const SizedBox(height: 24),

              // Danger Zone section
              _SectionHeader(title: 'DANGER ZONE'),
              const SizedBox(height: 12),

              _DangerZoneCard(
                items: [
                  _DangerItem(
                    icon: Icons.refresh,
                    title: 'Reset Program',
                    subtitle: 'Delete workouts, keep account',
                    onTap: () => _showResetProgramDialog(context, ref),
                  ),
                  _DangerItem(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete all data',
                    onTap: () => _showDeleteAccountDialog(context, ref),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context, ref),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 16),

              // Version
              Text(
                'AI Fitness Coach v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cyan, AppColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('AI Fitness Coach'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your AI-powered personal fitness coach. Get personalized workout plans, track your progress, and achieve your fitness goals.',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDark ? AppColors.cyan : AppColorsLight.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Text(
          'Sign Out?',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out? You can sign back in anytime.',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
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
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).signOut();
              context.go('/login');
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetProgramDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Row(
          children: [
            Icon(Icons.refresh, color: AppColors.orange, size: 24),
            const SizedBox(width: 12),
            Text(
              'Reset Program?',
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
            Text(
              'This will:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _DialogBulletPoint(
              text: 'Delete all your current workouts',
              color: AppColors.error,
              isDark: isDark,
            ),
            _DialogBulletPoint(
              text: 'Take you through onboarding again',
              color: AppColors.orange,
              isDark: isDark,
            ),
            _DialogBulletPoint(
              text: 'Keep your account and sign-in',
              color: AppColors.success,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Text(
              'Your completed workout history will be preserved.',
              style: TextStyle(
                fontSize: 13,
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
              await _resetProgram(context, ref);
            },
            child: const Text(
              'Reset Program',
              style: TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Text(
              'Delete Account?',
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
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will permanently delete:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _DialogBulletPoint(
              text: 'Your account and profile',
              color: AppColors.error,
              isDark: isDark,
            ),
            _DialogBulletPoint(
              text: 'All workout history',
              color: AppColors.error,
              isDark: isDark,
            ),
            _DialogBulletPoint(
              text: 'All saved preferences',
              color: AppColors.error,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Text(
              'You will need to sign up again to use the app.',
              style: TextStyle(
                fontSize: 13,
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
              await _deleteAccount(context, ref);
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetProgram(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not found');
      }

      // Call backend to reset program (keeps account, deletes workouts)
      final response = await apiClient.dio.post(
        '/api/v1/users/$userId/reset-onboarding',
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        // Navigate to onboarding
        if (context.mounted) {
          context.go('/onboarding');
        }
      } else {
        throw Exception('Failed to reset program');
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not found');
      }

      // Call backend to fully delete user account
      final response = await apiClient.delete(
        '${ApiConstants.users}/$userId/reset',
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        // Sign out and navigate to login
        await ref.read(authStateProvider.notifier).signOut();
        if (context.mounted) {
          context.go('/login');
        }
      } else {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
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

  void _showImportDialog(BuildContext context, WidgetRef ref) {
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

  Future<void> _exportData(
    BuildContext context,
    WidgetRef ref, {
    String? startDate,
    String? endDate,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading dialog with message
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
      // Use a longer timeout since export can take time for large datasets
      final response = await apiClient.dio.get(
        '${ApiConstants.users}/$userId/export$queryString',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 200 && response.data != null) {
        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().toIso8601String().split('T')[0];
        final filePath = '${tempDir.path}/fitness_data_$timestamp.zip';
        final file = File(filePath);
        await file.writeAsBytes(response.data as List<int>);

        // Share the file
        if (context.mounted) {
          await Share.shareXFiles(
            [XFile(filePath)],
            subject: 'AI Fitness Coach Data Export',
            text: 'My fitness data exported on $timestamp',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data exported successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception('Failed to export data');
      }
    } on DioException catch (e) {
      // Close loading dialog if still showing
      if (context.mounted) Navigator.pop(context);

      String errorMessage = 'Export failed';
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Export timed out. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
                _DialogBulletPoint(
                  text: 'Workouts & exercise plans',
                  color: AppColors.purple,
                  isDark: isDark,
                ),
                _DialogBulletPoint(
                  text: 'Performance history (weights, reps)',
                  color: AppColors.purple,
                  isDark: isDark,
                ),
                _DialogBulletPoint(
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
        final summary = imported?.entries
            .where((e) => (e.value as int) > 0)
            .map((e) => '${e.key}: ${e.value}')
            .join('\n') ?? 'Data imported';

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
        // Pop any open dialogs (loading indicator)
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
}

// ─────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Setting Item
// ─────────────────────────────────────────────────────────────────

class _SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isThemeToggle;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isThemeToggle = false,
  });
}

// ─────────────────────────────────────────────────────────────────
// Settings Card
// ─────────────────────────────────────────────────────────────────

class _SettingsCard extends ConsumerWidget {
  final List<_SettingItem> items;

  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : index == items.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            if (item.subtitle != null)
                              Text(
                                item.subtitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (item.isThemeToggle)
                        Switch(
                          value: isDark,
                          onChanged: (value) {
                            ref.read(themeModeProvider.notifier).toggle();
                          },
                          activeColor: AppColors.cyan,
                        )
                      else if (item.trailing != null)
                        item.trailing!
                      else if (item.onTap != null)
                        Icon(
                          Icons.chevron_right,
                          color: textMuted,
                        ),
                    ],
                  ),
                ),
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  color: cardBorder,
                  indent: 50,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Dialog Bullet Point
// ─────────────────────────────────────────────────────────────────

class _DialogBulletPoint extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _DialogBulletPoint({
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Danger Zone Card
// ─────────────────────────────────────────────────────────────────

class _DangerItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _DangerZoneCard extends StatelessWidget {
  final List<_DangerItem> items;

  const _DangerZoneCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : index == items.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  color: cardBorder,
                  indent: 68,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Notifications Card
// ─────────────────────────────────────────────────────────────────

class _NotificationsCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends ConsumerState<_NotificationsCard> {
  bool _isSendingTest = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final notifPrefs = ref.watch(notificationPreferencesProvider);

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Workout Reminders
          _buildNotificationToggle(
            icon: Icons.fitness_center,
            title: 'Workout Reminders',
            subtitle: 'Get reminded on workout days',
            value: notifPrefs.workoutReminders,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setWorkoutReminders(value);
            },
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Nutrition Reminders
          _buildNotificationToggle(
            icon: Icons.restaurant,
            title: 'Nutrition Reminders',
            subtitle: 'Log your meals',
            value: notifPrefs.nutritionReminders,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setNutritionReminders(value);
            },
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Hydration Reminders
          _buildNotificationToggle(
            icon: Icons.water_drop,
            title: 'Hydration Reminders',
            subtitle: 'Stay hydrated',
            value: notifPrefs.hydrationReminders,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setHydrationReminders(value);
            },
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // AI Coach Messages
          _buildNotificationToggle(
            icon: Icons.smart_toy,
            title: 'AI Coach Messages',
            subtitle: 'Motivation & tips from your coach',
            value: notifPrefs.aiCoachMessages,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setAiCoachMessages(value);
            },
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Streak Alerts
          _buildNotificationToggle(
            icon: Icons.local_fire_department,
            title: 'Streak Alerts',
            subtitle: 'Keep your workout streak alive',
            value: notifPrefs.streakAlerts,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setStreakAlerts(value);
            },
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Weekly Summary
          _buildNotificationToggle(
            icon: Icons.bar_chart,
            title: 'Weekly Summary',
            subtitle: 'Your progress report',
            value: notifPrefs.weeklySummary,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setWeeklySummary(value);
            },
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Test Notification Button
          InkWell(
            onTap: _isSendingTest ? null : _sendTestNotification,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    color: AppColors.cyan,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Notification',
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Send a test push notification',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isSendingTest)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cyan,
                      ),
                    )
                  else
                    Icon(
                      Icons.send,
                      color: AppColors.cyan,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // All Notification Tests Link
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationTestScreen(),
                ),
              );
            },
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: AppColors.purple,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Notification Tests',
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Test workout, nutrition, hydration & more',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textSecondary,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: textSecondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.cyan,
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isSendingTest = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      final notificationService = ref.read(notificationServiceProvider);

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // First, make sure the FCM token is registered
      await notificationService.registerTokenWithBackend(apiClient, userId);

      // Then send test notification
      final success = await notificationService.sendTestNotification(apiClient, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Test notification sent! Check your notifications.'
                  : 'Failed to send test notification',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingTest = false);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Export Data Dialog with Date Filter
// ─────────────────────────────────────────────────────────────────

enum _ExportTimeRange {
  lastMonth,
  last3Months,
  last6Months,
  lastYear,
  allTime,
  custom,
}

class _ExportDataDialog extends StatefulWidget {
  final Future<void> Function(String? startDate, String? endDate) onExport;

  const _ExportDataDialog({required this.onExport});

  @override
  State<_ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<_ExportDataDialog> {
  _ExportTimeRange _selectedRange = _ExportTimeRange.allTime;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  String _getTimeRangeLabel(_ExportTimeRange range) {
    switch (range) {
      case _ExportTimeRange.lastMonth:
        return 'Last 1 month';
      case _ExportTimeRange.last3Months:
        return 'Last 3 months';
      case _ExportTimeRange.last6Months:
        return 'Last 6 months';
      case _ExportTimeRange.lastYear:
        return 'Last year';
      case _ExportTimeRange.allTime:
        return 'All time';
      case _ExportTimeRange.custom:
        return 'Custom range';
    }
  }

  (String?, String?) _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedRange) {
      case _ExportTimeRange.lastMonth:
        final start = DateTime(today.year, today.month - 1, today.day);
        return (_formatDate(start), _formatDate(today));
      case _ExportTimeRange.last3Months:
        final start = DateTime(today.year, today.month - 3, today.day);
        return (_formatDate(start), _formatDate(today));
      case _ExportTimeRange.last6Months:
        final start = DateTime(today.year, today.month - 6, today.day);
        return (_formatDate(start), _formatDate(today));
      case _ExportTimeRange.lastYear:
        final start = DateTime(today.year - 1, today.month, today.day);
        return (_formatDate(start), _formatDate(today));
      case _ExportTimeRange.allTime:
        return (null, null);
      case _ExportTimeRange.custom:
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
          // Ensure end date is not before start date
          if (_customEndDate != null && _customEndDate!.isBefore(picked)) {
            _customEndDate = picked;
          }
        } else {
          _customEndDate = picked;
          // Ensure start date is not after end date
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
              children: _ExportTimeRange.values.map((range) {
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
            if (_selectedRange == _ExportTimeRange.custom) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerButton(
                      label: 'Start',
                      date: _customStartDate,
                      onTap: () => _selectDate(context, true),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerButton(
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
            _DialogBulletPoint(
              text: 'Workout history and progress',
              color: AppColors.cyan,
              isDark: isDark,
            ),
            _DialogBulletPoint(
              text: 'Personal records',
              color: AppColors.cyan,
              isDark: isDark,
            ),
            _DialogBulletPoint(
              text: 'Body measurements',
              color: AppColors.cyan,
              isDark: isDark,
            ),
            _DialogBulletPoint(
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

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isDark;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date != null
                        ? '${months[date!.month - 1]} ${date!.day}, ${date!.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null
                          ? (isDark ? AppColors.textPrimary : AppColorsLight.textPrimary)
                          : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
