import 'package:flutter/material.dart';
import '../../../../data/models/muscle_analytics.dart';

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
          label: 'Push / Pull',
          leftLabel: 'Push',
          rightLabel: 'Pull',
          leftValue: balance.pushVolumeKg ?? 0,
          rightValue: balance.pullVolumeKg ?? 0,
          isBalanced: balance.isPushPullBalanced,
        ),
        const SizedBox(height: 16),

        // Upper/Lower Balance
        _BalanceBar(
          label: 'Upper / Lower',
          leftLabel: 'Upper',
          rightLabel: 'Lower',
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
    final theme = Theme.of(context);
    final total = leftValue + rightValue;
    final leftPercent = total > 0 ? leftValue / total : 0.5;
    final rightPercent = total > 0 ? rightValue / total : 0.5;

    final leftColor = theme.colorScheme.primary;
    final rightColor = theme.colorScheme.secondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isBalanced ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBalanced ? Icons.check_circle : Icons.warning,
                        size: 14,
                        color: isBalanced ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBalanced ? 'Balanced' : 'Imbalanced',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isBalanced ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Balance bar
            Row(
              children: [
                // Left side label
                SizedBox(
                  width: 50,
                  child: Text(
                    '${(leftPercent * 100).toInt()}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: leftColor,
                    ),
                  ),
                ),

                // Bar
                Expanded(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          Flexible(
                            flex: (leftPercent * 100).toInt(),
                            child: Container(
                              color: leftColor,
                              child: Center(
                                child: leftPercent >= 0.3
                                    ? Text(
                                        leftLabel,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          // Center line indicator
                          Container(
                            width: 2,
                            color: isBalanced ? Colors.green : Colors.orange,
                          ),
                          Flexible(
                            flex: (rightPercent * 100).toInt(),
                            child: Container(
                              color: rightColor,
                              child: Center(
                                child: rightPercent >= 0.3
                                    ? Text(
                                        rightLabel,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Right side label
                SizedBox(
                  width: 50,
                  child: Text(
                    '${(rightPercent * 100).toInt()}%',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: rightColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Volume labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatVolume(leftValue)} kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${_formatVolume(rightValue)} kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
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
