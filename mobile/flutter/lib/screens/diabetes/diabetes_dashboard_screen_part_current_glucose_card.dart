part of 'diabetes_dashboard_screen.dart';


// ============================================
// Current Glucose Card
// ============================================

class _CurrentGlucoseCard extends StatelessWidget {
  final GlucoseReading reading;
  final Animation<double> pulseAnimation;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _CurrentGlucoseCard({
    required this.reading,
    required this.pulseAnimation,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final status = reading.status;
    final timeSince = DateTime.now().difference(reading.timestamp);
    final timeAgoText = _formatTimeSince(timeSince);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: status.color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bloodtype,
                  color: AppColors.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Current Glucose',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status.icon,
                      color: status.color,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Large Glucose Value with pulse animation
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    status == GlucoseStatus.normal ? 1.0 : pulseAnimation.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        status.color.withOpacity(0.2),
                        status.color.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: status.color.withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        reading.valueMgDl.toInt().toString(),
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: status.color,
                        ),
                      ),
                      Text(
                        'mg/dL',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Time since reading
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                timeAgoText,
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
              if (reading.source != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reading.source == 'cgm' ? 'CGM' : 'Manual',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeSince(Duration duration) {
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}


// ============================================
// Quick Actions Row
// ============================================

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onLogGlucose;
  final VoidCallback onLogInsulin;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color cardBorder;

  const _QuickActionsRow({
    required this.onLogGlucose,
    required this.onLogInsulin,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.bloodtype,
            label: 'Log Glucose',
            color: AppColors.cyan,
            onTap: onLogGlucose,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            cardBorder: cardBorder,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.medication,
            label: 'Log Insulin',
            color: AppColors.purple,
            onTap: onLogInsulin,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            cardBorder: cardBorder,
          ),
        ),
      ],
    );
  }
}


class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color elevatedColor;
  final Color textPrimary;
  final Color cardBorder;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.elevatedColor,
    required this.textPrimary,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================
// Time in Range Card
// ============================================

class _TimeInRangeCard extends StatelessWidget {
  final TimeInRangeData data;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _TimeInRangeCard({
    required this.data,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Time in Range',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Last ${data.daysIncluded} days',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stacked bar chart
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  // Below range
                  if (data.percentBelow > 0)
                    Flexible(
                      flex: (data.percentBelow * 10).round(),
                      child: Container(color: AppColors.error),
                    ),
                  // In range
                  Flexible(
                    flex: (data.percentInRange * 10).round(),
                    child: Container(color: AppColors.success),
                  ),
                  // Above range
                  if (data.percentAbove > 0)
                    Flexible(
                      flex: (data.percentAbove * 10).round(),
                      child: Container(color: AppColors.warning),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RangeLegendItem(
                color: AppColors.error,
                label: 'Below',
                percentage: data.percentBelow,
                range: '<70',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _RangeLegendItem(
                color: AppColors.success,
                label: 'In Range',
                percentage: data.percentInRange,
                range: '70-140',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _RangeLegendItem(
                color: AppColors.warning,
                label: 'Above',
                percentage: data.percentAbove,
                range: '>140',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Target recommendation
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (data.percentInRange >= 70
                      ? AppColors.success
                      : AppColors.info)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  data.percentInRange >= 70
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: data.percentInRange >= 70
                      ? AppColors.success
                      : AppColors.info,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.percentInRange >= 70
                        ? 'Great! You\'re meeting the target of 70%+ in range.'
                        : 'Target: 70%+ time in range (70-140 mg/dL)',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _RangeLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percentage;
  final String range;
  final Color textPrimary;
  final Color textMuted;

  const _RangeLegendItem({
    required this.color,
    required this.label,
    required this.percentage,
    required this.range,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
        Text(
          '$range mg/dL',
          style: TextStyle(
            fontSize: 9,
            color: textMuted.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}


// ============================================
// Insulin Summary Card
// ============================================

class _InsulinSummaryCard extends StatelessWidget {
  final InsulinSummary summary;
  final List<InsulinDose> doses;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _InsulinSummaryCard({
    required this.summary,
    required this.doses,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.medication,
                color: AppColors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Insulin',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${summary.doseCount} dose${summary.doseCount != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total summary
          Row(
            children: [
              Expanded(
                child: _InsulinStat(
                  label: 'Total',
                  value: '${summary.totalUnits.toStringAsFixed(1)}U',
                  color: AppColors.purple,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: cardBorder,
              ),
              Expanded(
                child: _InsulinStat(
                  label: 'Rapid',
                  value: '${summary.totalRapidUnits.toStringAsFixed(1)}U',
                  color: AppColors.cyan,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: cardBorder,
              ),
              Expanded(
                child: _InsulinStat(
                  label: 'Long',
                  value: '${summary.totalLongUnits.toStringAsFixed(1)}U',
                  color: AppColors.purple,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),

          if (doses.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Recent doses
            Text(
              'Recent Doses',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            ...doses.take(3).map((dose) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InsulinDoseItem(
                    dose: dose,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                  ),
                )),
          ],
        ],
      ),
    );
  }
}


class _InsulinStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textPrimary;
  final Color textMuted;

  const _InsulinStat({
    required this.label,
    required this.value,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}


class _InsulinDoseItem extends StatelessWidget {
  final InsulinDose dose;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _InsulinDoseItem({
    required this.dose,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = _formatTime(dose.timestamp);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dose.typeColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${dose.units.toStringAsFixed(1)} U',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: dose.typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      dose.typeLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: dose.typeColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (dose.notes != null)
                Text(
                  dose.notes!,
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
            ],
          ),
        ),
        Text(
          timeFormat,
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

