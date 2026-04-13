import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_links.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/animations/app_animations.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/notification_service.dart';
import '../../core/services/posthog_service.dart';
import '../../screens/onboarding/pre_auth_quiz_data.dart';
import '../../widgets/glass_back_button.dart';
import '../onboarding/widgets/foldable_quiz_scaffold.dart';
import '../settings/subscription/subscription_history_screen.dart';


part 'paywall_pricing_screen_part_accent_border_card.dart';
part 'paywall_pricing_screen_part_plan_change_confirmation_dialog.dart';

/// Fixed paywall accent — warm orange (Strava-style).
/// Research: warm tones outperform cool by 43.9% on mobile (4,100+ A/B tests).
const _paywallAccent = Color(0xFFFC4C02);
const _paywallAccentContrast = Color(0xFF000000);


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
  String _selectedPlan = 'premium_yearly';
  String _selectedBillingCycle = 'yearly'; // 'yearly' or 'monthly'
  bool _hasShownDiscount = false;

  @override
  void initState() {
    super.initState();
    // Track paywall pricing screen view
    Future.microtask(() {
      ref.read(posthogServiceProvider).capture(
        eventName: 'paywall_pricing_viewed',
      );
    });
  }

  /// Get dynamic price string from RevenueCat offerings, with fallback
  String _getDynamicPrice({
    required Offerings? offerings,
    required String productId,
    required String fallback,
  }) {
    if (offerings?.current == null) return fallback;
    for (final pkg in offerings!.current!.availablePackages) {
      if (pkg.storeProduct.identifier == productId) {
        return pkg.storeProduct.priceString;
      }
    }
    return fallback;
  }

  /// Get the monthly equivalent price string for yearly plan
  String _getMonthlyEquivalent({required Offerings? offerings}) {
    if (offerings?.current == null) return '\$4.17';
    for (final pkg in offerings!.current!.availablePackages) {
      if (pkg.storeProduct.identifier == SubscriptionNotifier.premiumYearlyId) {
        final monthly = pkg.storeProduct.price / 12;
        return '\$${monthly.toStringAsFixed(2)}';
      }
    }
    return '\$4.17';
  }

  /// Get per-day price string for yearly plan
  String _getDailyEquivalent({required Offerings? offerings}) {
    if (offerings?.current == null) return '\$0.14';
    for (final pkg in offerings!.current!.availablePackages) {
      if (pkg.storeProduct.identifier == SubscriptionNotifier.premiumYearlyId) {
        final daily = pkg.storeProduct.price / 365;
        return '\$${daily.toStringAsFixed(2)}';
      }
    }
    return '\$0.14';
  }

  /// Get savings percentage (yearly vs monthly * 12)
  int _getSavingsPercent({required Offerings? offerings}) {
    double yearlyPrice = 49.99;
    double monthlyPrice = 4.99;
    if (offerings?.current != null) {
      for (final pkg in offerings!.current!.availablePackages) {
        if (pkg.storeProduct.identifier == SubscriptionNotifier.premiumYearlyId) {
          yearlyPrice = pkg.storeProduct.price;
        }
        if (pkg.storeProduct.identifier == SubscriptionNotifier.premiumMonthlyId) {
          monthlyPrice = pkg.storeProduct.price;
        }
      }
    }
    final monthlyAnnualized = monthlyPrice * 12;
    if (monthlyAnnualized <= 0) return 0;
    return ((monthlyAnnualized - yearlyPrice) / monthlyAnnualized * 100).round();
  }

  /// Personalized headline from onboarding goal
  String _getPersonalizedHeadline() {
    try {
      final quizData = ref.read(preAuthQuizProvider);
      final goal = quizData.goal;
      if (goal != null && goal.isNotEmpty) {
        // Map goal IDs to readable phrases
        const goalPhrases = {
          'lose_weight': 'Your weight loss plan is ready',
          'build_muscle': 'Your muscle-building plan is ready',
          'gain_strength': 'Your strength plan is ready',
          'improve_fitness': 'Your fitness plan is ready',
          'stay_active': 'Your active lifestyle plan is ready',
          'body_recomp': 'Your body recomp plan is ready',
          'athletic_performance': 'Your performance plan is ready',
          'flexibility': 'Your flexibility plan is ready',
        };
        return goalPhrases[goal] ?? 'Your personalized plan is ready';
      }
    } catch (_) {}
    return 'Your AI coach is ready';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);
    final subscriptionState = ref.watch(subscriptionProvider);
    final currentTier = subscriptionState.tier;
    final isSubscribed = currentTier != SubscriptionTier.free;
    final windowState = ref.watch(windowModeProvider);
    final isFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);
    final hPad = isFoldable ? 14.0 : 20.0;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: '',
          headerOverlay: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GlassBackButton(
                onTap: () => context.pop(),
              ),
            ),
          ),
          headerExtra: _buildPricingLeftPane(colors, isSubscribed),
          content: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              children: [
                const SizedBox(height: 4),

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

                // Title (phone only — foldable shows it in left pane)
                if (!isFoldable) ...[
                  if (!isSubscribed) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getPersonalizedHeadline(),
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
                ],

                // Billing cycle tabs (Yearly / Monthly)
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
                        onTap: () {
                          setState(() {
                            _selectedBillingCycle = 'yearly';
                            _selectedPlan = 'premium_yearly';
                          });
                          ref.read(posthogServiceProvider).capture(
                            eventName: 'paywall_plan_selected',
                            properties: {'plan_name': 'premium_yearly', 'billing_cycle': 'yearly'},
                          );
                        },
                        colors: colors,
                      ),
                      _BillingTab(
                        label: 'Monthly',
                        sublabel: '${_getDynamicPrice(offerings: subscriptionState.offerings, productId: SubscriptionNotifier.premiumMonthlyId, fallback: '\$4.99')}/mo',
                        isSelected: _selectedBillingCycle == 'monthly',
                        onTap: () {
                          setState(() {
                            _selectedBillingCycle = 'monthly';
                            _selectedPlan = 'premium_monthly';
                          });
                          ref.read(posthogServiceProvider).capture(
                            eventName: 'paywall_plan_selected',
                            properties: {'plan_name': 'premium_monthly', 'billing_cycle': 'monthly'},
                          );
                        },
                        colors: colors,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isFoldable ? 10 : 14),

                // Single Premium plan (dynamic pricing from RevenueCat offerings)
                _AccentBorderCard(
                  isSelected: true,
                  colors: colors,
                  accentOverride: _paywallAccent,
                  child: _TierPlanCard(
                    planId: _selectedBillingCycle == 'yearly' ? 'premium_yearly' : 'premium_monthly',
                    tierName: 'Premium',
                    badge: _selectedBillingCycle == 'yearly'
                        ? 'SAVE ${_getSavingsPercent(offerings: subscriptionState.offerings)}%'
                        : '',
                    badgeColor: const Color(0xFF16A34A),
                    accentColor: _paywallAccent,
                    price: _selectedBillingCycle == 'yearly'
                        ? _getMonthlyEquivalent(offerings: subscriptionState.offerings)
                        : _getDynamicPrice(
                            offerings: subscriptionState.offerings,
                            productId: SubscriptionNotifier.premiumMonthlyId,
                            fallback: '\$4.99',
                          ),
                    period: '/mo',
                    billedAs: _selectedBillingCycle == 'yearly'
                        ? '${_getDynamicPrice(offerings: subscriptionState.offerings, productId: SubscriptionNotifier.premiumYearlyId, fallback: '\$49.99')}/year \u00b7 ${_getDailyEquivalent(offerings: subscriptionState.offerings)}/day'
                        : 'Billed monthly',
                    features: const [
                      'Unlimited personalized AI workouts',
                      'Snap a photo, get instant macros',
                      'Injury-aware training adjustments',
                      'Detailed progress & body tracking',
                      'AI video form analysis & scoring',
                      'Push past every plateau',
                    ],
                    isSelected: true,
                    onTap: () {},
                    colors: colors,
                  ),
                ),

                SizedBox(height: isFoldable ? 12 : 16),

                // Main action button with shimmer
                _ShimmerOverlay(
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: subscriptionState.isLoading
                        ? null
                        : () => _handleAction(context, ref, isSubscribed, currentTier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _paywallAccent,
                        foregroundColor: _paywallAccentContrast,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: subscriptionState.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation(_paywallAccentContrast),
                            ),
                          )
                        : Text(
                            _getButtonText(isSubscribed, currentTier),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                    ),
                  ),
                ),

                // Reassurance text
                if (!isSubscribed) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Cancel anytime. No charge today.',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],

                SizedBox(height: isFoldable ? 10 : 16),

                // Preview options (de-emphasized text links)
                if (!isSubscribed && widget.showPlanPreview)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/plan-preview'),
                        child: Text(
                          'See Your AI Plan',
                          style: TextStyle(fontSize: 13, color: colors.textSecondary, decoration: TextDecoration.underline, decorationColor: colors.textSecondary),
                        ),
                      ),
                      Text(
                        '  \u00b7  ',
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/demo-workout'),
                        child: Text(
                          'Try a Free Workout',
                          style: TextStyle(fontSize: 13, color: colors.textSecondary, decoration: TextDecoration.underline, decorationColor: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),

                // Maybe later (de-emphasized skip)
                if (!isSubscribed) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () => _handleMaybeLater(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Maybe later',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: colors.textMuted.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                SizedBox(height: isFoldable ? 10 : 16),

                // Footer links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _restorePurchases(context, ref),
                      child: Text('Restore', style: TextStyle(fontSize: 13, color: colors.cyan)),
                    ),
                    Text(' • ', style: TextStyle(color: colors.textMuted)),
                    GestureDetector(
                      onTap: () => _openTermsOfService(),
                      child: Text('Terms', style: TextStyle(fontSize: 13, color: colors.textMuted)),
                    ),
                    Text(' • ', style: TextStyle(color: colors.textMuted)),
                    GestureDetector(
                      onTap: () => _openPrivacyPolicy(),
                      child: Text('Privacy', style: TextStyle(fontSize: 13, color: colors.textMuted)),
                    ),
                    if (isSubscribed) ...[
                      Text(' • ', style: TextStyle(color: colors.textMuted)),
                      GestureDetector(
                        onTap: () => _navigateToSubscriptionHistory(context),
                        child: Text('History', style: TextStyle(fontSize: 13, color: colors.cyan)),
                      ),
                    ],
                    if (isSubscribed && currentTier != SubscriptionTier.lifetime) ...[
                      Text(' • ', style: TextStyle(color: colors.textMuted)),
                      GestureDetector(
                        onTap: () => _openSubscriptionSettings(),
                        child: Text('Cancel', style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }


  String _getButtonText(bool isSubscribed, SubscriptionTier currentTier) {
    if (!isSubscribed) {
      return _selectedPlan.contains('yearly') ? 'Start Free Trial' : 'Subscribe Now';
    }
    return 'Change Plan';
  }

  void _handleMaybeLater(BuildContext context, WidgetRef ref) async {
    ref.read(posthogServiceProvider).capture(
      eventName: 'paywall_skip_tapped',
      properties: {'has_shown_discount': _hasShownDiscount},
    );

    // Show 25% discount popup the first time user tries to leave
    if (!_hasShownDiscount) {
      _hasShownDiscount = true;
      ref.read(posthogServiceProvider).capture(
        eventName: 'paywall_discount_shown',
        properties: {'discount_percent': 25},
      );
      final accepted = await _showDiscountPopup(context);
      if (accepted == true) {
        ref.read(posthogServiceProvider).capture(
          eventName: 'paywall_discount_accepted',
          properties: {'discount_percent': 25},
        );
        // User accepted the 25% discount — purchase discounted yearly
        final success = await ref.read(subscriptionProvider.notifier).purchase('premium_yearly_25off');
        if (success && context.mounted) {
          final isReturning = ref.read(authStateProvider).user?.isPaywallComplete ?? false;
          if (isReturning) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Welcome to FitWiz Pro! Your subscription is active.'), behavior: SnackBarBehavior.floating),
            );
            context.go('/home');
          } else {
            await _markPaywallComplete(ref);
            await _navigateAfterPaywall(context, ref);
          }
        }
        return;
      }
    }

    // User declined discount (or second tap) — start 7-day RevenueCat trial
    // by purchasing yearly plan (which has a 7-day free trial attached)
    ref.read(posthogServiceProvider).capture(
      eventName: 'paywall_trial_auto_started',
      properties: {},
    );

    final isReturningUser = ref.read(authStateProvider).user?.isPaywallComplete ?? false;
    final trialSuccess = await ref.read(subscriptionProvider.notifier).purchase('premium_yearly');
    if (trialSuccess && context.mounted) {
      if (isReturningUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to FitWiz Pro! Your subscription is active.'), behavior: SnackBarBehavior.floating),
        );
        context.go('/home');
      } else {
        await _markPaywallComplete(ref);
        await _navigateAfterPaywall(context, ref);
      }
    } else if (context.mounted) {
      if (isReturningUser) {
        if (context.canPop()) context.pop();
      } else {
        // New user — let them through, hard paywall will gate premium features
        await _markPaywallComplete(ref);
        await _navigateAfterPaywall(context, ref);
      }
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

      // Store in SharedPreferences so notification scheduling knows paywall is done
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('paywall_completed', true);

      // Now that both onboarding and paywall are complete, schedule notifications
      ref.read(notificationPreferencesProvider.notifier).rescheduleNotifications();
      debugPrint('🔔 [Paywall] paywall_completed saved & notifications scheduled');
    } catch (e) {
      debugPrint('❌ [Paywall] Failed to update paywall_completed flag: $e');
    }
  }

  /// Navigate to subscription success screen after paywall completion
  Future<void> _navigateAfterPaywall(BuildContext context, WidgetRef ref) async {
    if (context.mounted) {
      debugPrint('🎉 [Paywall] Navigating to subscription success');
      context.go('/subscription-success');
    }
  }

  Future<bool?> _showDiscountPopup(BuildContext context) {
    // Use ref.colors(context) for dynamic accent color
    final colors = ref.colors(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DiscountPopup(colors: colors),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, bool isSubscribed, SubscriptionTier currentTier) async {
    ref.read(posthogServiceProvider).capture(
      eventName: 'paywall_cta_tapped',
      properties: {'selected_plan': _selectedPlan},
    );
    // If user is already subscribed, show plan change confirmation dialog
    if (isSubscribed && currentTier != SubscriptionTier.free) {
      final confirmed = await _showPlanChangeConfirmation(context, currentTier);
      if (confirmed != true) return;
    }

    ref.read(posthogServiceProvider).capture(
      eventName: 'paywall_purchase_initiated',
      properties: {'selected_plan': _selectedPlan},
    );

    final success = await ref.read(subscriptionProvider.notifier).purchase(_selectedPlan);
    final isReturningUser = ref.read(authStateProvider).user?.isPaywallComplete ?? false;

    if (success && context.mounted) {
      if (isSubscribed || isReturningUser) {
        // Existing user upgrading — snackbar + go home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSubscribed ? 'Plan updated successfully!' : 'Welcome to FitWiz Pro! Your subscription is active.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/home');
      } else {
        // Brand new user — full onboarding celebration + workout generation
        await _markPaywallComplete(ref);
        await _navigateAfterPaywall(context, ref);
      }
    } else if (!success && context.mounted) {
      if (isReturningUser) {
        // Returning user cancelled — just go back
        if (context.canPop()) context.pop();
      } else {
        // New user — let them through, hard paywall will gate premium features
        await _markPaywallComplete(ref);
        await _navigateAfterPaywall(context, ref);
      }
    }
  }

  /// Get plan details by plan ID
  Map<String, dynamic> _getPlanDetails(String planId) {
    switch (planId) {
      case 'premium_yearly':
        return {
          'name': 'Premium Yearly',
          'price': 49.99,
          'period': 'year',
          'monthlyPrice': 4.17,
        };
      case 'premium_yearly_discount':
        return {
          'name': 'Premium Yearly (Discounted)',
          'price': 39.99,
          'period': 'year',
          'monthlyPrice': 3.33,
        };
      case 'premium_monthly':
        return {
          'name': 'Premium Monthly',
          'price': 4.99,
          'period': 'month',
          'monthlyPrice': 4.99,
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
      case SubscriptionTier.premium:
      case SubscriptionTier.premiumPlus: // Legacy — treat as premium
        return state.subscriptionEndDate != null &&
                state.subscriptionEndDate!.difference(DateTime.now()).inDays > 60
            ? 'premium_yearly'
            : 'premium_monthly';
      default:
        return 'free';
    }
  }

  /// Show plan change confirmation dialog
  Future<bool?> _showPlanChangeConfirmation(BuildContext context, SubscriptionTier currentTier) {
    // Use ref.colors(context) for dynamic accent color
    final colors = ref.colors(context);
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
      AppPageRoute(
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

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _openTermsOfService() async {
    try {
      await launchUrl(Uri.parse(AppLinks.termsOfService), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      await launchUrl(Uri.parse(AppLinks.privacyPolicy), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _buildPricingLeftPane(ThemeColors colors, bool isSubscribed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          isSubscribed ? 'Change Plan' : 'Your AI coach',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            height: 1.3,
          ),
        ),
        if (!isSubscribed)
          Text(
            'is ready',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.accent,
              height: 1.3,
            ),
          ),
        const SizedBox(height: 16),

        // Trial badge
        if (!isSubscribed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.accent.withValues(alpha: 0.1),
                  colors.accent.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, size: 18, color: colors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '7-day free trial\nCancel anytime, no questions asked',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),

        // What you get
        Text(
          'What you get',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _LeftPaneFeature(icon: Icons.auto_fix_high, text: 'Unlimited AI workouts', colors: colors),
        const SizedBox(height: 6),
        _LeftPaneFeature(icon: Icons.camera_alt_outlined, text: 'Food photo scanning', colors: colors),
        const SizedBox(height: 6),
        _LeftPaneFeature(icon: Icons.restaurant_menu, text: 'Full nutrition tracking', colors: colors),
        const SizedBox(height: 6),
        _LeftPaneFeature(icon: Icons.local_fire_department, text: 'Hell Mode & supersets', colors: colors),
        const SizedBox(height: 6),
        _LeftPaneFeature(icon: Icons.healing_outlined, text: 'Injury-aware workouts', colors: colors),
        const SizedBox(height: 6),
        _LeftPaneFeature(icon: Icons.fitness_center, text: '52 skill progressions', colors: colors),
        const SizedBox(height: 14),

        // Trial reassurance
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.textSecondary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.textSecondary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: colors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Start with a 7-day free trial. Cancel anytime — no charge until the trial ends.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
