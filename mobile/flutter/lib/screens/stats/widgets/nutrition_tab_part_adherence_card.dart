part of 'nutrition_tab.dart';


// ── Card 5: Adherence & Consistency ──────────────────────────────

class _AdherenceCard extends StatelessWidget {
  final AsyncValue<AdherenceSummary?> adherence;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const _AdherenceCard({
    required this.adherence,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: adherence.when(
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (_, __) => SizedBox(
          height: 60,
          child: Center(
            child: Text('Could not load adherence data',
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (data) {
          if (data == null) {
            return SizedBox(
              height: 60,
              child: Center(
                child: Text('Not enough data for adherence analysis',
                    style: TextStyle(color: textMuted, fontSize: 13)),
              ),
            );
          }

          final ratingColor = switch (data.sustainabilityRating) {
            'high' => const Color(0xFF4CAF50),
            'medium' => const Color(0xFFFF9800),
            _ => const Color(0xFFF44336),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Adherence & Consistency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ratingColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.sustainabilityRating.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ratingColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Overall adherence + sustainability row
              Row(
                children: [
                  // Circular progress for overall adherence
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (data.averageAdherence / 100).clamp(0.0, 1.0),
                          strokeWidth: 5,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(ratingColor),
                        ),
                        Text(
                          '${data.averageAdherence.round()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MiniStatRow(
                          label: 'Consistency',
                          value: '${data.consistencyScore.round()}%',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 4),
                        _MiniStatRow(
                          label: 'Logging',
                          value: '${data.loggingScore.round()}%',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 4),
                        _MiniStatRow(
                          label: 'Weeks analyzed',
                          value: '${data.weeksAnalyzed}',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Weekly adherence mini chart
              if (data.weeklyAdherence.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Last ${data.weeklyAdherence.length} weeks',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: Row(
                    children: data.weeklyAdherence.map((w) {
                      final pct =
                          (w.avgOverallAdherence / 100).clamp(0.0, 1.0);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: pct > 0 ? pct : 0.05,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: ratingColor
                                            .withValues(alpha: 0.4 + pct * 0.6),
                                        borderRadius:
                                            BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              // AI recommendation
              if (data.recommendation.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 14, color: textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.recommendation,
                          style:
                              TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}


class _MiniStatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniStatRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
      ],
    );
  }
}

