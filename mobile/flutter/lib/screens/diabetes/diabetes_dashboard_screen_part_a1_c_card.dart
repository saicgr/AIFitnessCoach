part of 'diabetes_dashboard_screen.dart';


// ============================================
// A1C Card
// ============================================

class _A1CCard extends StatelessWidget {
  final A1CRecord latestA1C;
  final A1CRecord? estimatedA1C;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _A1CCard({
    required this.latestA1C,
    this.estimatedA1C,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final daysSinceMeasured =
        DateTime.now().difference(latestA1C.measuredAt).inDays;

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
                Icons.analytics,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'A1C',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // A1C Values
          Row(
            children: [
              // Latest A1C
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: latestA1C.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: latestA1C.statusColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            latestA1C.value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: latestA1C.statusColor,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 2),
                            child: Text(
                              '%',
                              style: TextStyle(
                                fontSize: 14,
                                color: latestA1C.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$daysSinceMeasured days ago',
                        style: TextStyle(
                          fontSize: 10,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Estimated A1C
              if (estimatedA1C != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: textMuted.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Estimated',
                              style: TextStyle(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: textMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              estimatedA1C!.value.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4, left: 2),
                              child: Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on readings',
                          style: TextStyle(
                            fontSize: 10,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Status label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: latestA1C.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  latestA1C.value < 6.5 ? Icons.check_circle : Icons.warning,
                  color: latestA1C.statusColor,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  latestA1C.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: latestA1C.statusColor,
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


// ============================================
// Recent Readings Card
// ============================================

class _RecentReadingsCard extends StatelessWidget {
  final List<GlucoseReading> readings;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _RecentReadingsCard({
    required this.readings,
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
                Icons.history,
                color: AppColors.cyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Readings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  HapticService.light();
                  // Show all glucose readings in a sheet
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: isDark ? AppColors.elevated : Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.7,
                      maxChildSize: 0.9,
                      builder: (_, controller) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                            const SizedBox(height: 16),
                            Text('All Blood Glucose Readings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                            const SizedBox(height: 16),
                            Expanded(child: ListView(controller: controller, children: const [Center(child: Text('No additional readings available'))])),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Readings list
          ...readings.take(5).map((reading) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _ReadingItem(
                  reading: reading,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                ),
              )),
        ],
      ),
    );
  }
}


class _ReadingItem extends StatelessWidget {
  final GlucoseReading reading;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _ReadingItem({
    required this.reading,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final status = reading.status;
    final timeFormat = _formatDateTime(reading.timestamp);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: status.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              status.icon,
              color: status.color,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${reading.valueMgDl.toInt()} mg/dL',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                timeFormat,
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        if (reading.source != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reading.source == 'cgm' ? 'CGM' : 'Manual',
              style: TextStyle(
                fontSize: 9,
                color: textMuted,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final readingDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    final timeStr = '$hour:$minute $period';

    if (readingDate == today) {
      return 'Today at $timeStr';
    } else if (readingDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at $timeStr';
    } else {
      return '${dateTime.month}/${dateTime.day} at $timeStr';
    }
  }
}


// ============================================
// Health Connect Sync Card
// ============================================

class _HealthConnectSyncCard extends StatelessWidget {
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  final VoidCallback onSync;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _HealthConnectSyncCard({
    this.lastSyncedAt,
    required this.isSyncing,
    required this.onSync,
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
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.15),
            AppColors.cyan.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Connect',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (lastSyncedAt != null)
                  Text(
                    'Last synced ${_formatTimeSince(DateTime.now().difference(lastSyncedAt!))}',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  )
                else
                  Text(
                    'Sync your glucose data',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isSyncing ? null : onSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, size: 18),
                      SizedBox(width: 6),
                      Text('Sync'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTimeSince(Duration duration) {
    if (duration.inMinutes < 1) return 'just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}


// ============================================
// Insulin Type Chip (for bottom sheet)
// ============================================

class _InsulinTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final Color textMuted;

  const _InsulinTypeChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : textMuted.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : textMuted,
          ),
        ),
      ),
    );
  }
}

