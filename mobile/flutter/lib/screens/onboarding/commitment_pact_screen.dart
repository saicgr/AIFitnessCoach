import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/services/api_client.dart';
import 'founder_note_sheet.dart';

/// Commitment Pact Screen — Onboarding v5
///
/// Post-paywall, pre-home. Shows the user's Week 1 schedule and asks them
/// to commit. The commitment-consistency principle (Cialdini): users who
/// publicly commit to a plan have 8-12% higher follow-through. Tapping
/// "I'm in" persists `commitment_pact_accepted=true` to the backend.
class CommitmentPactScreen extends ConsumerStatefulWidget {
  const CommitmentPactScreen({super.key});

  @override
  ConsumerState<CommitmentPactScreen> createState() =>
      _CommitmentPactScreenState();
}

class _CommitmentPactScreenState extends ConsumerState<CommitmentPactScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-warm today's workout while the user reads + commits. The home
    // screen normally hits /workouts/today on first mount, which triggers
    // a 5–15s Gemini generation if no plan exists yet — that's the
    // "Generating workout…" placeholder users were seeing on home. By
    // kicking the same fetch off here (post-paywall, ~2 screens ahead of
    // home), generation overlaps with the commit-pact + notifications-
    // prime + founder-note time on screen, so by the time the user lands
    // on home the workout is already cached. Cache-first on home means
    // the placeholder never shows.
    //
    // Why HERE (not earlier): post-paywall ensures we don't burn Gemini
    // quota on free-tier abandons. Why not later: anything past
    // notifications-prime is too close to home — generation needs the
    // full 5–15s lead time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        ref.read(todayWorkoutProvider);
      } catch (e) {
        debugPrint('commitment-pact: pre-warm failed (non-fatal): $e');
      }
    });
  }

  Future<void> _commit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    HapticFeedback.heavyImpact();

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch(
        '/users/me',
        data: {
          'commitment_pact_accepted': true,
          'commitment_pact_accepted_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Non-fatal — backend mirror is best-effort.
      debugPrint('commitment-pact: backend write failed: $e');
    }

    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_commitment_pact_accepted',
        );

    // Onboarding v5.1: post-paid-conversion founder note (Airbnb pattern).
    // Strongest commitment moment in the funnel — they just paid AND
    // committed. The note here lands harder than at first-login. One-time
    // via `seen_founder_note_subscriber`; no-ops if user already saw the
    // new-user trigger.
    if (mounted) {
      await FounderNoteSheet.showAfterConversion(context);
    }

    if (mounted) context.go('/notifications-prime');
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                'One last thing.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 6),
              Text(
                'Can you commit to week 1?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 150.ms).slideY(begin: -0.1),
              const SizedBox(height: 6),
              Text(
                "We'll handle the plan — you handle showing up.",
                style: TextStyle(fontSize: 15, color: textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 28),

              // Week 1 schedule preview
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: const [
                    _DayPactRow(
                      delay: 450,
                      day: 'Mon',
                      label: 'Upper Body Push',
                      duration: '45 min',
                    ),
                    SizedBox(height: 8),
                    _DayPactRow(
                      delay: 600,
                      day: 'Tue',
                      label: 'Active recovery',
                      duration: '15 min',
                      isLight: true,
                    ),
                    SizedBox(height: 8),
                    _DayPactRow(
                      delay: 750,
                      day: 'Wed',
                      label: 'Lower Body',
                      duration: '50 min',
                    ),
                    SizedBox(height: 8),
                    _DayPactRow(
                      delay: 900,
                      day: 'Thu',
                      label: 'Rest',
                      duration: 'Recovery',
                      isLight: true,
                    ),
                    SizedBox(height: 8),
                    _DayPactRow(
                      delay: 1050,
                      day: 'Fri',
                      label: 'Upper Body Pull',
                      duration: '45 min',
                    ),
                    SizedBox(height: 8),
                    _DayPactRow(
                      delay: 1200,
                      day: 'Sat',
                      label: 'Full Body',
                      duration: '50 min',
                    ),
                  ],
                ),
              ),

              // Pact CTA
              GestureDetector(
                onTap: _submitting ? null : _commit,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _submitting
                          ? [
                              AppColors.onboardingAccent.withValues(alpha: 0.6),
                              AppColors.onboardingAccent.withValues(alpha: 0.4),
                            ]
                          : const [
                              AppColors.onboardingAccent,
                              Color(0xFFFF6B00)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.onboardingAccent.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "I'm in",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 22),
                            ],
                          ),
                  ),
                ),
              ).animate(delay: 1400.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _submitting
                    ? null
                    : () => context.go('/notifications-prime'),
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPactRow extends StatelessWidget {
  final int delay;
  final String day;
  final String label;
  final String duration;
  final bool isLight;

  const _DayPactRow({
    required this.delay,
    required this.day,
    required this.label,
    required this.duration,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLight
              ? (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
              : AppColors.onboardingAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isLight ? textSecondary : AppColors.onboardingAccent,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          Text(
            duration,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 350.ms).slideX(begin: 0.05);
  }
}
