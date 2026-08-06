part of 'my_library_tab.dart';


class _HistoryTimelineCard extends StatelessWidget {
  final ExerciseHistoryItem item;
  final bool isDark;
  final bool isLast;
  final bool useKg;

  const _HistoryTimelineCard({
    required this.item,
    required this.isDark,
    required this.isLast,
    required this.useKg,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Determine trend indicator
    final isIncreasing = item.progression?.isIncreasing == true;
    final isDecreasing = item.progression?.isDecreasing == true;
    final trendColor = isIncreasing
        ? AppColors.success  // accent-allowlist: success/positive state — must stay green regardless of accent
        : isDecreasing
            ? AppColors.error  // accent-allowlist: error/destructive state — must stay red regardless of accent
            : textMuted;
    final trendIcon = isIncreasing
        ? Icons.trending_up
        : isDecreasing
            ? Icons.trending_down
            : Icons.trending_flat;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: trendColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: textMuted.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Card content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
                border: isDark
                    ? null
                    : Border.all(color: AppColorsLight.cardBorder),
              ),
              child: Row(
                children: [
                  // Exercise info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.exerciseName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          // 2 lines, not 1 — the variant qualifier that tells
                          // this row apart from a sibling exercise (e.g.
                          // "... Resistance Band Seated" vs "... Standing")
                          // is almost always at the END of the name, so a
                          // 1-line ellipsis is exactly what eats it.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (item.lastWorkoutDate != null)
                          Text(
                            _formatRelativeDate(item.lastWorkoutDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        // Only a real logged weight is a "Best" — a bodyweight
                        // move or a stretch has no weight/rep concept, and the
                        // backend represents that as 0/0, not null. Showing
                        // "Best: 0kg x 0" would be a fabricated stat, so gate
                        // on > 0 rather than merely non-null. Unit follows the
                        // user's workout-weight preference (defaults lbs),
                        // never a hard-coded "kg".
                        if (item.maxWeight != null &&
                            item.maxWeight! > 0 &&
                            item.maxReps != null &&
                            item.maxReps! > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Best: ${WeightUtils.formatWorkoutWeight(item.maxWeight!, useKg: useKg)} x ${item.maxReps}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trend indicator
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(trendIcon, size: 20, color: trendColor),
                      if (item.progression?.changePercent != null)
                        Text(
                          '${item.progression!.changePercent! > 0 ? '+' : ''}${item.progression!.changePercent!.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) {
        final weeks = diff.inDays ~/ 7;
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      }
      if (diff.inDays < 365) {
        final months = diff.inDays ~/ 30;
        return months == 1 ? '1 month ago' : '$months months ago';
      }
      return '${diff.inDays ~/ 365}y ago';
    } catch (_) {
      return dateStr;
    }
  }
}

