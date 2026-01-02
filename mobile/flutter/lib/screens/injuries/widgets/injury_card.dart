import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/injury.dart';

class InjuryCard extends StatelessWidget {
  final Injury injury;
  final VoidCallback? onTap;
  final VoidCallback? onCheckIn;

  const InjuryCard({super.key, required this.injury, this.onTap, this.onCheckIn});

  Color _getSeverityColor() {
    switch (injury.severity.toLowerCase()) {
      case 'mild': return AppColors.success;
      case 'moderate': return AppColors.warning;
      case 'severe': return AppColors.error;
      default: return AppColors.textMuted;
    }
  }

  IconData _getBodyPartIcon() {
    switch (injury.bodyPart.toLowerCase()) {
      case 'shoulder': return Icons.accessibility_new;
      case 'back': case 'lower_back': return Icons.airline_seat_flat;
      case 'knee': return Icons.airline_seat_legroom_extra;
      case 'hip': return Icons.directions_walk;
      case 'ankle': return Icons.snowshoeing;
      case 'elbow': return Icons.sports_handball;
      case 'wrist': return Icons.front_hand;
      case 'neck': return Icons.face;
      case 'calf': case 'hamstring': case 'quadriceps': return Icons.directions_run;
      case 'chest': return Icons.favorite;
      default: return Icons.healing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final severityColor = _getSeverityColor();
    final isHealed = injury.status.toLowerCase() == 'healed';
    final isRecovering = injury.status.toLowerCase() == 'recovering';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHealed
                ? AppColors.success.withValues(alpha: 0.5)
                : isRecovering
                    ? AppColors.warning.withValues(alpha: 0.3)
                    : cardBorder,
            width: isHealed || isRecovering ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getBodyPartIcon(), color: severityColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        injury.bodyPartDisplay,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (injury.injuryType != null) ...[
                            Text(_formatInjuryType(injury.injuryType!), style: TextStyle(fontSize: 12, color: textSecondary)),
                            Text(' - ', style: TextStyle(fontSize: 12, color: textMuted)),
                          ],
                          Text(injury.recoveryPhaseDisplay, style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    injury.severityDisplay,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: severityColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isHealed) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recovery Progress', style: TextStyle(fontSize: 11, color: textMuted)),
                      Text('${injury.recoveryProgress.toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: severityColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: injury.recoveryProgress / 100,
                      backgroundColor: cardBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(severityColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                if (injury.painLevel != null) ...[
                  Icon(Icons.sentiment_dissatisfied, size: 14, color: _getPainColor(injury.painLevel!)),
                  const SizedBox(width: 4),
                  Text('Pain: ${injury.painLevel}/10', style: TextStyle(fontSize: 12, color: textMuted)),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.schedule, size: 14, color: textMuted),
                const SizedBox(width: 4),
                Text(
                  isHealed
                      ? 'Healed'
                      : injury.daysUntilRecovery != null
                          ? '${injury.daysUntilRecovery} days left'
                          : '${injury.daysSinceReported} days ago',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const Spacer(),
                if (!isHealed && onCheckIn != null)
                  TextButton.icon(
                    onPressed: onCheckIn,
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Check-in', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: severityColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                Icon(Icons.chevron_right, color: textMuted, size: 20),
              ],
            ),
            if (isHealed) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    const Text('Fully Recovered', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPainColor(int painLevel) {
    if (painLevel <= 3) return AppColors.success;
    if (painLevel <= 6) return AppColors.warning;
    return AppColors.error;
  }

  String _formatInjuryType(String type) => type.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
}
