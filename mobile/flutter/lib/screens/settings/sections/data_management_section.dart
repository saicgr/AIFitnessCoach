import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/subscription_provider.dart';
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
          ],
        ),
      ],
    );
  }

  void _navigateToSubscriptionHistory(BuildContext context) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => const SubscriptionHistoryScreen(),
      ),
    );
  }

  void _navigateToRequestRefund(BuildContext context) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => const RequestRefundScreen(),
      ),
    );
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
      case SubscriptionTier.premiumPlus:
        price = '\$79.99/year';
        tierName = 'Premium Plus';
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
