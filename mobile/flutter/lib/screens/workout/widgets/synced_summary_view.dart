import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';

/// Read-only summary view for workouts imported from Apple Health,
/// Health Connect, Garmin, or Fitbit.
///
/// Replaces the regular Zealova summary layout for synced rows so we
/// don't render the misleading "Marked Done" pill and the
/// "Manually marked as done at {timestamp}" AI Coach Review fallback —
/// synced sessions don't have Zealova-shaped per-set logs and shouldn't
/// pretend to. Renders only the metadata fields actually present
/// (duration, calories, HR avg/max, distance, pace), plus a single
/// "Synced Activity" info card explaining the source.
class SyncedSummaryView extends StatelessWidget {
  final WorkoutSummaryResponse summary;
  const SyncedSummaryView({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final platform = summary.syncedPlatformLabel;

    final name = (summary.workout['name'] as String?)?.trim();
    final scheduledDate = summary.workout['scheduled_date'] as String?;

    final duration = _readInt(summary.workout, 'duration_minutes');
    final calories = _readMetadataInt('active_energy_burned_kcal') ??
        _readInt(summary.workout, 'estimated_calories_stored');
    final distanceM = summary.distanceMeters ?? _readMetadataDouble('distance_meters');
    final avgHr = summary.avgHrBpm ?? _readMetadataInt('heart_rate_avg_bpm');
    final maxHr = summary.maxHrBpm ?? _readMetadataInt('heart_rate_max_bpm');

    final stats = <_StatTile>[
      if (duration != null && duration > 0)
        _StatTile(
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: '${duration}m',
        ),
      if (calories != null && calories > 0)
        _StatTile(
          icon: Icons.local_fire_department_rounded,
          label: 'Calories',
          value: '$calories',
        ),
      if (distanceM != null && distanceM > 0)
        _StatTile(
          icon: Icons.straighten_rounded,
          label: 'Distance',
          value: _formatDistance(distanceM),
        ),
      if (avgHr != null && avgHr > 0)
        _StatTile(
          icon: Icons.favorite_outline,
          label: 'Avg HR',
          value: '$avgHr bpm',
        ),
      if (maxHr != null && maxHr > 0)
        _StatTile(
          icon: Icons.monitor_heart_outlined,
          label: 'Max HR',
          value: '$maxHr bpm',
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name?.isNotEmpty == true ? name! : '$platform activity',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: textMuted),
              const SizedBox(width: 6),
              Text(
                _formatDate(scheduledDate),
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
              const SizedBox(width: 10),
              _SyncedPill(platform: platform),
            ],
          ),
          const SizedBox(height: 20),

          // Stat grid — only fields that actually have values.
          if (stats.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats
                    .map((s) => SizedBox(
                          width: (MediaQuery.of(context).size.width - 40 - 32 - 24) / 3,
                          child: s.build(context, isDark),
                        ))
                    .toList(),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'No activity metrics were captured for this session.',
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
            ),

          const SizedBox(height: 20),

          // Single info card — replaces the "AI Coach Review · Manually
          // marked as done at <ts>" placeholder that the regular Zealova
          // summary path renders for completion_method='marked_done' rows.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync_rounded,
                        color: AppColors.cyan, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Synced Activity',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "This workout was imported from $platform. Zealova "
                  "doesn't have a per-exercise breakdown for synced "
                  "sessions — open $platform on your device for the "
                  "full session details.",
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────

  int? _readInt(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  int? _readMetadataInt(String key) {
    try {
      final meta = summary.workout['generation_metadata'];
      if (meta is! Map) return null;
      final v = meta[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    } catch (_) {
      return null;
    }
  }

  double? _readMetadataDouble(String key) {
    try {
      final meta = summary.workout['generation_metadata'];
      if (meta is! Map) return null;
      final v = meta[key];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    } catch (_) {
      return null;
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso.replaceAll('Z', '+00:00')).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      const weekdays = [
        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
      ];
      return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _SyncedPill extends StatelessWidget {
  final String platform;
  const _SyncedPill({required this.platform});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_rounded, size: 12, color: AppColors.cyan),
          const SizedBox(width: 4),
          Text(
            'Synced from $platform',
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  Widget build(BuildContext context, bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.cyan),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
