import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/discover_provider.dart';
import '../../../data/providers/user_cohort_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Workstream 2 — compact rank card shown only for week-1 users on home.
///
/// Lets new users see they're part of a community immediately. Taps through
/// to the Discover tab. Disappears automatically after day 7.
class HomeRankCard extends ConsumerWidget {
  const HomeRankCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWeek1 = ref.watch(isWeek1UserProvider);
    if (!isWeek1) return const SizedBox.shrink();

    final snapshotAsync = ref.watch(discoverSnapshotProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    return snapshotAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) {
        if (s == null) return const SizedBox.shrink();
        final hasRank = s.yourRank > 0;
        final percentileText = hasRank && s.yourPercentile > 0
            ? 'Top ${(100 - s.yourPercentile).clamp(1, 99).toStringAsFixed(0)}% this week'
            : 'Log a workout to join the board';
        final subtitle = hasRank
            ? '#${s.yourRank} of ${s.totalActive} active users · Tap to see Discover'
            : 'See where you stack up once you complete this week\'s first session';

        return GestureDetector(
          onTap: () {
            HapticService.light();
            context.go('/discover');
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.leaderboard, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        percentileText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
