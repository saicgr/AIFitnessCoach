import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/onboarding_repository.dart';
import '../../../data/services/api_client.dart';
import '../widgets/widgets.dart';

/// The danger zone section containing destructive actions.
class DangerZoneSection extends ConsumerWidget {
  const DangerZoneSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'DANGER ZONE'),
        const SizedBox(height: 12),
        DangerZoneCard(
          items: [
            DangerItemData(
              icon: Icons.refresh,
              title: 'Reset Program',
              subtitle: 'Delete workouts, keep account',
              onTap: () => _showResetProgramDialog(context, ref),
            ),
            DangerItemData(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently delete all data',
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),
          ],
        ),
      ],
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
            DialogBulletPoint(
              text: 'Delete all your current workouts',
              color: AppColors.error,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'Take you through onboarding again',
              color: AppColors.orange,
              isDark: isDark,
            ),
            DialogBulletPoint(
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
            DialogBulletPoint(
              text: 'Your account and profile',
              color: AppColors.error,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'All workout history',
              color: AppColors.error,
              isDark: isDark,
            ),
            DialogBulletPoint(
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
        '/users/$userId/reset-onboarding',
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        // Reset onboarding state (clear in-memory conversation)
        ref.read(onboardingStateProvider.notifier).reset();

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
    // Store navigator and scaffold messenger before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not found');
      }

      debugPrint('[Settings] Deleting account for user: $userId');

      // Call backend to fully delete user account
      final response = await apiClient.delete(
        '${ApiConstants.users}/$userId/reset',
      );

      debugPrint('[Settings] Delete response: ${response.statusCode}');

      // Close loading dialog
      navigator.pop();

      if (response.statusCode == 200) {
        debugPrint('[Settings] Account deleted successfully, clearing local data...');

        // Clear all local storage (SharedPreferences)
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        debugPrint('[Settings] Local storage cleared');

        // Reset onboarding state (clear in-memory conversation)
        ref.read(onboardingStateProvider.notifier).reset();
        debugPrint('[Settings] Onboarding state reset');

        // Sign out
        await ref.read(authStateProvider.notifier).signOut();
        debugPrint('[Settings] Signed out, navigating to stats welcome...');

        // Navigate to stats welcome (primary entry point for new users)
        router.go('/stats-welcome');
      } else {
        throw Exception('Failed to delete account: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Settings] Delete account error: $e');
      // Close loading dialog if still showing
      try {
        navigator.pop();
      } catch (_) {
        // Dialog may already be closed
      }

      // Show error
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
