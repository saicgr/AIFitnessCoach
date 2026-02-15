import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../data/services/api_client.dart';
import 'cancel_confirmation_sheet.dart';
import 'pause_subscription_sheet.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/glass_sheet.dart';

/// Subscription Management Screen
/// Shows current subscription status with cancel, pause, and resume options
class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  ConsumerState<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends ConsumerState<SubscriptionManagementScreen> {
  bool _isLoading = true;
  String? _error;
  CurrentSubscription? _subscription;
  UpcomingRenewal? _upcomingRenewal;
  bool _isPaused = false;
  DateTime? _pausedUntil;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionDetails();
  }

  Future<void> _loadSubscriptionDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        final repository = ref.read(subscriptionRepositoryProvider);
        final subscription = await repository.getCurrentSubscription(userId);
        final upcomingRenewal = await repository.getUpcomingRenewal(userId);

        // Check if subscription is paused
        final subscriptionState = ref.read(subscriptionProvider);
        final isPaused = subscriptionState.tier != SubscriptionTier.free &&
            upcomingRenewal != null &&
            !upcomingRenewal.isAutoRenew;

        if (mounted) {
          setState(() {
            _subscription = subscription;
            _upcomingRenewal = upcomingRenewal;
            _isPaused = isPaused;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'User not authenticated';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showCancelConfirmation() {
    HapticFeedback.mediumImpact();
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: CancelConfirmationSheet(
          planName: _subscription?.planName ?? 'Premium',
          onCancelConfirmed: _handleCancelConfirmed,
          onPauseInstead: _showPauseSheet,
        ),
      ),
    );
  }

  void _showPauseSheet() {
    HapticFeedback.lightImpact();
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: PauseSubscriptionSheet(
          planName: _subscription?.planName ?? 'Premium',
          onPauseConfirmed: _handlePauseConfirmed,
        ),
      ),
    );
  }

  Future<void> _handleCancelConfirmed(String reason) async {
    // Redirect to App Store / Play Store subscription management
    await _openStoreSubscriptions();
  }

  Future<void> _handlePauseConfirmed(int durationDays) async {
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.post(
          '/subscriptions/$userId/pause',
          data: {'duration_days': durationDays},
        );

        if (mounted) {
          Navigator.pop(context); // Close the sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Subscription paused for $durationDays days'),
              backgroundColor: AppColors.cyan,
            ),
          );
          await _loadSubscriptionDetails();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pause subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleResume() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.post('/subscriptions/$userId/resume');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription resumed successfully'),
              backgroundColor: AppColors.green,
            ),
          );
          await _loadSubscriptionDetails();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resume subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openStoreSubscriptions() async {
    Uri? uri;

    if (Platform.isIOS) {
      uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else if (Platform.isAndroid) {
      uri = Uri.parse(
          'https://play.google.com/store/account/subscriptions');
    }

    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open subscription settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final subscriptionState = ref.watch(subscriptionProvider);
    final isLifetime = subscriptionState.tier == SubscriptionTier.lifetime;
    final isFree = subscriptionState.tier == SubscriptionTier.free;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Manage Subscription',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cyan))
          : _error != null
              ? _buildErrorState(isDark, textPrimary)
              : RefreshIndicator(
                  onRefresh: _loadSubscriptionDetails,
                  color: AppColors.cyan,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current plan card
                        _buildCurrentPlanCard(
                          isDark,
                          textPrimary,
                          textSecondary,
                          textMuted,
                          cardColor,
                          cardBorder,
                          subscriptionState,
                          isLifetime,
                        ),

                        const SizedBox(height: 24),

                        // Billing info (if not lifetime)
                        if (!isLifetime && !isFree) ...[
                          _buildBillingCard(
                            isDark,
                            textPrimary,
                            textSecondary,
                            textMuted,
                            cardColor,
                            cardBorder,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Quick links
                        _buildQuickLinksSection(
                          isDark,
                          textPrimary,
                          textSecondary,
                          textMuted,
                          cardColor,
                          cardBorder,
                        ),

                        const SizedBox(height: 24),

                        // Management actions (if not lifetime or free)
                        if (!isLifetime && !isFree)
                          _buildManagementActions(
                            isDark,
                            textPrimary,
                            textSecondary,
                            textMuted,
                            cardColor,
                            cardBorder,
                          ),

                        // Upgrade prompt for free users
                        if (isFree) _buildUpgradePrompt(isDark, textPrimary),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState(bool isDark, Color textPrimary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load subscription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSubscriptionDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
    SubscriptionState subscriptionState,
    bool isLifetime,
  ) {
    final tier = subscriptionState.tier;
    final tierDisplayName = _getTierDisplayName(tier);
    final tierColor = _getTierColor(tier);
    final isTrialing = subscriptionState.isTrialActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withValues(alpha: 0.15),
            tierColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tierColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTierIcon(tier),
                  color: tierColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tierDisplayName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (isLifetime) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.all_inclusive,
                                  size: 12,
                                  color: AppColors.purple,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'LIFETIME',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isTrialing)
                      _buildTrialBadge(subscriptionState.trialEndDate)
                    else if (_isPaused)
                      _buildPausedBadge()
                    else
                      Text(
                        isLifetime
                            ? 'Access never expires'
                            : 'Active subscription',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (subscriptionState.subscriptionEndDate != null && !isLifetime) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    _isPaused
                        ? 'Paused until: ${DateFormat('MMM d, yyyy').format(subscriptionState.subscriptionEndDate!)}'
                        : 'Renews: ${DateFormat('MMM d, yyyy').format(subscriptionState.subscriptionEndDate!)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrialBadge(DateTime? trialEndDate) {
    final daysLeft = trialEndDate != null
        ? trialEndDate.difference(DateTime.now()).inDays
        : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 14, color: AppColors.orange),
          const SizedBox(width: 4),
          Text(
            '$daysLeft days left in trial',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_circle, size: 14, color: Colors.amber.shade700),
          const SizedBox(width: 4),
          Text(
            'Subscription Paused',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
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
          Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.cyan, size: 20),
              const SizedBox(width: 10),
              Text(
                'Billing Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingRenewal != null) ...[
            _buildBillingRow(
              'Next billing date',
              DateFormat('MMM d, yyyy').format(_upcomingRenewal!.renewalDate),
              textSecondary,
              textPrimary,
            ),
            const SizedBox(height: 12),
            _buildBillingRow(
              'Amount',
              '\$${_upcomingRenewal!.amount.toStringAsFixed(2)} ${_upcomingRenewal!.currency}',
              textSecondary,
              textPrimary,
            ),
            const SizedBox(height: 12),
            _buildBillingRow(
              'Auto-renew',
              _upcomingRenewal!.isAutoRenew ? 'Enabled' : 'Disabled',
              textSecondary,
              _upcomingRenewal!.isAutoRenew ? AppColors.green : Colors.orange,
            ),
          ] else
            Text(
              'No billing information available',
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildBillingRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: labelColor),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinksSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          _buildQuickLinkTile(
            icon: Icons.history,
            title: 'Subscription History',
            subtitle: 'View all past transactions',
            onTap: () => context.push('/subscription-history'),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            showDivider: true,
            cardBorder: cardBorder,
          ),
          _buildQuickLinkTile(
            icon: Icons.money_off,
            title: 'Request Refund',
            subtitle: 'Submit a refund request',
            onTap: () => context.push('/request-refund'),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            showDivider: true,
            cardBorder: cardBorder,
          ),
          _buildQuickLinkTile(
            icon: Icons.restore,
            title: 'Restore Purchases',
            subtitle: 'Sync with App Store / Play Store',
            onTap: () async {
              HapticFeedback.lightImpact();
              final success =
                  await ref.read(subscriptionProvider.notifier).restorePurchases();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Purchases restored successfully'
                          : 'No purchases to restore',
                    ),
                    backgroundColor: success ? AppColors.green : Colors.orange,
                  ),
                );
              }
            },
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            showDivider: false,
            cardBorder: cardBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textSecondary,
    required bool showDivider,
    required Color cardBorder,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.cyan, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: cardBorder, indent: 60),
      ],
    );
  }

  Widget _buildManagementActions(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MANAGE SUBSCRIPTION',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              if (_isPaused)
                _buildActionTile(
                  icon: Icons.play_circle_outline,
                  title: 'Resume Subscription',
                  subtitle: 'Start billing again',
                  color: AppColors.green,
                  onTap: _handleResume,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  showDivider: true,
                  cardBorder: cardBorder,
                )
              else
                _buildActionTile(
                  icon: Icons.pause_circle_outline,
                  title: 'Pause Subscription',
                  subtitle: 'Take a break for up to 3 months',
                  color: Colors.amber.shade700,
                  onTap: _showPauseSheet,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  showDivider: true,
                  cardBorder: cardBorder,
                ),
              _buildActionTile(
                icon: Icons.cancel_outlined,
                title: 'Cancel Subscription',
                subtitle: 'Cancel auto-renewal',
                color: Colors.red.shade400,
                onTap: _showCancelConfirmation,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                showDivider: false,
                cardBorder: cardBorder,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _openStoreSubscriptions,
            child: Text(
              'Manage in ${Platform.isIOS ? 'App Store' : 'Play Store'}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.cyan,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textSecondary,
    required bool showDivider,
    required Color cardBorder,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: cardBorder, indent: 60),
      ],
    );
  }

  Widget _buildUpgradePrompt(bool isDark, Color textPrimary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.15),
            AppColors.purple.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch,
            size: 48,
            color: AppColors.cyan,
          ),
          const SizedBox(height: 16),
          Text(
            'Upgrade to Premium',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get unlimited workouts, AI coaching, and more',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/paywall-features'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Plans',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTierDisplayName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.premiumPlus:
        return 'Premium Plus';
      case SubscriptionTier.lifetime:
        return 'Lifetime';
    }
  }

  Color _getTierColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return AppColors.textMuted;
      case SubscriptionTier.premium:
        return AppColors.cyan;
      case SubscriptionTier.premiumPlus:
        return AppColors.purple;
      case SubscriptionTier.lifetime:
        return AppColors.purple;
    }
  }

  IconData _getTierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.person_outline;
      case SubscriptionTier.premium:
        return Icons.workspace_premium;
      case SubscriptionTier.premiumPlus:
        return Icons.diamond_outlined;
      case SubscriptionTier.lifetime:
        return Icons.all_inclusive;
    }
  }
}
