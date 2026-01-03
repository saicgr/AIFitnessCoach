import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/providers/calibration_provider.dart';
import '../settings/subscription/subscription_history_screen.dart';

/// Paywall/Membership Screen
/// Shows current plan status and upgrade/downgrade options
/// Now includes "Preview Your Plan" to show users their personalized workout plan before subscribing
class PaywallPricingScreen extends ConsumerStatefulWidget {
  /// If true, shows the "See Your Plan First" banner prominently
  final bool showPlanPreview;

  const PaywallPricingScreen({super.key, this.showPlanPreview = true});

  @override
  ConsumerState<PaywallPricingScreen> createState() => _PaywallPricingScreenState();
}

class _PaywallPricingScreenState extends ConsumerState<PaywallPricingScreen> {
  String _selectedPlan = 'premium_plus_yearly';
  String _selectedBillingCycle = 'yearly'; // 'yearly', 'monthly', or 'lifetime'
  bool _hasShownDiscount = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subscriptionState = ref.watch(subscriptionProvider);
    final currentTier = subscriptionState.tier;
    final isSubscribed = currentTier != SubscriptionTier.free;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Header - Fixed at top
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Row(
                        children: [
                          Icon(Icons.chevron_left, color: colors.cyan, size: 28),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: colors.cyan,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isSubscribed)
                      GestureDetector(
                        onTap: () => _skipToFree(context, ref),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: colors.textSecondary, size: 22),
                        ),
                      ),
                  ],
                ),
              ),

              // Scrollable content - CLEAN, PAYMENT FIRST DESIGN
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Show current plan status if subscribed
                      if (isSubscribed) ...[
                        _CurrentPlanCard(
                          tier: currentTier,
                          isTrialActive: subscriptionState.isTrialActive,
                          trialEndDate: subscriptionState.trialEndDate,
                          subscriptionEndDate: subscriptionState.subscriptionEndDate,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Simple title
                      if (!isSubscribed) ...[
                        Text(
                          'Start your fitness journey',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '7-day free trial',
                              style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.cancel_outlined, color: colors.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Cancel anytime',
                              style: TextStyle(fontSize: 14, color: colors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        Text(
                          'Change Plan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Billing cycle tabs (Yearly / Monthly / Lifetime)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _BillingTab(
                              label: 'Yearly',
                              sublabel: 'Best value',
                              isSelected: _selectedBillingCycle == 'yearly',
                              onTap: () => setState(() {
                                _selectedBillingCycle = 'yearly';
                                _selectedPlan = 'premium_plus_yearly';
                              }),
                              colors: colors,
                            ),
                            _BillingTab(
                              label: 'Monthly',
                              sublabel: 'Flexible',
                              isSelected: _selectedBillingCycle == 'monthly',
                              onTap: () => setState(() {
                                _selectedBillingCycle = 'monthly';
                                _selectedPlan = 'premium_plus_monthly';
                              }),
                              colors: colors,
                            ),
                            if (currentTier != SubscriptionTier.lifetime)
                              _BillingTab(
                                label: 'Lifetime',
                                sublabel: 'One-time',
                                isSelected: _selectedBillingCycle == 'lifetime',
                                onTap: () => setState(() {
                                  _selectedBillingCycle = 'lifetime';
                                  _selectedPlan = 'lifetime';
                                }),
                                colors: colors,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Plan options based on selected billing cycle
                      if (_selectedBillingCycle == 'lifetime')
                        _LifetimePlanCard(
                          isSelected: _selectedPlan == 'lifetime',
                          onTap: () => setState(() => _selectedPlan = 'lifetime'),
                          colors: colors,
                        )
                      else
                        Column(
                          children: [
                            // Premium Plus plan (with rainbow border if yearly)
                            if (_selectedBillingCycle == 'yearly')
                              _RainbowBorderCard(
                                isSelected: _selectedPlan == 'premium_plus_yearly',
                                child: _TierPlanCard(
                                  planId: 'premium_plus_yearly',
                                  tierName: 'Premium Plus',
                                  badge: 'BEST VALUE',
                                  badgeColor: const Color(0xFF00D9FF),
                                  accentColor: const Color(0xFF00D9FF),
                                  price: '\$6.67',
                                  period: '/mo',
                                  billedAs: '\$79.99/year',
                                  features: const [
                                    '∞ Unlimited workouts',
                                    '📸 Food photo scanning',
                                    '🍎 Full nutrition tracking',
                                    '📊 Advanced analytics',
                                  ],
                                  isSelected: _selectedPlan == 'premium_plus_yearly',
                                  onTap: () => setState(() => _selectedPlan = 'premium_plus_yearly'),
                                  colors: colors,
                                ),
                              )
                            else
                              _TierPlanCard(
                                planId: 'premium_plus_monthly',
                                tierName: 'Premium Plus',
                                badge: 'MOST POPULAR',
                                badgeColor: const Color(0xFFAA66FF),
                                accentColor: const Color(0xFFAA66FF),
                                price: '\$9.99',
                                period: '/mo',
                                billedAs: 'Billed monthly',
                                features: const [
                                  '∞ Unlimited workouts',
                                  '📸 Food photo scanning',
                                  '🍎 Full nutrition tracking',
                                  '📊 Advanced analytics',
                                ],
                                isSelected: _selectedPlan == 'premium_plus_monthly',
                                onTap: () => setState(() => _selectedPlan = 'premium_plus_monthly'),
                                colors: colors,
                              ),

                            const SizedBox(height: 10),

                            // Premium plan
                            _TierPlanCard(
                              planId: _selectedBillingCycle == 'yearly' ? 'premium_yearly' : 'premium_monthly',
                              tierName: 'Premium',
                              badge: _selectedBillingCycle == 'yearly' ? 'SAVE 33%' : '',
                              badgeColor: const Color(0xFF00CC66),
                              accentColor: const Color(0xFF00CC66),
                              price: _selectedBillingCycle == 'yearly' ? '\$4.00' : '\$5.99',
                              period: '/mo',
                              billedAs: _selectedBillingCycle == 'yearly' ? '\$47.99/year' : 'Billed monthly',
                              features: const [
                                'Daily workouts',
                                '5 food scans/day',
                                'Full macro tracking',
                              ],
                              isSelected: _selectedPlan == (_selectedBillingCycle == 'yearly' ? 'premium_yearly' : 'premium_monthly'),
                              onTap: () => setState(() => _selectedPlan = _selectedBillingCycle == 'yearly' ? 'premium_yearly' : 'premium_monthly'),
                              colors: colors,
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Main action button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: subscriptionState.isLoading
                            ? null
                            : () => _handleAction(context, ref, isSubscribed, currentTier),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getButtonColor(),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: subscriptionState.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                _getButtonText(isSubscribed, currentTier),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                        ),
                      ),

                      // Continue Free button - clear and visible
                      if (!isSubscribed) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            onPressed: () => _skipToFree(context, ref),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: colors.cardBorder),
                              ),
                            ),
                            child: Text(
                              'Continue Free',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Preview options - compact row
                      if (!isSubscribed && widget.showPlanPreview)
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/plan-preview'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: colors.cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.visibility_outlined, size: 18, color: colors.cyan),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Preview Plan',
                                        style: TextStyle(fontSize: 13, color: colors.cyan, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/demo-workout'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: colors.cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_circle_outline, size: 18, color: Colors.green),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Try Workout',
                                        style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Footer links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _restorePurchases(context, ref),
                            child: Text(
                              'Restore',
                              style: TextStyle(fontSize: 13, color: colors.cyan),
                            ),
                          ),
                          Text(' • ', style: TextStyle(color: colors.textMuted)),
                          GestureDetector(
                            onTap: () => _openTermsOfService(),
                            child: Text(
                              'Terms',
                              style: TextStyle(fontSize: 13, color: colors.textMuted),
                            ),
                          ),
                          Text(' • ', style: TextStyle(color: colors.textMuted)),
                          GestureDetector(
                            onTap: () => _openPrivacyPolicy(),
                            child: Text(
                              'Privacy',
                              style: TextStyle(fontSize: 13, color: colors.textMuted),
                            ),
                          ),
                          if (isSubscribed) ...[
                            Text(' • ', style: TextStyle(color: colors.textMuted)),
                            GestureDetector(
                              onTap: () => _navigateToSubscriptionHistory(context),
                              child: Text(
                                'History',
                                style: TextStyle(fontSize: 13, color: colors.cyan),
                              ),
                            ),
                          ],
                          if (isSubscribed && currentTier != SubscriptionTier.lifetime) ...[
                            Text(' • ', style: TextStyle(color: colors.textMuted)),
                            GestureDetector(
                              onTap: () => _openSubscriptionSettings(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(fontSize: 13, color: Colors.red.shade400),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getButtonColor() {
    switch (_selectedPlan) {
      case 'premium_plus_yearly':
        return const Color(0xFF00D9FF); // Cyan
      case 'premium_plus_monthly':
        return const Color(0xFFAA66FF); // Purple
      case 'premium_yearly':
        return const Color(0xFF00CC66); // Green
      case 'premium_monthly':
        return const Color(0xFFFF8C42); // Orange
      case 'lifetime':
        return const Color(0xFFFFB800); // Gold
      default:
        return const Color(0xFF00D9FF);
    }
  }

  String _getButtonText(bool isSubscribed, SubscriptionTier currentTier) {
    if (!isSubscribed) {
      return _selectedPlan.contains('yearly') ? 'Start Free Trial' : 'Subscribe Now';
    }
    if (_selectedPlan == 'lifetime') return 'Get Lifetime';
    return 'Change Plan';
  }

  void _skipToFree(BuildContext context, WidgetRef ref) async {
    // Show discount popup the first time user tries to leave
    if (!_hasShownDiscount) {
      _hasShownDiscount = true;
      final accepted = await _showDiscountPopup(context);
      if (accepted == true) {
        // User accepted the discount - purchase lifetime at discounted price
        final success = await ref.read(subscriptionProvider.notifier).purchase('lifetime_discount');
        if (success && context.mounted) {
          await _markPaywallComplete(ref);
          await _navigateAfterPaywall(context, ref);
        }
        return;
      }
      // If user declined, let them go
    }

    await ref.read(subscriptionProvider.notifier).skipToFree();
    await _markPaywallComplete(ref);
    if (context.mounted) {
      await _navigateAfterPaywall(context, ref);
    }
  }

  Future<void> _markPaywallComplete(WidgetRef ref) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'paywall_completed': true},
        );
      }
      ref.read(authStateProvider.notifier).markPaywallComplete();
    } catch (e) {
      debugPrint('❌ [Paywall] Failed to update paywall_completed flag: $e');
    }
  }

  /// Navigate to calibration intro if user hasn't completed/skipped calibration, otherwise go home
  Future<void> _navigateAfterPaywall(BuildContext context, WidgetRef ref) async {
    try {
      // Check calibration status
      await ref.read(calibrationStatusProvider.notifier).refreshStatus();
      final calibrationStatus = ref.read(calibrationStatusProvider);

      if (context.mounted) {
        // If calibration not completed and not skipped, offer calibration
        // For new users, status will be null - they should see calibration
        final status = calibrationStatus.status;
        final isCompleted = status?.isCompleted ?? false;
        final isSkipped = status?.isSkipped ?? false;

        if (!isCompleted && !isSkipped) {
          debugPrint('🎯 [Paywall] Navigating to calibration (status: ${status == null ? "null" : "exists"}, completed: $isCompleted, skipped: $isSkipped)');
          context.go('/calibration/intro', extra: {'fromOnboarding': true});
        } else {
          debugPrint('🏠 [Paywall] Navigating to home (completed: $isCompleted, skipped: $isSkipped)');
          context.go('/home');
        }
      }
    } catch (e) {
      debugPrint('❌ [Paywall] Error checking calibration status: $e');
      // On error, just go home
      if (context.mounted) {
        context.go('/home');
      }
    }
  }

  Future<bool?> _showDiscountPopup(BuildContext context) {
    final colors = context.colors;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DiscountPopup(colors: colors),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, bool isSubscribed, SubscriptionTier currentTier) async {
    // If user is already subscribed, show plan change confirmation dialog
    if (isSubscribed && currentTier != SubscriptionTier.free) {
      final confirmed = await _showPlanChangeConfirmation(context, currentTier);
      if (confirmed != true) return;
    }

    final success = await ref.read(subscriptionProvider.notifier).purchase(_selectedPlan);
    if (success && context.mounted) {
      if (isSubscribed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Already subscribed users go directly home (no calibration prompt)
        context.go('/home');
      } else {
        // New subscribers go through calibration flow
        await _markPaywallComplete(ref);
        await _navigateAfterPaywall(context, ref);
      }
    }
  }

  /// Get plan details by plan ID
  Map<String, dynamic> _getPlanDetails(String planId) {
    switch (planId) {
      case 'premium_plus_yearly':
        return {
          'name': 'Premium Plus Yearly',
          'price': 79.99,
          'period': 'year',
          'monthlyPrice': 6.67,
        };
      case 'premium_plus_monthly':
        return {
          'name': 'Premium Plus Monthly',
          'price': 9.99,
          'period': 'month',
          'monthlyPrice': 9.99,
        };
      case 'premium_yearly':
        return {
          'name': 'Premium Yearly',
          'price': 47.99,
          'period': 'year',
          'monthlyPrice': 4.00,
        };
      case 'premium_monthly':
        return {
          'name': 'Premium Monthly',
          'price': 5.99,
          'period': 'month',
          'monthlyPrice': 5.99,
        };
      case 'lifetime':
        return {
          'name': 'Lifetime',
          'price': 99.99,
          'period': 'one-time',
          'monthlyPrice': 0.0,
        };
      default:
        return {
          'name': 'Unknown',
          'price': 0.0,
          'period': 'unknown',
          'monthlyPrice': 0.0,
        };
    }
  }

  /// Get current plan ID from tier
  String _getCurrentPlanId(SubscriptionTier tier, SubscriptionState state) {
    // Estimate based on tier - in real app this would come from backend
    switch (tier) {
      case SubscriptionTier.premiumPlus:
        return state.subscriptionEndDate != null &&
                state.subscriptionEndDate!.difference(DateTime.now()).inDays > 60
            ? 'premium_plus_yearly'
            : 'premium_plus_monthly';
      case SubscriptionTier.premium:
        return state.subscriptionEndDate != null &&
                state.subscriptionEndDate!.difference(DateTime.now()).inDays > 60
            ? 'premium_yearly'
            : 'premium_monthly';
      case SubscriptionTier.lifetime:
        return 'lifetime';
      default:
        return 'free';
    }
  }

  /// Show plan change confirmation dialog
  Future<bool?> _showPlanChangeConfirmation(BuildContext context, SubscriptionTier currentTier) {
    final colors = context.colors;
    final subscriptionState = ref.read(subscriptionProvider);
    final currentPlanId = _getCurrentPlanId(currentTier, subscriptionState);
    final currentPlan = _getPlanDetails(currentPlanId);
    final newPlan = _getPlanDetails(_selectedPlan);

    final priceDiff = newPlan['price'] - currentPlan['price'];
    final isUpgrade = priceDiff > 0;
    final isDowngrade = priceDiff < 0;
    final isSameTier = currentPlanId == _selectedPlan;

    if (isSameTier) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already on this plan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return Future.value(false);
    }

    // Calculate effective date (next billing cycle for downgrades, immediate for upgrades)
    final effectiveDate = isDowngrade && subscriptionState.subscriptionEndDate != null
        ? subscriptionState.subscriptionEndDate!
        : DateTime.now();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PlanChangeConfirmationDialog(
        colors: colors,
        currentPlanName: currentPlan['name'] as String,
        currentPlanPrice: currentPlan['price'] as double,
        newPlanName: newPlan['name'] as String,
        newPlanPrice: newPlan['price'] as double,
        priceDiff: priceDiff,
        isUpgrade: isUpgrade,
        effectiveDate: effectiveDate,
      ),
    );
  }

  /// Navigate to subscription history
  void _navigateToSubscriptionHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionHistoryScreen(),
      ),
    );
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(subscriptionProvider.notifier).restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Purchases restored!' : 'No purchases found'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openSubscriptionSettings() async {
    final url = Platform.isIOS
      ? 'https://apps.apple.com/account/subscriptions'
      : 'https://play.google.com/store/account/subscriptions';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTermsOfService() async {
    const url = 'https://fitwiz.app/terms';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://fitwiz.app/privacy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

}

