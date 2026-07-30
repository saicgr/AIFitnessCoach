import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/discover_provider.dart';
import '../../../data/providers/user_cohort_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'leaderboard_standing_gate.dart';

/// Workstream 2 — compact rank card shown only for week-1 users on home.
///
/// Lets new users see they're part of a community immediately. Taps through
/// to the Discover tab. Disappears automatically after day 7.
///
/// Week-1 is exactly the window in which a placement is least likely to be
/// real: signing up writes XP, which puts the account on the board before it
/// has done anything. Whether a `#N` / `Top N%` may be shown as a standing is
/// decided in one place for all Home rank surfaces —
/// [homeMayShowStanding] — and everything else renders the honest
/// starting state (an invitation, never a rank the user did not earn).
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
        // A rank is a STANDING only once the cohort is meaningful and the user
        // has actually put a session on this week's board. The two blockers
        // are NOT the same state and must not share copy: telling a user who
        // trained on Monday to "log a workout to join the board" (which is what
        // a single boolean does on the current 3-user production cohort) is
        // exactly the kind of untrue statement this gate exists to remove.
        final visibility = homeStandingVisibility(ref, s);
        final String percentileText;
        final String subtitle;
        switch (visibility) {
          case HomeStandingVisibility.standing:
            percentileText = s.yourPercentile > 0
                ? 'Top ${(100 - s.yourPercentile).clamp(1, 99).toStringAsFixed(0)}% this week'
                : 'You\'re on this week\'s board';
            subtitle =
                '#${s.yourRank} of ${s.totalActive} active users · Tap to see Discover';
          case HomeStandingVisibility.onBoardCohortTooSmall:
            // Participated, but the cohort is too small for a percentile to
            // carry information. Acknowledge the session; print no placement.
            percentileText = 'You\'re on this week\'s board';
            subtitle =
                'Too few people training this week to rank · Tap to see Discover';
          case HomeStandingVisibility.notOnBoard:
            percentileText = 'Log a workout to join the board';
            subtitle =
                'See where you stack up once you complete this week\'s first session';
        }

        return GestureDetector(
          onTap: () {
            HapticService.light();
            context.push('/leaderboard');
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
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
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
