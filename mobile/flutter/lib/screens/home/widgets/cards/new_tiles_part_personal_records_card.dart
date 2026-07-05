part of 'new_tiles.dart';


/// ============================================================
/// PERSONAL RECORDS CARD
/// Shows recent PRs (Personal Records) achieved
/// ============================================================
class PersonalRecordsCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const PersonalRecordsCard({
    super.key,
    this.size = TileSize.full,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    // Select just the slices read here — avoids rebuilds on unrelated
    // scores mutations (readiness, nutrition, strength).
    final (prStats, scoresLoading) = ref.watch(
      scoresProvider.select((s) => (s.prStats, s.isLoading)),
    );
    final recentPrs = prStats?.recentPrs ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.emoji_events, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.personalRecordsCardPersonalRecords,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  HapticService.light();
                  context.push('/achievements');
                },
                child: Text(
                  AppLocalizations.of(context)!.personalRecordsCardViewAll,
                  style: TextStyle(
                    fontSize: 12,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (scoresLoading && recentPrs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor,
                  ),
                ),
              ),
            )
          else if (recentPrs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppLocalizations.of(context)!.personalRecordsCardCompleteWorkoutsToPR,
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            )
          else
            ...recentPrs.take(size == TileSize.half ? 2 : 3).map((pr) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.military_tech, color: accentColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pr.exerciseDisplayName,
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                            Text(
                              _timeAgo(context, pr.achievedAt),
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        pr.liftDescription,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  static String _timeAgo(BuildContext context, String isoDate) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return l10n.personalRecordsCardToday;
    if (diff.inDays == 1) return l10n.personalRecordsCardYesterday;
    if (diff.inDays < 7) return l10n.personalRecordsCardDaysAgo(diff.inDays);
    if (diff.inDays < 14) return l10n.personalRecordsCard1WeekAgo;
    if (diff.inDays < 30) return l10n.personalRecordsCardWeeksAgo((diff.inDays / 7).floor());
    if (diff.inDays < 60) return l10n.personalRecordsCard1MonthAgo;
    return l10n.personalRecordsCardMonthsAgo((diff.inDays / 30).floor());
  }
}


/// ============================================================
/// AI COACH TIP CARD
/// Daily tip from AI coach
/// ============================================================
class AICoachTipCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const AICoachTipCard({
    super.key,
    this.size = TileSize.full,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    // Watch the daily tip provider
    final tipAsync = ref.watch(dailyTipProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tips_and_updates, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.personalRecordsCardCoachTip,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: accentColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          tipAsync.when(
            data: (tip) => Text(
              tip ?? _getDefaultTip(context),
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
                height: 1.4,
              ),
            ),
            loading: () => _buildLoadingState(context, textMuted),
            error: (_, __) => Text(
              _getDefaultTip(context),
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              HapticService.light();
              context.push('/chat');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.personalRecordsCardAskCoachForMore,
                  style: TextStyle(
                    fontSize: 13,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: accentColor, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, Color textMuted) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          AppLocalizations.of(context)!.personalRecordsCardGettingPersonalizedTip,
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _getDefaultTip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.personalRecordsCardMorningTip;
    } else if (hour < 17) {
      return l10n.personalRecordsCardAfternoonTip;
    } else {
      return l10n.personalRecordsCardEveningTip;
    }
  }
}


// CaloriesSummaryCard and MacroRingsCard moved to their own dedicated files:
// - cards/calories_summary_card.dart
// - cards/macro_rings_card.dart
// Both are exported via cards/cards.dart.

/// ============================================================
/// BODY WEIGHT CARD
/// Recent weight with trend arrow
/// ============================================================
class BodyWeightCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const BodyWeightCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    final measureState = ref.watch(measurementsProvider);
    final weightEntry = measureState.summary?.latestByType[MeasurementType.weight];
    final currentWeight = weightEntry?.value;
    final change = measureState.summary?.changeFromPrevious[MeasurementType.weight] ?? 0.0;
    final isDown = change < 0;

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/measurements');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.personalRecordsCardWeight,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentWeight?.toStringAsFixed(1) ?? '--',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(weightEntry?.unit ?? 'kg', style: TextStyle(fontSize: 14, color: textMuted)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDown ? Icons.trending_down : Icons.trending_up,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${change.abs().toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


/// ============================================================
/// LEADERBOARD RANK CARD
/// User's position on the leaderboard
/// ============================================================
class LeaderboardRankCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const LeaderboardRankCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    final xpState = ref.watch(xpProvider);
    final userId = ref.watch(currentUserIdProvider);
    final userEntry = userId != null
        ? xpState.leaderboard.cast<XPLeaderboardEntry?>().firstWhere(
              (e) => e!.userId == userId,
              orElse: () => null,
            )
        : null;
    final rank = userEntry?.rank ?? 0;
    final totalUsers = xpState.leaderboard.length;
    final percentile = totalUsers > 0 ? ((totalUsers - rank) / totalUsers * 100).toInt() : 0;

    return InkWell(
      onTap: () {
        HapticService.light();
        context.go('/social');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.personalRecordsCardRank,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.personalRecordsCardTopPercentile(percentile),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.personalRecordsCardOfUsers(totalUsers),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


/// ============================================================
/// WATER INTAKE CARD
/// Daily hydration tracking
/// ============================================================
class WaterIntakeCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const WaterIntakeCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    final hydration = ref.watch(hydrationProvider);
    final glasses = (hydration.todaySummary?.totalMl ?? 0) ~/ 250;
    final targetGlasses = (hydration.todaySummary?.goalMl ?? hydration.dailyGoalMl ?? 2500) ~/ 250;
    final progress = targetGlasses > 0 ? glasses / targetGlasses : 0.0;

    return InkWell(
      onTap: () {
        HapticService.light();
        context.go('/nutrition?tab=2');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.personalRecordsCardWater,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 2,
              runSpacing: 2,
              children: List.generate(targetGlasses, (index) {
                final isFilled = index < glasses;
                return Icon(
                  isFilled ? Icons.water_drop : Icons.water_drop_outlined,
                  color: isFilled ? accentColor : textMuted.withValues(alpha: 0.3),
                  size: 18,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.personalRecordsCardGlasses(glasses, targetGlasses),
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }
}


/// ============================================================
/// SLEEP SCORE CARD
/// Last night's sleep quality
/// ============================================================
class SleepScoreCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const SleepScoreCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purpleColor = const Color(0xFF7C4DFF);

    final sleepAsync = ref.watch(sleepProvider);
    final sleepData = sleepAsync.valueOrNull;
    final sleepHours = sleepData != null ? sleepData.totalMinutes / 60.0 : null;
    final sleepQuality = sleepData?.quality ?? 'No data';

    return Container(
      margin: size == TileSize.full
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purpleColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bedtime, color: purpleColor, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.personalRecordsCardSleep,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sleepHours != null ? '${sleepHours.toStringAsFixed(1)}h' : '--',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: purpleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    sleepQuality,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: purpleColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sleepData != null
                ? AppLocalizations.of(context)!.personalRecordsCardQualitySleep(sleepQuality)
                : AppLocalizations.of(context)!.personalRecordsCardConnectHealthToTrack,
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }
}

