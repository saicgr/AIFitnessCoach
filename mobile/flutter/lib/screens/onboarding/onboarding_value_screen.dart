import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import 'onboarding_experiments.dart';
import 'widgets/onboarding_theme.dart';

import '../../l10n/generated/app_localizations.dart';
/// Onboarding conversion v6 — price-anchor "value stack".
///
/// Shown right before the paywall. It stacks what the user would pay to
/// get Zealova's capabilities from separate apps, so the paywall price
/// lands small (classic price anchoring).
///
/// HONESTY / CURRENCY: competitor prices have no API and genuinely vary by
/// country, so they are shown as US App Store rates, USD, with a dated
/// source and an explicit, locale-aware footnote. Zealova's real price in
/// the user's local currency is shown on the very next screen (the
/// RevenueCat-backed paywall). Form analysis is presented as a Zealova
/// capability the comparison apps lack — not given a fabricated price.
class OnboardingValueScreen extends ConsumerStatefulWidget {
  const OnboardingValueScreen({super.key});

  static const String routePath = '/onboarding-value';
  static const String _nextRoute = '/paywall-pricing';

  @override
  ConsumerState<OnboardingValueScreen> createState() =>
      _OnboardingValueScreenState();
}

class _Competitor {
  final String category;
  final String example;
  final double monthlyUsd;
  final IconData icon;
  const _Competitor(this.category, this.example, this.monthlyUsd, this.icon);
}

class _OnboardingValueScreenState
    extends ConsumerState<OnboardingValueScreen> {
  // Competitor monthly prices verified 2026-05-21 via WebSearch:
  //   Fitbod $15.99/mo  — fitbod.me / Help Center
  //   MyFitnessPal Premium $19.99/mo — blog.myfitnesspal.com
  // All USD, US App Store. Re-verify quarterly; update the footnote date.
  static const List<_Competitor> _competitors = [
    _Competitor('AI workout generation', 'like Fitbod', 15.99,
        Icons.fitness_center_rounded),
    _Competitor('Calorie + macro tracking', 'like MyFitnessPal Premium',
        19.99, Icons.restaurant_rounded),
  ];

  // Zealova's headline US price. The paywall (next screen) shows the real
  // RevenueCat-localized price; this USD figure keeps the on-screen
  // comparison internally consistent (all USD).
  static const double _zealovaUsd = 7.99;

  static const String _verifiedDate = 'May 2026';

  double get _competitorsTotal =>
      _competitors.fold(0.0, (sum, c) => sum + c.monthlyUsd);

  @override
  void initState() {
    super.initState();
    _maybeSkip();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_value_viewed',
        );
  }

  Future<void> _maybeSkip() async {
    final enabled = await OnboardingExperiments.isEnabled(
      ref.read(posthogServiceProvider),
      OnboardingExperiments.flagValue,
    );
    if (!enabled && mounted) {
      context.go(OnboardingValueScreen._nextRoute);
    }
  }

  void _continue() {
    HapticFeedback.mediumImpact();
    context.go(OnboardingValueScreen._nextRoute);
  }

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = OnboardingTheme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final total = _competitorsTotal;
    final saving = total - _zealovaUsd;

    // Locale-aware honesty footnote — competitor prices are US rates.
    final country = (WidgetsBinding
                .instance.platformDispatcher.locale.countryCode ??
            '')
        .toUpperCase();
    final isUs = country.isEmpty || country == 'US';
    final footnote = isUs
        ? 'Competitor prices are US App Store rates, verified $_verifiedDate.'
        : 'Competitor prices are US App Store rates (USD, $_verifiedDate) '
            'and vary by country. Your Zealova price in local currency is '
            'on the next screen.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: OnboardingBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  Text(
                    AppLocalizations.of(context).onboardingValueThreeToolsOneApp,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: t.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context).onboardingValueHereSWhatThat,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: t.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 120.ms),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        // Competitor price rows.
                        for (var i = 0; i < _competitors.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CompetitorRow(
                              competitor: _competitors[i],
                              money: _money,
                            )
                                .animate()
                                .fadeIn(delay: (220 + i * 90).ms)
                                .slideX(begin: 0.05),
                          ),
                        const SizedBox(height: 4),
                        // Running total.
                        _TotalRow(
                          total: total,
                          reduceMotion: reduceMotion,
                          money: _money,
                        ).animate().fadeIn(delay: 440.ms),
                        const SizedBox(height: 18),
                        // The Zealova replacement card.
                        _ZealovaCard(
                          priceLabel: _money(_zealovaUsd),
                        ).animate().fadeIn(delay: 560.ms).slideY(begin: 0.06),
                        const SizedBox(height: 14),
                        // Saving line.
                        Center(
                          child: Text(
                            'That is ${_money(saving)} less every month.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: t.selectionAccent,
                            ),
                          ),
                        ).animate().fadeIn(delay: 680.ms),
                        const SizedBox(height: 12),
                        Text(
                          footnote,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: t.textMuted,
                          ),
                        ).animate().fadeIn(delay: 760.ms),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ValueContinueButton(onTap: _continue)
                      .animate()
                      .fadeIn(delay: 820.ms)
                      .slideY(begin: 0.1),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One competitor row — category, example app, monthly price.
class _CompetitorRow extends StatelessWidget {
  final _Competitor competitor;
  final String Function(double) money;
  const _CompetitorRow({required this.competitor, required this.money});

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.textMuted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(competitor.icon, size: 20, color: t.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competitor.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  competitor.example,
                  style: TextStyle(fontSize: 12, color: t.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${money(competitor.monthlyUsd)}/mo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: t.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The summed competitor total, with an animated count-up (skipped when
/// the OS has reduce-motion enabled).
class _TotalRow extends StatelessWidget {
  final double total;
  final bool reduceMotion;
  final String Function(double) money;
  const _TotalRow({
    required this.total,
    required this.reduceMotion,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context).onboardingValueSeparateApps,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: t.textSecondary,
          ),
        ),
        reduceMotion
            ? Text(
                '${money(total)}/mo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: t.textPrimary,
                ),
              )
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: total),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '${money(value)}/mo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: t.textPrimary,
                  ),
                ),
              ),
      ],
    );
  }
}

/// The Zealova replacement card — one price, all three capabilities,
/// including the form analysis the comparison apps do not offer.
class _ZealovaCard extends StatelessWidget {
  final String priceLabel;
  const _ZealovaCard({required this.priceLabel});

  static const List<String> _includes = [
    'AI workout generation',
    'Calorie + macro tracking, from a food photo',
    'AI form analysis, which neither app above offers',
  ];

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.onboardingAccent.withValues(alpha: 0.16),
            AppColors.onboardingAccent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.onboardingAccent.withValues(alpha: 0.45),
          width: 1.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).onboardingValueZealovaAllOfIt,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: t.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Text(
                '$priceLabel/mo',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onboardingAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in _includes)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 17, color: t.selectionAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
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

class _ValueContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ValueContinueButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).onboardingValueSeeMyPlanAnd,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.onboardingAccent, Color(0xFFFF6B00)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.onboardingAccent.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).onboardingValueSeeMyPlan,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
