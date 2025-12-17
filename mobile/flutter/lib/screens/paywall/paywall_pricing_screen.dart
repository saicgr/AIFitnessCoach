import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/subscription_provider.dart';

/// Paywall/Membership Screen
/// Shows current plan status and upgrade/downgrade options
class PaywallPricingScreen extends ConsumerStatefulWidget {
  const PaywallPricingScreen({super.key});

  @override
  ConsumerState<PaywallPricingScreen> createState() => _PaywallPricingScreenState();
}

class _PaywallPricingScreenState extends ConsumerState<PaywallPricingScreen> {
  String _selectedPlan = 'ultra_yearly';
  String _selectedBillingCycle = 'yearly'; // 'yearly', 'monthly', or 'lifetime'

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subscriptionState = ref.watch(subscriptionProvider);
    final currentTier = subscriptionState.tier;
    final isSubscribed = currentTier != SubscriptionTier.free;
    final hasTrial = _selectedBillingCycle == 'yearly';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Header
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

              // Title
              Text(
                isSubscribed ? 'Change Plan' : 'Choose Your Plan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSubscribed
                  ? 'Upgrade, downgrade, or cancel anytime'
                  : 'Unlock your full fitness potential',
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),

              const SizedBox(height: 16),

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
                      sublabel: '7-day trial',
                      isSelected: _selectedBillingCycle == 'yearly',
                      onTap: () => setState(() {
                        _selectedBillingCycle = 'yearly';
                        _selectedPlan = 'ultra_yearly';
                      }),
                      colors: colors,
                    ),
                    _BillingTab(
                      label: 'Monthly',
                      sublabel: 'Flexible',
                      isSelected: _selectedBillingCycle == 'monthly',
                      onTap: () => setState(() {
                        _selectedBillingCycle = 'monthly';
                        _selectedPlan = 'ultra_monthly';
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

              const SizedBox(height: 16),

              // Plan options based on selected billing cycle
              Expanded(
                child: _selectedBillingCycle == 'lifetime'
                  ? _LifetimePlanCard(
                      isSelected: _selectedPlan == 'lifetime',
                      onTap: () => setState(() => _selectedPlan = 'lifetime'),
                      colors: colors,
                    )
                  : Column(
                      children: [
                        // Ultra plan (with rainbow border if yearly)
                        if (_selectedBillingCycle == 'yearly')
                          _RainbowBorderCard(
                            isSelected: _selectedPlan == 'ultra_yearly',
                            child: _TierPlanCard(
                              planId: 'ultra_yearly',
                              tierName: 'Ultra',
                              badge: 'BEST VALUE',
                              badgeColor: const Color(0xFF00D9FF),
                              accentColor: const Color(0xFF00D9FF),
                              price: '\$6.67',
                              period: '/mo',
                              billedAs: '\$79.99/year',
                              features: const [
                                '∞ Unlimited AI conversations',
                                '∞ Unlimited food scans',
                                '⚡ Priority responses',
                                '📊 Advanced analytics',
                              ],
                              isSelected: _selectedPlan == 'ultra_yearly',
                              onTap: () => setState(() => _selectedPlan = 'ultra_yearly'),
                              colors: colors,
                            ),
                          )
                        else
                          _TierPlanCard(
                            planId: 'ultra_monthly',
                            tierName: 'Ultra',
                            badge: 'MOST POPULAR',
                            badgeColor: const Color(0xFFAA66FF),
                            accentColor: const Color(0xFFAA66FF),
                            price: '\$9.99',
                            period: '/mo',
                            billedAs: 'Billed monthly',
                            features: const [
                              '∞ Unlimited AI conversations',
                              '∞ Unlimited food scans',
                              '⚡ Priority responses',
                              '📊 Advanced analytics',
                            ],
                            isSelected: _selectedPlan == 'ultra_monthly',
                            onTap: () => setState(() => _selectedPlan = 'ultra_monthly'),
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
                            '100 AI conversations/day',
                            '50 food scans/day',
                            '🏋️ Personalized workouts',
                          ],
                          isSelected: _selectedPlan == (_selectedBillingCycle == 'yearly' ? 'premium_yearly' : 'premium_monthly'),
                          onTap: () => setState(() => _selectedPlan = _selectedBillingCycle == 'yearly' ? 'premium_yearly' : 'premium_monthly'),
                          colors: colors,
                        ),
                      ],
                    ),
              ),

              // Trial badge for new users
              if (!isSubscribed && hasTrial)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Nothing due today • Cancel anytime',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Action button
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

              const SizedBox(height: 10),

              // Why does it cost this much?
              GestureDetector(
                onTap: () => _showWhyCostSheet(context, colors),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Why does it cost this much?',
                        style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      ),
                      Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Footer links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _restorePurchases(context, ref),
                    child: Text(
                      'Restore',
                      style: TextStyle(fontSize: 14, color: colors.cyan),
                    ),
                  ),
                  if (isSubscribed && currentTier != SubscriptionTier.lifetime) ...[
                    Text(' • ', style: TextStyle(color: colors.textSecondary)),
                    GestureDetector(
                      onTap: () => _openSubscriptionSettings(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                  if (!isSubscribed) ...[
                    Text(' • ', style: TextStyle(color: colors.textSecondary)),
                    GestureDetector(
                      onTap: () => _skipToFree(context, ref),
                      child: Text(
                        'Maybe later',
                        style: TextStyle(fontSize: 14, color: colors.textSecondary),
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
    );
  }

  Color _getButtonColor() {
    switch (_selectedPlan) {
      case 'ultra_yearly':
        return const Color(0xFF00D9FF); // Cyan
      case 'ultra_monthly':
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
    await ref.read(subscriptionProvider.notifier).skipToFree();
    if (context.mounted) {
      context.go('/home');
    }
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, bool isSubscribed, SubscriptionTier currentTier) async {
    final success = await ref.read(subscriptionProvider.notifier).purchase(_selectedPlan);
    if (success && context.mounted) {
      if (isSubscribed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      context.go('/home');
    }
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

  void _showWhyCostSheet(BuildContext context, ThemeColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WhyCostSheet(colors: colors),
    );
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
                Text(
                  tierName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
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
                const Spacer(),
                Row(
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
            // Features in 2 columns
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: features.map((feature) => SizedBox(
                  width: 140,
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
                  _featureRow('🏆 Everything in Ultra', colors),
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

/// Bottom sheet explaining pricing
class _WhyCostSheet extends StatelessWidget {
  final ThemeColors colors;

  const _WhyCostSheet({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Developer photo placeholder
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: colors.cyan.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 35,
              color: colors.cyan,
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Hi, I'm the developer ",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const Text('👋', style: TextStyle(fontSize: 20)),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            "I wanted to share why your subscription matters.",
            style: TextStyle(
              fontSize: 15,
              color: colors.textPrimary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            "Running advanced AI for personalized workouts, nutrition analysis, and real-time coaching requires significant infrastructure. Your subscription directly supports server costs, AI compute, and continuous improvements.",
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            "With your support, we're working on adding professional workout videos from real trainers and expanding our exercise library. Your subscription helps make this vision a reality! 💪",
            style: TextStyle(
              fontSize: 15,
              color: colors.textPrimary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 16),
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
      case SubscriptionTier.ultra:
        return 'Ultra';
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
