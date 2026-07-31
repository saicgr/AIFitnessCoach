part of 'food_mood_analytics_card.dart';


/// Detailed Food Mood Analytics Sheet
class _FoodMoodAnalyticsSheet extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const _FoodMoodAnalyticsSheet({
    required this.userId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(foodMoodAnalyticsProvider(userId));

    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentTint = context.accentColor;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentTint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.mood,
                    color: accentTint,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  AppLocalizations.of(context).foodMoodAnalyticsFoodMoodInsights,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: analyticsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(AppLocalizations.of(context).foodMoodAnalyticsUnableToLoadData, style: TextStyle(color: textMuted)),
              ),
              data: (analytics) => _buildDetailedAnalytics(
                context,
                analytics,
                elevated,
                textPrimary,
                textMuted,
                cardBorder,
                accentTint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalytics(
    BuildContext context,
    FoodMoodAnalytics analytics,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    Color accentTint,
  ) {
    final l10n = AppLocalizations.of(context);
    if (!analytics.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mood, size: 64, color: textMuted.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              l10n.foodMoodAnalyticsNoMoodDataYet,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.foodMoodAnalyticsTrackYourMoodWhen,
              style: TextStyle(fontSize: 14, color: textMuted.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Stats
          _buildOverviewCard(context, analytics, elevated, textPrimary, textMuted, cardBorder),
          const SizedBox(height: 24),

          // Mood Distribution
          Text(
            l10n.foodMoodAnalyticsMoodAfterEating,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildMoodDistribution(analytics.moodAfterDistribution, elevated, textPrimary, cardBorder),
          const SizedBox(height: 24),

          // Energy Levels
          Text(
            l10n.foodMoodAnalyticsEnergyLevels,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildEnergyChart(context, analytics.energyDistribution, analytics.averageEnergy, elevated, textPrimary, textMuted, cardBorder),
          const SizedBox(height: 24),

          // Foods that boost mood
          if (analytics.positiveCorrelations.isNotEmpty) ...[
            Text(
              l10n.foodMoodAnalyticsFoodsThatBoostYour,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _buildFoodCorrelations(
              analytics.positiveCorrelations,
              const Color(0xFF6BCB77), // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
              elevated,
              textPrimary,
              textMuted,
              cardBorder,
            ),
            const SizedBox(height: 24),
          ],

          // Foods to watch
          if (analytics.negativeCorrelations.isNotEmpty) ...[
            Text(
              l10n.foodMoodAnalyticsFoodsToWatch,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _buildFoodCorrelations(
              analytics.negativeCorrelations,
              const Color(0xFFFF6B6B), // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
              elevated,
              textPrimary,
              textMuted,
              cardBorder,
            ),
            const SizedBox(height: 24),
          ],

          // Meal type insights
          if (analytics.mealTypeMoods.isNotEmpty) ...[
            Text(
              l10n.foodMoodAnalyticsByMealType,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _buildMealTypeInsights(analytics.mealTypeMoods, elevated, textPrimary, textMuted, cardBorder),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    FoodMoodAnalytics analytics,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
  ) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOverviewStat(
            '${(analytics.moodImprovementRate * 100).toStringAsFixed(0)}%',
            l10n.foodMoodAnalyticsMoodImproved,
            const Color(0xFF6BCB77), // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
            textMuted,
          ),
          Container(width: 1, height: 50, color: cardBorder),
          _buildOverviewStat(
            '${(analytics.moodTrackingRate * 100).toStringAsFixed(0)}%',
            l10n.foodMoodAnalyticsTrackingRate,
            const Color(0xFF3498DB), // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
            textMuted,
          ),
          Container(width: 1, height: 50, color: cardBorder),
          _buildOverviewStat(
            '${analytics.logsWithMood}',
            l10n.foodMoodAnalyticsMealsTracked,
            const Color(0xFF9B59B6), // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
            textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String value, String label, Color color, Color textMuted) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      ],
    );
  }

  Widget _buildMoodDistribution(
    Map<FoodMood, int> distribution,
    Color elevated,
    Color textPrimary,
    Color cardBorder,
  ) {
    final total = distribution.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: FoodMood.values.map((mood) {
          final count = distribution[mood] ?? 0;
          if (count == 0) return const SizedBox.shrink();

          final percent = (count / total * 100).toStringAsFixed(0);
          final color = _getMoodColor(mood);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnergyChart(
    BuildContext context,
    Map<int, int> distribution,
    double average,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
  ) {
    final total = distribution.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Text(
          AppLocalizations.of(context).foodMoodAnalyticsNoEnergyDataRecorded,
          style: TextStyle(color: textMuted),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final level = i + 1;
              final count = distribution[level] ?? 0;
              final height = total > 0 ? (count / total * 80).clamp(8.0, 80.0) : 8.0;
              final color = _getEnergyColor(level);

              return Column(
                children: [
                  Container(
                    width: 40,
                    height: height,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    level.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: level == average.round() ? color : textMuted,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).foodMoodAnalyticsAverage,
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
              Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getEnergyColor(average.round()),
                ),
              ),
              Text(
                ' / 5',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCorrelations(
    List<FoodMoodCorrelation> correlations,
    Color accentColor,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: correlations.asMap().entries.map((entry) {
          final correlation = entry.value;
          final isLast = entry.key == correlations.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: cardBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _capitalize(correlation.foodName),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${correlation.occurrences}x',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealTypeInsights(
    Map<String, MealTypeMoodStats> mealTypeMoods,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: mealTypeMoods.entries.map((entry) {
          final stats = entry.value;
          final isLast = entry.key == mealTypeMoods.keys.last;
          final emoji = _getMealTypeEmoji(stats.mealType);
          final color = stats.positiveRate > 0.7
              ? const Color(0xFF6BCB77) // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
              : stats.positiveRate > 0.4
                  ? const Color(0xFFF39C12) // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
                  : const Color(0xFFFF6B6B); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: cardBorder)),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _capitalize(stats.mealType),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(stats.positiveRate * 100).toStringAsFixed(0)}% positive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getMoodColor(FoodMood mood) {
    switch (mood) {
      case FoodMood.great:
        return const Color(0xFF6BCB77); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case FoodMood.good:
        return const Color(0xFF4ECDC4); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case FoodMood.neutral:
        return const Color(0xFF95A5A6); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case FoodMood.tired:
        return const Color(0xFF9B59B6); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case FoodMood.stressed:
        return const Color(0xFFE74C3C); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case FoodMood.hungry:
        return const Color(0xFFFF6B6B); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case FoodMood.satisfied:
        return const Color(0xFF3498DB); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case FoodMood.bloated:
        return const Color(0xFFF39C12); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
    }
  }

  Color _getEnergyColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFFE74C3C); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case 2:
        return const Color(0xFFF39C12); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case 3:
        return const Color(0xFFFFEB3B); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case 4:
        return const Color(0xFF4ECDC4); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      case 5:
        return const Color(0xFF6BCB77); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
      default:
        return const Color(0xFF95A5A6); // accent-allowlist: food-mood and energy-level identity/severity color coding (chart-legend style categorical encoding, matches macroProtein/macroCarbs/macroFat convention)
    }
  }

  String _getMealTypeEmoji(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '';
      case 'lunch':
        return '';
      case 'dinner':
        return '';
      case 'snack':
        return '';
      default:
        return '';
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

