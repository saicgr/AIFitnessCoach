import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/daily_coach_insight_provider.dart';
import '../../../data/repositories/auth_repository.dart';

/// "Coach is learning you" banner on Home for new accounts.
///
/// Reviewer transcripts (DC Rainmaker, Quantified Scientist) flagged the
/// 7-day calibration period as a pain point in Google Health Coach —
/// users churn because early insights feel dumb. We surface what's getting
/// calibrated so the dumbness is framed as "learning, not broken."
///
/// Progress is REAL: the server's `calibration_status` (daily-insight
/// payload) reports per-signal days-of-data vs what the readiness/vitals/
/// training-load services actually require before their baselines are
/// trustworthy — not an account-age countdown.
///
/// Self-collapses to zero height when:
///   * every baseline is ready (`all_ready`)
///   * the server payload has no calibration status (no spam on
///     indeterminate state — includes loading/error)
///   * user has tapped the dismiss `×`
///   * the account is older than [_kMaxBannerAge] (safety valve so users
///     who never sync a wearable aren't nagged forever)
class CalibrationBanner extends ConsumerStatefulWidget {
  const CalibrationBanner({super.key});

  /// Hard stop: however incomplete the baselines are, stop showing the
  /// banner once the account is this old — at that point "still learning"
  /// reads as "broken", and the per-signal detail lives in Vitals anyway.
  static const Duration _kMaxBannerAge = Duration(days: 30);

  /// SharedPreferences key for the dismiss flag. Per-install, not per-user
  /// — once a user dismisses the banner it stays dismissed even if they
  /// sign out and back in. Re-shown on a fresh install.
  static const String _kDismissedKey = 'calibration_banner_dismissed';

  @override
  ConsumerState<CalibrationBanner> createState() => _CalibrationBannerState();
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

  static const Map<String, String> _signalLabels = {
    'resting_hr': 'Resting HR baseline',
    'hrv': 'HRV baseline',
    'sleep': 'Sleep pattern',
    'training_intensity': 'Training intensity',
  };

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();

    // Safety valve: never show past 30 days of account age.
    final createdAtStr = ref.watch(authStateProvider).user?.createdAt;
    if (createdAtStr == null || createdAtStr.isEmpty) {
      return const SizedBox.shrink();
    }
    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null ||
        DateTime.now().difference(createdAt) >=
            CalibrationBanner._kMaxBannerAge) {
      return const SizedBox.shrink();
    }

    // Real per-signal progress from the server. Hidden while loading, on
    // error, when the payload omits it, and once every baseline is ready.
    final status = ref
        .watch(dailyCoachInsightProvider)
        .valueOrNull
        ?.calibrationStatus;
    if (status == null || status.allReady) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

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
                    status.readyCount > 0
                        ? 'Coach is learning you — '
                              '${status.readyCount} of ${status.totalCount} '
                              'baselines ready'
                        : 'Coach is learning you',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final sig in status.signals)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Icon(
                            sig.isReady
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 13,
                            color: sig.isReady
                                ? AppColors.cyan
                                : textSecondary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _signalLabels[sig.key] ?? sig.key,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Text(
                            sig.isReady
                                ? 'Ready'
                                : sig.hasNoData
                                ? 'Waiting for data'
                                : '${sig.daysCollected}/${sig.daysNeeded} days',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sig.isReady
                                  ? AppColors.cyan
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    'Insights get sharper as data comes in.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: textSecondary),
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
