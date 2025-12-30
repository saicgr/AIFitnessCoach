import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/services/api_client.dart';
import '../../nutrition/nutrition_onboarding/nutrition_onboarding_screen.dart';
import '../dialogs/export_dialog.dart';
import '../dialogs/import_dialog.dart';
import '../widgets/widgets.dart';

/// The data management section for import/export functionality.
class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionState = ref.watch(nutritionPreferencesProvider);
    final hasCompletedNutritionOnboarding = nutritionState.onboardingCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'DATA MANAGEMENT'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.file_download_outlined,
              title: 'Export Data',
              subtitle: 'Download your workout data',
              onTap: () => showExportDialog(context, ref),
            ),
            SettingItemData(
              icon: Icons.file_upload_outlined,
              title: 'Import Data',
              subtitle: 'Restore from backup',
              onTap: () => showImportDialog(context, ref),
            ),
            if (hasCompletedNutritionOnboarding)
              SettingItemData(
                icon: Icons.restaurant_menu_outlined,
                title: 'Redo Nutrition Setup',
                subtitle: 'Update your diet preferences',
                onTap: () => _showRedoNutritionDialog(context, ref),
              ),
          ],
        ),
      ],
    );
  }

  void _showRedoNutritionDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Row(
          children: [
            Icon(
              Icons.restaurant_menu,
              color: isDark ? AppColors.green : AppColorsLight.success,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Redo Nutrition Setup?',
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
              'This will let you update your:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            DialogBulletPoint(
              text: 'Nutrition goals',
              color: isDark ? AppColors.green : AppColorsLight.success,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'Diet type preferences',
              color: isDark ? AppColors.green : AppColorsLight.success,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'Meal patterns',
              color: isDark ? AppColors.green : AppColorsLight.success,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'Allergies & restrictions',
              color: isDark ? AppColors.green : AppColorsLight.success,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Text(
              'Your logged meals and nutrition history will be preserved.',
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
            onPressed: () {
              Navigator.pop(context);
              _startNutritionOnboarding(context, ref);
            },
            child: Text(
              'Continue',
              style: TextStyle(
                color: isDark ? AppColors.green : AppColorsLight.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startNutritionOnboarding(BuildContext context, WidgetRef ref) async {
    // Reset nutrition onboarding completed flag on backend
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        // Call backend to reset nutrition onboarding
        await apiClient.dio.post(
          '/api/v1/nutrition/$userId/reset-onboarding',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [Settings] Could not reset nutrition onboarding on backend: $e');
      // Continue anyway - user can still redo onboarding
    }

    if (!context.mounted) return;

    // Navigate to nutrition onboarding
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NutritionOnboardingScreen(
          onComplete: () {
            Navigator.of(context).pop(true);
          },
          onSkip: () {
            Navigator.of(context).pop(false);
          },
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nutrition preferences updated!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
