import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/scores.dart';
import '../../../../data/providers/scores_provider.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/context_logging_service.dart';
import '../../../../data/services/haptic_service.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Compact fitness score card for home screen.
/// Shows overall fitness score with strength and nutrition breakdown.
/// Taps to navigate to the full scoring screen.
///
/// Day-zero honesty (E2E register #17): `/scores/overview` returns
/// `overall_fitness_score`, `nutrition_score` and `consistency_score` as
/// **null** until the corresponding row exists (`fitness_scores` /
/// `nutrition_scores` / `latest_strength_scores` were all empty for both
/// 2026-07-28 QA accounts). `ScoresState`'s getters coalesce those nulls to
/// `0`, so a user who signed up minutes ago was handed a graded scorecard
/// reading Strength 0 / Overall 0 / Nutrition 0 / Consistency 0%, in the
/// "worst band" colour, under a level badge. That is a fabricated score in
/// exactly the same class as the 2000 kcal default: a number the server never
/// produced, presented as the user's own.
///
/// So the card asks whether a score EXISTS before it renders one. With no
/// computed score it shows a starting state that names what produces the
/// score, and never a digit. It flips to the real scorecard the moment the
/// backend has one.
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
    // .select() the scalar slices this card reads — a whole-state watch
    // rebuilt it on every scores mutation (PR loads, errors, etc.).
    // Every pillar is read from its NULLABLE source, never from the `?? 0`
    // getters on ScoresState. A 0 out of those getters is indistinguishable
    // from "the server never computed this", and printing it is the same
    // fabricated-number defect as the 2000 kcal default (register #17).
    //
    // Per-pillar, not per-card: gating the whole card on "any score exists"
    // still ships fabricated zeros the moment ONE pillar lands — a user who
    // logs meals for three days gets a nutrition score and is then shown
    // Strength 0, Overall 0, Readiness 0 and Consistency 0% next to it, under
    // a "BEGINNER" badge the backend never assigned. Each value now renders
    // only if it exists; the rest render an em dash.
    final (
      bool initialLoading,
      int? overallScore,
      int? strengthScore,
      int? nutritionScore,
      int? consistencyScore,
      FitnessLevel? fitnessLevel,
      int? readinessScore,
    ) = ref.watch(scoresProvider.select((s) => (
          s.isLoading && s.overview == null,
          s.fitnessScore?.overallScore ?? s.overview?.overallFitnessScore,
          // `ScoresOverview.overallStrengthScore` is a non-nullable int the
          // backend fills with 0 when `latest_strength_scores` has no row, so
          // 0-from-overview is treated as absent (a genuine strength score of
          // 0 is not a state the scorer produces).
          s.strengthScores?.overallScore ??
              ((s.overview?.overallStrengthScore ?? 0) > 0
                  ? s.overview!.overallStrengthScore
                  : null),
          s.nutritionScore?.overallScore ?? s.overview?.nutritionScore,
          s.fitnessScore?.consistencyScore ?? s.overview?.consistencyScore,
          // Level is derived from the overall score — no score, no level, and
          // never the enum's `beginner` default as a stand-in.
          s.fitnessScore?.level ??
              (s.overview?.fitnessLevel != null
                  ? s.overview!.fitnessLevelEnum
                  : null),
          s.todayReadiness?.readinessScore ??
              s.overview?.todayReadiness?.readinessScore,
        )));
    // The card frame itself only appears once SOMETHING has been scored;
    // otherwise the starting state below is the honest surface.
    final hasComputedScore = overallScore != null ||
        strengthScore != null ||
        nutritionScore != null ||
        consistencyScore != null;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    // Don't show if still loading initial data
    if (initialLoading) {
      return _buildLoadingCard(isDark);
    }

    // Nothing has been scored yet — show the honest starting state instead of
    // a graded 0 / 0 / 0 / 0% scorecard the backend never computed.
    if (!hasComputedScore) {
      return _buildStartingStateCard(isDark);
    }

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
              context.push('/stats');
            },
            borderRadius: BorderRadius.circular(16),
            child: Builder(
              builder: (context) {
                final accentColor = ref.colors(context).accent;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  child: Column(
                  children: [
                    // Title row
                    Row(
                      children: [
                        Icon(
                          Icons.insights,
                          color: accentColor,
                          size: 20,
                        ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).strengthFitnessScore,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    // No overall score → no level badge. `FitnessLevel`'s
                    // `beginner` default is a stand-in the backend never
                    // assigned; showing it grades a user who hasn't been
                    // graded.
                    if (fitnessLevel != null)
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
                        label: AppLocalizations.of(context).scoreBreakdownStrength,
                        score: strengthScore,
                        icon: Icons.fitness_center,
                        isDark: isDark,
                      ),
                    ),
                    // Overall score (center - larger)
                    Expanded(
                      flex: 2,
                      child: _OverallScoreCircle(score: overallScore),
                    ),
                    // Nutrition score (right)
                    Expanded(
                      child: _ScoreItem(
                        label: AppLocalizations.of(context).settingsNutritionSection,
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
                      label: AppLocalizations.of(context).strengthOverviewCardReadiness,
                      // No check-in today → no readiness. "0" would read as a
                      // catastrophic readiness rather than "not measured".
                      value: readinessScore == null
                          ? _kNoValue
                          : '$readinessScore',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 20),
                    _BottomIndicator(
                      icon: Icons.trending_up,
                      label: AppLocalizations.of(context).scoreBreakdownConsistency,
                      value: consistencyScore == null
                          ? _kNoValue
                          : AppLocalizations.of(context)!
                              .fitnessScoreCardValue(consistencyScore),
                      isDark: isDark,
                    ),
                  ],
                ),
                  ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.colors(context).accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).fitnessScoreCardLoadingScores,
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

  /// Day-zero / no-data state. Same frame as the real card so the home rhythm
  /// doesn't jump when the first score lands, but it carries NO digits, no
  /// rings at 0 and no level badge — a score that does not exist is never
  /// drawn as a zero.
  Widget _buildStartingStateCard(bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.colors(context).accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticService.light();
            context.push('/stats');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.insights, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your fitness score starts here',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Strength, nutrition and consistency get scored from '
                        'what you log. Finish a session and log a day of '
                        'meals, and the first real numbers land here.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int? score) => _scoreColor(score);
}

/// Placeholder printed wherever the backend has not produced a score. Never a
/// digit — a missing score must not be readable as a bad score.
const String _kNoValue = '—';

/// Band colour for a score, or a neutral grey when there is no score to band.
Color _scoreColor(int? score) {
  if (score == null) return AppColors.textMuted;
  if (score >= 80) return AppColors.green;
  if (score >= 60) return AppColors.cyan;
  if (score >= 40) return AppColors.yellow;
  return Colors.orange;
}

/// Central overall score display
class _OverallScoreCircle extends StatelessWidget {
  final int? score;

  const _OverallScoreCircle({required this.score});

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
                  score == null ? _kNoValue : '$score',
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
          AppLocalizations.of(context).overallScoreHeroOverall,
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

  Color _getScoreColor(int? score) => _scoreColor(score);
}

/// Small score item for strength/nutrition
class _ScoreItem extends StatelessWidget {
  final String label;

  /// Null when the backend has produced no score for this pillar — the ring
  /// stays empty and neutral and the value reads as an em dash, never 0.
  final int? score;
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
    final progress = (score ?? 0) / 100.0;

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
          score == null ? _kNoValue : '$score',
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

  Color _getScoreColor(int? score) => _scoreColor(score);
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
          AppLocalizations.of(context)!.fitnessScoreCardValue2(label),
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
