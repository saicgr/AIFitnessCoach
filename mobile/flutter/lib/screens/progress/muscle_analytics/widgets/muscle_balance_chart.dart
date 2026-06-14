import 'package:flutter/material.dart';
import '../../../../data/models/muscle_analytics.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/design_system/zealova.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Chart showing push/pull and upper/lower balance ratios
class MuscleBalanceChart extends StatelessWidget {
  final MuscleBalanceData balance;

  const MuscleBalanceChart({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Push/Pull Balance
        _BalanceBar(
          label: AppLocalizations.of(context).muscleBalanceChartPushPull,
          leftLabel: AppLocalizations.of(context).muscleBalanceChartPush,
          rightLabel: AppLocalizations.of(context).muscleBalanceChartPull,
          leftValue: balance.pushVolumeKg ?? 0,
          rightValue: balance.pullVolumeKg ?? 0,
          isBalanced: balance.isPushPullBalanced,
        ),
        const SizedBox(height: 16),

        // Upper/Lower Balance
        _BalanceBar(
          label: AppLocalizations.of(context).quizTrainingStyleUpperLower,
          leftLabel: AppLocalizations.of(context).muscleBalanceChartUpper,
          rightLabel: AppLocalizations.of(context).muscleBalanceChartLower,
          leftValue: balance.upperVolumeKg ?? 0,
          rightValue: balance.lowerVolumeKg ?? 0,
          isBalanced: balance.isUpperLowerBalanced,
        ),
      ],
    );
  }
}

class _BalanceBar extends StatelessWidget {
  final String label;
  final String leftLabel;
  final String rightLabel;
  final double leftValue;
  final double rightValue;
  final bool isBalanced;

  const _BalanceBar({
    required this.label,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    required this.isBalanced,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final total = leftValue + rightValue;
    final leftPercent = total > 0 ? leftValue / total : 0.5;
    final rightPercent = total > 0 ? rightValue / total : 0.5;

    // The split bar is a single accent fill (left) over a hairline track
    // (right). Balanced/imbalanced is semantic — success/warning, NOT accent.
    final fillColor = tc.accent;
    final semColor = isBalanced ? tc.success : tc.warning;

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: ZType.lbl(12, color: tc.textPrimary, letterSpacing: 1.4),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: semColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBalanced
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                      size: 13,
                      color: semColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (isBalanced
                              ? AppLocalizations.of(context)
                                  .quizProgressionConstraintsBalanced
                              : AppLocalizations.of(context)
                                  .muscleBalanceChartImbalanced)
                          .toUpperCase(),
                      style: ZType.lbl(9, color: semColor, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Balance bar — Anton % numerals flank a thin split track.
          Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  '${(leftPercent * 100).toInt()}%',
                  style: ZType.disp(15, color: tc.textPrimary),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Row(
                    children: [
                      Flexible(
                        flex: (leftPercent * 100).toInt().clamp(1, 100),
                        child: Container(
                          height: 6,
                          color: fillColor,
                          child: Center(
                            child: leftPercent >= 0.3
                                ? Text(
                                    leftLabel.toUpperCase(),
                                    style: ZType.lbl(8,
                                        color: tc.accentContrast,
                                        letterSpacing: 1.0),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      // Center hairline divider.
                      Container(width: 1, height: 6, color: AppColors.hairline),
                      Flexible(
                        flex: (rightPercent * 100).toInt().clamp(1, 100),
                        child: Container(
                          height: 6,
                          color: AppColors.hairlineStrong,
                          child: Center(
                            child: rightPercent >= 0.3
                                ? Text(
                                    rightLabel.toUpperCase(),
                                    style: ZType.lbl(8,
                                        color: tc.textSecondary,
                                        letterSpacing: 1.0),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(rightPercent * 100).toInt()}%',
                  textAlign: TextAlign.end,
                  style: ZType.disp(15, color: tc.textPrimary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Volume labels — Barlow telemetry.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatVolume(leftValue)} KG',
                style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.0),
              ),
              Text(
                '${_formatVolume(rightValue)} KG',
                style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k';
    }
    return volume.toStringAsFixed(0);
  }
}
