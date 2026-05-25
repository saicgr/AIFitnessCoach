import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/services/health_service.dart';
import '../ai_settings/ai_settings_screen.dart';

import '../../l10n/generated/app_localizations.dart';
/// Health Connect / Apple Health onboarding step.
///
/// Shown once, post-paywall, in the `context.go` chain:
///   commitment-pact → THIS → permissions-primer → home
///
/// It sells the recovery / sleep-coaching features, connects the platform
/// health store, and captures the GDPR Art. 9 explicit opt-in to store that
/// data on Zealova's servers (`health_data_consent`) — without which the AI
/// coach, the sleep/health history screens and proactive coaching all stay
/// empty. `permissions_primer_screen.dart` defers to this screen by design
/// ("Health Connect has its own onboarding screen").
///
/// The screen's body copy explicitly states the data is stored on Zealova's
/// servers for coaching and can be turned off anytime — so tapping the
/// primary CTA is an informed, explicit, affirmative opt-in (the "dedicated
/// opt-in flow" `updateHealthDataConsent` is designed for). Skipping is
/// allowed; the user can still connect later from Settings → Health Sync.
class HealthConnectOnboardingScreen extends ConsumerStatefulWidget {
  const HealthConnectOnboardingScreen({super.key});

  static const String prefsKey = 'health_connect_onboarding_shown';
  static const String routePath = '/health-connect-onboarding';

  @override
  ConsumerState<HealthConnectOnboardingScreen> createState() =>
      _HealthConnectOnboardingScreenState();
}

class _HealthConnectOnboardingScreenState
    extends ConsumerState<HealthConnectOnboardingScreen> {
  bool _isConnecting = false;

  String get _platformName =>
      Platform.isAndroid ? 'Health Connect' : 'Apple Health';

  /// Prefs flag flips the moment the screen finishes (connect or skip), so
  /// the post-paywall chain never re-shows it.
  Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(HealthConnectOnboardingScreen.prefsKey, true);
  }

  /// Connect the platform health store AND record the Art. 9 server-storage
  /// consent. Whatever the outcome, the user is routed onward — onboarding
  /// is never trapped behind an OS permission grant.
  Future<void> _connect() async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);
    HapticFeedback.mediumImpact();

    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_health_connect_tapped',
        );

    try {
      final notifier = ref.read(healthSyncProvider.notifier);
      final available = await notifier.checkAvailability();
      if (available) {
        final connected = await notifier.connect();
        if (connected) {
          // Wearable connected on-device — record the explicit opt-in so
          // the backend may store it server-side for the AI coach.
          await ref
              .read(aiSettingsProvider.notifier)
              .updateHealthDataConsent(true);
          ref.read(dailyActivityProvider.notifier).loadTodayActivity();
          ref.read(posthogServiceProvider).capture(
                eventName: 'onboarding_health_connect_succeeded',
              );
        }
      } else if (mounted && Platform.isAndroid) {
        // Health Connect app not installed — don't trap the user; they
        // can connect later from Settings → Health Sync.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).healthConnectOnboardingHealthConnectIsnT),
          ),
        );
      }
    } catch (e) {
      debugPrint('health-connect onboarding: connect failed: $e');
    }

    await _markShown();
    if (!mounted) return;
    context.go('/permissions-primer');
  }

  Future<void> _skip() async {
    HapticFeedback.lightImpact();
    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_health_connect_skipped',
        );
    await _markShown();
    if (!mounted) return;
    context.go('/permissions-primer');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    const accent = AppColors.purple;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
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
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        const _Illustration(accent: accent)
                            .animate()
                            .scale(
                              duration: 400.ms,
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                            )
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 32),
                        Text(
                          AppLocalizations.of(context).healthConnectOnboardingUnlockYourAiHealth,
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
                          'Connect $_platformName so Zealova can turn your '
                          'sleep, recovery and activity into real coaching.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                        const SizedBox(height: 32),
                        _BenefitRow(
                          icon: Icons.bedtime_rounded,
                          title: AppLocalizations.of(context).healthConnectOnboardingSleepCoaching,
                          subtitle:
                              'A morning briefing and specific tips on the nights you sleep poorly.',
                          accent: accent,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 350.ms).slideX(
                              begin: -0.05,
                              end: 0,
                              duration: 300.ms,
                            ),
                        const SizedBox(height: 16),
                        _BenefitRow(
                          icon: Icons.fitness_center_rounded,
                          title: AppLocalizations.of(context).healthConnectOnboardingRecoveryAwareWorkouts,
                          subtitle:
                              'Your training auto-adjusts when recovery is low — lighter days exactly when you need them.',
                          accent: accent,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 450.ms).slideX(
                              begin: -0.05,
                              end: 0,
                              duration: 300.ms,
                            ),
                        const SizedBox(height: 16),
                        _BenefitRow(
                          icon: Icons.auto_awesome_rounded,
                          title: AppLocalizations.of(context).healthConnectOnboardingACoachThatSees,
                          subtitle:
                              'Your AI coach factors in sleep, steps, heart rate and recovery — and spots patterns across them.',
                          accent: accent,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 550.ms).slideX(
                              begin: -0.05,
                              end: 0,
                              duration: 300.ms,
                            ),
                      ],
                    ),
                  ),
                ),
                // Art. 9 informed-consent statement — the explicit opt-in is
                // the affirmative tap on the primary CTA directly below.
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 14, color: textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connecting securely stores this health data on '
                          "Zealova's servers so your AI coach can use it. "
                          'You can turn it off anytime in Settings.',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isConnecting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Connect $_platformName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isConnecting ? null : _skip,
                  child: Text(
                    AppLocalizations.of(context).notifsLaterButton,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
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
      child: Icon(
        Icons.monitor_heart_rounded,
        color: accent,
        size: 56,
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.35,
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
