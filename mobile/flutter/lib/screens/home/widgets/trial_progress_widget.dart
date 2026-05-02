import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';

/// Trial Progress Widget — Onboarding v5
///
/// Persistent home-screen module shown only during the 7-day trial.
/// Reads from /subscriptions/trial-status-v5 (user-aware, lightweight).
/// Anchors the goal date in the user's daily view, builds loss aversion
/// over the trial, and provides a continuous "Day X / 7" reminder.
///
/// Hides itself silently when:
///   - User isn't in trial
///   - Subscription paused
///   - Trial ended
class TrialProgressWidget extends ConsumerStatefulWidget {
  const TrialProgressWidget({super.key});

  @override
  ConsumerState<TrialProgressWidget> createState() =>
      _TrialProgressWidgetState();
}

class _TrialProgressWidgetState extends ConsumerState<TrialProgressWidget> {
  Map<String, dynamic>? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/subscriptions/trial-status-v5');
      if (mounted) {
        setState(() {
          _status = response.data as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } on DioException catch (_) {
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_status == null) return const SizedBox.shrink();

    final inTrial = _status?['is_in_trial'] == true;
    final isPaused = _status?['is_paused'] == true;
    if (!inTrial || isPaused) return const SizedBox.shrink();

    final dayOfTrial = _status?['day_of_trial'] as int? ?? 1;
    final daysRemaining = _status?['days_remaining'] as int? ?? 0;
    final goalDate = _status?['goal_target_date'] as String?;
    final progress = (dayOfTrial / 7).clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.onboardingAccent.withValues(alpha: 0.12),
            const Color(0xFFFF6B00).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onboardingAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.onboardingAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'TRIAL · DAY $dayOfTrial / 7',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              if (daysRemaining > 0)
                Text(
                  daysRemaining == 1
                      ? '1 day left'
                      : '$daysRemaining days left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.onboardingAccent.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.onboardingAccent,
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.05),
          if (goalDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.flag_rounded,
                    size: 16, color: AppColors.onboardingAccent),
                const SizedBox(width: 6),
                Text(
                  'Goal: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                Text(
                  _formatGoalDate(goalDate),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatGoalDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
