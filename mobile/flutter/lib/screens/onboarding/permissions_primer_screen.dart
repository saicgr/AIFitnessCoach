import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/services/notification_service.dart';

/// Unified pre-permission rationale screen for the four most-used
/// runtime permissions: camera, photos, microphone, and notifications.
/// Replaces the previous two-screen flow (NotificationPrimeScreen +
/// PermissionsPrimerScreen) that made users sit through two separate
/// "explainer + grant" pages back to back.
///
/// Shown ONCE post-onboarding (after commit-pact). Prefs flag flips
/// the moment the screen is shown, regardless of which buttons get
/// tapped — skipping is fine, individual features will re-prompt on
/// first use if granted permissions were denied here.
///
/// We DO NOT request location or Health Connect here. Location is
/// request-on-feature (gym auto-switch). Health Connect has its own
/// onboarding screen.
class PermissionsPrimerScreen extends ConsumerStatefulWidget {
  const PermissionsPrimerScreen({super.key});

  static const String prefsKey = 'permissions_primer_shown';
  static const String routePath = '/permissions-primer';

  @override
  ConsumerState<PermissionsPrimerScreen> createState() =>
      _PermissionsPrimerScreenState();
}

class _PermissionsPrimerScreenState
    extends ConsumerState<PermissionsPrimerScreen> {
  bool _isRequesting = false;

  Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PermissionsPrimerScreen.prefsKey, true);
    // Mirror the legacy notification-prime flag too so the home-screen
    // post-frame redirect (which still checks both flags as a guard)
    // never tries to bounce the user to the deprecated standalone
    // notification screen after this unified primer has run.
    await prefs.setBool('notification_prime_shown', true);
  }

  /// Walks Camera → Photos → Microphone in sequence. We deliberately ask
  /// in a fixed order (Camera first since it's the most-used feature) so
  /// the OS prompts feel coherent, not interleaved.
  Future<void> _grantAll() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    HapticFeedback.mediumImpact();

    ref.read(posthogServiceProvider).capture(
      eventName: 'permissions_primer_grant_tapped',
    );

    // permission_handler's .request() returns the new status. We don't
    // care about the outcome here — we surface real rationale at the
    // feature site (food camera, voice button) if they later deny.
    try {
      await Permission.camera.request();
    } catch (e) {
      debugPrint('Camera permission request failed: $e');
    }
    try {
      // Android 13+ uses READ_MEDIA_IMAGES (Permission.photos);
      // older Android maps this to READ_EXTERNAL_STORAGE under the hood.
      await Permission.photos.request();
    } catch (e) {
      debugPrint('Photos permission request failed: $e');
    }
    try {
      await Permission.microphone.request();
    } catch (e) {
      debugPrint('Microphone permission request failed: $e');
    }
    // Notifications — last in the sequence so the user has already
    // tapped through the media OS prompts before iOS shows its
    // "Allow notifications?" sheet. Routing through
    // NotificationService.requestPermissionWhenReady() keeps the
    // Firebase Messaging listener wiring identical to the legacy
    // NotificationPrimeScreen, so push delivery + tap-to-deeplink
    // still work without a separate post-grant init step.
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.requestPermissionWhenReady();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }

    await _markShown();
    if (!mounted) return;
    // Route directly to home — the home-screen post-frame logic only
    // bounces to /notifications-prime when its prefs flag is unset,
    // and by the time the user reaches this primer the notification
    // screen has already run as part of the commit-pact → home chain.
    // The previous `context.go('/notifications-prime')` here caused
    // users to see the notification screen twice.
    context.go('/home');
  }

  Future<void> _skip() async {
    HapticFeedback.lightImpact();
    ref.read(posthogServiceProvider).capture(
      eventName: 'permissions_primer_skipped',
    );
    await _markShown();
    if (!mounted) return;
    // Route directly to home — the home-screen post-frame logic only
    // bounces to /notifications-prime when its prefs flag is unset,
    // and by the time the user reaches this primer the notification
    // screen has already run as part of the commit-pact → home chain.
    // The previous `context.go('/notifications-prime')` here caused
    // users to see the notification screen twice.
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = isDark ? AppColors.cyan : AppColorsLight.cyan;

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
                  child: SingleChildScrollView(
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
                          'A few quick permissions',
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
                          'Granting these now means features just work — no surprise prompts mid-workout.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                        const SizedBox(height: 32),
                        _BenefitRow(
                          icon: Icons.camera_alt_rounded,
                          title: 'Camera',
                          subtitle:
                              'Snap a meal to log it instantly, scan barcodes, or capture progress photos.',
                          accent: accent,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 350.ms).slideX(
                              begin: -0.05,
                              end: 0,
                              duration: 300.ms,
                            ),
                        const SizedBox(height: 16),
                        _BenefitRow(
                          icon: Icons.photo_library_rounded,
                          title: 'Photos',
                          subtitle:
                              'Pick existing meal photos and progress shots from your library.',
                          accent: accent,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 450.ms).slideX(
                              begin: -0.05,
                              end: 0,
                              duration: 300.ms,
                            ),
                        const SizedBox(height: 16),
                        _BenefitRow(
                          icon: Icons.mic_rounded,
                          title: 'Microphone',
                          subtitle:
                              'Talk to your AI coach hands-free and dictate quick food + workout notes.',
                          accent: accent,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 550.ms).slideX(
                              begin: -0.05,
                              end: 0,
                              duration: 300.ms,
                            ),
                        const SizedBox(height: 16),
                        _BenefitRow(
                          icon: Icons.notifications_active_rounded,
                          title: 'Notifications',
                          subtitle:
                              'Workout reminders, weekly check-ins, and a heads-up before your trial ends.',
                          accent: accent,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 650.ms).slideX(
                              begin: -0.05,
                              end: 0,
                              duration: 300.ms,
                            ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _grantAll,
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
                            'Grant permissions',
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
                  Platform.isIOS
                      ? 'Each app feature will explain itself before asking the OS.'
                      : 'You can change these anytime in Settings.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
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
        Icons.shield_moon_rounded,
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
