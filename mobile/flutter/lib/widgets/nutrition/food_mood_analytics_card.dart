import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/repositories/nutrition_repository.dart';

/// Provider for food-mood analytics data
/// Note: Removed autoDispose to prevent refetching on navigation
final foodMoodAnalyticsProvider = FutureProvider.family<FoodMoodAnalytics, String>((ref, userId) async {
  // Guard: Return empty analytics if userId is empty
  if (userId.isEmpty) {
    return FoodMoodAnalytics.empty();
  }

  final repository = ref.watch(nutritionRepositoryProvider);

  // Get food logs from the last 30 days
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  final logs = await repository.getFoodLogs(
    userId,
    limit: 200,
    fromDate: DateFormat('yyyy-MM-dd').format(thirtyDaysAgo),
    toDate: DateFormat('yyyy-MM-dd').format(now),
  );

  return FoodMoodAnalytics.fromLogs(logs);
});

/// Food-Mood Correlation Analytics Model
class FoodMoodAnalytics {
  /// Total logs analyzed
  final int totalLogs;

  /// Logs with mood data
  final int logsWithMood;

  /// Mood distribution before eating
  final Map<FoodMood, int> moodBeforeDistribution;

  /// Mood distribution after eating
  final Map<FoodMood, int> moodAfterDistribution;

  /// Energy level distribution
  final Map<int, int> energyDistribution;

  /// Average energy level
  final double averageEnergy;

  /// Mood improvements (mood before -> mood after transitions)
  final Map<String, int> moodTransitions;

  /// Foods associated with positive moods
  final List<FoodMoodCorrelation> positiveCorrelations;

  /// Foods associated with negative moods
  final List<FoodMoodCorrelation> negativeCorrelations;

  /// Meals by type with mood data
  final Map<String, MealTypeMoodStats> mealTypeMoods;

  const FoodMoodAnalytics({
    required this.totalLogs,
    required this.logsWithMood,
    required this.moodBeforeDistribution,
    required this.moodAfterDistribution,
    required this.energyDistribution,
    required this.averageEnergy,
    required this.moodTransitions,
    required this.positiveCorrelations,
    required this.negativeCorrelations,
    required this.mealTypeMoods,
  });

  /// Create an empty analytics object (used when userId is not available)
  factory FoodMoodAnalytics.empty() {
    return const FoodMoodAnalytics(
      totalLogs: 0,
      logsWithMood: 0,
      moodBeforeDistribution: {},
      moodAfterDistribution: {},
      energyDistribution: {},
      averageEnergy: 0,
      moodTransitions: {},
      positiveCorrelations: [],
      negativeCorrelations: [],
      mealTypeMoods: {},
    );
  }

  factory FoodMoodAnalytics.fromLogs(List<FoodLog> logs) {
    final logsWithMood = logs.where((l) => l.moodBefore != null || l.moodAfter != null).toList();

    // Mood before distribution
    final moodBeforeDistribution = <FoodMood, int>{};
    for (final mood in FoodMood.values) {
      moodBeforeDistribution[mood] = 0;
    }
    for (final log in logsWithMood) {
      final mood = log.moodBeforeEnum;
      if (mood != null) {
        moodBeforeDistribution[mood] = (moodBeforeDistribution[mood] ?? 0) + 1;
      }
    }

    // Mood after distribution
    final moodAfterDistribution = <FoodMood, int>{};
    for (final mood in FoodMood.values) {
      moodAfterDistribution[mood] = 0;
    }
    for (final log in logsWithMood) {
      final mood = log.moodAfterEnum;
      if (mood != null) {
        moodAfterDistribution[mood] = (moodAfterDistribution[mood] ?? 0) + 1;
      }
    }

    // Energy distribution
    final energyDistribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      energyDistribution[i] = 0;
    }
    double totalEnergy = 0;
    int energyCount = 0;
    for (final log in logs) {
      if (log.energyLevel != null && log.energyLevel! > 0) {
        final level = log.energyLevel!.clamp(1, 5);
        energyDistribution[level] = (energyDistribution[level] ?? 0) + 1;
        totalEnergy += level;
        energyCount++;
      }
    }

    // Mood transitions
    final moodTransitions = <String, int>{};
    for (final log in logsWithMood) {
      if (log.moodBefore != null && log.moodAfter != null) {
        final key = '${log.moodBefore}_to_${log.moodAfter}';
        moodTransitions[key] = (moodTransitions[key] ?? 0) + 1;
      }
    }

    // Food correlations
    final foodMoodMap = <String, List<FoodMood>>{};
    for (final log in logsWithMood) {
      final afterMood = log.moodAfterEnum;
      if (afterMood != null) {
        for (final item in log.foodItems) {
          final name = item.name.toLowerCase();
          foodMoodMap[name] = [...(foodMoodMap[name] ?? []), afterMood];
        }
      }
    }

    // Calculate correlations
    final correlations = <FoodMoodCorrelation>[];
    foodMoodMap.forEach((food, moods) {
      if (moods.length >= 2) {
        final positiveCount = moods.where((m) =>
          m == FoodMood.great || m == FoodMood.good || m == FoodMood.satisfied
        ).length;
        final negativeCount = moods.where((m) =>
          m == FoodMood.tired || m == FoodMood.stressed || m == FoodMood.bloated
        ).length;

        correlations.add(FoodMoodCorrelation(
          foodName: food,
          occurrences: moods.length,
          positiveRate: positiveCount / moods.length,
          negativeRate: negativeCount / moods.length,
        ));
      }
    });

    // Sort correlations
    final positiveCorrelations = correlations
        .where((c) => c.positiveRate > 0.5)
        .toList()
      ..sort((a, b) => b.positiveRate.compareTo(a.positiveRate));

