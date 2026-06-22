import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/services/health_service.dart';
import '../../widgets/health_connect_sheet.dart';
import '../ai_settings/ai_settings_screen.dart';
import 'onboarding_experiments.dart';

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

  /// `onboarding_hc_walkthrough` kill-switch (default ON, fail-open). Shows an
  /// animated mock of the OS permission sheet so users know which toggle to
  /// flip — Gravl-style. Flip the flag off to hide.
  bool _showWalkthrough = true;

  String get _platformName =>
      Platform.isAndroid ? 'Health Connect' : 'Apple Health';

  @override
  void initState() {
    super.initState();
    OnboardingExperiments.isEnabled(
      ref.read(posthogServiceProvider),
      OnboardingExperiments.flagHcWalkthrough,
    ).then((on) {
      if (mounted && !on) setState(() => _showWalkthrough = false);
    });
  }

  /// Prefs flag flips the moment the screen finishes (connect or skip), so
  /// the post-paywall chain never re-shows it.
  ///
  /// Also marks the Health-Connect primer as seen so the home auto-popup
  /// (`_maybeShowHealthConnectPopup`) doesn't re-prompt for the same
  /// connection immediately after onboarding — the primer here already gave
  /// the user the connect/skip choice. Manual "Connect Health" chip taps
  /// elsewhere still open the sheet on demand.
  Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(HealthConnectOnboardingScreen.prefsKey, true);
    await markHealthPrimerSeen();
  }

  /// Connect the platform health store AND record the Art. 9 server-storage
  /// consent. Whatever the outcome, the user is routed onward — onboarding
  /// is never trapped behind an OS permission grant.
  Future<void> _connect() async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);
    HapticFeedback.mediumImpact();

    // Capture context-bound objects BEFORE the async gaps so we never touch
    // a possibly-unmounted BuildContext after awaiting.
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    ref
        .read(posthogServiceProvider)
        .capture(eventName: 'onboarding_health_connect_tapped');

    var connectedOk = false;
    String? failureMessage;
    try {
      final notifier = ref.read(healthSyncProvider.notifier);
      final available = await notifier.checkAvailability();
      if (available) {
        final connected = await notifier.connect();
        if (connected) {
          connectedOk = true;
          // Wearable connected on-device — record the explicit opt-in so
          // the backend may store it server-side for the AI coach.
          await ref
              .read(aiSettingsProvider.notifier)
              .updateHealthDataConsent(true);
          ref.read(dailyActivityProvider.notifier).loadTodayActivity();
          ref
              .read(posthogServiceProvider)
              .capture(eventName: 'onboarding_health_connect_succeeded');
        } else {
          // The platform sheet failed to grant (or never presented). Surface
          // it instead of silently advancing (feedback_no_silent_fallbacks) so
          // the user knows the connection didn't take and can retry or skip.
          final err = ref.read(healthSyncProvider).error;
          debugPrint('health-connect onboarding: not connected — ${err ?? '(no error reported)'}');
          failureMessage = Platform.isAndroid
              ? l10n.healthConnectOnboardingHealthConnectIsnT
              : "Couldn't connect Apple Health. Open the Health app ▸ Sharing ▸ Apps ▸ Zealova to allow access, then try again.";
        }
      } else {
        failureMessage = Platform.isAndroid
            ? l10n.healthConnectOnboardingHealthConnectIsnT
            : 'Apple Health is unavailable on this device.';
      }
    } catch (e) {
      debugPrint('health-connect onboarding: connect failed: $e');
      failureMessage =
          'Something went wrong connecting $_platformName. You can try again, or set it up later in Settings.';
    }

    if (!mounted) return;
    setState(() => _isConnecting = false);

    if (connectedOk) {
      await _markShown();
      router.go('/permissions-primer');
    } else if (failureMessage != null) {
      // Stay on the screen — the "Maybe later" button still lets them skip,
      // so this surfaces the problem without trapping onboarding.
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  Future<void> _skip() async {
    HapticFeedback.lightImpact();
    ref
        .read(posthogServiceProvider)
        .capture(eventName: 'onboarding_health_connect_skipped');
    await _markShown();
    if (!mounted) return;
    context.go('/permissions-primer');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    const accent = AppColors.purple;

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
                          AppLocalizations.of(
                            context,
                          ).healthConnectOnboardingUnlockYourAiHealth,
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
                        if (_showWalkthrough) ...[
                          const SizedBox(height: 24),
                          _PermissionSheetWalkthrough(
                            platformName: _platformName,
                            isAndroid: Platform.isAndroid,
                            accent: accent,
                            isDark: isDark,
                          ).animate().fadeIn(delay: 320.ms, duration: 450.ms),
                          const SizedBox(height: 8),
                          Text(
                            "When you tap below, you'll see this — turn on "
                            'access and you\'re done.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textSecondary,
                              height: 1.35,
                            ),
                          ).animate().fadeIn(delay: 420.ms),
                        ],
                        const SizedBox(height: 32),
                        _BenefitRow(
                              icon: Icons.bedtime_rounded,
                              title: AppLocalizations.of(
                                context,
                              ).healthConnectOnboardingSleepCoaching,
                              subtitle:
                                  'A morning briefing and specific tips on the nights you sleep poorly.',
                              accent: accent,
                              isDark: isDark,
                            )
                            .animate()
                            .fadeIn(delay: 350.ms)
                            .slideX(begin: -0.05, end: 0, duration: 300.ms),
                        const SizedBox(height: 16),
                        _BenefitRow(
                              icon: Icons.fitness_center_rounded,
                              title: AppLocalizations.of(
                                context,
                              ).healthConnectOnboardingRecoveryAwareWorkouts,
                              subtitle:
                                  'Your training auto-adjusts when recovery is low — lighter days exactly when you need them.',
                              accent: accent,
                              isDark: isDark,
                            )
                            .animate()
                            .fadeIn(delay: 450.ms)
                            .slideX(begin: -0.05, end: 0, duration: 300.ms),
                        const SizedBox(height: 16),
                        _BenefitRow(
                              icon: Icons.auto_awesome_rounded,
                              title: AppLocalizations.of(
                                context,
                              ).healthConnectOnboardingACoachThatSees,
                              subtitle:
                                  'Your AI coach factors in sleep, steps, heart rate and recovery — and spots patterns across them.',
                              accent: accent,
                              isDark: isDark,
                            )
                            .animate()
                            .fadeIn(delay: 550.ms)
                            .slideX(begin: -0.05, end: 0, duration: 300.ms),
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
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: textSecondary,
                      ),
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
                              valueColor: AlwaysStoppedAnimation(Colors.white),
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

