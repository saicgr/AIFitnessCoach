import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_links.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/providers/lapsed_paywall_gate_provider.dart';
import '../../core/animations/app_animations.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/notification_service.dart';
import '../../core/services/posthog_service.dart';
import 'widgets/inline_referral_expander.dart';
import 'widgets/credibility_strip.dart';
import 'widgets/goal_speed_comparison.dart';
import '../onboarding/goal_speed_calculator.dart';
import 'paywall_experiments.dart';
import '../onboarding/onboarding_experiments.dart';
import '../../screens/onboarding/pre_auth_quiz_data.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/plan_portability_badge.dart';
import '../onboarding/widgets/foldable_quiz_scaffold.dart';
import 'package:fitwiz/core/constants/branding.dart';

import '../../l10n/generated/app_localizations.dart';
part 'paywall_pricing_screen_part_accent_border_card.dart';
part 'paywall_pricing_screen_part_plan_change_confirmation_dialog.dart';

/// Fixed paywall accent — warm orange (Strava-style).
/// Research: warm tones outperform cool by 43.9% on mobile (4,100+ A/B tests).
const _paywallAccent = Color(0xFFFC4C02);
// Industry-standard contrast on a brand-fill CTA. Black-on-orange reads
// bargain; every top fitness paywall (Cal AI, Fastic, Lumen, Centr, Whoop,
// BetterMe, Noom) uses pure white at weight 700.
const _paywallAccentContrast = Color(0xFFFFFFFF);

/// Paywall/Membership Screen
/// Shows current plan status and upgrade/downgrade options
/// Now includes "Preview Your Plan" to show users their personalized workout plan before subscribing
class PaywallPricingScreen extends ConsumerStatefulWidget {
  /// If true, shows the "See Your Plan First" banner prominently
  final bool showPlanPreview;

  const PaywallPricingScreen({super.key, this.showPlanPreview = true});

  @override
  ConsumerState<PaywallPricingScreen> createState() =>
      _PaywallPricingScreenState();
}

class _PaywallPricingScreenState extends ConsumerState<PaywallPricingScreen> {
  String _selectedPlan = 'premium_yearly';
  String _selectedBillingCycle = 'yearly'; // 'yearly' or 'monthly'
  bool _hasShownDiscount = false;

  // A/B-experiment state. Starts at the shipped treatment default so the
  // first frame already shows the conversion levers; replaced once the
  // PostHog flags resolve in initState.
  PaywallExperiments _experiments = PaywallExperiments.treatmentDefaults;

  // Cal AI / BetterMe / Headway / Lose It-style 3-page intro flow.
  // Used only for non-subscribed users in the post-quiz funnel; subscribed
  // users coming from settings still see the legacy Change-Plan layout
  // because the intro framing doesn't apply to them.
  late final PageController _pageController;
  int _currentPage = 0;
  // Cal AI-style 4-page intro flow: founder/hero → reminder → value grid →
  // timeline-offer.
  static const int _totalPages = 4;
  // Index of the notification-primer (reminder) page.
  static const int _reminderPage = 1;
  // Index of the "here's what you unlock" value-grid page.
  static const int _valuePage = 2;

  // Skip ("Maybe later") visibility — platform-aware.
  //
  // Google Play REQUIRES a clearly-visible dismiss at any price (its
  // "Paywall Restriction" policy deactivates apps that hide it), so on
  // Android the skip is visible from the first frame.
  //
  // iOS polices *deceptive* dismissal (hidden/trapping X), but tolerates a
  // short delay before a then-clearly-visible skip. We hide it for a few
  // seconds so the user reads all three intro beats first, then fade it in.
  // (The iOS hard-gate — `_experiments.hardGate` scoped to iOS — removes it
  // entirely; the $1 / trial entry is what keeps that palatable.)
  bool _skipVisible = !Platform.isIOS;
  Timer? _skipRevealTimer;
  static const Duration _kSkipRevealDelay = Duration(seconds: 4);

