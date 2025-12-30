import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/context_logging_service.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/overall_score_hero.dart';
import 'widgets/score_breakdown_section.dart';
import 'widgets/nutrition_score_card.dart';
import 'widgets/consistency_score_card.dart';

/// Full scoring screen showing detailed fitness score breakdown.
class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({super.key});

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScores();
    });
  }

  @override
  void dispose() {
    // Log time spent on screen
    final duration = DateTime.now().difference(_startTime).inMilliseconds;
    ref.read(contextLoggingServiceProvider).logScoreView(
      screen: 'scoring_screen',
      durationMs: duration,
    );
    super.dispose();
  }

  void _loadScores() {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      ref.read(scoresProvider.notifier).loadAllScores(userId: userId);
    }
  }

  Future<void> _onRefresh() async {
    HapticService.light();
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      await ref.read(scoresProvider.notifier).refreshAll(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoresState = ref.watch(scoresProvider);
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            floating: true,
            pinned: false,
            title: Text(
              'Fitness Score',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: scoresState.isLoading ? AppColors.textMuted : textColor,
                ),
                onPressed: scoresState.isLoading ? null : _onRefresh,
              ),
            ],
          ),
          // Content
          if (scoresState.isLoading && scoresState.overview == null)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            SliverToBoxAdapter(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: _buildContent(context, scoresState, isDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScoresState state, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Overall score hero
          OverallScoreHero(
            overallScore: state.overallFitnessScore,
            level: state.fitnessLevel,
            trend: state.fitnessScore?.trend,
            previousScore: state.fitnessScore?.previousScore,
          ),
          const SizedBox(height: 24),
          // Score breakdown
          ScoreBreakdownSection(
            strengthScore: state.overallStrengthScore,
            nutritionScore: state.nutritionScoreValue,
            consistencyScore: state.consistencyScore,
            readinessScore: state.readinessScore,
          ),
          const SizedBox(height: 24),
          // Nutrition score detail
          NutritionScoreCard(
            score: state.nutritionScore,
            level: state.nutritionLevel,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // Consistency score detail
          ConsistencyScoreCard(
            consistencyScore: state.consistencyScore,
            overview: state.overview,
            isDark: isDark,
          ),
          const SizedBox(height: 32),
          // How scores are calculated
          _buildHowItWorks(isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(bool isDark) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.cyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How Scores Are Calculated',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWeightItem('Strength Score', '40%', textMuted),
          _buildWeightItem('Consistency', '30%', textMuted),
          _buildWeightItem('Nutrition', '20%', textMuted),
          _buildWeightItem('Readiness', '10%', textMuted),
          const SizedBox(height: 8),
          Text(
            'Your overall fitness score combines these factors to give you a comprehensive view of your fitness journey.',
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightItem(String label, String weight, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.cyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
          Text(
            weight,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}
