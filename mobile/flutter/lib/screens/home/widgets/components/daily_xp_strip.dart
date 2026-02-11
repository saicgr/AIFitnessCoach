import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/providers/daily_xp_strip_provider.dart';
import '../../../../data/providers/xp_provider.dart';
import '../../../../data/services/haptic_service.dart';
import 'package:go_router/go_router.dart';

/// Compact horizontal strip showing today's XP goals progress
/// Positioned above the hero card on home screen
/// Can be dismissed for the day by tapping the close button
class DailyXPStrip extends ConsumerStatefulWidget {
  const DailyXPStrip({super.key});

  @override
  ConsumerState<DailyXPStrip> createState() => _DailyXPStripState();
}

class _DailyXPStripState extends ConsumerState<DailyXPStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _dismissController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<double>(begin: 0, end: -50).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeInCubic),
    );
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    HapticService.light();

    await _dismissController.forward();
    if (mounted) {
      ref.read(dailyXPStripDismissedTodayProvider.notifier).dismissForToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = ref.watch(dailyXPStripVisibleProvider);
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: const ValueKey('daily_xp_strip_dismiss'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        HapticService.light();
        ref.read(dailyXPStripDismissedTodayProvider.notifier).dismissForToday();
      },
      child: AnimatedBuilder(
        animation: _dismissController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final ref = this.ref;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Get dynamic accent color
    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    final loginStreak = ref.watch(loginStreakProvider);
    final hasLoggedInToday = ref.watch(hasLoggedInTodayProvider);
    final hasDoubleXP = ref.watch(hasDoubleXPProvider);
    final multiplier = ref.watch(xpMultiplierProvider);

    // Calculate daily goals progress
    final dailyGoalsData = _calculateDailyGoals(hasLoggedInToday, multiplier);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/xp-goals');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // XP icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Daily goals progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Today: ${dailyGoalsData.completed}/${dailyGoalsData.total} goals',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      if (hasDoubleXP) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: Colors.amber,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${multiplier.toInt()}x',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: dailyGoalsData.progress,
                            minHeight: 4,
                            backgroundColor: textSecondary.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(accentColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${dailyGoalsData.xpEarned} XP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Streak indicator
            if (loginStreak != null && loginStreak.currentStreak > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.deepOrange.shade500,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${loginStreak.currentStreak}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],

            // Chevron for tap to open details
            Icon(
              Icons.chevron_right,
              color: textSecondary,
              size: 20,
            ),

            // Close button to dismiss for the day
            GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.close,
                  color: textSecondary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DailyGoalsData _calculateDailyGoals(bool hasLoggedInToday, double multiplier) {
    // Daily goals:
    // 1. Log in today - Fixed +5 XP (one-time per day)
    // 2. Complete 1 workout - 100 XP
    // 3. Log a meal - 25 XP
    // 4. Hit protein goal - 50 XP
    const totalGoals = 4;
    // Fixed daily login XP
    const dailyLoginXP = 5;

    // For now, only login goal is tracked
    // TODO: Integrate with workout and nutrition providers for full tracking
    int completedGoals = 0;
    int xpEarned = 0;

    if (hasLoggedInToday) {
      completedGoals = 1;
      xpEarned = (dailyLoginXP * multiplier).round();
    }

    return _DailyGoalsData(
      completed: completedGoals,
      total: totalGoals,
      progress: completedGoals / totalGoals,
      xpEarned: xpEarned,
    );
  }
}

class _DailyGoalsData {
  final int completed;
  final int total;
  final double progress;
  final int xpEarned;

  _DailyGoalsData({
    required this.completed,
    required this.total,
    required this.progress,
    required this.xpEarned,
  });
}
