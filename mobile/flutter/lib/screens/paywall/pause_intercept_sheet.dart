import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/services/api_client.dart';

/// Pause Intercept Sheet — Onboarding v5
///
/// Shown when user taps cancel during trial or active sub. Industry data:
/// 22% of would-be cancellers accept a pause. Of those, 41% eventually
/// convert. Net 9% absolute lift in retained subscribers.
///
/// Usage: invoke from cancel button before showing the $47.99 retention
/// offer or actual cancellation. Result distinguishes:
///   PauseInterceptResult.paused14
///   PauseInterceptResult.paused30
///   PauseInterceptResult.proceedToCancel  (user explicitly skipped pause)
class PauseInterceptSheet extends ConsumerStatefulWidget {
  final String userId;
  const PauseInterceptSheet({super.key, required this.userId});

  static Future<PauseInterceptResult> show(
      BuildContext context, String userId) async {
    final result = await showModalBottomSheet<PauseInterceptResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PauseInterceptSheet(userId: userId),
    );
    return result ?? PauseInterceptResult.dismissed;
  }

  @override
  ConsumerState<PauseInterceptSheet> createState() =>
      _PauseInterceptSheetState();
}

class _PauseInterceptSheetState extends ConsumerState<PauseInterceptSheet> {
  bool _submitting = false;

  Future<void> _pause(int days, PauseInterceptResult result) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    HapticFeedback.heavyImpact();

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/subscriptions/${widget.userId}/pause',
        data: {
          'duration_days': days,
          'reason': 'pre_cancel_intercept',
        },
      );
      ref.read(posthogServiceProvider).capture(
            eventName: 'pause_intercept_accepted',
            properties: {'duration_days': days},
          );
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      // Surface a snackbar — don't crash the cancel flow
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't pause: $e")),
        );
        Navigator.of(context).pop(PauseInterceptResult.proceedToCancel);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : AppColorsLight.elevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          AppColors.onboardingAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pause_circle_outline_rounded,
                        color: AppColors.onboardingAccent, size: 36),
                  ).animate().scale(duration: 350.ms),

                  const SizedBox(height: 16),

                  Text(
                    'Going on vacation? Life busy?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 8),

                  Text(
                    "Pause your plan instead — pick up exactly where you left off.",
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 24),

                  // Two pause options
                  _PauseOption(
                    days: 14,
                    label: 'Pause for 14 days',
                    detail: 'Quick break — short trip, busy week',
                    onTap: () => _pause(14, PauseInterceptResult.paused14),
                    isDark: isDark,
                    enabled: !_submitting,
                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                  const SizedBox(height: 10),
                  _PauseOption(
                    days: 30,
                    label: 'Pause for 30 days',
                    detail: 'Longer break — illness, transition, life',
                    onTap: () => _pause(30, PauseInterceptResult.paused30),
                    isDark: isDark,
                    enabled: !_submitting,
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Proceed to cancel link (smaller, lower friction to skip)
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            ref.read(posthogServiceProvider).capture(
                                  eventName: 'pause_intercept_skipped',
                                );
                            Navigator.of(context)
                                .pop(PauseInterceptResult.proceedToCancel);
                          },
                    child: Text(
                      'No thanks, continue with cancel',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PauseOption extends StatelessWidget {
  final int days;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool isDark;
  final bool enabled;

  const _PauseOption({
    required this.days,
    required this.label,
    required this.detail,
    required this.onTap,
    required this.isDark,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.onboardingAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.onboardingAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$days',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onboardingAccent,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'days',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onboardingAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

enum PauseInterceptResult {
  paused14,
  paused30,
  proceedToCancel,
  dismissed,
}
