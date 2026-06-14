import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'inflammation_chip.dart' show inflammationColor;
import 'score_explain_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Animated calorie chip with count-up and shimmer effect
class AnimatedCalorieChip extends StatefulWidget {
  final int calories;
  final Color color;

  const AnimatedCalorieChip({
    super.key,
    required this.calories,
    required this.color,
  });

  @override
  State<AnimatedCalorieChip> createState() => _AnimatedCalorieChipState();
}

class _AnimatedCalorieChipState extends State<AnimatedCalorieChip>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _countAnimation = IntTween(begin: 0, end: widget.calories).animate(
      CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
    );

    _countController.forward();
  }

  @override
  void didUpdateWidget(AnimatedCalorieChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calories != widget.calories) {
      _countAnimation = IntTween(
        begin: _countAnimation.value,
        end: widget.calories,
      ).animate(
        CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
      );
      _countController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 16, color: widget.color),
          const SizedBox(height: 4),
          // The earlier shimmer ShaderMask blended `Colors.white` into the
          // text gradient, which against the light-mode card background
                // rendered the digits effectively invisible mid-shimmer (user
          // report 2026-05-25: "calorie not displaying properly after I
          // hit Analyze"). Plain animated text matches the macro chips and
          // keeps the count-up motion without the visibility regression.
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, child) {
              return Text(
                '${_countAnimation.value}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              );
            },
          ),
          Text(
            'kcal',
            style: TextStyle(
              fontSize: 9,
              color: widget.color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact macro chip for the single-row macro display
class CompactMacroChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const CompactMacroChip({
    super.key,
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact goal score badge
class CompactGoalScore extends StatelessWidget {
  final int score;
  final bool isDark;

  const CompactGoalScore({
    super.key,
    required this.score,
    required this.isDark,
  });

  Color _getScoreColor() {
    if (score >= 8) return AppColors.green;
    if (score >= 5) return AppColors.yellow;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scoreColor.withValues(alpha: 0.45)),
      ),
      child: Text(
        AppLocalizations.of(context)!.mealScoreWidgetsValue(score),
        style: ZType.data(13, color: scoreColor),
      ),
    );
  }
}

/// Labeled pill for secondary meal scores (health, goal alignment).
///
/// When [showHelpIcon] is true a small "?" glyph is appended after the value
/// to signal the pill is tappable (opens the ScoreExplainSheet).
class _LabeledScorePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showHelpIcon;

  const _LabeledScorePill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showHelpIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    // Content-sized (mainAxisSize.min, no Flexible) so the pill is safe inside
    // the parent Wrap — a Flexible/Expanded child under Wrap's unbounded width
    // would throw. Labels are short ("Health", "Inflammation", "Goal Fit"), so
    // they never need to ellipsize.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: ZType.lbl(9.5, color: color.withValues(alpha: 0.85), letterSpacing: 1.2),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: ZType.data(12, color: color),
          ),
          if (showHelpIcon) ...[
            const SizedBox(width: 4),
            Icon(Icons.help_outline, size: 12, color: color.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );
  }
}

/// Row that surfaces the meal's health score and goal alignment %
/// alongside the overall meal score chip already in the header.
class MealScoreBreakdownRow extends StatelessWidget {
  final int? healthScore;
  final int? goalAlignmentPercentage;
  /// `health_score_reasons` chips shown by the ScoreExplainSheet when the
  /// Health pill is tapped. Pass either Gemini-emitted tags or locally
  /// derived ones via `healthReasonsFromSignals`.
  final List<String>? healthScoreReasons;
  /// Meal-level inflammation score (0-10). When present, an "Inflammation N/10"
  /// pill renders beside Health so the two diet-quality scores read together
  /// at a glance (user request — they only saw Health here before).
  final int? inflammationScore;
  /// `inflammation_triggers` tags shown by the ScoreExplainSheet when the
  /// inflammation pill is tapped.
  final List<String>? inflammationTriggers;

  const MealScoreBreakdownRow({
    super.key,
    this.healthScore,
    this.goalAlignmentPercentage,
    this.healthScoreReasons,
    this.inflammationScore,
    this.inflammationTriggers,
  });

  bool get _hasAnything =>
      healthScore != null ||
      goalAlignmentPercentage != null ||
      inflammationScore != null;

  Color _healthColor(int score) {
    // 3-tier scheme aligned with ScoreExplainSheet's legend bands so the
    // "Health X/10" pill colour always matches the explainer sheet:
    // >=7 GOOD (green), >=4 AVERAGE (teal-600), else POOR (coral).
    // NOT AppColors.teal — that constant is #C0C0C0 (silver grey), which made
    // the "Health X/10" pill icon + text unreadable. Real teal (teal-600).
    if (score >= 7) return AppColors.green;
    if (score >= 4) return const Color(0xFF0D9488);
    return AppColors.coral;
  }

  Color _alignmentColor(int pct) {
    if (pct >= 80) return AppColors.green;
    if (pct >= 50) return AppColors.yellow;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAnything) return const SizedBox.shrink();

    // Wrap (not Row) so up to three pills — Health, Inflammation, Goal Fit —
    // flow onto a second line on narrow devices (iPhone SE) instead of
    // overflowing. NOTE: every pill must use selfExpand:false here — an
    // Expanded inside a Wrap throws a ParentDataWidget error.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (healthScore != null)
          // Tap-to-explain — opens ScoreExplainSheet with reason chips.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ScoreExplainSheet.showHealth(
              context,
              score: healthScore,
              reasons: healthScoreReasons ?? const ['ai_unavailable'],
            ),
            child: _LabeledScorePill(
              icon: Icons.favorite,
              label: AppLocalizations.of(context).mealScoreWidgetsHealth,
              value: '${healthScore!}/10',
              color: _healthColor(healthScore!),
              showHelpIcon: true,
            ),
          ),
        if (inflammationScore != null)
          // Inflammation, beside Health. Neutral icon (NOT a flame — see
          // InflammationChip) + the shared inflammationColor() grading so the
          // pill matches the chip everywhere else.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ScoreExplainSheet.show(
              context,
              kind: ScoreKind.inflammation,
              value: inflammationScore,
              triggers: inflammationTriggers ?? const [],
            ),
            child: _LabeledScorePill(
              icon: Icons.bubble_chart_outlined,
              label: 'Inflammation',
              value: '${inflammationScore!}/10',
              color: inflammationColor(inflammationScore!),
              showHelpIcon: true,
            ),
          ),
        if (goalAlignmentPercentage != null)
          _LabeledScorePill(
            icon: Icons.flag,
            label: AppLocalizations.of(context).mealScoreWidgetsGoalFit,
            value: '${goalAlignmentPercentage!}%',
            color: _alignmentColor(goalAlignmentPercentage!),
          ),
      ],
    );
  }
}
