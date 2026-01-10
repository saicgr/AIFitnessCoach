import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/weekly_plan.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/providers/weekly_plan_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Contextual banner types in priority order
enum ContextualBannerType {
  fasting,     // Highest priority - time sensitive
  weeklyGoal,  // Actionable
  personalRecord, // Celebratory
}

/// Data class for banner content
class BannerContent {
  final ContextualBannerType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String actionLabel;
  final String actionRoute;
  final String dismissKey;

  const BannerContent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.actionLabel,
    required this.actionRoute,
    required this.dismissKey,
  });
}

/// Contextual banner that shows personalized, time-sensitive messages
///
/// Priority order:
/// 1. Fasting window ending soon (< 2 hours)
/// 2. Weekly goal progress (Thu-Sun, 1-3 workouts remaining)
/// 3. Recent PR celebration (within 24 hours)
class ContextualBanner extends ConsumerStatefulWidget {
  final bool isDark;

  const ContextualBanner({super.key, required this.isDark});

  @override
  ConsumerState<ContextualBanner> createState() => _ContextualBannerState();
}

class _ContextualBannerState extends ConsumerState<ContextualBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  Set<String> _dismissedKeys = {};
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _loadDismissedState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final weekKey = _getWeekKey(today);

    setState(() {
      _dismissedKeys = {};

      // Check fasting dismiss (resets when fast ID changes - handled by key)
      final fastingDismissed = prefs.getString('contextual_banner_fasting_dismissed');
      if (fastingDismissed != null) {
        _dismissedKeys.add(fastingDismissed);
      }

      // Check weekly goal dismiss (resets weekly)
      final weeklyDismissed = prefs.getString('contextual_banner_weekly_dismissed');
      if (weeklyDismissed == weekKey) {
        _dismissedKeys.add('weekly_$weekKey');
      }

      // Check PR dismiss (resets daily)
      final prDismissed = prefs.getString('contextual_banner_pr_dismissed');
      if (prDismissed == todayKey) {
        _dismissedKeys.add('pr_$todayKey');
      }

      _prefsLoaded = true;
    });

    // Start animation after loading prefs
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  String _getWeekKey(DateTime date) {
    // Get Monday of the current week
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return '${monday.year}-${monday.month}-${monday.day}';
  }

  Future<void> _dismiss(String dismissKey, ContextualBannerType type) async {
    HapticService.light();

    await _animationController.reverse();

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();

    switch (type) {
      case ContextualBannerType.fasting:
        await prefs.setString('contextual_banner_fasting_dismissed', dismissKey);
        break;
      case ContextualBannerType.weeklyGoal:
        final weekKey = _getWeekKey(today);
        await prefs.setString('contextual_banner_weekly_dismissed', weekKey);
        break;
      case ContextualBannerType.personalRecord:
        final todayKey = '${today.year}-${today.month}-${today.day}';
        await prefs.setString('contextual_banner_pr_dismissed', todayKey);
        break;
    }

    if (mounted) {
      setState(() {
        _dismissedKeys.add(dismissKey);
      });
      // Restart animation for next banner if any
      _animationController.forward();
    }
  }

  BannerContent? _determineBannerContent() {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final weekKey = _getWeekKey(today);

    // Priority 1: Fasting window ending soon
    final fastingState = ref.watch(fastingProvider);
    if (fastingState.activeFast != null) {
      final fast = fastingState.activeFast!;
      final remainingMinutes = fast.goalDurationMinutes - fast.elapsedMinutes;

      // Show when less than 2 hours remaining
      if (remainingMinutes > 0 && remainingMinutes <= 120) {
        final fastDismissKey = 'fasting_${fast.id}';
        if (!_dismissedKeys.contains(fastDismissKey)) {
          final hours = remainingMinutes ~/ 60;
          final mins = remainingMinutes % 60;
          final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

          return BannerContent(
            type: ContextualBannerType.fasting,
            title: 'Almost there!',
            subtitle: 'Fasting window ends in $timeStr',
            icon: Icons.timer_outlined,
            accentColor: AppColors.orange,
            actionLabel: 'View Fast',
            actionRoute: '/fasting',
            dismissKey: fastDismissKey,
          );
        }
      }
    }

    // Priority 2: Weekly goal progress (Thu-Sun)
    final dayOfWeek = today.weekday; // 1 = Monday, 7 = Sunday
    if (dayOfWeek >= 4) { // Thursday onwards
      final weeklyDismissKey = 'weekly_$weekKey';
      if (!_dismissedKeys.contains(weeklyDismissKey)) {
        final weeklyPlanState = ref.watch(weeklyPlanProvider);
        final plan = weeklyPlanState.currentPlan;

        if (plan != null) {
          // Count completed vs planned workouts
          int completedCount = 0;
          int plannedCount = 0;

          for (final entry in plan.dailyEntries) {
            if (entry.dayType == DayType.training) {
              plannedCount++;
              if (entry.workoutCompleted) {
                completedCount++;
              }
            }
          }

          final remaining = plannedCount - completedCount;

          // Show if 1-3 workouts remaining
          if (remaining > 0 && remaining <= 3) {
            final workoutWord = remaining == 1 ? 'workout' : 'workouts';

            return BannerContent(
              type: ContextualBannerType.weeklyGoal,
              title: 'Keep it up!',
              subtitle: "You're $remaining $workoutWord away from your weekly goal",
              icon: Icons.flag_outlined,
              accentColor: AppColors.cyan,
              actionLabel: 'View Workouts',
              actionRoute: '/workouts',
              dismissKey: weeklyDismissKey,
            );
          }
        }
      }
    }

    // Priority 3: Recent PR celebration
    final prDismissKey = 'pr_$todayKey';
    if (!_dismissedKeys.contains(prDismissKey)) {
      final prStats = ref.watch(prStatsProvider);

      if (prStats != null && prStats.recentPrs.isNotEmpty) {
        // Check if any PR was achieved today or yesterday
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        for (final pr in prStats.recentPrs) {
          try {
            final prDate = DateTime.parse(pr.achievedAt);
            final prDateOnly = DateTime(prDate.year, prDate.month, prDate.day);
            final todayOnly = DateTime(now.year, now.month, now.day);
            final yesterdayOnly = DateTime(yesterday.year, yesterday.month, yesterday.day);

            if (prDateOnly == todayOnly || prDateOnly == yesterdayOnly) {
              // Format weight - convert from kg to lbs for display
              final weightLbs = (pr.weightKg * 2.205).round();

              return BannerContent(
                type: ContextualBannerType.personalRecord,
                title: 'New PR!',
                subtitle: '${pr.exerciseName}: $weightLbs lbs',
                icon: Icons.emoji_events_outlined,
                accentColor: AppColors.success,
                actionLabel: 'View Stats',
                actionRoute: '/stats',
                dismissKey: prDismissKey,
              );
            }
          } catch (_) {
            // Skip invalid date
          }
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const SizedBox.shrink();
    }

    final content = _determineBannerContent();

    if (content == null) {
      return const SizedBox.shrink();
    }

    final isDark = widget.isDark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: content.accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: content.accentColor.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: content.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    content.icon,
                    color: content.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        content.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Action button
                TextButton(
                  onPressed: () {
                    HapticService.light();
                    context.push(content.actionRoute);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: content.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    content.actionLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Dismiss button
                IconButton(
                  onPressed: () => _dismiss(content.dismissKey, content.type),
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
