import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/wrapped_summary.dart';
import '../../data/providers/wrapped_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/pill_app_bar.dart';

class MyWrappedScreen extends ConsumerWidget {
  const MyWrappedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.colors(context).accent;
    final accentGradient = ref.colors(context).accentGradient;

    final summaryAsync = ref.watch(wrappedSummaryProvider);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            PillAppBar(
              title: 'My Wrapped',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: summaryAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Failed to load wrapped data',
                    style: TextStyle(color: textMuted),
                  ),
                ),
                data: (summary) => _buildBody(
                  context,
                  summary,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cardBorder: cardBorder,
                  accent: accent,
                  accentGradient: accentGradient,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WrappedSummary summary, {
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
    required Color accent,
    required LinearGradient accentGradient,
  }) {
    final hasAvailable = summary.available.isNotEmpty;
    final hasCurrentMonth = summary.currentMonth != null;

    if (!hasAvailable && !hasCurrentMonth) {
      return _buildEmptyState(elevated, textPrimary, textMuted, cardBorder, accent, accentGradient);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Hero card for latest wrapped
        if (hasAvailable)
          _buildHeroCard(context, summary.available.first, elevated, textPrimary, textMuted, accent, accentGradient),

        // Current month progress
        if (hasCurrentMonth) ...[
          const SizedBox(height: 16),
          _buildCurrentMonthProgress(
            summary.currentMonth!,
            elevated, textPrimary, textMuted, cardBorder, accent,
          ),
        ],

        // Past wraps grid
        if (summary.available.length > 1) ...[
          const SizedBox(height: 24),
          Text(
            'PAST WRAPS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _buildPastWrapsGrid(context, summary.available.sublist(1), elevated, textPrimary, textMuted, accent),
        ],

        // Personality collection
        const SizedBox(height: 24),
        _buildPersonalitySection(context, summary.personalitiesCollected, elevated, textPrimary, textMuted, cardBorder, accent),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    WrappedPeriodInfo latest,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color accent,
    LinearGradient accentGradient,
  ) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/wrapped/${latest.period}');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1.5,
            color: accent.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period label
            Text(
              _monthName(latest.period),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Personality badge
            if (latest.personality != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: accentGradient,
                ),
                child: Text(
                  latest.personality!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Stats
            Text(
              '${latest.totalWorkouts} workouts  ·  ${_formatVolume(latest.totalVolumeLbs)}',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 18),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      context.push('/wrapped/${latest.period}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: accentGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'View Again',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      context.push('/wrapped/${latest.period}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.share_outlined, size: 15, color: accent),
                            const SizedBox(width: 6),
                            Text(
                              'Share',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMonthProgress(
    CurrentMonthProgress current,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    Color accent,
  ) {
    final monthName = _monthName(current.period).split(' ').first;
    final workoutsNeeded = 3 - current.workoutsSoFar;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  current.daysUntilDrop > 0
                      ? '$monthName Wrapped drops in ${current.daysUntilDrop} days'
                      : '$monthName Wrapped drops soon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stat chips
          Row(
            children: [
              _buildStatChip('${current.workoutsSoFar}', 'workouts', Icons.fitness_center_rounded, textPrimary, textMuted, accent),
              const SizedBox(width: 8),
              _buildStatChip(_formatVolume(current.volumeSoFar), 'volume', Icons.trending_up_rounded, textPrimary, textMuted, accent),
              const SizedBox(width: 8),
              _buildStatChip('${current.prsSoFar}', 'PRs', Icons.emoji_events_rounded, textPrimary, textMuted, accent),
            ],
          ),
          const SizedBox(height: 12),

          if (!current.eligible && workoutsNeeded > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (current.workoutsSoFar / 3).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: accent.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete $workoutsNeeded more workout${workoutsNeeded == 1 ? '' : 's'} to unlock',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Your $monthName Wrapped is building...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: accent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String value,
    String label,
    IconData icon,
    Color textPrimary,
    Color textMuted,
    Color accent,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastWrapsGrid(
    BuildContext context,
    List<WrappedPeriodInfo> past,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color accent,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: past.length,
      itemBuilder: (context, index) {
        final wrap = past[index];
        return GestureDetector(
          onTap: () {
            HapticService.selection();
            context.push('/wrapped/${wrap.period}');
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _monthAbbr(wrap.period),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                if (wrap.personality != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    wrap.personality!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${wrap.totalWorkouts} workouts',
                  style: TextStyle(fontSize: 10, color: textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalitySection(
    BuildContext context,
    int collected,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    Color accent,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Personalities',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showPersonalityInfo(context, textPrimary, textMuted, accent),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                '$collected of 12 collected',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 12 personality slots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(12, (index) {
              final isFilled = index < collected;
              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isFilled
                      ? accent.withValues(alpha: 0.8)
                      : accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: isFilled
                      ? null
                      : Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: isFilled
                    ? const Center(
                        child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
                      )
                    : null,
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'Earn a unique personality each month by completing at least 3 workouts.',
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color elevated, Color textPrimary, Color textMuted, Color cardBorder, Color accent, LinearGradient accentGradient) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: accentGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('?', style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                )),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Monthly Wrapped',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete at least 3 workouts this month\nto unlock your personalized recap',
              style: TextStyle(fontSize: 14, color: textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonalityInfo(BuildContext context, Color textPrimary, Color textMuted, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.psychology_outlined, size: 40, color: accent),
              const SizedBox(height: 12),
              Text(
                'Fitness Personalities',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Each month, when you complete your Monthly Wrapped, our AI analyzes your workout patterns and assigns you a unique fitness personality.\n\n'
                'There are 12 slots — one for each month of the year. Stay consistent to collect them all!',
                style: TextStyle(fontSize: 14, color: textMuted, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatVolume(double lbs) {
    if (lbs >= 1000000) return '${(lbs / 1000000).toStringAsFixed(1)}M lbs';
    if (lbs >= 1000) return '${(lbs / 1000).toStringAsFixed(0)}K lbs';
    return '${lbs.toStringAsFixed(0)} lbs';
  }

  static String _monthName(String period) {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[(month - 1).clamp(0, 11)]} ${parts[0]}';
  }

  static String _monthAbbr(String period) {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final month = int.tryParse(parts[1]) ?? 1;
    const abbrs = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return abbrs[(month - 1).clamp(0, 11)];
  }
}
