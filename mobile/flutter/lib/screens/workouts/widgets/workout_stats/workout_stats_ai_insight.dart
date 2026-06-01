part of 'workout_stats_section.dart';

/// 1. AI INSIGHT STRIP.
///
/// Watches [trainingInsightProvider]. Shows the insight headline with a sparkle
/// icon in a subtle accent-tinted card; tapping opens the full Stats screen.
/// While loading it shows a one-line skeleton; on null/empty it renders nothing
/// (the surrounding [SizedBox] gaps collapse since the parent uses a Column).
///
/// No fabricated copy: only the provider's real headline is shown. The
/// `isFallback` flag is surfaced as a subtle "auto" marker so a deterministic
/// fallback headline is honestly distinguished from an AI-authored one.
///
/// NOTE: no longer rendered in the section (the "momentum" card was removed
/// from [WorkoutStatsSection]). Kept for reference / potential reuse.
// ignore: unused_element
class _AiInsightStrip extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const _AiInsightStrip({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trainingInsightProvider);

    return async.when(
      loading: () => StatCardShell(
        isDark: isDark,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: accent),
            const SizedBox(width: 10),
            const Expanded(child: SkeletonBox(height: 14)),
          ],
        ),
      ),
      // An insight is a nice-to-have; if it errors, stay silent rather than
      // showing an error chrome that would clutter the top of the section.
      error: (_, __) => const SizedBox.shrink(),
      data: (insight) {
        if (insight == null || insight.headline.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        return _InsightCard(
          insight: insight,
          isDark: isDark,
          accent: accent,
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  final TrainingInsight insight;
  final bool isDark;
  final Color accent;

  const _InsightCard({
    required this.insight,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final hasBody = insight.body.trim().isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.30)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.auto_awesome, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.headline,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: textPrimary,
                    ),
                  ),
                  if (hasBody) ...[
                    const SizedBox(height: 4),
                    Text(
                      insight.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }
}
