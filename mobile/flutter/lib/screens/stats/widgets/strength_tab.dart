import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../widgets/app_loading.dart';
import '../../progress/widgets/strength_overview_card.dart';
import 'overview_tab.dart';

// ═══════════════════════════════════════════════════════════════════
// STRENGTH TAB - Readiness, Strength Scores, PRs, Analytics
// ═══════════════════════════════════════════════════════════════════

class StrengthTab extends ConsumerWidget {
  final String? userId;

  const StrengthTab({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return AppLoading.fullScreen();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await ref.read(scoresProvider.notifier).loadAllScores(userId: userId);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fitness Score Summary
                FitnessScoreCard(userId: userId!),
                const SizedBox(height: 16),

                // Strength Overview Card
                StrengthOverviewCard(
                  userId: userId!,
                  onTapMuscleGroup: (muscleGroup) {
                    context.push('/stats/muscle-analytics/$muscleGroup');
                  },
                ),
                const SizedBox(height: 24),

                // Recent Personal Records
                SectionHeader(title: 'Recent Personal Records'),
                const SizedBox(height: 12),
                const PRListWidget(),
                const SizedBox(height: 16),

                const SizedBox(height: 80), // Bottom padding for floating buttons
              ],
            ),
          ),
        ),

        // Floating analytics buttons at bottom
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _FloatingNavButton(
                    icon: Icons.emoji_events,
                    label: 'Exercises & PRs',
                    color: colorScheme.primary,
                    onTap: () => context.push('/stats/exercise-history'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FloatingNavButton(
                    icon: Icons.fitness_center,
                    label: 'Muscle Analytics',
                    color: colorScheme.secondary,
                    onTap: () => context.push('/stats/muscle-analytics'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Fitness Score Summary Card showing overall score and 4 component breakdowns
class FitnessScoreCard extends ConsumerWidget {
  final String userId;

  const FitnessScoreCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final fitnessBreakdown = ref.watch(fitnessScoreBreakdownProvider);

    if (fitnessBreakdown == null) {
      return const SizedBox.shrink();
    }

    final overallScore = fitnessBreakdown.overallScore;
    final levelColor = Color(fitnessBreakdown.levelColorValue);

    final components = [
      _ScoreComponent('Strength', fitnessBreakdown.strengthScore, 0.40, const Color(0xFFEF4444)),
      _ScoreComponent('Consistency', fitnessBreakdown.consistencyScore, 0.30, const Color(0xFF3B82F6)),
      _ScoreComponent('Nutrition', fitnessBreakdown.nutritionScore, 0.20, const Color(0xFF22C55E)),
      _ScoreComponent('Readiness', fitnessBreakdown.readinessScore, 0.10, const Color(0xFFA855F7)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with overall score
          Row(
            children: [
              // Score circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: levelColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$overallScore',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitness Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fitnessBreakdown.levelDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: levelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Component bars
          ...components.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${c.label} (${(c.weight * 100).toInt()}%)',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    Text(
                      '${c.score}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: c.score / 100,
                    minHeight: 6,
                    backgroundColor: c.color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(c.color),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ScoreComponent {
  final String label;
  final int score;
  final double weight;
  final Color color;

  const _ScoreComponent(this.label, this.score, this.weight, this.color);
}

class _FloatingNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FloatingNavButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
