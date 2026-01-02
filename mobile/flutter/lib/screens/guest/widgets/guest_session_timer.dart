import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/guest_mode_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Displays the remaining session time for guest mode
/// Enhanced with Demo Day banner and countdown timer
/// Makes free trial experience more prominent
class GuestSessionTimer extends ConsumerWidget {
  const GuestSessionTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestState = ref.watch(guestModeProvider);
    final remaining = guestState.remainingTime;
    final progress = guestState.sessionProgress;

    if (!guestState.isGuestMode) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Determine color based on remaining time
    Color timerColor;
    String statusMessage;
    if (remaining.inMinutes < 2) {
      timerColor = AppColors.error;
      statusMessage = 'Hurry! Time running out';
    } else if (remaining.inMinutes < 5) {
      timerColor = AppColors.warning;
      statusMessage = 'Keep exploring!';
    } else {
      timerColor = AppColors.success;
      statusMessage = 'Enjoy your free demo';
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final timeString = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            timerColor.withOpacity(0.15),
            timerColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: timerColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Demo Day Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: timerColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: timerColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.celebration,
                    size: 18,
                    color: timerColor,
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: const Duration(milliseconds: 800),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'FREE DEMO DAY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: timerColor,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TRY FREE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        statusMessage,
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Countdown timer display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: timerColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: timerColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, size: 16, color: timerColor),
                      const SizedBox(width: 6),
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: timerColor,
                        ),
                      ),
                    ],
                  ),
                ).animate(
                  onPlay: (controller) => remaining.inMinutes < 2 ? controller.repeat(reverse: true) : null,
                ).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: const Duration(milliseconds: 500),
                ),
              ],
            ),
          ),

          // Progress bar and quick actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 1 - progress,
                    backgroundColor: timerColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),

                // Quick action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        icon: Icons.visibility_outlined,
                        label: 'Preview Plan',
                        color: AppColors.cyan,
                        onTap: () {
                          HapticService.light();
                          context.push('/plan-preview');
                        },
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        icon: Icons.play_circle_outline,
                        label: 'Try Workout',
                        color: Colors.green,
                        onTap: () {
                          HapticService.light();
                          context.push('/demo-workout');
                        },
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
