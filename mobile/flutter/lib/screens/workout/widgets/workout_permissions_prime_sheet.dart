import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';

/// Soft pre-permission sheet shown at the start of the user's first workout.
///
/// Voice (microphone) and Bluetooth (Nearby Devices on Android) system prompts
/// may appear during a workout if the user uses voice commands or an auto-
/// connecting BLE heart rate monitor. This sheet explains that context before
/// the system prompts fire, so users aren't caught off guard mid-set.
///
/// Shown at most once per install — flag stored at [prefsKey].
class WorkoutPermissionsPrimeSheet extends StatelessWidget {
  const WorkoutPermissionsPrimeSheet({super.key});

  /// SharedPreferences flag — set to true once the sheet is dismissed.
  static const String prefsKey = 'workout_permissions_prime_shown';

  /// Show the sheet if it hasn't been shown yet. Returns when dismissed.
  /// Call this at the start of an active workout before BLE auto-reconnect or
  /// speech init. Resolves immediately (no sheet) if already shown or if the
  /// caller context is no longer mounted.
  static Future<void> maybeShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(prefsKey) ?? false) return;
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const WorkoutPermissionsPrimeSheet(),
    );

    // Only mark shown after the user explicitly dismissed, not on route pop.
    await prefs.setBool(prefsKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = isDark ? AppColors.orange : AppColorsLight.orange;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: textSecondary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Two quick heads-ups',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ).animate().fadeIn(duration: 250.ms),
            const SizedBox(height: 6),
            Text(
              'You may see these system prompts during your workout. Both are optional — skip either and the workout still works.',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 250.ms),
            const SizedBox(height: 20),
            _PermissionRow(
              icon: Icons.mic_rounded,
              title: 'Microphone',
              subtitle:
                  'Tap the mic mid-set to ask questions or log notes by voice.',
              accent: accent,
              isDark: isDark,
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 12),
            _PermissionRow(
              icon: Icons.bluetooth_searching_rounded,
              title: 'Nearby devices',
              subtitle:
                  'Lets us auto-connect a BLE heart-rate strap if one is nearby.',
              accent: accent,
              isDark: isDark,
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Got it, let\u2019s go',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 20),
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
