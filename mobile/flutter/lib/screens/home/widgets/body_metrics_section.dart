import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/stat_typography.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Body Metrics & Score section for home screen
/// Shows fitness score, strength score, and key body metrics
class BodyMetricsSection extends ConsumerStatefulWidget {
  const BodyMetricsSection({super.key});

  @override
  ConsumerState<BodyMetricsSection> createState() => _BodyMetricsSectionState();
}

class _BodyMetricsSectionState extends ConsumerState<BodyMetricsSection> {
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
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    // .select() the 4 scalars this section reads — a whole-state watch
    // rebuilt it on every scores mutation (isLoading flips, PR loads, etc.).
    final (overallScore, strengthScore, consistencyScore, fitnessLevel) =
        ref.watch(scoresProvider.select((s) => (
              s.overallFitnessScore,
              s.overallStrengthScore,
              s.consistencyScore,
              s.fitnessLevel,
            )));

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with View All button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).bodyMetricsBodyMetricsScore,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/stats'),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Metrics cards row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Overall Fitness Score - main card
                Expanded(
                  flex: 2,
                  child: _buildScoreCard(
                    context,
                    title: AppLocalizations.of(context).strengthFitnessScore,
                    score: overallScore,
                    subtitle: fitnessLevel.displayName,
                    icon: Icons.fitness_center,
                    accentColor: accentColor,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      HapticService.light();
                      context.push('/stats');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Secondary scores column
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildMiniScoreCard(
                        title: AppLocalizations.of(context).scoreBreakdownStrength,
                        score: strengthScore,
                        icon: Icons.bolt,
                        accentColor: accentColor,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 8),
                      _buildMiniScoreCard(
                        title: AppLocalizations.of(context).scoreBreakdownConsistency,
                        score: consistencyScore,
                        icon: Icons.trending_up,
                        accentColor: accentColor,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
    BuildContext context, {
    required String title,
    required int score,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 16, color: textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            // Hero focal number for the card — big & glanceable, with the
            // "/ 100" denominator rendered as the smaller trailing unit.
            StatNumber(
              value: '$score',
              size: StatType.hero,
              color: accentColor,
              unit: '/ 100',
              unitColor: textSecondary,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniScoreCard({
    required String title,
    required int score,
    required IconData icon,
    required Color accentColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          StatNumber(
            value: '$score',
            size: StatType.secondary,
            color: textPrimary,
          ),
        ],
      ),
    );
  }
}
