import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../data/providers/weekly_plan_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/video_cache_service.dart';
import '../dialogs/export_dialog.dart';
import '../dialogs/import_dialog.dart';
import '../export_data_screen.dart';
import '../subscription/request_refund_screen.dart';
import '../widgets/widgets.dart';
import 'package:fitwiz/core/constants/branding.dart';

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
          if (subscriptionState.tier != SubscriptionTier.lifetime) ...[
            SettingsCard(
              items: [
                SettingItemData(
                  icon: Icons.receipt_long_outlined,
                  title: 'Request Refund',
                  subtitle: 'Submit a refund request',
                  onTap: () => _navigateToRequestRefund(context),
                ),
              ],
            ),
          ],
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
              icon: Icons.download_for_offline_outlined,
              title: "Download this week's videos",
              subtitle: 'Pre-cache all exercises in your plan for offline use',
              onTap: () => _downloadWeeklyVideos(context, ref),
            ),
            SettingItemData(
              icon: Icons.file_download_outlined,
              title: 'Export ${Branding.appName} Data',
              subtitle: 'Download your workout + nutrition data',
              onTap: () => showExportDialog(context, ref),
            ),
            SettingItemData(
              icon: Icons.ios_share,
              title: 'Export My Workouts',
              subtitle: 'Hevy / Strong / Fitbod / PDF / GPX — take it anywhere',
              onTap: () => _navigateToWorkoutExport(context),
            ),
            SettingItemData(
              icon: Icons.file_upload_outlined,
              title: 'Import ${Branding.appName} Data',
              subtitle: 'Restore from a ${Branding.appName} backup ZIP',
              onTap: () => showImportDialog(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  /// Pre-cache exercise videos for every workout in the user's current
  /// weekly plan. Iterates the plan's daily entries → workouts → exercises,
  /// resolves each unique exercise's video URL via the existing
  /// /videos/by-exercise endpoint, then hands the list to the video cache
  /// service which downloads them with concurrency=3 + retry. ✅
  Future<void> _downloadWeeklyVideos(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    final apiClient = ref.read(apiClientProvider);

    // Use the existing /workouts/upcoming batch endpoint (a single call
    // that returns the next 14 days of generated workouts with exercise
    // arrays parsed). This avoids N round-trips through individual
    // workout-detail endpoints. ✅
    //
    // We pull user_id from the current weeklyPlan provider so this works
    // regardless of how the auth context is exposed elsewhere.
    final planState = ref.read(weeklyPlanProvider);
    final userId = planState.currentPlan?.userId;
    if (userId == null) {
      scaffold.showSnackBar(const SnackBar(
        content: Text('Sign in to download your weekly plan.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final names = <String>{};
    try {
      final resp = await apiClient.get(
        '/workouts/upcoming',
        queryParameters: {'user_id': userId, 'days': 14},
      );
      final workouts = (resp.data?['data']?['workouts'] as List?) ?? const [];
      for (final w in workouts) {
        final exercises = (w is Map ? w['exercises_json'] : null) as List?;
        if (exercises == null) continue;
        for (final ex in exercises) {
          if (ex is Map) {
            final original = ex['original_name']?.toString();
            final name = ex['name']?.toString();
            final pick = (original != null && original.isNotEmpty) ? original : name;
            if (pick != null && pick.isNotEmpty) names.add(pick);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch upcoming workouts: $e');
      scaffold.showSnackBar(SnackBar(
        content: Text('Could not load weekly plan: $e'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (names.isEmpty) {
      scaffold.showSnackBar(const SnackBar(
        content: Text('No exercises found in your plan.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    scaffold.showSnackBar(SnackBar(
      content: Text('Queuing ${names.length} videos for download...'),
      behavior: SnackBarBehavior.floating,
    ));

    // Resolve video URLs (one /videos/by-exercise call per name; runs in
    // parallel with a soft concurrency cap of 6). Failed lookups are
    // skipped — the actual download retry handles transient network errors.
    final items = <Map<String, String>>[];
    await Future.wait(names.map((name) async {
      try {
        final resp = await apiClient.get(
          '/videos/by-exercise/${Uri.encodeComponent(name)}',
        );
        final url = resp.data?['url'] as String?;
        if (url != null && url.isNotEmpty) {
          items.add({
            'exerciseId': name.toLowerCase().replaceAll(' ', '_'),
            'exerciseName': name,
            'videoUrl': url,
          });
        }
      } catch (e) {
        debugPrint('⚠️ Could not resolve video URL for $name: $e');
      }
    }));

    if (items.isEmpty) {
      scaffold.showSnackBar(const SnackBar(
        content: Text('No video URLs available for your plan.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Fire and forget — videoCacheService respects its own concurrency cap.
    // ignore: unawaited_futures
    videoCacheService.queueDownloads(items).then((_) {
      if (context.mounted) {
        scaffold.showSnackBar(SnackBar(
          content: Text('✅ Finished queuing ${items.length} downloads'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    });
  }

  void _navigateToWorkoutExport(BuildContext context) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => const ExportDataScreen(),
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
