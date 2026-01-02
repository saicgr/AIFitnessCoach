import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/services/api_client.dart';
import '../../nutrition/nutrition_onboarding/nutrition_onboarding_screen.dart';
import '../dialogs/export_dialog.dart';
import '../dialogs/import_dialog.dart';
import '../subscription/subscription_history_screen.dart';
import '../subscription/request_refund_screen.dart';
import '../widgets/widgets.dart';

/// The data management section for import/export functionality.
class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionState = ref.watch(nutritionPreferencesProvider);
    final hasCompletedNutritionOnboarding = nutritionState.onboardingCompleted;
    final subscriptionState = ref.watch(subscriptionProvider);
    final isSubscribed = subscriptionState.tier != SubscriptionTier.free;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subscription section (if subscribed)
        if (isSubscribed) ...[
          const SectionHeader(title: 'SUBSCRIPTION'),
          const SizedBox(height: 12),
          // Upcoming renewal card
          _UpcomingRenewalCard(
            subscriptionState: subscriptionState,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          SettingsCard(
            items: [
              SettingItemData(
                icon: Icons.history,
                title: 'Subscription History',
                subtitle: 'View past transactions',
                onTap: () => _navigateToSubscriptionHistory(context),
              ),
              if (subscriptionState.tier != SubscriptionTier.lifetime)
                SettingItemData(
                  icon: Icons.receipt_long_outlined,
                  title: 'Request Refund',
                  subtitle: 'Submit a refund request',
                  onTap: () => _navigateToRequestRefund(context),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        const SectionHeader(title: 'DATA MANAGEMENT'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.cloud_download_outlined,
              title: 'Downloaded Videos',
              subtitle: 'Manage offline exercise videos',
              isDownloadedVideosManager: true,
            ),
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

  void _navigateToSubscriptionHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionHistoryScreen(),
      ),
    );
  }

  void _navigateToRequestRefund(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RequestRefundScreen(),
      ),
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
          '/nutrition/$userId/reset-onboarding',
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

/// Upcoming renewal info card
class _UpcomingRenewalCard extends StatelessWidget {
  final SubscriptionState subscriptionState;
  final bool isDark;

  const _UpcomingRenewalCard({
    required this.subscriptionState,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Get renewal info based on subscription state
    final isLifetime = subscriptionState.tier == SubscriptionTier.lifetime;
    final renewalDate = subscriptionState.subscriptionEndDate;
    final isTrialActive = subscriptionState.isTrialActive;
    final trialEndDate = subscriptionState.trialEndDate;

    // Get price based on tier
    String price;
    String tierName;
    switch (subscriptionState.tier) {
      case SubscriptionTier.ultra:
        price = '\$79.99/year';
        tierName = 'Ultra';
        break;
      case SubscriptionTier.premium:
        price = '\$47.99/year';
        tierName = 'Premium';
        break;
      case SubscriptionTier.lifetime:
        price = 'Never';
        tierName = 'Lifetime';
        break;
      default:
        price = '';
        tierName = 'Free';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLifetime ? Icons.workspace_premium : Icons.autorenew,
                  color: AppColors.cyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLifetime ? 'Lifetime Access' : 'Upcoming Renewal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '$tierName Plan',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLifetime)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    price,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
            ],
          ),

          if (!isLifetime) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: textMuted,
                  ),
                  const SizedBox(width: 8),
                  if (isTrialActive && trialEndDate != null)
                    Expanded(
                      child: Text(
                        'Trial ends ${DateFormat('MMM d, yyyy').format(trialEndDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    )
                  else if (renewalDate != null)
                    Expanded(
                      child: Text(
                        'Next charge: ${DateFormat('MMM d, yyyy').format(renewalDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        'Auto-renewal active',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  'No upcoming charges - you have lifetime access',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
