import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

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
  late AnimationController _shimmerController;
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

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

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
    _shimmerController.dispose();
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
          AnimatedBuilder(
            animation: Listenable.merge([_countAnimation, _shimmerController]),
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color,
                      widget.color.withValues(alpha: 0.5),
                      Colors.white,
                      widget.color.withValues(alpha: 0.5),
                      widget.color,
                    ],
                    stops: [
                      0.0,
                      _shimmerController.value - 0.3,
                      _shimmerController.value,
                      _shimmerController.value + 0.3,
                      1.0,
                    ].map((s) => s.clamp(0.0, 1.0)).toList(),
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text(
                  '${_countAnimation.value}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
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
        color: scoreColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Text(
        '$score/10',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: scoreColor,
        ),
      ),
    );
  }
}

/// Labeled pill for secondary meal scores (health, goal alignment).
class _LabeledScorePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LabeledScorePill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$label ',
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row that surfaces the meal's health score and goal alignment %
/// alongside the overall meal score chip already in the header.
class MealScoreBreakdownRow extends StatelessWidget {
  final int? healthScore;
  final int? goalAlignmentPercentage;

  const MealScoreBreakdownRow({
    super.key,
    this.healthScore,
    this.goalAlignmentPercentage,
  });

  bool get _hasAnything =>
      healthScore != null || goalAlignmentPercentage != null;

  Color _healthColor(int score) {
    if (score >= 8) return AppColors.green;
    if (score >= 5) return AppColors.teal;
    if (score >= 3) return AppColors.yellow;
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

    return Row(
      children: [
        if (healthScore != null)
          _LabeledScorePill(
            icon: Icons.favorite,
            label: 'Health',
            value: '${healthScore!}/10',
            color: _healthColor(healthScore!),
          ),
        if (healthScore != null && goalAlignmentPercentage != null)
          const SizedBox(width: 8),
        if (goalAlignmentPercentage != null)
          _LabeledScorePill(
            icon: Icons.flag,
            label: 'Goal fit',
            value: '${goalAlignmentPercentage!}%',
            color: _alignmentColor(goalAlignmentPercentage!),
          ),
      ],
    );
  }
}
