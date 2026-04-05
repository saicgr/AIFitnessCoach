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
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

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
                    color: purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.mood,
                    color: purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Food & Mood Insights',
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
                child: Text('Unable to load data', style: TextStyle(color: textMuted)),
              ),
              data: (analytics) => _buildDetailedAnalytics(
                analytics,
                elevated,
                textPrimary,
                textMuted,
                cardBorder,
                purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalytics(
    FoodMoodAnalytics analytics,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
    Color purple,
  ) {
    if (!analytics.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mood, size: 64, color: textMuted.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No mood data yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your mood when logging meals\nto see patterns and insights',
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
          _buildOverviewCard(analytics, elevated, textPrimary, textMuted, cardBorder),
          const SizedBox(height: 24),

          // Mood Distribution
          Text(
            'MOOD AFTER EATING',
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
            'ENERGY LEVELS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildEnergyChart(analytics.energyDistribution, analytics.averageEnergy, elevated, textPrimary, textMuted, cardBorder),
          const SizedBox(height: 24),

          // Foods that boost mood
          if (analytics.positiveCorrelations.isNotEmpty) ...[
            Text(
              'FOODS THAT BOOST YOUR MOOD',
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
              const Color(0xFF6BCB77),
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
              'FOODS TO WATCH',
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
              const Color(0xFFFF6B6B),
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
              'BY MEAL TYPE',
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
    FoodMoodAnalytics analytics,
    Color elevated,
    Color textPrimary,
    Color textMuted,
    Color cardBorder,
  ) {
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
            'Mood improved',
            const Color(0xFF6BCB77),
            textMuted,
          ),
          Container(width: 1, height: 50, color: cardBorder),
          _buildOverviewStat(
            '${(analytics.moodTrackingRate * 100).toStringAsFixed(0)}%',
            'Tracking rate',
            const Color(0xFF3498DB),
            textMuted,
          ),
          Container(width: 1, height: 50, color: cardBorder),
          _buildOverviewStat(
            '${analytics.logsWithMood}',
            'Meals tracked',
            const Color(0xFF9B59B6),
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
          'No energy data recorded yet',
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
                'Average: ',
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
              ? const Color(0xFF6BCB77)
              : stats.positiveRate > 0.4
                  ? const Color(0xFFF39C12)
                  : const Color(0xFFFF6B6B);

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
        return const Color(0xFF6BCB77);
      case FoodMood.good:
        return const Color(0xFF4ECDC4);
      case FoodMood.neutral:
        return const Color(0xFF95A5A6);
      case FoodMood.tired:
        return const Color(0xFF9B59B6);
      case FoodMood.stressed:
        return const Color(0xFFE74C3C);
      case FoodMood.hungry:
        return const Color(0xFFFF6B6B);
      case FoodMood.satisfied:
        return const Color(0xFF3498DB);
      case FoodMood.bloated:
        return const Color(0xFFF39C12);
    }
  }

  Color _getEnergyColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFFE74C3C);
      case 2:
        return const Color(0xFFF39C12);
      case 3:
        return const Color(0xFFFFEB3B);
      case 4:
        return const Color(0xFF4ECDC4);
      case 5:
        return const Color(0xFF6BCB77);
      default:
        return const Color(0xFF95A5A6);
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

