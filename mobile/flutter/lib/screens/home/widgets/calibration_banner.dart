import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';

/// "Coach is learning you — first {N} days" banner on Home for new accounts.
///
/// Reviewer transcripts (DC Rainmaker, Quantified Scientist) flagged the
/// 7-day calibration period as a pain point in Google Health Coach —
/// users churn because early insights feel dumb. We surface what's getting
/// calibrated so the dumbness is framed as "learning, not broken."
///
/// Self-collapses to zero height when:
///   * `user.createdAt` is more than `_kCalibrationWindow` ago
///   * user has tapped the dismiss `×`
///   * `user.createdAt` is unavailable (no spam on indeterminate state)
class CalibrationBanner extends ConsumerStatefulWidget {
  const CalibrationBanner({super.key});

  /// 7-day calibration window. Matches the "first week" framing used
  /// across Whoop, Fitbit, and Garmin calibration UX.
  static const Duration _kCalibrationWindow = Duration(days: 7);

  /// SharedPreferences key for the dismiss flag. Per-install, not per-user
  /// — once a user dismisses the banner it stays dismissed even if they
  /// sign out and back in. Re-shown on a fresh install.
  static const String _kDismissedKey = 'calibration_banner_dismissed';

  @override
  ConsumerState<CalibrationBanner> createState() =>
      _CalibrationBannerState();
}

class _CalibrationBannerState extends ConsumerState<CalibrationBanner> {
  bool _dismissed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dismissed = prefs.getBool(CalibrationBanner._kDismissedKey) ?? false;
      _loaded = true;
    });
  }

  Future<void> _onDismiss() async {
    setState(() => _dismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CalibrationBanner._kDismissedKey, true);
    } catch (_) {
      // Non-fatal — banner is gone in-memory; will reappear next launch.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();

    final user = ref.watch(authStateProvider).user;
    final createdAtStr = user?.createdAt;
    if (createdAtStr == null || createdAtStr.isEmpty) {
      return const SizedBox.shrink();
    }

    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(createdAtStr);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final age = DateTime.now().difference(createdAt);
    if (age >= CalibrationBanner._kCalibrationWindow) {
      // Past calibration window — banner self-collapses without state change.
      return const SizedBox.shrink();
    }

    final daysLeft = CalibrationBanner._kCalibrationWindow.inDays - age.inDays;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cyan.withValues(alpha: 0.32),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.20),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coach is learning you — $daysLeft ${daysLeft == 1 ? "day" : "days"} left',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColorsLight.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Calibrating: resting HR baseline · HRV baseline · sleep pattern · training intensity. '
                    'Insights get sharper as data comes in.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColorsLight.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary,
              ),
              onPressed: _onDismiss,
              tooltip: 'Dismiss',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