  // v7 first-run redesign: page 0 leads with founder-note proof instead of
  // the phone-mock hero. Kill switch `onboarding_v7_paywall_founder_page`
  // (default ON, fail-open) restores the hero without a redeploy.
  bool _founderPageEnabled = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Track the screen view and resolve the paywall A/B experiments.
    Future.microtask(() async {
      final posthog = ref.read(posthogServiceProvider);
      // Onboarding conversion v6: attribute the view to the user's "why"
      // so the personalized-headline variant can be measured.
      final primaryWhys = ref.read(preAuthQuizProvider).primaryWhys;
      final primaryWhy = (primaryWhys != null && primaryWhys.isNotEmpty)
          ? primaryWhys.first
          : null;
      posthog.capture(
        eventName: 'paywall_pricing_viewed',
        properties: primaryWhy != null ? {'primary_why': primaryWhy} : null,
      );
      final exp = await loadPaywallExperiments(
        posthog,
        surface: 'soft_paywall',
      );
      if (mounted) setState(() => _experiments = exp);
      final founderOn = await OnboardingExperiments.isEnabled(
        posthog,
        OnboardingExperiments.flagPaywallFounderPageV7,
      );
      if (mounted && !founderOn) {
        setState(() => _founderPageEnabled = false);
      }
    });
  }

  /// Page 1's "Remind me 🔔" CTA fires the OS notification prompt — the
  /// day-5 trial promise is impossible without permission, and this is the
  /// one moment the user actively WANTS notifications. Sets the same
  /// `notification_prime_shown` pref the standalone prime screen uses, so
  /// the post-onboarding /notifications-prime chain auto-skips.
  Future<void> _requestNotificationPermissionFromReminderPage() async {
    try {
      await ref.read(notificationServiceProvider).requestPermissionWhenReady();
    } catch (e) {
      debugPrint('🔔 [Paywall] notification permission request failed: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_prime_shown', true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _skipRevealTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// On iOS, reveal the de-emphasized "Maybe later" skip a few seconds after
  /// the user lands on the last intro page — so they read the offer first.
  /// No-op on Android (skip is already visible) and once already revealed.
  void _scheduleSkipReveal() {
    if (_skipVisible || _skipRevealTimer != null) return;
    _skipRevealTimer = Timer(_kSkipRevealDelay, () {
      if (mounted) setState(() => _skipVisible = true);
    });
  }

  void _goToNextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToPreviousPage() {
    HapticFeedback.selectionClick();
    // Back from any later page steps one page; back from the first page
    // (page 0, the founder/hero beat) bails out of the paywall entirely.
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      // First interactive page → bail out of the paywall entirely.
      //
      // Bug fix: `context.pop()` (go_router) only pops a single
      // sub-route inside the paywall's nested Navigator, which on
      // soft-paywall trial screens landed the user on the NEXT paywall
      // variant instead of dismissing back to the previous app screen.
      // Use the ROOT Navigator so the entire paywall stack pops in one
      // hop — pre-trial flows still pop normally; post-trial hard
      // paywall keeps `PopScope(canPop: false)` so this is a no-op.
      final rootNav = Navigator.of(context, rootNavigator: true);
      if (rootNav.canPop()) {
        rootNav.pop();
      } else if (context.canPop()) {
        // Fallback for edge cases where the paywall was pushed via
        // go_router without a nested Navigator above it.
        context.pop();
      }
    }
  }

  /// Date 7 days from now in the user's local timezone, formatted "Mar 9".
  /// Used on the timeline page to ground the trial-end commitment in a
  /// real, concrete date instead of "in 7 days."
  String _trialEndDateString() {
    final end = DateTime.now().add(const Duration(days: 7));
    return DateFormat('MMM d').format(end);
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
    if (offerings?.current == null) return '\$5.00';
    for (final pkg in offerings!.current!.availablePackages) {
      if (pkg.storeProduct.identifier == SubscriptionNotifier.premiumYearlyId) {
        final monthly = pkg.storeProduct.price / 12;
        return '\$${monthly.toStringAsFixed(2)}';
      }
    }
    return '\$5.00';
  }

  /// Get per-day price string for yearly plan
  String _getDailyEquivalent({required Offerings? offerings}) {
    if (offerings?.current == null) return '\$0.16';
    for (final pkg in offerings!.current!.availablePackages) {
      if (pkg.storeProduct.identifier == SubscriptionNotifier.premiumYearlyId) {
        final daily = pkg.storeProduct.price / 365;
        return '\$${daily.toStringAsFixed(2)}';
      }
    }
    return '\$0.16';
  }

  /// Get savings percentage (yearly vs monthly * 12)
  int _getSavingsPercent({required Offerings? offerings}) {
    double yearlyPrice = 59.99;
    double monthlyPrice = 7.99;
    if (offerings?.current != null) {
      for (final pkg in offerings!.current!.availablePackages) {
        if (pkg.storeProduct.identifier ==
            SubscriptionNotifier.premiumYearlyId) {
          yearlyPrice = pkg.storeProduct.price;
        }
        if (pkg.storeProduct.identifier ==
            SubscriptionNotifier.premiumMonthlyId) {
          monthlyPrice = pkg.storeProduct.price;
        }
      }
    }
    final monthlyAnnualized = monthlyPrice * 12;
    if (monthlyAnnualized <= 0) return 0;
    return ((monthlyAnnualized - yearlyPrice) / monthlyAnnualized * 100)
        .round();
  }

  /// Personalized headline from onboarding goal. When the goal is weight-
  /// related (lose_weight / body_recomp / build_muscle) and we have both
  /// current and goal weight, surface the actual delta — e.g. "Your plan
  /// to lose 12 lb" — same pattern Cal AI / Fastic / Noom use to anchor
  /// the user on a concrete outcome before the price.
  String _getPersonalizedHeadline() {
    try {
      final quizData = ref.read(preAuthQuizProvider);
      final goal = quizData.goal;
      final currentKg = quizData.weightKg;
      final goalKg = quizData.goalWeightKg;
      final useMetric = quizData.useMetricUnits;

      if (currentKg != null && goalKg != null && currentKg > 0 && goalKg > 0) {
        final deltaKg = goalKg - currentKg;
        final absDeltaKg = deltaKg.abs();
        if (absDeltaKg >= 0.5) {
          final unit = useMetric ? 'kg' : 'lb';
          final amount = useMetric
              ? absDeltaKg.round()
              : (absDeltaKg * 2.20462).round();
          if (amount > 0) {
            if (deltaKg < 0) return 'Your plan to lose $amount $unit';
            if (deltaKg > 0) return 'Your plan to gain $amount $unit';
          }
        } else {
          // Maintenance: explicit, not vague.
          return 'Your plan to maintain your weight';
        }
      }

      if (goal != null && goal.isNotEmpty) {
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
    final isFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(
      windowState,
    );
    final hPad = isFoldable ? 14.0 : 20.0;

    // Non-subscribed (post-onboarding) users get the Cal AI-style 3-page
    // intro flow. Subscribed users coming from Settings → Manage Plan get
    // the legacy single-page Change-Plan layout below.
    if (!isSubscribed) {
      return _buildIntroFlow(context, colors, subscriptionState, currentTier);
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: '',
          headerOverlay: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GlassBackButton(onTap: () => context.pop()),
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
                    billingPeriod: subscriptionState.billingPeriod,
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
                          AppLocalizations.of(
                            context,
                          ).paywallPricing7DayFreeTrial,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.cancel_outlined,
                          color: colors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).paywallPricingCancelAnytime,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text(
                      AppLocalizations.of(context).paywallPricingChangePlan,
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
                        label: AppLocalizations.of(
                          context,
                        ).paywallPricingYearly,
                        sublabel: AppLocalizations.of(
                          context,
                        ).paywallPricingBestValue,
                        badge:
                            'SAVE ${_getSavingsPercent(offerings: subscriptionState.offerings)}%',
                        // Phase C: louder savings badge on the value plan.
                        prominentBadge: _experiments.pricingPsychology,
                        isSelected: _selectedBillingCycle == 'yearly',
                        onTap: () {
                          setState(() {
                            _selectedBillingCycle = 'yearly';
                            _selectedPlan = 'premium_yearly';
                          });
                          ref
                              .read(posthogServiceProvider)
                              .capture(
                                eventName: 'paywall_plan_selected',
                                properties: {
                                  'plan_name': 'premium_yearly',
                                  'billing_cycle': 'yearly',
                                },
                              );
                        },
                        colors: colors,
                      ),
                      _BillingTab(
                        label: AppLocalizations.of(context).xpGoalsMonthly,
                        sublabel:
                            '${_getDynamicPrice(offerings: subscriptionState.offerings, productId: SubscriptionNotifier.premiumMonthlyId, fallback: '\$7.99')}/mo',
                        // Phase C: quieter monthly tab so the annual + trial
                        // path reads as the obvious default.
                        deEmphasized: _experiments.pricingPsychology,
                        isSelected: _selectedBillingCycle == 'monthly',
                        onTap: () {
                          setState(() {
                            _selectedBillingCycle = 'monthly';
                            _selectedPlan = 'premium_monthly';
                          });
                          ref
                              .read(posthogServiceProvider)
                              .capture(
                                eventName: 'paywall_plan_selected',
                                properties: {
                                  'plan_name': 'premium_monthly',
                                  'billing_cycle': 'monthly',
                                },
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
                    planId: _selectedBillingCycle == 'yearly'
                        ? 'premium_yearly'
                        : 'premium_monthly',
                    tierName: 'Premium',
                    // Badge moved to the Yearly tab pill; keep empty here
                    // so the price doesn't fight a sibling badge.
                    badge: '',
                    badgeColor: const Color(0xFF16A34A),
                    accentColor: _paywallAccent,
                    // Anchor: when Yearly is selected, render the full
                    // monthly price as a strikethrough so users perceive
                    // the discount as a real reduction rather than a flat
                    // rate. Standard price-anchoring pattern (Cal AI,
                    // BetterMe, Headway, Lumen).
                    anchorPrice: _selectedBillingCycle == 'yearly'
                        ? _getDynamicPrice(
                            offerings: subscriptionState.offerings,
                            productId: SubscriptionNotifier.premiumMonthlyId,
                            fallback: '\$7.99',
                          )
                        : null,
                    price: _selectedBillingCycle == 'yearly'
                        ? _getMonthlyEquivalent(
                            offerings: subscriptionState.offerings,
                          )
                        : _getDynamicPrice(
                            offerings: subscriptionState.offerings,
                            productId: SubscriptionNotifier.premiumMonthlyId,
                            fallback: '\$7.99',
                          ),
                    period: '/mo',
                    billedAs: _selectedBillingCycle == 'yearly'
                        ? '${_getDynamicPrice(offerings: subscriptionState.offerings, productId: SubscriptionNotifier.premiumYearlyId, fallback: '\$59.99')}/year \u00b7 ${_getDailyEquivalent(offerings: subscriptionState.offerings)}/day'
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

                // Phase C: tangible value framing. The yearly plan works
                // out to roughly $5 a month, comfortably less than one
                // coffee a week — a concrete anchor lands harder than the
                // raw number alone.
                if (!isSubscribed &&
                    _experiments.pricingPsychology &&
                    _selectedBillingCycle == 'yearly') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_cafe_outlined,
                        size: 14,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).paywallPricingLessThanThePrice,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isFoldable ? 8 : 12),
                ],

                // Credibility strip (compact) — methodology + technology
                // trust that needs no traction data. Sits between the plan
                // card and the CTA microcopy; auto-upgrades to a real
                // rating once SocialProofConfig is populated.
                if (!isSubscribed && _experiments.credibilityStrip) ...[
                  PaywallCredibilityStrip(
                    colors: colors,
                    accent: _paywallAccent,
                    compact: true,
                  ),
                  SizedBox(height: isFoldable ? 10 : 14),
                ],

                // "No payment due now" trust microcopy — placed DIRECTLY
                // above the CTA. Reassurance read in the instant before
                // the tap lifts trial-start conversion; the same line
                // below the button is read far less. Shown only on the
                // free-trial (yearly) path, where the claim is true — the
                // monthly path charges on purchase and says "Subscribe
                // Now", so no microcopy there (honesty over uplift).
                if (!isSubscribed &&
                    _experiments.noPaymentMicrocopy &&
                    _selectedPlan.contains('yearly')) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: _paywallAccent,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).paywallPricingNoPaymentDueNow,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Main action button with shimmer
                _ShimmerOverlay(
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: subscriptionState.isLoading
                          ? null
                          : () => _handleAction(
                              context,
                              ref,
                              isSubscribed,
                              currentTier,
                            ),
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
                                valueColor: const AlwaysStoppedAnimation(
                                  _paywallAccentContrast,
                                ),
                              ),
                            )
                          : Text(
                              _getButtonText(isSubscribed, currentTier),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: _paywallAccentContrast,
                              ),
                            ),
                    ),
                  ),
                ),

                // 3-row trust strip \u2014 replaces the single muted
                // "Cancel anytime. No charge today." line. Each row pairs
                // a small icon with a one-line reassurance \u2014 same pattern
                // used by Cal AI, Fastic, BetterMe, Headway, Lumen.
                if (!isSubscribed) ...[
                  const SizedBox(height: 12),
                  _TrustStrip(colors: colors),
                  const SizedBox(height: 12),
                  // Plan-portability guarantee. Anchors the App-Store
                  // description claim "your plan is yours forever" \u2014 has to
                  // be visible on the paywall to honour 2.3.1 (no claims the
                  // build doesn't deliver). Banner variant.
                  const PlanPortabilityBadge(size: PortabilitySize.banner),
                ],

                // Maybe later (de-emphasized skip).
                // HARD GATE: when the `paywall_hard_gate` experiment is on we
                // drop this entirely — the only way past the onboarding
                // paywall is start-trial / subscribe / restore, matching the
                // single-tier-paid model and closing the "skip → silently
                // hard-locked on /home" leak (see PaywallExperiments.hardGate).
                if (!isSubscribed && !_experiments.hardGate) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () => _handleMaybeLater(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          AppLocalizations.of(context).notifsLaterButton,
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

                // Secure-checkout reassurance — handles the payment-safety
                // objection. Placed with the legal block so it reads as a
                // fact, not a sales line. Platform-accurate wording.
                if (_experiments.secureCheckoutBadge) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          Platform.isIOS
                              ? AppLocalizations.of(
                                  context,
                                ).paywallPricingBilledSecurelyThroughThe
                              : 'Billed securely through Google Play',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isFoldable ? 6 : 8),
                ],

                // App Store 3.1.2 + Google Play: auto-renewal must be
                // disclosed adjacent to the purchase CTA.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Subscription auto-renews at the listed price unless '
                    'cancelled at least 24 hours before the end of the '
                    'current period. Manage or cancel anytime in your device '
                    'account settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: colors.textMuted,
                    ),
                  ),
                ),
                SizedBox(height: isFoldable ? 8 : 12),

                // Footer links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _restorePurchases(context, ref),
                      child: Text(
                        AppLocalizations.of(context).paywallPricingRestore,
                        style: TextStyle(fontSize: 13, color: colors.cyan),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).programLibrary,
                      style: TextStyle(color: colors.textMuted),
                    ),
                    GestureDetector(
                      onTap: () => _openTermsOfService(),
                      child: Text(
                        AppLocalizations.of(context).paywallPricingTerms,
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).programLibrary,
                      style: TextStyle(color: colors.textMuted),
                    ),
                    GestureDetector(
                      onTap: () => _openPrivacyPolicy(),
                      child: Text(
                        AppLocalizations.of(context).settingsPrivacySection,
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                    ),
                    if (isSubscribed &&
                        currentTier != SubscriptionTier.lifetime) ...[
                      Text(
                        AppLocalizations.of(context).programLibrary,
                        style: TextStyle(color: colors.textMuted),
                      ),
                      GestureDetector(
                        onTap: () => _openSubscriptionSettings(),
                        child: Text(
                          AppLocalizations.of(context).buttonCancel,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Referral expander lives at the very bottom — matches the
                // "Have a code?" pattern on Cal AI / BetterMe paywalls
                // where it's reachable but never competes with the CTA.
                if (!isSubscribed) ...[
                  const SizedBox(height: 8),
                  const InlineReferralExpander(),
                ],

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
      return _selectedPlan.contains('yearly')
          ? 'Start Free Trial'
          : 'Subscribe Now';
    }
    return 'Change Plan';
  }

  // ─────────────────────────────────────────────────────────────────────
  // Cal AI-style 3-page intro flow (non-subscribed users only)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildIntroFlow(
    BuildContext context,
    ThemeColors colors,
    SubscriptionState subscriptionState,
    SubscriptionTier currentTier,
  ) {
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _goToPreviousPage();
          },
          child: Column(
            children: [
              _buildIntroTopBar(colors, context, ref),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    // iOS: once the user reaches the last (offer) page, start
                    // the timer that fades the "Maybe later" skip in.
                    if (i == _totalPages - 1) _scheduleSkipReveal();
                    // v7: per-page funnel visibility (which beat loses
                    // people: proof → reminder → offer).
                    ref
                        .read(posthogServiceProvider)
                        .capture(
                          eventName: 'paywall_intro_page_viewed',
                          properties: {
                            'page': i,
                            'variant': _founderPageEnabled
                                ? 'v7_founder'
                                : 'hero',
                          },
                        );
                  },
                  children: [
                    if (_founderPageEnabled)
                      _buildIntroPageFounder(colors)
                    else
                      _buildIntroPageHero(colors),
                    _buildIntroPageReminder(colors),
                    _buildIntroPageValue(colors),
                    _buildIntroPageTimeline(colors, subscriptionState),
                  ],
                ),
              ),
              _buildIntroBottomBar(colors, subscriptionState, currentTier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroTopBar(
    ThemeColors colors,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Back chevron on every page — on page 0 it bails out of the
          // paywall entirely (see `_goToPreviousPage`), matching the system
          // back gesture rather than duplicating a no-op.
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              splashRadius: 22,
              icon: Icon(
                Icons.chevron_left,
                size: 28,
                color: colors.textPrimary,
              ),
              onPressed: _goToPreviousPage,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _restorePurchases(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                AppLocalizations.of(context).paywallPricingRestore,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroBottomBar(
    ThemeColors colors,
    SubscriptionState subscriptionState,
    SubscriptionTier currentTier,
  ) {
    final isLast = _currentPage == _totalPages - 1;
    final label = switch (_currentPage) {
      // Page 0 = founder/hero proof beat.
      0 => 'Try for \$0.00',
      // Page 1 IS the notification primer — the CTA asks for the reminder,
      // and tapping it fires the OS permission prompt.
      _reminderPage => AppLocalizations.of(context).paywallRemindMeCta,
      // Page 2 = value grid — a plain "keep going", not a subscribe ask.
      _valuePage => 'Continue',
      _ =>
        _selectedPlan.contains('yearly')
            ? 'Start My 7-Day Free Trial'
            : 'Subscribe Now',
    };
    return Padding(
      // Bottom padding kept tight: the enclosing SafeArea already insets
      // for the home indicator, so extra padding here just floats the CTA
      // block up and leaves a dead gap above the bezel.
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).paywallPricingNoPaymentDueNow2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: subscriptionState.isLoading
                  ? null
                  : () {
                      if (isLast) {
                        _handleAction(context, ref, false, currentTier);
                      } else {
                        // Reminder page → request notification permission so
                        // the day-5 reminder promise can actually be kept.
                        // Fire-and-forget: page advance never blocks on
                        // the OS prompt.
                        if (_currentPage == _reminderPage) {
                          unawaited(
                            _requestNotificationPermissionFromReminderPage(),
                          );
                        }
                        _goToNextPage();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _paywallAccent,
                foregroundColor: _paywallAccentContrast,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: subscriptionState.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          _paywallAccentContrast,
                        ),
                      ),
                    )
                  : Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Barlow Condensed',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: _paywallAccentContrast,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Page-position dots — quiet wayfinding so users feel the
          // 3-step shape rather than wondering how deep the flow is.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (i) {
              final selected = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: selected ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected
                      ? _paywallAccent
                      : colors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          // Quiet exit on the last page only — once the user has seen all 3
          // beats. Platform-aware:
          //  • iOS hard-gate (paywall_hard_gate) removes it entirely — the
          //    $1 / trial entry keeps that palatable, and Apple permits hard
          //    paywalls for no-free-tier apps. Scoped to iOS only.
          //  • Otherwise it's shown, but on iOS it fades in a few seconds
          //    after this page appears (`_scheduleSkipReveal`); Android shows
          //    it immediately — Google Play requires a clearly-visible
          //    dismiss at any price ("Paywall Restriction" enforcement).
          if (isLast && !(_experiments.hardGate && Platform.isIOS)) ...[
            const SizedBox(height: 6),
            AnimatedOpacity(
              opacity: _skipVisible ? 1 : 0,
              duration: const Duration(milliseconds: 280),
              child: IgnorePointer(
                ignoring: !_skipVisible,
                child: GestureDetector(
                  onTap: () => _handleMaybeLater(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      AppLocalizations.of(context).notifsLaterButton,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Page 1 (v7): founder proof ───────────────────────────────────
  // Honest social proof: no fabricated ratings (we have none, and fake
  // proof is an App Store 2.3.1 risk). The founder's why reframes the
  // price against a $400/mo trainer before any number appears.
  Widget _buildIntroPageFounder(ThemeColors colors) {
    final l10n = AppLocalizations.of(context);
    // No-scroll guarantee, same technique as the reminder/value/timeline
    // pages: scale the whole page down to fit the viewport instead of
    // scrolling past the third testimonial to reach the CTA.
    return LayoutBuilder(
      builder: (context, viewport) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: viewport.maxWidth - 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Text(
                    l10n.paywallFounderKicker,
                    style: const TextStyle(
                      fontFamily: 'Barlow Condensed',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: _paywallAccent,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    l10n.paywallFounderHeadline,
                    style: TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 30,
                      height: 1.05,
                      color: colors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.textMuted.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.paywallFounderQuote,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.55,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFFFB366), _paywallAccent],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'C',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.paywallFounderName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  l10n.paywallFounderSub,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.08),
                  const SizedBox(height: 10),
                  // Two tester quotes, each anchored to a distinct feature icon so
                  // the pair reads as breadth (training discipline + nutrition with
                  // a real medical constraint) rather than two interchangeable
                  // "I like this app" blurbs.
                  _TesterQuoteCard(
                    quote: l10n.paywallTesterQuote,
                    name: l10n.paywallTesterName,
                    icon: Icons.fitness_center_rounded,
                    accent: _paywallAccent,
                    colors: colors,
                    animDelayMs: 280,
                  ),
                  const SizedBox(height: 8),
                  _TesterQuoteCard(
                    quote: l10n.paywallTesterQuote2,
                    name: l10n.paywallTesterName2,
                    icon: Icons.restaurant_menu_rounded,
                    accent: _paywallAccent,
                    colors: colors,
                    animDelayMs: 340,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      l10n.paywallEarlyAccess,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ).animate().fadeIn(delay: 380.ms),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Page 1 (legacy): hero ────────────────────────────────────────
  Widget _buildIntroPageHero(ThemeColors colors) {
    final headline = _heroHeadline();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.18,
              color: colors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).paywallPricingFreeFor7Days,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: _PhoneFrame(
                colors: colors,
                child: _WorkoutMockCard(colors: colors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _heroHeadline() {
    try {
      final quizData = ref.read(preAuthQuizProvider);

      // Onboarding conversion v6: when the user told us their "why" on the
      // first onboarding screen, echo it back here — the emotional anchor
      // lands harder than a goal label right before the price. The
      // concrete weight delta still shows on the weight-projection screen
      // earlier in the funnel.
      const whyHeadlines = {
        'feel_confident': 'Your plan to feel confident in your body',
        'keep_up': 'Your plan to keep up with your family',
        'event': 'Your plan to be ready for your event',
        'health': 'Your plan to take charge of your health',
        'feel_strong': 'Your plan to feel strong and capable',
        'energy': 'Your plan for more energy, less stress',
      };
      final whys = quizData.primaryWhys;
      final why = (whys != null && whys.isNotEmpty) ? whys.first : null;
      if (why != null && whyHeadlines.containsKey(why)) {
        return whyHeadlines[why]!;
      }

      final cur = quizData.weightKg;
      final goal = quizData.goalWeightKg;
      final useMetric = quizData.useMetricUnits;
      if (cur != null && goal != null && cur > 0 && goal > 0) {
        final delta = (goal - cur).abs();
        if (delta >= 0.5) {
          final unit = useMetric ? 'kg' : 'lb';
          final amt = useMetric ? delta.round() : (delta * 2.20462).round();
          if (amt > 0) {
            return goal < cur
                ? 'Your plan to lose $amt $unit'
                : 'Your plan to gain $amt $unit';
          }
        }
      }
      final g = quizData.goal;
      if (g == 'lose_weight') return 'Your weight loss plan is ready';
      if (g == 'build_muscle') return 'Your muscle plan is ready';
      if (g == 'gain_strength') return 'Your strength plan is ready';
    } catch (_) {}
    return 'Your ${Branding.appName} plan is ready';
  }

  // ── Page 2: reminder bell ────────────────────────────────────────
  // This page's one job is the trial-reminder assurance — the bottom-bar
  // CTA on this page ("Remind me 🔔") fires the OS notification prompt, so
  // the bell + copy stay the prominent foreground content. (The value
  // grid moved to its own page — see _buildIntroPageValue — rather than
  // competing with this page's message.)
  Widget _buildIntroPageReminder(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).paywallPricingWeLlSendYou,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).paywallPricingNoSurprisesCancelAnytime,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          // Expanded already absorbs whatever space is left below the copy
          // without overflowing or needing to scroll — the bell just
          // occupies less of it on short phones (Center never forces the
          // 220px box past what Expanded actually has).
          Expanded(
            child: Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft halo behind the bell.
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _paywallAccent.withValues(alpha: 0.16),
                            _paywallAccent.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    // Bell — shakes once on entry, then again every 2.4s
                    // so the screen never goes fully static. Subtle enough
                    // to read as "ringing" without being distracting.
                    Animate(
                      onPlay: (c) => c.repeat(reverse: false),
                      effects: [
                        const ShakeEffect(
                          duration: Duration(milliseconds: 700),
                          hz: 4,
                          rotation: 0.12,
                        ),
                        const ThenEffect(delay: Duration(milliseconds: 1700)),
                      ],
                      child: Icon(
                        Icons.notifications_rounded,
                        size: 150,
                        color: colors.textMuted.withValues(alpha: 0.45),
                      ),
                    ),
                    // Badge — pops in with a spring on first build.
                    Positioned(
                      top: 30,
                      right: 50,
                      child:
                          Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: _paywallAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '1',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                              .animate()
                              .scale(
                                begin: const Offset(0, 0),
                                end: const Offset(1, 1),
                                duration: const Duration(milliseconds: 420),
                                curve: Curves.elasticOut,
                              )
                              .fadeIn(
                                duration: const Duration(milliseconds: 220),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 3: value grid ───────────────────────────────────────────
  // "Here's everything you unlock" — a 4-item squircle-icon + text grid,
  // its own beat between the reminder and the price so the value recap
  // is fully legible (not squeezed as a background element) right before
  // the decision moment.
  Widget _buildIntroPageValue(ThemeColors colors) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, viewport) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: viewport.maxWidth - 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Text(
                    l10n.paywallValueReelKicker,
                    style: const TextStyle(
                      fontFamily: 'Barlow Condensed',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: _paywallAccent,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    l10n.paywallValueHeadline,
                    style: TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 28,
                      height: 1.08,
                      color: colors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06),
                  const SizedBox(height: 22),
                  // Vertical auto-scrolling value reel — replaces the old
                  // static 2×2 grid (4 features only). Same seamless-loop
                  // Ticker technique as the horizontal marquee on
                  // paywall_features_screen.dart, rotated to vertical with
                  // full-width cards so it reads as "everything unlocks",
                  // not just the headline four.
                  SizedBox(
                    height: 300,
                    child: _VerticalValueMarquee(
                      features: _valueMarqueeFeatures(l10n),
                      pixelsPerSecond: 16,
                      accent: _paywallAccent,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => _open(AppLinks.features),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.paywallValueSeeAllFeatures,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary,
                              decoration: TextDecoration.underline,
                              decorationColor: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Page 4: timeline + plans ─────────────────────────────────────
  Widget _buildIntroPageTimeline(
    ThemeColors colors,
    SubscriptionState subscriptionState,
  ) {
    final monthlyPrice = _getDynamicPrice(
      offerings: subscriptionState.offerings,
      productId: SubscriptionNotifier.premiumMonthlyId,
      fallback: '\$7.99',
    );
    final yearlyMonthly = _getMonthlyEquivalent(
      offerings: subscriptionState.offerings,
    );
    final yearlyTotal = _getDynamicPrice(
      offerings: subscriptionState.offerings,
      productId: SubscriptionNotifier.premiumYearlyId,
      fallback: '\$59.99',
    );
    final savings = _getSavingsPercent(offerings: subscriptionState.offerings);
    // No-scroll guarantee: scale the whole offer down to fit the page's
    // fixed viewport instead of scrolling past it to reach the CTA/legal
    // text — a no-op (scale 1.0) on phones tall enough to already fit,
    // a uniform shrink only on short ones. Same technique as the feature
    // marquee in paywall_features_screen.dart.
    return LayoutBuilder(
      builder: (context, viewport) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: viewport.maxWidth - 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Kicker carries the trial mechanics; the masthead leads with the
                  // real hook (nothing due today) instead of restating "free trial".
                  Text(
                    '7 DAYS · \$0.00 TODAY',
                    style: TextStyle(
                      fontFamily: 'Barlow Condensed',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: _paywallAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PAY NOTHING\nTODAY',
                    style: TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 34,
                      height: 1.02,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ⚡ N× FASTER comparison hero — VALUE-FIRST placement: the derived
                  // per-user multiplier hits immediately after the headline, before
                  // the trial-mechanics timeline and the plan tiles (Cal AI / Noom
                  // pattern: outcome before mechanics). Ships dark; the A/B treatment
                  // is the PostHog flag `paywall_goal_speed_comparison`. Degrades to a
                  // cited "~2× more likely" line when body metrics are missing.
                  if (_experiments.goalSpeedComparison) ...[
                    Builder(
                      builder: (context) {
                        final quiz = ref.read(preAuthQuizProvider);
                        final proj = GoalSpeedCalculator.compute(
                          currentWeightKg: quiz.weightKg ?? 0,
                          goalWeightKg: quiz.goalWeightKg ?? 0,
                          weightChangeRate: quiz.weightChangeRate,
                        );
                        return GoalSpeedComparison(
                          projection: proj,
                          colors: colors,
                          accent: _paywallAccent,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Trial mechanics as a compressed rail card — just the two
                  // moments that matter on THIS page (unlock, first charge).
                  // The day-5 reminder already got its own beat on page 2
                  // (_buildIntroPageReminder) — repeating "we remind you"
                  // here was flagged as redundant, so this card no longer
                  // restates it; the date is still covered by the OS
                  // notification the user opted into on that page.
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _RailStep(
                          filled: true,
                          title: 'Today — everything unlocks',
                          detail: 'Workouts, food scan, form check, coach.',
                          colors: colors,
                          accent: _paywallAccent,
                        ),
                        _RailStep(
                          filled: false,
                          isLast: true,
                          title: 'Day 7 — first charge',
                          monoTag:
                              '${_trialEndDateString().toUpperCase()} · CANCEL ANYTIME BEFORE',
                          colors: colors,
                          accent: _paywallAccent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Plan selection is driven entirely by the two cards below — no
                  // trial TOGGLE. Apple's Jan 2026 Guideline 3.1.2c enforcement
                  // rejects a switch that enables/disables a free trial (this is
                  // what Cal AI was pulled for in Apr 2026), independent of the copy
                  // around it. The yearly card carries the trial terms compliantly.
                  // Yearly is the HERO tile (highest LTV, research-default); monthly
                  // demotes to a quiet selectable row below.
                  // COMPLIANCE (Apple pulled Cal AI for the inverse, Apr 2026): the
                  // hero's Anton headline is the REAL billed amount ($59.99 /yr);
                  // the per-month equivalence is the small subtitle — never the
                  // other way around.
                  _YearlyHeroTile(
                    price: yearlyTotal,
                    perMonth: yearlyMonthly,
                    ribbon: '7 DAYS FREE · SAVE $savings%',
                    isSelected: _selectedBillingCycle == 'yearly',
                    onTap: () => _selectBillingCycle('yearly'),
                    colors: colors,
                    accent: _paywallAccent,
                  ),
                  const SizedBox(height: 8),
                  // COMPLIANCE: the row's price stays the REAL renewal price
                  // ($7.99/mo); the "$1 first month" intro is the small ribbon,
                  // never the other way around. ⚠️ Ribbon defaults ON for pre-launch
                  // VISUAL PREVIEW (flag `paywall_monthly_intro`, default TRUE —
                  // see paywall_experiments.dart). The `onboarding_intro_monthly`
                  // SKU does NOT exist yet, so checkout still charges $7.99 —
                  // build + wire the SKU before selling to real users.
                  _MonthlyRowTile(
                    title: AppLocalizations.of(context).xpGoalsMonthly,
                    price: monthlyPrice,
                    ribbon: _experiments.monthlyIntro
                        ? 'FIRST MONTH \$1'
                        : null,
                    isSelected: _selectedBillingCycle == 'monthly',
                    onTap: () => _selectBillingCycle('monthly'),
                    colors: colors,
                    accent: _paywallAccent,
                  ),
                  const SizedBox(height: 12),
                  // Trust strip — answers the three objections at a glance; the full
                  // legally-required disclosure follows below (Play policy requires
                  // the complete cancel/renewal terms adjacent to the CTA, so the
                  // chips supplement it, never replace it).
                  Row(
                    children: [
                      _TrustChip(label: 'CANCEL ANYTIME', colors: colors),
                      const SizedBox(width: 6),
                      _TrustChip(label: 'DAY-5 REMINDER', colors: colors),
                      const SizedBox(width: 6),
                      _TrustChip(label: '\$0 TODAY', colors: colors),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const InlineReferralExpander(),
                  const SizedBox(height: 8),
                  // App Store Guideline 3.1.2 + Google Play subscription policy:
                  // auto-renewal AND cancellation terms must be disclosed adjacent to
                  // the purchase CTA. Google Play rejects/deactivates paywalls that
                  // omit how-to-cancel + the trial→paid conversion terms, so on the
                  // trial path we state explicitly that cancelling before the trial
                  // ends means no charge.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _selectedBillingCycle == 'yearly'
                          ? 'Your 7-day free trial is free — cancel before it ends and '
                                'you won’t be charged. After the trial, the subscription '
                                'auto-renews at the price above unless cancelled at least '
                                '24 hours before the period ends. Cancel anytime in your '
                                'device account settings.'
                          : 'Subscription auto-renews at the price above unless '
                                'cancelled at least 24 hours before the end of the current '
                                'period. Cancel anytime in your device account settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _openTermsOfService,
                        child: Text(
                          AppLocalizations.of(context).paywallPricingTerms,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Text(
                        '  ·  ',
                        style: TextStyle(fontSize: 12, color: colors.textMuted),
                      ),
                      GestureDetector(
                        onTap: _openPrivacyPolicy,
                        child: Text(
                          AppLocalizations.of(context).settingsPrivacySection,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Single chokepoint for plan selection — used by both the trial toggle
  /// and the plan tiles so the analytics event fires identically.
  void _selectBillingCycle(String cycle) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedBillingCycle = cycle;
      _selectedPlan = cycle == 'yearly' ? 'premium_yearly' : 'premium_monthly';
    });
    ref
        .read(posthogServiceProvider)
        .capture(
          eventName: 'paywall_plan_selected',
          properties: {'plan_name': _selectedPlan, 'billing_cycle': cycle},
        );
  }

  void _handleMaybeLater(BuildContext context, WidgetRef ref) async {
    ref
        .read(posthogServiceProvider)
        .capture(
          eventName: 'paywall_skip_tapped',
          properties: {'has_shown_discount': _hasShownDiscount},
        );

    // 25% retention discount popup (soft-paywall exit intent). Gated on
    // the `premium_yearly_25off` SKU existing in Play Console + RevenueCat
    // — without it the discount path crashes with "Product not found".
    // PaywallExperiments.softPaywallExitOffer defaults to false for exactly
    // this reason; flip the PostHog flag `paywall_soft_exit_offer` on once
    // the SKU is live and this path activates with no code change.
    final retentionDiscountEnabled = _experiments.softPaywallExitOffer;
    if (retentionDiscountEnabled && !_hasShownDiscount) {
      _hasShownDiscount = true;
      ref
          .read(posthogServiceProvider)
          .capture(
            eventName: 'paywall_discount_shown',
            properties: {'discount_percent': 25},
          );
      final accepted = await _showDiscountPopup(context);
      if (accepted == true) {
        ref
            .read(posthogServiceProvider)
            .capture(
              eventName: 'paywall_discount_accepted',
              properties: {'discount_percent': 25},
            );
        // User accepted the 25% discount — purchase discounted yearly.
        // GUARD: if the `premium_yearly_25off` SKU isn't in the current
        // RevenueCat offering (it must be created in Play Console first),
        // fall back to the standard yearly product instead of crashing
        // with "Product not found".
        final offerings = ref.read(subscriptionProvider).offerings;
        final discountSkuAvailable =
            offerings?.current?.availablePackages.any(
              (p) => p.storeProduct.identifier == 'premium_yearly_25off',
            ) ??
            false;
        final discountSku = discountSkuAvailable
            ? 'premium_yearly_25off'
            : SubscriptionNotifier.premiumYearlyId;
        if (!discountSkuAvailable) {
          debugPrint(
            '⚠️ [Paywall] premium_yearly_25off missing from offerings — '
            'falling back to premium_yearly',
          );
        }
        final success = await ref
            .read(subscriptionProvider.notifier)
            .purchase(discountSku);
        if (success && context.mounted) {
          // Trial started — keep the day-5 reminder promise.
          unawaited(
            ref.read(notificationServiceProvider).scheduleTrialEndReminder(),
          );
          final isReturning =
              ref.read(authStateProvider).user?.isPaywallComplete ?? false;
          if (isReturning) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).paywallPricingYouReAllSet,
                ),
                behavior: SnackBarBehavior.floating,
              ),
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

    // "Maybe later" must be a true skip — no Google Play / App Store purchase
    // sheet. Earlier behavior auto-launched a `premium_yearly` purchase, which
    // surfaced the billing sheet; if the user dismissed it, the next-screen
    // navigation still ran. That looked like "skip → store popup → minimize →
    // app advances anyway" and also pulled trial activations from users who
    // never opted in. Keep skip cleanly free.
    ref
        .read(posthogServiceProvider)
        .capture(eventName: 'paywall_skipped_no_purchase', properties: {});

    // If this paywall view was triggered by the lapsed-user router branch
    // (see `_maybeRouteLapsedUser` in app_router.dart), fire a dedicated
    // dismiss event so the lifecycle funnel can measure winback conversion
    // separately from new-user paywall skips. The gate is "recent" if
    // marked within the last hour — anything older was a different session.
    final gateMs = ref.read(lapsedPaywallGateProvider);
    if (gateMs != null) {
      final ageMs = DateTime.now().millisecondsSinceEpoch - gateMs;
      if (ageMs < const Duration(hours: 1).inMilliseconds) {
        ref
            .read(posthogServiceProvider)
            .capture(
              eventName: 'paywall_routed_lapsed_user_dismissed',
              properties: {'age_ms_since_route': ageMs},
            );
      }
    }

    final isReturningUser =
        ref.read(authStateProvider).user?.isPaywallComplete ?? false;
    if (!context.mounted) return;
    if (isReturningUser) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } else {
      // New user — flag paywall complete so we don't loop them back here on
      // the next launch. Hard paywall on premium-gated features still kicks in.
      await _markPaywallComplete(ref);
      await _navigateAfterPaywall(context, ref);
    }
  }

  /// Mark the paywall done. The local state (auth notifier + the
  /// `paywall_completed` pref) is written synchronously so navigation can
  /// proceed immediately and a fast relaunch can't loop the user back here;
  /// the server PUT is fire-and-forget so "Maybe later" dismisses instantly
  /// instead of blocking on a `getUserId()` + PUT round-trip.
  Future<void> _markPaywallComplete(WidgetRef ref) async {
    ref.read(authStateProvider.notifier).markPaywallComplete();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('paywall_completed', true);
    } catch (e) {
      debugPrint('❌ [Paywall] Failed to persist paywall_completed pref: $e');
    }
    // Both onboarding + paywall complete — (re)schedule notifications.
    ref
        .read(notificationPreferencesProvider.notifier)
        .rescheduleNotifications();
    // Server sync is deferred: the local flag + hard paywall already gate
    // everything, so the UI never waits on this network call.
    unawaited(() async {
      try {
        final apiClient = ref.read(apiClientProvider);
        final userId = await apiClient.getUserId();
        if (userId != null) {
          await apiClient.put(
            '${ApiConstants.users}/$userId',
            data: {'paywall_completed': true},
          );
        }
        debugPrint('🔔 [Paywall] paywall_completed synced to server');
      } catch (e) {
        debugPrint('❌ [Paywall] Failed to update paywall_completed flag: $e');
      }
    }());
  }

  /// Navigate to subscription success screen after paywall completion
  Future<void> _navigateAfterPaywall(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!context.mounted) return;
    // EXPERIMENT (default OFF): when personal-info was moved to after the
    // paywall, collect name + DOB now (before the commitment pact). Otherwise
    // it was already collected pre-coach-selection.
    final user = ref.read(authStateProvider).user;
    if (OnboardingExperiments.personalInfoAfterPaywall &&
        user != null &&
        !user.isPersonalInfoComplete) {
      debugPrint('🎉 [Paywall] → /personal-info (post-paywall treatment)');
      context.go('/personal-info');
      return;
    }
    debugPrint('🎉 [Paywall] Navigating to commitment pact');
    context.go('/commitment-pact');
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

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    bool isSubscribed,
    SubscriptionTier currentTier,
  ) async {
    ref
        .read(posthogServiceProvider)
        .capture(
          eventName: 'paywall_cta_tapped',
          properties: {'selected_plan': _selectedPlan},
        );
    // If user is already subscribed, show plan change confirmation dialog
    if (isSubscribed && currentTier != SubscriptionTier.free) {
      final confirmed = await _showPlanChangeConfirmation(context, currentTier);
      if (confirmed != true) return;
    }

    ref
        .read(posthogServiceProvider)
        .capture(
          eventName: 'paywall_purchase_initiated',
          properties: {'selected_plan': _selectedPlan},
        );

    final success = await ref
        .read(subscriptionProvider.notifier)
        .purchase(_selectedPlan);
    // After awaiting purchase the user may have closed the paywall. Reading
    // `ref` after the State is disposed throws "Cannot use ref after dispose".
    // Guard with mounted before subsequent ref.read calls.
    if (!mounted) return;
    final isReturningUser =
        ref.read(authStateProvider).user?.isPaywallComplete ?? false;

    if (success && context.mounted) {
      // v7: yearly purchases start a 7-day trial — schedule the promised
      // day-5 reminder (one-off local notification, exact-ID replaceable).
      if (_selectedPlan.contains('yearly')) {
        unawaited(
          ref.read(notificationServiceProvider).scheduleTrialEndReminder(),
        );
      }
      if (isSubscribed || isReturningUser) {
        // Existing user upgrading — snackbar + go home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSubscribed
                  ? AppLocalizations.of(
                      context,
                    ).paywallPricingPlanUpdatedSuccessfully
                  : AppLocalizations.of(context).paywallPricingYouReAllSet,
            ),
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
      // Surface any error the subscription notifier set so users see *why* the
      // purchase didn't go through, instead of silently navigating away.
      final subState = ref.read(subscriptionProvider);
      final purchaseError = subState.error;
      if (purchaseError != null && purchaseError.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(purchaseError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (subState.wasCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase cancelled'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (isReturningUser) {
        // Returning user cancelled — just go back
        if (context.canPop()) context.pop();
      }
      // New user: no unsuccessful purchase (cancelled or failed) advances
      // them past the paywall anymore — they stay here and can retry, or
      // explicitly tap "Maybe later"/Skip to bypass it.
    }
  }

  /// Get plan details by plan ID
  Map<String, dynamic> _getPlanDetails(String planId) {
    switch (planId) {
      case 'premium_yearly':
        return {
          'name': 'Premium Yearly',
          'price': 59.99,
          'period': 'year',
          'monthlyPrice': 5.00,
        };
      case 'premium_yearly_discount':
        return {
          'name': 'Premium Yearly (Discounted)',
          'price': 47.99,
          'period': 'year',
          'monthlyPrice': 4.00,
        };
      case 'premium_monthly':
        return {
          'name': 'Premium Monthly',
          'price': 7.99,
          'period': 'month',
          'monthlyPrice': 7.99,
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
                state.subscriptionEndDate!.difference(DateTime.now()).inDays >
                    60
            ? 'premium_yearly'
            : 'premium_monthly';
      default:
        return 'free';
    }
  }

  /// Show plan change confirmation dialog
  Future<bool?> _showPlanChangeConfirmation(
    BuildContext context,
    SubscriptionTier currentTier,
  ) {
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context).paywallPricingYouAreAlreadyOn,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return Future.value(false);
    }

    // Calculate effective date (next billing cycle for downgrades, immediate for upgrades)
    final effectiveDate =
        isDowngrade && subscriptionState.subscriptionEndDate != null
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

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(subscriptionProvider.notifier)
        .restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? AppLocalizations.of(context).paywallPricingPurchasesRestored
                : AppLocalizations.of(context).paywallPricingNoPurchasesFound,
          ),
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
      await launchUrl(
        Uri.parse(AppLinks.termsOfService),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      await launchUrl(
        Uri.parse(AppLinks.privacyPolicy),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  Widget _buildPricingLeftPane(ThemeColors colors, bool isSubscribed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          isSubscribed
              ? AppLocalizations.of(context).paywallPricingChangePlan
              : AppLocalizations.of(context).paywallPricingYourAiCoach,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            height: 1.3,
          ),
        ),
        if (!isSubscribed)
          Text(
            AppLocalizations.of(context).paywallPricingIsReady,
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
              border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, size: 18, color: colors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).paywallPricing7DayFreeTrial2,
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
          AppLocalizations.of(context).paywallPricingWhatYouGet,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _LeftPaneFeature(
          icon: Icons.auto_fix_high,
          text: 'Unlimited AI workouts',
          colors: colors,
        ),
        const SizedBox(height: 6),
        _LeftPaneFeature(
          icon: Icons.camera_alt_outlined,
          text: 'Food photo scanning',
          colors: colors,
        ),
        const SizedBox(height: 6),
        _LeftPaneFeature(
          icon: Icons.restaurant_menu,
          text: 'Full nutrition tracking',
          colors: colors,
        ),
        const SizedBox(height: 6),
        _LeftPaneFeature(
          icon: Icons.local_fire_department,
          text: 'Hell Mode & supersets',
          colors: colors,
        ),
        const SizedBox(height: 6),
        _LeftPaneFeature(
          icon: Icons.healing_outlined,
          text: 'Injury-aware workouts',
          colors: colors,
        ),
        const SizedBox(height: 6),
        _LeftPaneFeature(
          icon: Icons.fitness_center,
          text: '52 skill progressions',
          colors: colors,
        ),
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
                  AppLocalizations.of(context).paywallPricingStartWithA7,
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

/// One tester quote on the founder page: a small feature-icon badge next
/// to the quote instead of a bare text block, so each testimonial reads as
/// proof of a specific capability rather than a generic "I like this app".
class _TesterQuoteCard extends StatelessWidget {
  final String quote;
  final String name;
  final IconData icon;
  final Color accent;
  final ThemeColors colors;
  final int animDelayMs;

  const _TesterQuoteCard({
    required this.quote,
    required this.name,
    required this.icon,
    required this.accent,
    required this.colors,
    required this.animDelayMs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: animDelayMs.ms).slideY(begin: 0.08);
  }
}

/// A single entry in the vertical value reel: icon + short title + one-line
/// benefit. First four entries reuse the existing localized copy (was the
/// static grid's only content); the rest are plain strings, matching the
/// precedent set by the horizontal marquee's `_Feat` list on
/// paywall_features_screen.dart (decorative feature-breadth copy isn't
/// localized there either).
typedef _ValueFeat = (IconData, String, String);

List<_ValueFeat> _valueMarqueeFeatures(AppLocalizations l10n) => [
  (Icons.auto_fix_high_rounded, l10n.paywallValueItem1Title, l10n.paywallValueItem1Sub),
  (Icons.restaurant_menu_rounded, l10n.paywallValueItem2Title, l10n.paywallValueItem2Sub),
  (Icons.videocam_outlined, l10n.paywallValueItem3Title, l10n.paywallValueItem3Sub),
  (Icons.chat_bubble_outline_rounded, l10n.paywallValueItem4Title, l10n.paywallValueItem4Sub),
  (Icons.timer_outlined, 'Fasting Tracker', 'Guided windows with live body-status'),
  (Icons.local_drink_outlined, 'Hydration Tracker', 'Daily water goal, logged in seconds'),
  (Icons.map_outlined, 'Muscle Heatmap', 'See exactly what you\'ve trained'),
  (Icons.mic_none_rounded, 'Voice Logging', 'Say your sets, hands stay free'),
  (Icons.receipt_long_outlined, 'Recipe Import', 'Paste any link, get full macros'),
  (Icons.healing_outlined, 'Injury-Safe Plans', 'Auto-routes around what hurts'),
  (Icons.psychology_outlined, 'AI Coach Personas', '5 coaching styles to choose from'),
  (Icons.battery_charging_full_rounded, 'Recovery Score', 'Know when to push or rest'),
  (Icons.view_week_outlined, 'Superset Builder', 'Stack exercises your way'),
  (Icons.watch_outlined, 'Wearable Sync', 'Apple Health & Health Connect'),
  (Icons.emoji_events_outlined, '52+ Skill Progressions', 'From first pull-up to muscle-up'),
  (Icons.insights_rounded, 'Progress Photos & Charts', 'Every metric, visualized'),
  (Icons.groups_rounded, 'Active Community', 'Friends, groups & challenges'),
  (Icons.tune_rounded, 'Fully Customizable', 'Build your own workouts, your way'),
];

/// One full-width card in the vertical value reel.
class _ValueMarqueeCard extends StatelessWidget {
  final _ValueFeat feat;
  final Color accent;
  final ThemeColors colors;

  const _ValueMarqueeCard({
    required this.feat,
    required this.accent,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(feat.$1, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  feat.$2,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feat.$3,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical sibling of the horizontal `_Marquee` on
/// paywall_features_screen.dart — same seamless-loop technique (a [Ticker]
/// advances a [ScrollController]; content is rendered twice back-to-back and
/// the offset wraps within one copy's extent so the loop has no visible
/// seam), rotated to scroll vertically with full-width cards instead of
/// pill chips. Replaces the old static 2×2 grid (4 features) so this page
/// surfaces everything a subscriber unlocks, not just the headline four.
class _VerticalValueMarquee extends StatefulWidget {
  final List<_ValueFeat> features;
  final double pixelsPerSecond;
  final Color accent;
  final ThemeColors colors;

  const _VerticalValueMarquee({
    required this.features,
    required this.pixelsPerSecond,
    required this.accent,
    required this.colors,
  });

  @override
  State<_VerticalValueMarquee> createState() => _VerticalValueMarqueeState();
}

class _VerticalValueMarqueeState extends State<_VerticalValueMarquee>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ScrollController _controller = ScrollController();
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    // Start after the first frame so the controller is attached and
    // maxScrollExtent is known.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ticker.start();
    });
  }

  /// Height of ONE list copy. Content is two identical copies stacked, so
  /// total content height is `maxScrollExtent + viewportDimension`; half of
  /// that is exactly one copy.
  double _oneCopyHeight() {
    final p = _controller.position;
    return (p.maxScrollExtent + p.viewportDimension) / 2;
  }

  void _onTick(Duration elapsed) {
    final dtMs = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_controller.hasClients) return;
    final oneCopy = _oneCopyHeight();
    if (oneCopy <= 0) return;

    var next = _controller.offset + widget.pixelsPerSecond * dtMs;
    // Seamless wrap: keep the offset within [0, oneCopy) so copy-1 and
    // copy-2 are visually interchangeable.
    if (next >= oneCopy) next -= oneCopy;
    _controller.jumpTo(next);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget listCopy() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final f in widget.features)
          _ValueMarqueeCard(feat: f, accent: widget.accent, colors: widget.colors),
      ],
    );

    // Edge fade: opaque in the middle, transparent at top/bottom, so cards
    // dissolve into the background for the "infinite rail" feel.
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: [0.0, 0.08, 0.92, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: ListView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [listCopy(), listCopy()],
      ),
    );
  }
}

/// Three-row reassurance strip rendered under the CTA. Mirrors the
/// "no commitment / reminder before charge / cancel anywhere" pattern
/// used by every top fitness paywall (Cal AI, Fastic, BetterMe, Lumen,
/// Headway, Centr). Stronger than a single muted line because each row
/// addresses a different objection on its own line with its own icon.
class _TrustStrip extends StatelessWidget {
  final ThemeColors colors;
  const _TrustStrip({required this.colors});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String)>[
      (Icons.lock_open_rounded, 'No commitment — cancel anytime'),
      (Icons.notifications_active_outlined, 'Reminder before your trial ends'),
      (Icons.payments_outlined, 'No charge today'),
      // "Yours forever" wedge — Apple-safe phrasing per Option C (export, not
      // free post-trial access). Settings → Export Data ships the CSV / JSON
      // export for Hevy, Strong, Fitbod, and generic targets, paywall-free.
      (
        Icons.file_download_outlined,
        'Your data is yours — export anytime, even after canceling',
      ),
    ];
    return Column(
      children: rows.map((r) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(r.$1, size: 14, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                r.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Intro-flow widgets — phone-frame mock, timeline node, plan tile.
// All defined in this file to keep the paywall as a single touch-point.
// ─────────────────────────────────────────────────────────────────────

/// Stylized iPhone bezel rendered fully in code (no asset). Wraps the
/// hero workout-card mock so page 1 reads as "this is the app" without
/// needing a screenshot file shipped in the bundle.
class _PhoneFrame extends StatelessWidget {
  final Widget child;
  final ThemeColors colors;
  const _PhoneFrame({required this.child, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 480,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Container(
          color: colors.background,
          child: Column(
            children: [
              // Status-bar / Dynamic Island stub.
              SizedBox(
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 18, top: 4),
                        child: Text(
                          '9:41',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    // Notch / Dynamic Island removed for a cleaner frame.
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-app workout-day card mock used on page 1. Stylized — not a real
/// screenshot — so it stays in sync with the app's visual language even
/// as the app evolves, with no asset to maintain.
class _WorkoutMockCard extends StatelessWidget {
  final ThemeColors colors;
  const _WorkoutMockCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).todayScoreCardToday,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context).paywallPricingPushDay,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _paywallAccent,
                  _paywallAccent.withValues(alpha: 0.78),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context).paywallPricingAi6Exercises,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context).paywallPricing45Min,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  AppLocalizations.of(
                    context,
                  ).paywallPricingChestShouldersTriceps,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ..._mockExerciseRows(colors),
          const Spacer(),
          // Quick stats strip — mimics the home dashboard chips.
          Row(
            children: [
              _miniStat(colors, '🔥', '2,148', 'kcal'),
              const SizedBox(width: 6),
              _miniStat(colors, '💪', '128g', 'protein'),
              const SizedBox(width: 6),
              _miniStat(colors, '🔁', '4', 'streak'),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _mockExerciseRows(ThemeColors colors) {
    final rows = const [
      ('Bench Press', '4 × 8'),
      ('Incline DB Press', '3 × 10'),
      ('Cable Fly', '3 × 12'),
    ];
    return rows
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _paywallAccent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    e.$2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _miniStat(
    ThemeColors colors,
    String emoji,
    String value,
    String label,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical timeline row (icon · connector · title + subtitle).
/// Renders one node. The connector to the next node is drawn inline so
/// users perceive the three steps as a continuous progression.
/// One row of the compressed trial-mechanics rail card: node dot + title,
/// optional detail line, optional Space Mono date tag. [filled] marks the
/// "you are here" node (accent, plus glyph); later steps are hollow.
class _RailStep extends StatelessWidget {
  final bool filled;
  final bool isLast;
  final String title;
  final String? detail;
  final String? monoTag;
  final ThemeColors colors;
  final Color accent;

  const _RailStep({
    required this.filled,
    this.isLast = false,
    required this.title,
    this.detail,
    this.monoTag,
    required this.colors,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsetsDirectional.only(end: 12, top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? accent : colors.surface,
              border: filled
                  ? null
                  : Border.all(color: colors.cardBorder, width: 2),
            ),
            child: filled
                ? Icon(Icons.add_rounded, size: 13, color: colors.background)
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: filled
                              ? colors.textPrimary
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                    if (monoTag != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          monoTag!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Space Mono',
                            fontSize: 9.5,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: colors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The yearly HERO plan tile: accent-bordered card with a floating savings
/// ribbon and the REAL billed amount as an Anton headline (compliance: the
/// per-month equivalence is the small subtitle, never the headline).
class _YearlyHeroTile extends StatelessWidget {
  final String price;
  final String perMonth;
  final String ribbon;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors colors;
  final Color accent;

  const _YearlyHeroTile({
    required this.price,
    required this.perMonth,
    required this.ribbon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.07)
                  : colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accent : colors.cardBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontFamily: 'Anton',
                        fontSize: 34,
                        height: 1,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ year',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '= $perMonth/MO',
                      style: TextStyle(
                        fontFamily: 'Space Mono',
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Yearly — 7 days free, then billed once a year.',
                  style: TextStyle(fontSize: 12.5, color: colors.textMuted),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            top: 0,
            start: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                ribbon,
                style: const TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Color(0xFF160B03),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The demoted monthly plan: a quiet single-row selectable tile. The price
/// shown is the REAL renewal price (compliance).
class _MonthlyRowTile extends StatelessWidget {
  final String title;
  final String price;
  final String? ribbon;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors colors;
  final Color accent;

  const _MonthlyRowTile({
    required this.title,
    required this.price,
    this.ribbon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.07) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : colors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            if (ribbon != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  ribbon!,
                  style: TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: accent,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              price,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            Text(
              ' /mo',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// One chip of the trust strip (CANCEL ANYTIME · DAY-5 REMINDER · $0 TODAY).
class _TrustChip extends StatelessWidget {
  final String label;
  final ThemeColors colors;

  const _TrustChip({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Barlow Condensed',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: colors.textMuted,
          ),
        ),
      ),
    );
  }
}
