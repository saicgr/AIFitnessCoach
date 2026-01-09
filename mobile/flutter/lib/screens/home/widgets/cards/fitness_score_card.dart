import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/scores.dart';
import '../../../../data/providers/scores_provider.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/context_logging_service.dart';
import '../../../../data/services/haptic_service.dart';

/// Compact fitness score card for home screen.
/// Shows overall fitness score with strength and nutrition breakdown.
/// Taps to navigate to the full scoring screen.
class FitnessScoreCard extends ConsumerStatefulWidget {
  const FitnessScoreCard({super.key});

  @override
  ConsumerState<FitnessScoreCard> createState() => _FitnessScoreCardState();
}

class _FitnessScoreCardState extends ConsumerState<FitnessScoreCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScores();
    });
  }

  void _loadScores() {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      ref.read(scoresProvider.notifier).loadScoresOverview(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoresState = ref.watch(scoresProvider);
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    // Don't show if still loading initial data
    if (scoresState.isLoading && scoresState.overview == null) {
      return _buildLoadingCard(isDark);
    }

    final overallScore = scoresState.overallFitnessScore;
    final strengthScore = scoresState.overallStrengthScore;
    final nutritionScore = scoresState.nutritionScoreValue;
    final consistencyScore = scoresState.consistencyScore;
    final fitnessLevel = scoresState.fitnessLevel;
    final readinessScore = scoresState.readinessScore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getScoreColor(overallScore).withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              HapticService.light();
              // Log score view
              ref.read(contextLoggingServiceProvider).logScoreView(
                screen: 'home_card',
              );
              context.push('/scores');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: AppColors.cyan, width: 4),
                  top: BorderSide(color: _getScoreColor(overallScore).withOpacity(0.3)),
                  right: BorderSide(color: _getScoreColor(overallScore).withOpacity(0.3)),
                  bottom: BorderSide(color: _getScoreColor(overallScore).withOpacity(0.3)),
                ),
              ),
              child: Column(
              children: [
                // Title row
                Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: AppColors.cyan,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fitness Score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(overallScore).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fitnessLevel.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(overallScore),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Scores row
                Row(
                  children: [
                    // Strength score (left)
                    Expanded(
                      child: _ScoreItem(
                        label: 'Strength',
                        score: strengthScore,
                        icon: Icons.fitness_center,
                        isDark: isDark,
                      ),
                    ),
                    // Overall score (center - larger)
                    Expanded(
                      flex: 2,
                      child: _OverallScoreCircle(
                        score: overallScore,
                        level: fitnessLevel,
                      ),
                    ),
                    // Nutrition score (right)
                    Expanded(
                      child: _ScoreItem(
                        label: 'Nutrition',
                        score: nutritionScore,
                        icon: Icons.restaurant,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BottomIndicator(
                      icon: Icons.local_fire_department,
                      label: 'Readiness',
                      value: '$readinessScore',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 20),
                    _BottomIndicator(
                      icon: Icons.trending_up,
                      label: 'Consistency',
                      value: '$consistencyScore%',
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: AppColors.cyan, width: 4),
              top: BorderSide(color: AppColors.cyan.withOpacity(0.2)),
              right: BorderSide(color: AppColors.cyan.withOpacity(0.2)),
              bottom: BorderSide(color: AppColors.cyan.withOpacity(0.2)),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading scores...',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.green;
    if (score >= 60) return AppColors.cyan;
    if (score >= 40) return AppColors.yellow;
    return Colors.orange;
  }
}

/// Central overall score display
class _OverallScoreCircle extends StatelessWidget {
  final int score;
  final FitnessLevel level;

  const _OverallScoreCircle({
    required this.score,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'OVERALL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.green;
    if (score >= 60) return AppColors.cyan;
    if (score >= 40) return AppColors.yellow;
    return Colors.orange;
  }
}

/// Small score item for strength/nutrition
class _ScoreItem extends StatelessWidget {
  final String label;
  final int score;
  final IconData icon;
  final bool isDark;

  const _ScoreItem({
    required this.label,
    required this.score,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final scoreColor = _getScoreColor(score);
    final progress = score / 100.0;

    return Column(
      children: [
        // Circular ring with icon
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated progress ring
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4,
                  backgroundColor: textMuted.withOpacity(0.15),
                  color: scoreColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Icon in center
              Icon(
                icon,
                color: scoreColor,
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.green;
    if (score >= 60) return AppColors.cyan;
    if (score >= 40) return AppColors.yellow;
    return Colors.orange;
  }
}

/// Bottom indicator for readiness/consistency
class _BottomIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _BottomIndicator({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          ),
        ),
      ],
    );
  }
}
