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
/// Shown COLLAPSED by default (a slim one-line pill with a learning-progress
/// ring around the icon); tap to expand the per-signal breakdown. The collapse
/// state persists per-install.
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
  /// banner once the account is this old (30 days) — at that point "still
  /// learning" reads as "broken", and the per-signal detail lives in Vitals
  /// anyway.
  static const Duration _kMaxBannerAge = Duration(days: 30);

  /// SharedPreferences key for the dismiss flag. Per-install, not per-user
  /// — once a user dismisses the banner it stays dismissed even if they
  /// sign out and back in. Re-shown on a fresh install.
  static const String _kDismissedKey = 'calibration_banner_dismissed';

  /// SharedPreferences key for the collapse flag (per-install). Defaults to
  /// collapsed so the card starts as an unobtrusive one-liner.
  static const String _kCollapsedKey = 'calibration_banner_collapsed';

  @override
  ConsumerState<CalibrationBanner> createState() => _CalibrationBannerState();
}

class _CalibrationBannerState extends ConsumerState<CalibrationBanner> {
  bool _dismissed = false;
  bool _collapsed = true; // minimized by default
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dismissed = prefs.getBool(CalibrationBanner._kDismissedKey) ?? false;
      // Default true → starts collapsed until the user chooses to expand.
      _collapsed = prefs.getBool(CalibrationBanner._kCollapsedKey) ?? true;
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

  Future<void> _toggleCollapsed() async {
    final next = !_collapsed;
    setState(() => _collapsed = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CalibrationBanner._kCollapsedKey, next);
    } catch (_) {
      // Non-fatal — in-memory toggle stands for this session.
    }
  }

  /// The AI icon wrapped in a learning-progress ring (readyCount / totalCount).
  Widget _iconWithRing(int ready, int total) {
    final progress = total > 0 ? (ready / total).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              backgroundColor: AppColors.cyan.withValues(alpha: 0.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.cyan),
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withValues(alpha: 0.20),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: AppColors.cyan,
            ),
          ),
        ],
      ),
    );
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

    final ready = status.readyCount;
    final total = status.totalCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: _collapsed
            ? const EdgeInsets.fromLTRB(12, 8, 8, 8)
            : const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cyan.withValues(alpha: 0.32),
            width: 1,
          ),
        ),
        child: _collapsed
            ? _buildCollapsed(status, textPrimary, textSecondary, ready, total)
            : _buildExpanded(status, textPrimary, textSecondary, ready, total),
      ),
    );
  }

  /// Slim one-line pill: progress-ring icon + title + N/M + expand chevron.
  /// Tapping anywhere expands.
  Widget _buildCollapsed(
    CalibrationStatus status,
    Color textPrimary,
    Color textSecondary,
    int ready,
    int total,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleCollapsed,
      child: Row(
        children: [
          _iconWithRing(ready, total),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Coach is learning you',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
          Text(
            '$ready/$total',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.cyan,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 22, color: textSecondary),
        ],
      ),
    );
  }

  /// Full breakdown: ring icon + per-signal rows + footer, with a collapse
  /// chevron and the permanent-dismiss ×.
  Widget _buildExpanded(
    CalibrationStatus status,
    Color textPrimary,
    Color textSecondary,
    int ready,
    int total,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconWithRing(ready, total),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ready > 0
                    ? 'Coach is learning you — $ready of $total baselines ready'
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
                          color: sig.isReady ? AppColors.cyan : textSecondary,
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
        // Collapse to the slim pill (lighter action) …
        IconButton(
          icon: Icon(Icons.keyboard_arrow_up_rounded,
              size: 20, color: textSecondary),
          onPressed: _toggleCollapsed,
          tooltip: 'Minimize',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          visualDensity: VisualDensity.compact,
        ),
        // … or dismiss for good.
        IconButton(
          icon: Icon(Icons.close_rounded, size: 18, color: textSecondary),
          onPressed: _onDismiss,
          tooltip: 'Dismiss',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
