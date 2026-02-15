/// PR Details Bottom Sheet
///
/// Shows detailed information about Personal Records achieved during workout.
/// Displayed when user taps on the PR celebration banner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/pr_detection_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../achievements/achievements_screen.dart';

/// Shows a bottom sheet with PR details
Future<void> showPRDetailsSheet({
  required BuildContext context,
  required List<DetectedPR> prs,
}) {
  return showGlassSheet(
    context: context,
    builder: (context) => GlassSheet(
      child: PRDetailsSheet(prs: prs),
    ),
  );
}

/// Bottom sheet content displaying PR details
class PRDetailsSheet extends StatelessWidget {
  final List<DetectedPR> prs;

  const PRDetailsSheet({super.key, required this.prs});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    final isMultiplePRs = prs.length > 1;
    final headerText =
        isMultiplePRs ? 'ON FIRE! ${prs.length} PRs!' : 'NEW PERSONAL RECORD!';

    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMultiplePRs
                          ? [
                              const Color(0xFFFF6B6B),
                              const Color(0xFFFFD93D),
                            ]
                          : [orange, orange.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMultiplePRs
                        ? Icons.local_fire_department
                        : Icons.emoji_events,
                    color: Colors.white,
                    size: 28,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 600.ms,
                    ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    headerText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          // PR Cards
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: prs.length,
              itemBuilder: (context, index) {
                final pr = prs[index];
                return _PRDetailCard(
                  pr: pr,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  orange: orange,
                  success: success,
                )
                    .animate()
                    .fadeIn(delay: (100 * index).ms)
                    .slideX(begin: 0.1, delay: (100 * index).ms);
              },
            ),
          ),

          // View All Achievements Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (context) => const AchievementsScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: cyan,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All Achievements',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: cyan),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
    );
  }
}

/// Card showing details of a single PR
class _PRDetailCard extends StatelessWidget {
  final DetectedPR pr;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color orange;
  final Color success;

  const _PRDetailCard({
    required this.pr,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.orange,
    required this.success,
  });

  Color get _prTypeColor {
    switch (pr.type) {
      case PRType.weight:
        return orange;
      case PRType.reps:
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case PRType.volume:
        return isDark ? AppColors.purple : AppColorsLight.purple;
      case PRType.oneRM:
        return isDark ? AppColors.magenta : AppColorsLight.magenta;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.surface : AppColorsLight.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _prTypeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name and PR type badge
          Row(
            children: [
              Expanded(
                child: Text(
                  pr.exerciseName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _prTypeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pr.type.icon,
                      size: 14,
                      color: _prTypeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pr.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _prTypeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Values row
          Row(
            children: [
              // New value (prominently displayed)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEW RECORD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pr.formattedValue,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: orange,
                      ),
                    ),
                  ],
                ),
              ),

              // Previous value and improvement
              if (pr.previousValue != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PREVIOUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPreviousValue(),
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${pr.improvementPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: success,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // First time - show "First Record" badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'FIRST RECORD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: success,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Set details
          const SizedBox(height: 12),
          Text(
            '${pr.weight.toStringAsFixed(1)}kg x ${pr.reps} reps',
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPreviousValue() {
    if (pr.previousValue == null) return '';
    switch (pr.type) {
      case PRType.weight:
        return '${pr.previousValue!.toStringAsFixed(1)}kg';
      case PRType.reps:
        return '${pr.previousValue!.toInt()} reps';
      case PRType.volume:
        return '${pr.previousValue!.toStringAsFixed(0)}kg';
      case PRType.oneRM:
        return '${pr.previousValue!.toStringAsFixed(1)}kg';
    }
  }
}