    final negativeCorrelations = correlations
        .where((c) => c.negativeRate > 0.3)
        .toList()
      ..sort((a, b) => b.negativeRate.compareTo(a.negativeRate));

    // Meal type moods
    final mealTypeMoods = <String, MealTypeMoodStats>{};
    for (final mealType in ['breakfast', 'lunch', 'dinner', 'snack']) {
      final typeLogs = logsWithMood.where((l) => l.mealType == mealType).toList();
      if (typeLogs.isNotEmpty) {
        final positiveAfter = typeLogs.where((l) {
          final mood = l.moodAfterEnum;
          return mood == FoodMood.great || mood == FoodMood.good || mood == FoodMood.satisfied;
        }).length;

        mealTypeMoods[mealType] = MealTypeMoodStats(
          mealType: mealType,
          totalLogs: typeLogs.length,
          positiveRate: positiveAfter / typeLogs.length,
        );
      }
    }

    return FoodMoodAnalytics(
      totalLogs: logs.length,
      logsWithMood: logsWithMood.length,
      moodBeforeDistribution: moodBeforeDistribution,
      moodAfterDistribution: moodAfterDistribution,
      energyDistribution: energyDistribution,
      averageEnergy: energyCount > 0 ? totalEnergy / energyCount : 0,
      moodTransitions: moodTransitions,
      positiveCorrelations: positiveCorrelations.take(5).toList(),
      negativeCorrelations: negativeCorrelations.take(5).toList(),
      mealTypeMoods: mealTypeMoods,
    );
  }

  bool get hasData => logsWithMood > 0;

  double get moodTrackingRate => totalLogs > 0 ? logsWithMood / totalLogs : 0;

  /// Get improvement rate (transitions to better mood)
  double get moodImprovementRate {
    final improvements = moodTransitions.entries.where((e) {
      final parts = e.key.split('_to_');
      if (parts.length != 2) return false;
      return _isBetterMood(parts[1], parts[0]);
    }).fold<int>(0, (sum, e) => sum + e.value);

    final total = moodTransitions.values.fold<int>(0, (sum, v) => sum + v);
    return total > 0 ? improvements / total : 0;
  }

  bool _isBetterMood(String after, String before) {
    const moodRanking = {
      'great': 5,
      'good': 4,
      'satisfied': 4,
      'neutral': 3,
      'tired': 2,
      'hungry': 2,
      'stressed': 1,
      'bloated': 1,
    };
    return (moodRanking[after] ?? 3) > (moodRanking[before] ?? 3);
  }
}

/// Food to mood correlation
class FoodMoodCorrelation {
  final String foodName;
  final int occurrences;
  final double positiveRate;
  final double negativeRate;

  const FoodMoodCorrelation({
    required this.foodName,
    required this.occurrences,
    required this.positiveRate,
    required this.negativeRate,
  });
}

/// Meal type mood statistics
class MealTypeMoodStats {
  final String mealType;
  final int totalLogs;
  final double positiveRate;

  const MealTypeMoodStats({
    required this.mealType,
    required this.totalLogs,
    required this.positiveRate,
  });
}

/// Food Mood Analytics Card Widget
class FoodMoodAnalyticsCard extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const FoodMoodAnalyticsCard({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(foodMoodAnalyticsProvider(userId));

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return GestureDetector(
      onTap: () => _showAnalyticsSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
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
                    color: purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.mood,
                    color: purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'FOOD & MOOD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            analyticsAsync.when(
              loading: () => _buildLoadingState(textMuted),
              error: (_, __) => _buildErrorState(textMuted),
              data: (analytics) {
                if (!analytics.hasData) {
                  return _buildNoDataState(textMuted, purple);
                }
                return _buildSummary(analytics, textPrimary, textMuted, purple);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(
          'Analyzing mood patterns...',
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
      ],
    );
  }

  Widget _buildErrorState(Color textMuted) {
    return Text(
      'Unable to load mood data',
      style: TextStyle(fontSize: 14, color: textMuted),
    );
  }

  Widget _buildNoDataState(Color textMuted, Color purple) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start tracking mood',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Log how you feel before and after meals to discover patterns',
          style: TextStyle(fontSize: 12, color: textMuted.withOpacity(0.7)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tips_and_updates, size: 14, color: purple),
              const SizedBox(width: 6),
              Text(
                'Available when logging meals',
                style: TextStyle(fontSize: 11, color: purple),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(
    FoodMoodAnalytics analytics,
    Color textPrimary,
    Color textMuted,
    Color purple,
  ) {
    return Column(
      children: [
        // Stats row
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                '${(analytics.moodImprovementRate * 100).toStringAsFixed(0)}%',
                'Mood improved',
                const Color(0xFF6BCB77),
              ),
            ),
            Container(width: 1, height: 40, color: textMuted.withOpacity(0.2)),
            Expanded(
              child: _buildStatItem(
                analytics.averageEnergy.toStringAsFixed(1),
                'Avg energy',
                const Color(0xFFF39C12),
              ),
            ),
            Container(width: 1, height: 40, color: textMuted.withOpacity(0.2)),
            Expanded(
              child: _buildStatItem(
                '${analytics.logsWithMood}',
                'Tracked meals',
                purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Top insight
        if (analytics.positiveCorrelations.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6BCB77).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_capitalize(analytics.positiveCorrelations.first.foodName)} often improves your mood',
                    style: TextStyle(
                      fontSize: 12,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _showAnalyticsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FoodMoodAnalyticsSheet(
        userId: userId,
        isDark: isDark,
      ),
    );
  }
}

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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: nearBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
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
