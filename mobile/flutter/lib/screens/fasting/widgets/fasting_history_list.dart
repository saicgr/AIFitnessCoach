import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';

/// List of past fasting records
class FastingHistoryList extends StatelessWidget {
  final List<FastingRecord> history;
  final bool isDark;
  final VoidCallback? onLoadMore;

  const FastingHistoryList({
    super.key,
    required this.history,
    required this.isDark,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: history.length + (onLoadMore != null ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == history.length) {
          // Load more button
          return Center(
            child: TextButton(
              onPressed: onLoadMore,
              child: Text(
                'Load More',
                style: TextStyle(
                  color: isDark ? AppColors.purple : AppColorsLight.purple,
                ),
              ),
            ),
          );
        }
        return _FastingHistoryCard(
          record: history[index],
          isDark: isDark,
        );
      },
    );
  }
}

class _FastingHistoryCard extends StatelessWidget {
  final FastingRecord record;
  final bool isDark;

  const _FastingHistoryCard({
    required this.record,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Calculate completion percentage
    final completionPercent =
        record.actualDurationMinutes != null && record.goalDurationMinutes > 0
            ? (record.actualDurationMinutes! / record.goalDurationMinutes * 100)
                .clamp(0, 100)
            : 0.0;

    final completedGoal = completionPercent >= 100;
    final statusColor = completedGoal
        ? AppColors.success
        : completionPercent >= 80
            ? AppColors.warning
            : AppColors.coral;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(record.startTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${timeFormat.format(record.startTime)} - ${record.endTime != null ? timeFormat.format(record.endTime!) : 'Ongoing'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      completedGoal
                          ? Icons.check_circle
                          : Icons.timer_outlined,
                      color: statusColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      completedGoal
                          ? 'Completed'
                          : '${completionPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionPercent / 100,
              backgroundColor: statusColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Details row
          Row(
            children: [
              _DetailChip(
                icon: Icons.schedule,
                label: _formatDuration(record.actualDurationMinutes ?? 0),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _DetailChip(
                icon: Icons.flag,
                label: 'Goal: ${_formatDuration(record.goalDurationMinutes)}',
                isDark: isDark,
              ),
              const Spacer(),
              if (record.protocol.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.purple : AppColorsLight.purple)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.protocol.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.purple : AppColorsLight.purple,
                    ),
                  ),
                ),
            ],
          ),

          // Notes (if any)
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes, size: 14, color: textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}
