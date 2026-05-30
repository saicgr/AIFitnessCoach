part of 'workout_stats_section.dart';

/// 10. RECENT PRS.
///
/// Horizontal scroll of PR chips built from `PRStats.recentPrs`
/// (scoresProvider). Each chip shows the exercise, the lift, and the
/// improvement percent when present. Tapping any chip opens the full personal
/// records screen.
///
/// This block is intentionally NOT padded horizontally by the parent so the
/// scroll list can bleed to the screen edge; it manages its own 16px leading
/// inset via the header + list padding.
class _RecentPrsRow extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const _RecentPrsRow({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prStats = ref.watch(prStatsProvider);
    final scoresLoading = ref.watch(scoresLoadingProvider);
    final recent = prStats?.recentPrs ?? const <PersonalRecordScore>[];

    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    Widget header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Recent PRs',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          if (recent.isNotEmpty)
            TextButton(
              onPressed: () {
                HapticService.light();
                context.push('/stats/personal-records');
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See all',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMuted)),
                  Icon(Icons.chevron_right, size: 16, color: textMuted),
                ],
              ),
            ),
        ],
      ),
    );

    if (prStats == null && scoresLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  SizedBox(width: 140, child: _CardSkeleton(height: 64)),
                  SizedBox(width: 12),
                  SizedBox(width: 140, child: _CardSkeleton(height: 64)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Curated Plan-tab policy: render NOTHING when there is no PR yet (no empty
    // "hit a PR to see it here" placeholder inline). The card appears only once
    // the user has at least one real PR.
    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _PrChip(pr: recent[i], isDark: isDark, accent: accent),
          ),
        ),
      ],
    );
  }
}

class _PrChip extends StatelessWidget {
  final PersonalRecordScore pr;
  final bool isDark;
  final Color accent;

  const _PrChip({required this.pr, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    // Lift shown in lbs to match the project rule for lifted weight.
    final liftLbs = _kgToLbs(pr.weightKg);
    final liftLabel = '${liftLbs.round()} lbs x ${pr.reps}';
    final improvement = pr.improvementPercent;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/stats/personal-records');
      },
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, size: 16, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pr.exerciseDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              liftLabel,
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            if (improvement != null && improvement > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: success.withValues(alpha: isDark ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '+${improvement.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: success,
                  ),
                ),
              )
            else
              Text(
                pr.isAllTimePr ? 'All-time PR' : 'New PR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
