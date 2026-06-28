import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../settings/nutrition_import_screen.dart';

import '../../l10n/generated/app_localizations.dart';

/// OPTIONAL onboarding step — "Coming from another app? Import your history".
///
/// Surfaced (when [kNutritionImportOnboardingEnabled] is on) in the post-paywall
/// chain right after the Health-Connect step:
///   health-connect-onboarding → THIS → permissions-primer → home
///
/// CRITICAL — this step NEVER gates onboarding:
///   • A prominent Skip (top-right close + bottom button) always advances
///     straight to `/permissions-primer`.
///   • Tapping a source deep-links into the existing, fully-cancellable
///     importer ([NutritionImportScreen]); whatever the user does there (finish
///     or back out), control returns here and onboarding auto-advances. The
///     importer surfaces its own success/error UI, so the import result is
///     never coupled to signup completion.
class OnboardingNutritionImportScreen extends ConsumerStatefulWidget {
  const OnboardingNutritionImportScreen({super.key});

  static const String routePath = '/onboarding-nutrition-import';

  @override
  ConsumerState<OnboardingNutritionImportScreen> createState() =>
      _OnboardingNutritionImportScreenState();
}

class _OnboardingImportSource {
  const _OnboardingImportSource({
    required this.id,
    required this.label,
    required this.icon,
  });
  final String id; // matches NutritionImportScreen's source ids
  final String label;
  final IconData icon;
}

const _kOnboardingSources = <_OnboardingImportSource>[
  _OnboardingImportSource(
      id: 'myfitnesspal',
      label: 'MyFitnessPal',
      icon: Icons.local_dining_outlined),
  _OnboardingImportSource(
      id: 'macrofactor',
      label: 'MacroFactor',
      icon: Icons.insights_outlined),
  _OnboardingImportSource(
      id: 'cronometer',
      label: 'Cronometer',
      icon: Icons.pie_chart_outline),
  _OnboardingImportSource(
      id: 'apple_health',
      label: 'Apple Health',
      icon: Icons.favorite_outline),
];

class _OnboardingNutritionImportScreenState
    extends ConsumerState<OnboardingNutritionImportScreen> {
  static const String _nextRoute = '/permissions-primer';
  static const Color _accent = AppColors.purple; // matches the HC step accent

  bool _advancing = false;

  /// Advance onward in the onboarding chain. Idempotent — guards against a
  /// double-tap or a source-return racing with a manual Skip.
  void _advance() {
    if (_advancing || !mounted) return;
    _advancing = true;
    context.go(_nextRoute);
  }

  void _skip() {
    HapticFeedback.lightImpact();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_nutrition_import_skipped',
        );
    _advance();
  }

  Future<void> _pickSource(_OnboardingImportSource source) async {
    HapticFeedback.lightImpact();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_nutrition_import_source_tapped',
          properties: {'source': source.id},
        );
    // Deep-link into the existing importer with this source preselected. It is
    // fully cancellable and shows its own result UI, so onboarding is never
    // blocked on its outcome.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NutritionImportScreen(initialSourceId: source.id),
      ),
    );
    // Whatever happened in the importer, continue onboarding.
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.pureBlack, const Color(0xFF120A1A)]
                : [AppColorsLight.pureWhite, const Color(0xFFF6F2FA)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Top bar: a clear Skip escape hatch, always visible.
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      AppLocalizations.of(context).onboardingSkip,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        const _Illustration(accent: _accent)
                            .animate()
                            .scale(
                              duration: 400.ms,
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                            )
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 28),
                        Text(
                          'Coming from another app?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                        const SizedBox(height: 12),
                        Text(
                          'Import your history so your trends, streaks and '
                          'coaching start full, not from zero. Optional, and '
                          'you can always do it later in Settings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                        const SizedBox(height: 28),
                        for (var i = 0; i < _kOnboardingSources.length; i++) ...[
                          _SourceCard(
                            source: _kOnboardingSources[i],
                            accent: _accent,
                            isDark: isDark,
                            onTap: () => _pickSource(_kOnboardingSources[i]),
                          )
                              .animate()
                              .fadeIn(delay: (340 + i * 90).ms)
                              .slideY(begin: 0.08, end: 0, duration: 300.ms),
                          if (i < _kOnboardingSources.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final _OnboardingImportSource source;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(source.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  source.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.04),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.move_to_inbox_rounded, color: accent, size: 56),
    );
  }
}
