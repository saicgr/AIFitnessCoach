import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/skeleton/skeleton.dart';
import '../../../../data/models/scores.dart';
import '../../../../data/providers/scores_provider.dart';
import '../../../../widgets/design_system/zealova.dart';

/// Signature fitness-score breakdown section for the Stats Overview tab.
///
/// This is the consolidated home of the former standalone `/scores` screen:
/// the overall fitness-score hero (big Anton numeral + level badge + hairline
/// ring), the four weighted component scores (Strength 40% / Consistency 30% /
/// Nutrition 20% / Readiness 10%) as a 2x2 grid of hairline tiles, and a
/// compact "how it's weighted" footer.
///
/// Self-contained: it watches [scoresProvider] directly. The parent Stats
/// screen kicks off `loadScoresOverview` when the Overview tab opens (which
/// populates every component score via the overview payload); this section
/// additionally self-triggers `loadFitnessScore()` once so the hero carries the
/// authoritative overall score + week-over-week trend rather than the
/// overview's lighter snapshot. Renders a layout-matched skeleton until the
/// overview slice is populated — never a spinner.
class FitnessScoreBreakdownSection extends ConsumerStatefulWidget {
  const FitnessScoreBreakdownSection({super.key});

  @override
  ConsumerState<FitnessScoreBreakdownSection> createState() =>
      _FitnessScoreBreakdownSectionState();
}

class _FitnessScoreBreakdownSectionState
    extends ConsumerState<FitnessScoreBreakdownSection> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    // Fire after the first frame so the notifier's `_currentUserId` (set by the
    // parent overview load) is available. Guarded so it runs at most once.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  void _ensureLoaded() {
    if (_requested || !mounted) return;
    final state = ref.read(scoresProvider);
    if (state.fitnessScore != null || state.isCalculatingFitness) return;
    _requested = true;
    // No userId arg → notifier falls back to its cached `_currentUserId`.
    ref.read(scoresProvider.notifier).loadFitnessScore();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    final overview = ref.watch(scoresProvider.select((s) => s.overview));
    final overallScore =
        ref.watch(scoresProvider.select((s) => s.overallFitnessScore));
    final level = ref.watch(scoresProvider.select((s) => s.fitnessLevel));
    final strengthScore =
        ref.watch(scoresProvider.select((s) => s.overallStrengthScore));
    final nutritionScore =
        ref.watch(scoresProvider.select((s) => s.nutritionScoreValue));
    final consistencyScore =
        ref.watch(scoresProvider.select((s) => s.consistencyScore));
    final readinessScore =
        ref.watch(scoresProvider.select((s) => s.readinessScore));
    final breakdown = ref.watch(scoresProvider.select((s) => s.fitnessScore));
    final isInitialLoad = ref.watch(
      scoresProvider.select((s) => s.isLoading && s.overview == null),
    );

    final hasData = overview != null || breakdown != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZealovaSectionKicker('Fitness Score', fontSize: 12),
        const SizedBox(height: AppSpacing.sm),
        if (!hasData && isInitialLoad)
          _buildSkeleton(context)
        else ...[
          _ScoreHero(
            overallScore: overallScore,
            level: level,
            scoreChange: breakdown?.scoreChange,
            trend: breakdown?.trend,
            tc: tc,
          ),
          const SizedBox(height: AppSpacing.md),
          _BreakdownGrid(
            strengthScore: strengthScore,
            consistencyScore: consistencyScore,
            nutritionScore: nutritionScore,
            readinessScore: readinessScore,
            tc: tc,
          ),
          const SizedBox(height: AppSpacing.sm),
          _WeightsFooter(tc: tc),
        ],
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(height: 168, radius: 16),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 118, radius: 16)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 118, radius: 16)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 118, radius: 16)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 118, radius: 16)),
          ],
        ),
      ],
    );
  }
}