/// A looping, hand-built mock of the OS health-permission sheet (Health
/// Connect on Android / Apple Health on iOS). The master "Allow all" toggle
/// animates on with a pulsing highlight ring so the user knows exactly which
/// control to flip when the real sheet appears. No video asset, no screenshot.
class _PermissionSheetWalkthrough extends StatefulWidget {
  const _PermissionSheetWalkthrough({
    required this.platformName,
    required this.isAndroid,
    required this.accent,
    required this.isDark,
  });

  final String platformName;
  final bool isAndroid;
  final Color accent;
  final bool isDark;

  @override
  State<_PermissionSheetWalkthrough> createState() =>
      _PermissionSheetWalkthroughState();
}

class _PermissionSheetWalkthroughState
    extends State<_PermissionSheetWalkthrough>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Eased on-fraction for the master toggle: ramps on, holds, ramps off so
  /// the loop reads as "watch it turn on" without a jarring reset.
  double _toggleOn(double t) {
    if (t < 0.20) return 0;
    if (t < 0.45) return Curves.easeInOut.transform((t - 0.20) / 0.25);
    if (t < 0.85) return 1;
    return 1 - Curves.easeInOut.transform((t - 0.85) / 0.15);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sheetBg = isDark ? const Color(0xFF161420) : Colors.white;
    final rowText = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final subtext = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final frameBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final on = _toggleOn(t);
        // Two soft pulses per loop around the master toggle.
        final pulse = (0.5 + 0.5 * math.sin(t * 2 * math.pi * 2)).toDouble();

        return Center(
          child: Container(
            width: 250,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: frameBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 18,
                      color: widget.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Allow Zealova to access ${widget.platformName}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: rowText,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Master "Allow all" row with the pulsing highlight ring.
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity:
                              (0.45 * pulse) * (1 - on).clamp(0.0, 1.0) + 0.12,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.accent,
                                width: 1.5 + 1.5 * pulse,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: widget.accent.withValues(
                          alpha: 0.10 + 0.10 * on,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            widget.isAndroid ? 'Allow all' : 'Turn On All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: rowText,
                            ),
                          ),
                          const Spacer(),
                          _MiniToggle(value: on, accent: widget.accent),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._rows().map(
                  (label) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(fontSize: 12.5, color: subtext),
                          ),
                        ),
                        // Child rows follow the master with a tiny lag.
                        _MiniToggle(
                          value: (on - 0.15).clamp(0.0, 1.0) / 0.85,
                          accent: widget.accent,
                          small: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _rows() => widget.isAndroid
      ? const ['Exercise', 'Sleep', 'Heart rate', 'Steps']
      : const ['Workouts', 'Sleep', 'Heart Rate', 'Steps'];
}

/// Tiny iOS/Android-style toggle whose knob slides as [value] goes 0→1 and
/// whose track tints to [accent] when on.
class _MiniToggle extends StatelessWidget {
  const _MiniToggle({
    required this.value,
    required this.accent,
    this.small = false,
  });

  final double value; // 0..1
  final Color accent;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final w = small ? 36.0 : 42.0;
    final h = small ? 21.0 : 24.0;
    final knob = h - 6;
    final track = Color.lerp(
      Colors.grey.withValues(alpha: 0.45),
      accent,
      value,
    )!;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(h / 2),
      ),
      child: Align(
        alignment: Alignment(-1 + 2 * value, 0),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            width: knob,
            height: knob,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
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
      child: Icon(Icons.monitor_heart_rounded, color: accent, size: 56),
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
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
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
