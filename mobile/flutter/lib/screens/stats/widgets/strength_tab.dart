import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../progress/widgets/strength_overview_card.dart';
import 'muscle_score_breakdown_sheet.dart';
import 'overview_tab.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../common/app_refresh_indicator.dart';
// ═══════════════════════════════════════════════════════════════════
// STRENGTH TAB - Readiness, Strength Scores, PRs, Analytics
// ═══════════════════════════════════════════════════════════════════

class StrengthTab extends ConsumerWidget {
  final String? userId;

  const StrengthTab({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      // userId resolves a tick after the Stats screen mounts. Show a
      // layout-matched skeleton instead of a blocking spinner so the tab
      // never flashes a centred CircularProgressIndicator.
      return _buildSkeleton();
    }

    final tc = ThemeColors.of(context);

    return Stack(
      children: [
        AppRefreshIndicator(
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
                // Tap = open the Phase-4 per-exercise contribution drill-down
                // (Gravl-equivalent "see the logic / exercises contributing").
                // Long-press fallback opens the muscle-analytics history page.
                StrengthOverviewCard(
                  userId: userId!,
                  onTapMuscleGroup: (muscleGroup) {
                    MuscleScoreBreakdownSheet.show(context, muscleGroup);
                  },
                ),
                const SizedBox(height: 24),

                // Recent Personal Records
                SectionHeader(title: AppLocalizations.of(context).strengthRecentPersonalRecords),
                const SizedBox(height: 12),
                const PRListWidget(),
                const SizedBox(height: 16),

                const SizedBox(height: 80), // Bottom padding for floating buttons
              ],
            ),
          ),
        ),

        // Floating analytics buttons at bottom
        PositionedDirectional(start: 16,
          end: 16,
          bottom: 16,
          child: Container(
            decoration: BoxDecoration(
              color: tc.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
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
                    label: AppLocalizations.of(context).strengthExercisesPrs,
                    color: tc.accent,
                    onTap: () => context.push('/stats/exercise-history'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FloatingNavButton(
                    icon: Icons.fitness_center,
                    label: AppLocalizations.of(context).strengthMuscleAnalytics,
                    color: tc.textSecondary,
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

  /// Layout-matched skeleton for the Strength tab: fitness score card,
  /// strength overview card, then a few recent-PR rows. Mirrors the real
  /// scroll body so the skeleton → content swap is reflow-free.
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          // Fitness Score card
          SkeletonBox(height: 220, radius: 16),
          SizedBox(height: 16),
          // Strength Overview card
          SkeletonBox(height: 180, radius: 16),
          SizedBox(height: 24),
          // "Recent Personal Records" header
          SkeletonBox(width: 200, height: 18, radius: 6),
          SizedBox(height: 12),
          // PR rows
          SkeletonList(itemCount: 3, spacing: 12),
          SizedBox(height: 80),
        ],
      ),
    );
  }
}

/// Fitness Score Summary Card showing overall score and 4 component breakdowns
class FitnessScoreCard extends ConsumerWidget {
  final String userId;

  const FitnessScoreCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;

    final fitnessBreakdown = ref.watch(fitnessScoreBreakdownProvider);

    if (fitnessBreakdown == null) {
      return const SizedBox.shrink();
    }

    final overallScore = fitnessBreakdown.overallScore;

    final components = [
      _ScoreComponent('Strength', fitnessBreakdown.strengthScore, 0.40),
      _ScoreComponent('Consistency', fitnessBreakdown.consistencyScore, 0.30),
      _ScoreComponent('Nutrition', fitnessBreakdown.nutritionScore, 0.20),
      _ScoreComponent('Readiness', fitnessBreakdown.readinessScore, 0.10),
    ];

    // The single accent bar = the highest-scoring component (the "peak").
    final peakScore =
        components.map((c) => c.score).fold<int>(0, (a, b) => a > b ? a : b);

    return ZealovaCard(
      variant: ZealovaCardVariant.hero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: big Anton score numeral carries the hierarchy.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$overallScore',
                style: ZType.disp(56, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .strengthFitnessScore
                          .toUpperCase(),
                      style: ZType.lbl(13,
                          color: tc.textSecondary, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fitnessBreakdown.levelDescription,
                      style: ZType.lbl(11,
                          color: tc.textMuted, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ZealovaRule(margin: const EdgeInsets.only(bottom: 14)),

          // Component bars — thin hairline tracks; only the peak bar is accent.
          ...components.map((c) {
            final isPeak = c.score == peakScore && peakScore > 0;
            final barColor = isPeak ? accent : tc.textSecondary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${c.label.toUpperCase()}  ${(c.weight * 100).toInt()}%',
                        style: ZType.lbl(10,
                            color: tc.textMuted, letterSpacing: 1.2),
                      ),
                      Text(
                        '${c.score}',
                        style: ZType.data(12, color: tc.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      value: c.score / 100,
                      minHeight: 3,
                      backgroundColor: AppColors.hairline,
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ScoreComponent {
  final String label;
  final int score;
  final double weight;

  const _ScoreComponent(this.label, this.score, this.weight);
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
    final tc = ThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: ZType.lbl(11,
                      color: tc.textSecondary, letterSpacing: 1.2),
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
