import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../services/menu_recommendation_service.dart';
import '../../../../widgets/glass_sheet.dart';

/// "Why this pick?" glass sheet — renders the top positive + negative
/// signal contributions with substituted user numbers so the
/// recommendation feels transparent instead of magical.
class RecommendationExplainSheet extends StatelessWidget {
  final RecommendedItem pick;
  final int rank;
  final int totalAccepted;

  const RecommendationExplainSheet({
    super.key,
    required this.pick,
    required this.rank,
    required this.totalAccepted,
  });

  static Future<void> show(
    BuildContext context, {
    required RecommendedItem pick,
    required int rank,
    required int totalAccepted,
  }) {
    return showGlassSheet<void>(
      context: context,
      builder: (_) => RecommendationExplainSheet(
        pick: pick, rank: rank, totalAccepted: totalAccepted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = pick.topContributionsMeaningful(5);
    return GlassSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why ${pick.item.name}?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Score ${(pick.weightedScore * 10).toStringAsFixed(1)} / 10 · '
              'Rank #$rank of $totalAccepted',
              style: TextStyle(
                fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...top.map((kind) => _row(context, kind)),
            const SizedBox(height: 10),
            _AxisStrip(axes: pick.axes),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, SignalKind kind) {
    final contribution = pick.contributions[kind] ?? 0;
    final signalValue = _signalValue(kind);
    final isPositive = contribution > 0;
    final icon = isPositive ? Icons.check_circle : Icons.cancel;
    final color = isPositive ? AppColors.success : AppColors.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _reasonText(kind, signalValue, pick),
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  double _signalValue(SignalKind kind) {
    switch (kind) {
      case SignalKind.macroFit: return pick.signals.macroFit;
      case SignalKind.goalAlignment: return pick.signals.goalAlignment;
      case SignalKind.favoriteMatch: return pick.signals.favoriteMatch;
      case SignalKind.historyAffinity: return pick.signals.historyAffinity;
      case SignalKind.healthQuality: return pick.signals.healthQuality;
      case SignalKind.priceFit: return pick.signals.priceFit;
      case SignalKind.varietyBonus: return pick.signals.varietyBonus;
    }
  }

  String _reasonText(SignalKind kind, double value, RecommendedItem pick) {
    final item = pick.item;
    switch (kind) {
      case SignalKind.macroFit:
        if (value >= 0.7) {
          return 'Fits your remaining macros well — '
              '${item.scaledProteinG.round()}g protein, '
              '${item.scaledCarbsG.round()}g carbs, '
              '${item.scaledFatG.round()}g fat.';
        }
        return 'Only partial macro match; you\'d still have room left for more.';
      case SignalKind.goalAlignment:
        switch (item.rating) {
          case 'green': return 'Rated Good for your goals by the AI coach.';
          case 'yellow': return 'Moderate fit for your goals — eat strategically.';
          case 'red': return 'Coach flagged this as off-goal; weigh against other signals.';
          default: return 'No explicit goal rating for this dish.';
        }
      case SignalKind.favoriteMatch:
        if (value >= 0.78) {
          return 'Similar to a meal you\'ve saved as a favorite.';
        }
        return 'No strong favorite match.';
      case SignalKind.historyAffinity:
        if (value >= 0.3) {
          return 'You\'ve logged similar dishes recently — this aligns with your habits.';
        }
        return 'This would be a new dish for your history.';
      case SignalKind.healthQuality:
        if (value >= 0.7) {
          return 'Low inflammation${item.inflammationScore != null ? ' (${item.inflammationScore}/10)' : ''} and not ultra-processed.';
        }
        return 'Higher inflammation${item.inflammationScore != null ? ' (${item.inflammationScore}/10)' : ''} — keep the portion in check.';
      case SignalKind.priceFit:
        if (item.price == null) return 'No price listed to evaluate against your budget.';
        if (value >= 0.8) return 'Well within your per-meal budget of \$${item.price!.toStringAsFixed(2)}.';
        return 'Pushes your meal budget — consider cheaper alternatives.';
      case SignalKind.varietyBonus:
        if (value >= 0.7) return 'Different from what you\'ve already had today — good rotation.';
        return 'Similar to something you already ate today; rotation helps variety.';
    }
  }
}

class _AxisStrip extends StatelessWidget {
  final RecommendationAxes axes;
  const _AxisStrip({required this.axes});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _bar('Nutrition', axes.nutrition, AppColors.coral)),
        const SizedBox(width: 6),
        Expanded(child: _bar('Pleasure', axes.pleasure, AppColors.orange)),
        const SizedBox(width: 6),
        Expanded(child: _bar('Wellness', axes.wellness, AppColors.success)),
      ],
    );
  }

  Widget _bar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: color,
        )),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 2),
        Text('${(value * 100).round()}%', style: TextStyle(
          fontSize: 10, color: color, fontWeight: FontWeight.w700,
        )),
      ],
    );
  }
}
