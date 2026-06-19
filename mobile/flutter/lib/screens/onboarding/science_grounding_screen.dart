import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/science_citations.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/citation_link.dart';
import '../../widgets/glass_back_button.dart';
import 'widgets/onboarding_theme.dart';

/// Science-grounding screen — "Your plan is built on real science"
/// (Authority/citations, Pattern 1, 2026-06).
///
/// Sits post fitness-assessment, pre `/capability-and-community`, gated by the
/// default-OFF `onboarding_science_screen` experiment flag (so it is dark in
/// prod until the A/B is turned on — see [OnboardingExperiments.scienceScreen]
/// and `fitness_assessment_screen.dart`'s forward navigation).
///
/// HONESTY POLICY (CLAUDE.md): every claim shown traces to a verifiable
/// [ScienceCitation] the user can tap through to the primary source. These are
/// methodology claims ("our plans use progressive overload"), never an outcome
/// promise about Zealova — which is what keeps them defensible under FTC
/// substantiation rules and Apple 3.1.2.
class ScienceGroundingScreen extends ConsumerStatefulWidget {
  const ScienceGroundingScreen({super.key});

  static const String routePath = '/science-grounding';

  @override
  ConsumerState<ScienceGroundingScreen> createState() =>
      _ScienceGroundingScreenState();
}

class _ScienceGroundingScreenState
    extends ConsumerState<ScienceGroundingScreen> {
  /// The three methodology citations surfaced here. `safeRate` is deliberately
  /// skipped — it lives next to the weight-projection safe-rate cap.
  static const List<ScienceCitation> _citations = [
    ScienceCitations.progressiveOverload,
    ScienceCitations.protein,
    ScienceCitations.selfMonitoring,
  ];

  @override
  void initState() {
    super.initState();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_science_grounding_viewed',
        );
  }

  void _continue() {
    HapticFeedback.mediumImpact();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_science_grounding_completed',
        );
    context.go('/capability-and-community');
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassBackButton(
                    // Mirror weight_projection_screen: pop if we can, else
                    // fall back to the real predecessor GoRoute. We arrive here
                    // via context.go from fitness-assessment, so canPop() is
                    // false → /fitness-assessment (a registered route).
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/fitness-assessment');
                      }
                    },
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 20),

                // ── Header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: t.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.science_outlined,
                          color: t.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your plan is built on real science',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: t.textPrimary,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No fads, no fabricated stats — just the methods the '
                    'research actually backs. Tap any source to read it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: t.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // ── Citation cards
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _citations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      return _ScienceCard(
                        citation: _citations[i],
                        theme: t,
                      )
                          .animate()
                          .fadeIn(
                            delay: (300 + i * 120).ms,
                            duration: 400.ms,
                          )
                          .slideY(begin: 0.08);
                    },
                  ),
                ),

                // ── CTA
                _ContinueButton(theme: t, onTap: _continue)
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 400.ms)
                    .slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single methodology card: plain-language claim + a tappable primary source.
class _ScienceCard extends StatelessWidget {
  final ScienceCitation citation;
  final OnboardingTheme theme;

  const _ScienceCard({required this.citation, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.verified_outlined,
                  size: 18,
                  color: theme.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  citation.claim,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: CitationLink(
              citation: citation,
              accent: theme.accent,
              leading: 'Source: ',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Orange-gradient primary CTA, matching the other onboarding screens.
class _ContinueButton extends StatelessWidget {
  final OnboardingTheme theme;
  final VoidCallback onTap;

  const _ContinueButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        margin: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: theme.buttonGradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.accent.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Makes sense',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: theme.buttonText,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded,
                  color: theme.buttonText, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
