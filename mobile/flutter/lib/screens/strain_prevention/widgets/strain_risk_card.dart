import 'package:flutter/material.dart';
import '../../../data/models/strain_prevention.dart';

/// Card showing risk level for a muscle group with volume progress bar
class StrainRiskCard extends StatelessWidget {
  final MuscleGroupRisk risk;
  final VoidCallback? onTap;

  const StrainRiskCard({
    super.key,
    required this.risk,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final riskLevel = risk.riskLevelEnum;
    final riskColor = Color(riskLevel.colorValue);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: risk.hasActiveAlert
                ? riskColor.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.1),
            width: risk.hasActiveAlert ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with muscle group name and risk badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    risk.muscleGroupDisplay,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                _buildRiskBadge(riskLevel, riskColor, colorScheme),
              ],
            ),
            const SizedBox(height: 12),

            // Volume progress bar
            _buildVolumeProgressBar(riskColor, colorScheme),
            const SizedBox(height: 8),

            // Volume stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${risk.currentVolumeKg.toStringAsFixed(0)} kg',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'of ${risk.volumeCapKg.toStringAsFixed(0)} kg cap',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // Weekly increase if present
            if (risk.weeklyIncreasePercent != 0) ...[
              const SizedBox(height: 8),
              _buildWeeklyIncrease(colorScheme),
            ],

            // Alert message if present
            if (risk.hasActiveAlert && risk.alertMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getRiskIcon(riskLevel),
                      size: 16,
                      color: riskColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        risk.alertMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: riskColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(
    StrainRiskLevel level,
    Color riskColor,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRiskIcon(level),
            size: 14,
            color: riskColor,
          ),
          const SizedBox(width: 4),
          Text(
            level.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: riskColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeProgressBar(Color riskColor, ColorScheme colorScheme) {
    final utilization = risk.volumeUtilization / 100;
    final clampedUtilization = utilization.clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Progress
              FractionallySizedBox(
                widthFactor: clampedUtilization,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        riskColor.withValues(alpha: 0.7),
                        riskColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Overflow indicator if over cap
              if (risk.isOverCap)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: riskColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Over cap indicator
        if (risk.isOverCap) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.warning_amber,
                size: 12,
                color: riskColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${(risk.volumeUtilization - 100).toStringAsFixed(0)}% over cap',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: riskColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildWeeklyIncrease(ColorScheme colorScheme) {
    final isIncrease = risk.weeklyIncreasePercent > 0;
    final isDangerous = risk.weeklyIncreasePercent > risk.recommendedMaxIncrease;
    final color = isDangerous
        ? Colors.red
        : isIncrease
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        Icon(
          isIncrease ? Icons.trending_up : Icons.trending_down,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${isIncrease ? '+' : ''}${risk.weeklyIncreasePercent.toStringAsFixed(0)}% vs last week',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        if (isDangerous) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Too fast',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getRiskIcon(StrainRiskLevel level) {
    switch (level) {
      case StrainRiskLevel.safe:
        return Icons.check_circle;
      case StrainRiskLevel.warning:
        return Icons.warning_amber;
      case StrainRiskLevel.danger:
        return Icons.error;
      case StrainRiskLevel.critical:
        return Icons.dangerous;
    }
  }
}
