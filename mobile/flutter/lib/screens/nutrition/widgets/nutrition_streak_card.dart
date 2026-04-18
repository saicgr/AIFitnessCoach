import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Compact streak badge pinned near the top of the nutrition Daily tab.
///
/// Shows:
///   • a big current-streak number with a fire icon (warm gradient)
///   • weekly progress bar when a weekly goal is enabled
///   • a snowflake "Use Freeze" action — surfaced only when the streak is
///     currently at risk (user hasn't logged today) AND freezes are available.
///
/// Tapping the card opens a fuller details sheet with best/total stats so the
/// home screen stays compact while power users can still drill in.
class NutritionStreakCard extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const NutritionStreakCard({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final streak = prefsState.streak;
    // Always render — an empty state (streak == 0) is still motivating and
    // establishes where the badge will live so users don't get a layout jump
    // once they start logging.
    return _StreakCardBody(
      userId: userId,
      streak: streak,
      isDark: isDark,
      isLoading: prefsState.isLoading,
    );
  }
}

class _StreakCardBody extends ConsumerStatefulWidget {
  final String userId;
  final NutritionStreak? streak;
  final bool isDark;
  final bool isLoading;

  const _StreakCardBody({
    required this.userId,
    required this.streak,
    required this.isDark,
    required this.isLoading,
  });

  @override
  ConsumerState<_StreakCardBody> createState() => _StreakCardBodyState();
}

class _StreakCardBodyState extends ConsumerState<_StreakCardBody> {
  bool _submitting = false;

  /// The streak is "at risk" when the user hasn't logged yet today. If the
  /// last logged date is before today (in device local time), the fire will
  /// reset unless they log or spend a freeze.
  bool get _streakAtRisk {
    final s = widget.streak;
    if (s == null) return false;
    if (s.currentStreakDays <= 0) return false;
    final last = s.lastLoggedDate;
    if (last == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    return lastDay.isBefore(today);
  }

  Future<void> _useFreeze() async {
    if (_submitting) return;
    HapticService.medium();
    setState(() => _submitting = true);
    try {
      await ref
          .read(nutritionPreferencesProvider.notifier)
          .useStreakFreeze(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.ac_unit, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Streak freeze used — your streak is safe.'),
              ],
            ),
            backgroundColor: AppColors.cyan,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not use freeze: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.streak;
    final fire = AppColors.orange;
    final fireDeep = AppColors.red;
    final ice = AppColors.cyan;
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = widget.isDark
        ? AppColors.cardBorder
        : AppColorsLight.cardBorder;

    final streakDays = s?.currentStreakDays ?? 0;
    final best = s?.longestStreakEver ?? 0;
    final total = s?.totalDaysLogged ?? 0;
    final freezes = s?.freezesAvailable ?? 0;
    final weeklyGoalOn = s?.weeklyGoalEnabled ?? false;
    final weeklyGoalDays = s?.weeklyGoalDays ?? 5;
    final daysThisWeek = s?.daysLoggedThisWeek ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetailsSheet(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fire.withValues(alpha: widget.isDark ? 0.18 : 0.12),
                fireDeep.withValues(alpha: widget.isDark ? 0.10 : 0.06),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Fire badge with current streak number.
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [fire, fireDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: fire.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        Text(
                          '$streakDays',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + stat subtitle.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          streakDays == 0
                              ? 'Start your streak'
                              : '$streakDays-day streak',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          streakDays == 0
                              ? 'Log a meal today to get started'
                              : 'Best $best · Total $total days',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Use Freeze action — only surfaced when the streak is at
                  // risk. Outside of that, the action is tucked inside the
                  // details sheet so the card stays calm.
                  if (_streakAtRisk && freezes > 0)
                    _UseFreezeButton(
                      onTap: _submitting ? null : _useFreeze,
                      submitting: _submitting,
                      ice: ice,
                    )
                  else
                    _FreezesPill(count: freezes, ice: ice, textMuted: textMuted),
                ],
              ),
              if (weeklyGoalOn) ...[
                const SizedBox(height: 12),
                _WeeklyProgress(
                  logged: daysThisWeek,
                  target: weeklyGoalDays,
                  fire: fire,
                  textMuted: textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openDetailsSheet() {
    HapticService.light();
    final s = widget.streak;
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDark ? AppColors.pureBlack : Colors.white,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _StreakDetailsSheet(
        streak: s,
        isDark: widget.isDark,
        onUseFreeze: (s?.freezesAvailable ?? 0) > 0
            ? () async {
                Navigator.of(ctx).pop();
                await _useFreeze();
              }
            : null,
      ),
    );
  }
}

class _UseFreezeButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool submitting;
  final Color ice;

  const _UseFreezeButton({
    required this.onTap,
    required this.submitting,
    required this.ice,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: ice.withValues(alpha: onTap == null ? 0.10 : 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ice.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (submitting)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: ice),
              )
            else
              Icon(Icons.ac_unit_rounded, size: 14, color: ice),
            const SizedBox(width: 5),
            Text(
              submitting ? 'Using…' : 'Use freeze',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: ice,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreezesPill extends StatelessWidget {
  final int count;
  final Color ice;
  final Color textMuted;

  const _FreezesPill({
    required this.count,
    required this.ice,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: ice.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.ac_unit_rounded, size: 12, color: ice),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: ice,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  final int logged;
  final int target;
  final Color fire;
  final Color textMuted;

  const _WeeklyProgress({
    required this.logged,
    required this.target,
    required this.fire,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final total = target <= 0 ? 1 : target;
    final filled = logged.clamp(0, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'This week',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              '$logged / $target days',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: fire,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (int i = 0; i < total; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < filled
                        ? fire
                        : fire.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }
}

class _StreakDetailsSheet extends StatelessWidget {
  final NutritionStreak? streak;
  final bool isDark;
  final VoidCallback? onUseFreeze;

  const _StreakDetailsSheet({
    required this.streak,
    required this.isDark,
    required this.onUseFreeze,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final fire = AppColors.orange;
    final ice = AppColors.cyan;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: fire, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Your streak',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _StatRow(
              icon: Icons.local_fire_department_rounded,
              color: fire,
              label: 'Current',
              value: '${streak?.currentStreakDays ?? 0} days',
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.emoji_events_rounded,
              color: AppColors.yellow,
              label: 'Best ever',
              value: '${streak?.longestStreakEver ?? 0} days',
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.calendar_today_rounded,
              color: AppColors.purple,
              label: 'Total days logged',
              value: '${streak?.totalDaysLogged ?? 0}',
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.ac_unit_rounded,
              color: ice,
              label: 'Freezes available',
              value: '${streak?.freezesAvailable ?? 0}',
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            if (onUseFreeze != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onUseFreeze,
                  icon: Icon(Icons.ac_unit_rounded, color: ice),
                  label: Text(
                    'Use a freeze',
                    style: TextStyle(
                      color: ice,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ice.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Freezes protect your streak for a day you missed. '
              'You get 2 per week automatically.',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textMuted;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