/// The overall fitness-score hero: a hairline-framed card with a level kicker,
/// a big Anton numeral + hairline progress ring, and a week-over-week delta.
class _ScoreHero extends StatelessWidget {
  final int overallScore;
  final FitnessLevel level;
  final int? scoreChange;
  final String? trend;
  final ThemeColors tc;

  const _ScoreHero({
    required this.overallScore,
    required this.level,
    required this.scoreChange,
    required this.trend,
    required this.tc,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tc.accent;
    final change = scoreChange ?? 0;
    final isUp = change > 0 || trend == 'improving';
    final isDown = change < 0 || trend == 'declining';
    final deltaColor =
        isUp ? tc.success : (isDown ? tc.error : tc.textMuted);
    final deltaIcon = isUp
        ? Icons.arrow_upward_rounded
        : (isDown ? Icons.arrow_downward_rounded : Icons.trending_flat_rounded);
    final deltaLabel = change == 0
        ? 'SAME AS LAST WEEK'
        : (change > 0
            ? '+$change WEEK OVER WEEK'
            : '$change WEEK OVER WEEK');

    return ZealovaCard(
      variant: ZealovaCardVariant.hero,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Hairline ring + centered Anton numeral.
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: (overallScore / 100).clamp(0.0, 1.0),
                    strokeWidth: 5,
                    backgroundColor: AppColors.hairlineStrong,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$overallScore',
                  style: ZType.disp(38, color: accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OVERALL FITNESS',
                  style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 2),
                ),
                const SizedBox(height: 6),
                Text(
                  level.displayName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.lbl(20,
                      color: tc.textPrimary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(deltaIcon, size: 15, color: deltaColor),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        deltaLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZType.lbl(11,
                            color: deltaColor, letterSpacing: 1.2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The 2x2 grid of weighted component scores.
class _BreakdownGrid extends StatelessWidget {
  final int strengthScore;
  final int consistencyScore;
  final int nutritionScore;
  final int readinessScore;
  final ThemeColors tc;

  const _BreakdownGrid({
    required this.strengthScore,
    required this.consistencyScore,
    required this.nutritionScore,
    required this.readinessScore,
    required this.tc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ComponentTile(
                  icon: Icons.fitness_center,
                  label: 'Strength',
                  weight: '40%',
                  score: strengthScore,
                  tc: tc,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ComponentTile(
                  icon: Icons.trending_up,
                  label: 'Consistency',
                  weight: '30%',
                  score: consistencyScore,
                  tc: tc,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ComponentTile(
                  icon: Icons.restaurant,
                  label: 'Nutrition',
                  weight: '20%',
                  score: nutritionScore,
                  tc: tc,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ComponentTile(
                  icon: Icons.local_fire_department,
                  label: 'Readiness',
                  weight: '10%',
                  score: readinessScore,
                  tc: tc,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One weighted component tile: hairline glyph + weight chip, big Anton score,
/// label, and a hairline progress track. The accent is the one accent element.
class _ComponentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String weight;
  final int score;
  final ThemeColors tc;

  const _ComponentTile({
    required this.icon,
    required this.label,
    required this.weight,
    required this.score,
    required this.tc,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tc.accent;
    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tc.textSecondary),
              const Spacer(),
              Text(
                weight,
                style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$score',
            style: ZType.disp(30, color: accent),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: ZType.lbl(11, color: tc.textSecondary, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          // Hairline progress track (3px) — accent fill, no LinearProgress.
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: Stack(
                children: [
                  Container(color: AppColors.hairlineStrong),
                  FractionallySizedBox(
                    widthFactor: (score / 100).clamp(0.0, 1.0),
                    child: Container(color: accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact "how it's weighted" footer — the same weights the standalone
/// scoring screen documented, rendered as a single muted hairline line.
class _WeightsFooter extends StatelessWidget {
  final ThemeColors tc;

  const _WeightsFooter({required this.tc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 13, color: tc.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Strength 40 · Consistency 30 · Nutrition 20 · Readiness 10',
              style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
