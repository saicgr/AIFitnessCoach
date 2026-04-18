import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/services/notification_service.dart';

/// Pre-permission screen explaining *why* we use notifications, shown once
/// after paywall / onboarding and before landing on /home. The OS prompt only
/// fires if the user opts in on this screen — matching the iOS-standard
/// "soft prompt → hard prompt" pattern used by Duolingo, Noom, MyFitnessPal, etc.
///
/// Once the user chooses either "Enable" or "Not now", [prefsKey] flips to
/// true and the screen never shows again. Dismissal navigates to /home.
class NotificationPrimeScreen extends ConsumerStatefulWidget {
  const NotificationPrimeScreen({super.key});

  /// Set to `true` after the user has seen this screen (regardless of choice).
  /// Checked by the home-screen gate to avoid showing it on every launch.
  static const String prefsKey = 'notification_prime_shown';

  @override
  ConsumerState<NotificationPrimeScreen> createState() =>
      _NotificationPrimeScreenState();
}

class _NotificationPrimeScreenState
    extends ConsumerState<NotificationPrimeScreen> {
  bool _isRequesting = false;

  Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPrimeScreen.prefsKey, true);
  }

  Future<void> _enable() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    HapticFeedback.mediumImpact();

    ref.read(posthogServiceProvider).capture(
      eventName: 'notification_prime_enable_tapped',
    );

    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.requestPermissionWhenReady();
    } catch (e) {
      debugPrint('Failed to request notification permission: $e');
    }

    await _markShown();
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _skip() async {
    HapticFeedback.lightImpact();
    ref.read(posthogServiceProvider).capture(
      eventName: 'notification_prime_skipped',
    );
    await _markShown();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = isDark ? AppColors.orange : AppColorsLight.orange;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.pureBlack, const Color(0xFF0A0A1A)]
                : [AppColorsLight.pureWhite, const Color(0xFFF5F5FA)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const SizedBox(height: 24),
                        _Illustration(accent: accent)
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
                          'Stay on track with gentle reminders',
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
                          'Turn on notifications so FitWiz can coach you when it matters most.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                        const SizedBox(height: 32),
                        _BenefitRow(
                          icon: Icons.fitness_center_rounded,
                          title: 'Workout reminders',
                          subtitle:
                              'A quick nudge on your training days so you never miss a session.',
                          accent: accent,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 350.ms).slideX(
                              begin: -0.05,
                              end: 0,
                              duration: 300.ms,
                            ),
                        const SizedBox(height: 16),
                        _BenefitRow(
                          icon: Icons.local_fire_department_rounded,
                          title: 'Streak saves',
                          subtitle:
                              'We\u2019ll warn you before your streak breaks — never lose progress.',
                          accent: accent,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 450.ms).slideX(
                              begin: -0.05,
                              end: 0,
                              duration: 300.ms,
                            ),
                        const SizedBox(height: 16),
                        _BenefitRow(
                          icon: Icons.emoji_events_rounded,
                          title: 'PR celebrations',
                          subtitle:
                              'Get celebrated the moment you hit a new personal record.',
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
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _enable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isRequesting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Enable notifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isRequesting ? null : _skip,
                  child: Text(
                    'Not now',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can change this anytime in Settings.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary.withOpacity(0.7),
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
          colors: [accent.withOpacity(0.18), accent.withOpacity(0.04)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.notifications_active_rounded,
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
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.03);

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
              color: accent.withOpacity(0.15),
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
