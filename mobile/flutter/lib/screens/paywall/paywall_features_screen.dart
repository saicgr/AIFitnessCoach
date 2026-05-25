import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/services/posthog_service.dart';
import '../onboarding/widgets/foldable_quiz_scaffold.dart';
import 'paywall_experiments.dart';
import 'widgets/credibility_strip.dart';

import '../../l10n/generated/app_localizations.dart';
/// Paywall Screen 1: Feature Highlights
/// Shows the key features users get with premium
class PaywallFeaturesScreen extends ConsumerStatefulWidget {
  const PaywallFeaturesScreen({super.key});

  @override
  ConsumerState<PaywallFeaturesScreen> createState() =>
      _PaywallFeaturesScreenState();
}

class _PaywallFeaturesScreenState
    extends ConsumerState<PaywallFeaturesScreen> {
  // A/B-experiment state. Starts at the shipped treatment default and is
  // replaced once the PostHog flags resolve.
  PaywallExperiments _experiments = PaywallExperiments.treatmentDefaults;

  @override
  void initState() {
    super.initState();
    // Track the screen view and resolve the paywall A/B experiments once
    // (the old build-time microtask fired on every rebuild).
    Future.microtask(() async {
      final posthog = ref.read(posthogServiceProvider);
      posthog.capture(eventName: 'paywall_features_viewed');
      final exp = await loadPaywallExperiments(
        posthog,
        surface: 'soft_paywall',
      );
      if (mounted) setState(() => _experiments = exp);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);
    final windowState = ref.watch(windowModeProvider);
    final isFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: '',
          headerExtra: _buildPremiumSummary(colors),
          content: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Show title inline only on phone
                if (!isFoldable) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: colors.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.fitness_center,
                          size: 36,
                          color: colors.accentContrast,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).paywallFeaturesUnlockTheFull,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).paywallFeaturesAiCoachExperience,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (isFoldable) const SizedBox(height: 8),

                // Feature list
                _FeatureItem(icon: Icons.auto_fix_high, iconColor: colors.purple, title: AppLocalizations.of(context).paywallFeaturesUnlimitedAiWorkouts, subtitle: AppLocalizations.of(context).paywallFeaturesPersonalizedPlansForAny, colors: colors),
                const SizedBox(height: 14),
                _FeatureItem(icon: Icons.chat_bubble_outline, iconColor: colors.electricBlue, title: AppLocalizations.of(context).paywallFeaturesAiCoachChat, subtitle: AppLocalizations.of(context).paywallFeaturesNutritionFormRecoveryAs, colors: colors),
                const SizedBox(height: 14),
                _FeatureItem(icon: Icons.camera_alt_outlined, iconColor: colors.orange, title: AppLocalizations.of(context).paywallFeaturesFoodPhotoScanning, subtitle: AppLocalizations.of(context).paywallFeaturesSnapAPhotoGet, colors: colors),
                const SizedBox(height: 14),
                _FeatureItem(icon: Icons.healing_outlined, iconColor: colors.coral, title: AppLocalizations.of(context).paywallFeaturesInjuryAwareTraining, subtitle: AppLocalizations.of(context).paywallFeaturesAutoAdaptWorkoutsAround, colors: colors),
                const SizedBox(height: 14),
                _FeatureItem(icon: Icons.bar_chart_rounded, iconColor: Colors.greenAccent, title: AppLocalizations.of(context).paywallFeaturesProgressTrackingAnalytics, subtitle: AppLocalizations.of(context).paywallFeaturesChartsHeatmapsAndDetailed, colors: colors),
                const SizedBox(height: 14),
                _FeatureItem(icon: Icons.local_fire_department, iconColor: const Color(0xFFE74C3C), title: 'Hell Mode & skill progressions', subtitle: 'Push past every plateau', colors: colors),

                // Credibility strip — methodology + technology trust that
                // needs no traction data; auto-upgrades to real rating /
                // testimonials once SocialProofConfig is populated.
                if (_experiments.credibilityStrip) ...[
                  const SizedBox(height: 22),
                  PaywallCredibilityStrip(
                    colors: colors,
                    accent: colors.accent,
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
          button: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.push('/paywall-timeline'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.accentContrast,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context).paywallFeaturesLearnMore,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSummary(ThemeColors colors) {
    final categories = [
      (icon: Icons.fitness_center, label: AppLocalizations.of(context).paywallFeaturesAiWorkouts, count: AppLocalizations.of(context).paywallFeatures14Features),
      (icon: Icons.restaurant_rounded, label: AppLocalizations.of(context).settingsNutritionSection, count: AppLocalizations.of(context).paywallFeatures3Tools),
      (icon: Icons.healing_outlined, label: AppLocalizations.of(context).paywallFeaturesSafety, count: AppLocalizations.of(context).paywallFeaturesInjuryAware),
      (icon: Icons.trending_up, label: AppLocalizations.of(context).navProgress, count: AppLocalizations.of(context).paywallFeatures52Skills),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Centered app icon
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: colors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.fitness_center,
                  size: 32,
                  color: colors.accentContrast,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          AppLocalizations.of(context).paywallFeaturesUnlockTheFull,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        Text(
          AppLocalizations.of(context).paywallFeaturesAiCoachExperience,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.accent,
          ),
        ),
        const SizedBox(height: 20),

        // Feature category cards
        ...categories.map((cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(cat.icon, size: 18, color: colors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      cat.count,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),

        // Trial callout
        Container(
          padding: const EdgeInsets.all(12),
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
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final ThemeColors colors;

  const _FeatureItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