/// Rainbow animated border for recommended plan
class _RainbowBorderCard extends StatefulWidget {
  final Widget child;
  final bool isSelected;

  const _RainbowBorderCard({
    required this.child,
    required this.isSelected,
  });

  @override
  State<_RainbowBorderCard> createState() => _RainbowBorderCardState();
}

class _RainbowBorderCardState extends State<_RainbowBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getGlowColor(_controller.value).withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _RainbowBorderPainter(
              progress: _controller.value,
              isSelected: widget.isSelected,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }

  Color _getGlowColor(double progress) {
    // Cycle through colors based on animation progress
    final colors = [
      const Color(0xFF00D9FF), // Cyan
      const Color(0xFF00FF88), // Green
      const Color(0xFFFFB800), // Gold
      const Color(0xFFFF6B6B), // Coral
      const Color(0xFFAA66FF), // Purple
      const Color(0xFF00D9FF), // Back to Cyan
    ];

    final index = (progress * (colors.length - 1)).floor();
    final t = (progress * (colors.length - 1)) - index;

    return Color.lerp(colors[index], colors[(index + 1) % colors.length], t)!;
  }
}

class _RainbowBorderPainter extends CustomPainter {
  final double progress;
  final bool isSelected;

  _RainbowBorderPainter({required this.progress, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    // Rainbow gradient that rotates
    final gradient = SweepGradient(
      startAngle: progress * 2 * math.pi,
      endAngle: progress * 2 * math.pi + 2 * math.pi,
      colors: const [
        Color(0xFF00D9FF), // Cyan
        Color(0xFF00FF88), // Green
        Color(0xFFFFB800), // Gold
        Color(0xFFFF6B6B), // Coral
        Color(0xFFAA66FF), // Purple
        Color(0xFF00D9FF), // Back to Cyan
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_RainbowBorderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isSelected != isSelected;
}

/// Billing cycle tab selector
class _BillingTab extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors colors;

  const _BillingTab({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.cyan : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white.withOpacity(0.8) : colors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tier plan card with features (compact)
class _TierPlanCard extends StatelessWidget {
  final String planId;
  final String tierName;
  final String badge;
  final Color badgeColor;
  final Color accentColor;
  final String price;
  final String period;
  final String billedAs;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors colors;

  const _TierPlanCard({
    required this.planId,
    required this.tierName,
    required this.badge,
    required this.badgeColor,
    required this.accentColor,
    required this.price,
    required this.period,
    required this.billedAs,
    required this.features,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : colors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Radio + Title + Badge + Price
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? accentColor : colors.cardBorder,
                      width: 2,
                    ),
                    color: isSelected ? accentColor : Colors.transparent,
                  ),
                  child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    tierName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (badge.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      period,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            // Billed as subtitle
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 2),
              child: Text(
                billedAs,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            // Features in 2 columns - responsive width
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  // On small screens, use single column
                  final featureWidth = screenWidth < 380 ? double.infinity : 140.0;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: features.map((feature) => SizedBox(
                      width: featureWidth,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 14, color: accentColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              feature,
                              style: TextStyle(fontSize: 11, color: colors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lifetime plan card (special design)
class _LifetimePlanCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors colors;

  const _LifetimePlanCard({
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFB800); // Gold
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withOpacity(0.15),
              accentColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? accentColor : Colors.transparent,
                    border: Border.all(color: accentColor, width: 2),
                  ),
                  child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'Lifetime',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ONE-TIME',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$99.99',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                'Pay once, use forever',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                children: [
                  _featureRow('🏆 Everything in Premium Plus', colors),
                  _featureRow('♾️ Lifetime updates & features', colors),
                  _featureRow('💎 Early access to new features', colors),
                  _featureRow('🎯 No recurring charges ever', colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(String text, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(text, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
        ],
      ),
    );
  }
}

/// Current plan status card
class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionTier tier;
  final bool isTrialActive;
  final DateTime? trialEndDate;
  final DateTime? subscriptionEndDate;
  final ThemeColors colors;

  const _CurrentPlanCard({
    required this.tier,
    required this.isTrialActive,
    this.trialEndDate,
    this.subscriptionEndDate,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.cyan, colors.cyanDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            tier == SubscriptionTier.lifetime ? Icons.workspace_premium : Icons.star,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getTierName(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isTrialActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TRIAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTierName() {
    switch (tier) {
      case SubscriptionTier.premiumPlus:
        return 'Premium Plus';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.lifetime:
        return 'Lifetime';
      default:
        return 'Free';
    }
  }

  String _getStatusText() {
    if (tier == SubscriptionTier.lifetime) return 'Never expires';
    if (isTrialActive && trialEndDate != null) {
      return 'Trial ends ${DateFormat('MMM d').format(trialEndDate!)}';
    }
    if (subscriptionEndDate != null) {
      return 'Renews ${DateFormat('MMM d').format(subscriptionEndDate!)}';
    }
    return 'Active';
  }
}

/// Last-chance discount popup
class _DiscountPopup extends StatelessWidget {
  final ThemeColors colors;

  const _DiscountPopup({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB800).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: colors.textSecondary, size: 20),
                ),
              ),
            ),

            // Fire emoji and title
            const Text('🔥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Wait! Special Offer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'One-time exclusive discount just for you!',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Price comparison
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFB800).withOpacity(0.15),
                    const Color(0xFFFFB800).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'LIFETIME ACCESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFB800),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Original price crossed out
                      Text(
                        '\$99',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.red,
                          decorationThickness: 2.5,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Arrow
                      Icon(
                        Icons.arrow_forward,
                        color: const Color(0xFFFFB800),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      // Discounted price
                      Text(
                        '\$59',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFB800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SAVE \$40 (40% OFF)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Features
            Column(
              children: [
                _discountFeatureRow('✓ Unlimited AI coaching forever', colors),
                _discountFeatureRow('✓ All future updates included', colors),
                _discountFeatureRow('✓ No recurring payments', colors),
                _discountFeatureRow('✓ One-time payment only', colors),
              ],
            ),

            const SizedBox(height: 24),

            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Get Lifetime for \$59',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // No thanks link
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Text(
                'No thanks, I\'ll pass',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _discountFeatureRow(String text, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plan change confirmation dialog
class _PlanChangeConfirmationDialog extends StatelessWidget {
  final ThemeColors colors;
  final String currentPlanName;
  final double currentPlanPrice;
  final String newPlanName;
  final double newPlanPrice;
  final double priceDiff;
  final bool isUpgrade;
  final DateTime effectiveDate;

  const _PlanChangeConfirmationDialog({
    required this.colors,
    required this.currentPlanName,
    required this.currentPlanPrice,
    required this.newPlanName,
    required this.newPlanPrice,
    required this.priceDiff,
    required this.isUpgrade,
    required this.effectiveDate,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isUpgrade ? colors.cyan : Colors.orange;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUpgrade ? Icons.arrow_upward : Icons.arrow_downward,
                color: accentColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isUpgrade ? 'Confirm Upgrade' : 'Confirm Plan Change',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpgrade
                  ? 'You will be upgraded immediately'
                  : 'Changes will take effect at the end of your current billing period',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Plan comparison
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                children: [
                  // Current plan row
                  _PlanComparisonRow(
                    label: 'Current Plan',
                    planName: currentPlanName,
                    price: currentPlanPrice,
                    isHighlighted: false,
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  // Arrow
                  Icon(
                    Icons.arrow_downward,
                    color: colors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 12),
                  // New plan row
                  _PlanComparisonRow(
                    label: 'New Plan',
                    planName: newPlanName,
                    price: newPlanPrice,
                    isHighlighted: true,
                    highlightColor: accentColor,
                    colors: colors,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Price difference
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (priceDiff > 0 ? Colors.red : Colors.green).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    priceDiff > 0 ? Icons.trending_up : Icons.trending_down,
                    color: priceDiff > 0 ? Colors.red : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    priceDiff > 0
                        ? '+\$${priceDiff.abs().toStringAsFixed(2)}'
                        : '-\$${priceDiff.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: priceDiff > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    ' price difference',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Effective date
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Effective: ${DateFormat('MMM d, yyyy').format(effectiveDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        side: BorderSide(color: colors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Change',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
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

/// Plan comparison row widget
class _PlanComparisonRow extends StatelessWidget {
  final String label;
  final String planName;
  final double price;
  final bool isHighlighted;
  final Color? highlightColor;
  final ThemeColors colors;

  const _PlanComparisonRow({
    required this.label,
    required this.planName,
    required this.price,
    required this.isHighlighted,
    this.highlightColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              planName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? (highlightColor ?? colors.cyan) : colors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHighlighted
                ? (highlightColor ?? colors.cyan).withValues(alpha: 0.15)
                : colors.cardBorder.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '\$${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? (highlightColor ?? colors.cyan) : colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
