import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/onboarding_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/delete_account_flow.dart';
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
              onTap: () => showDeleteAccountFlow(context, ref),
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
      // Use authStateProvider for consistent auth state (not apiClientProvider.getUserId())
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null || userId.isEmpty) {
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

        // Navigate to pre-auth quiz
        if (context.mounted) {
          context.go('/pre-auth-quiz');
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

}
