import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/billing_reminder_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

/// A banner that shows when the user's subscription is renewing soon (within 5 days)
class RenewalReminderBanner extends ConsumerWidget {
  const RenewalReminderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renewalState = ref.watch(upcomingRenewalProvider);

    return renewalState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (renewal) {
        if (!renewal.showBanner) {
          return const SizedBox.shrink();
        }

        return _RenewalBannerContent(renewal: renewal);
      },
    );
  }
}

class _RenewalBannerContent extends ConsumerStatefulWidget {
  final UpcomingRenewal renewal;

  const _RenewalBannerContent({required this.renewal});

  @override
  ConsumerState<_RenewalBannerContent> createState() => _RenewalBannerContentState();
}

class _RenewalBannerContentState extends ConsumerState<_RenewalBannerContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismissBanner() async {
    if (_isDismissing) return;

    setState(() => _isDismissing = true);
    HapticService.light();

    // Animate out
    await _controller.reverse();

    // Dismiss on server
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      ref.read(dismissRenewalBannerProvider(userId));
    }

    // Invalidate to refresh
    ref.invalidate(upcomingRenewalProvider);
  }

  void _navigateToSubscription() {
    HapticService.light();
    context.push('/settings/subscription');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final renewal = widget.renewal;

    // Calculate urgency color based on days remaining
    Color bannerColor;
    Color iconColor;
    IconData icon;

    if (renewal.daysUntilRenewal != null && renewal.daysUntilRenewal! <= 1) {
      // Tomorrow or today - urgent
      bannerColor = AppColors.error.withValues(alpha: 0.15);
      iconColor = AppColors.error;
      icon = Icons.warning_amber_rounded;
    } else if (renewal.daysUntilRenewal != null && renewal.daysUntilRenewal! <= 3) {
      // Within 3 days - warning
      bannerColor = AppColors.orange.withValues(alpha: 0.15);
      iconColor = AppColors.orange;
      icon = Icons.schedule;
    } else {
      // 4-5 days - informational
      bannerColor = isDark
          ? AppColors.cyan.withValues(alpha: 0.15)
          : AppColorsLight.elevated;
      iconColor = AppColors.cyan;
      icon = Icons.info_outline;
    }

    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Build message
    String message;
    if (renewal.daysUntilRenewal == 0) {
      message = 'Your ${renewal.tierDisplayName} subscription renews today';
    } else if (renewal.daysUntilRenewal == 1) {
      message = 'Your ${renewal.tierDisplayName} subscription renews tomorrow';
    } else {
      message = 'Your ${renewal.tierDisplayName} subscription renews in ${renewal.daysUntilRenewal} days';
    }

    if (renewal.formattedAmount.isNotEmpty) {
      message += ' for ${renewal.formattedAmount}';
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigateToSubscription,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Renews on ${renewal.formattedRenewalDate}',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Manage button
                        TextButton(
                          onPressed: _navigateToSubscription,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: iconColor.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Manage',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Dismiss button
                        GestureDetector(
                          onTap: _isDismissing ? null : _dismissBanner,
                          child: Opacity(
                            opacity: _isDismissing ? 0.5 : 1.0,
                            child: Text(
                              'Dismiss',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
