import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';

class SyncedWorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  const SyncedWorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metadata = workout.generationMetadata ?? {};

    // Key stored by health_import_provider is 'source_app'
    final sourceApp = metadata['source_app'] as String?
        ?? metadata['source_app_name'] as String?
        ?? (Theme.of(context).platform == TargetPlatform.iOS ? 'Apple Health' : 'Health Connect');
    final calories = metadata['calories_burned'];
    final avgHR = metadata['avg_heart_rate'];
    final maxHR = metadata['max_heart_rate'];
    final minHR = metadata['min_heart_rate'];
    final distance = metadata['distance_meters'];
    final steps = metadata['total_steps'];

    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 68),
              ),

              // Source badge
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync_rounded, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              'Synced from $sourceApp',
                              style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Health metrics card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity Summary',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            if (workout.durationMinutes != null)
                              _MetricTile(
                                icon: Icons.timer_outlined,
                                label: 'Duration',
                                value: '${workout.durationMinutes} min',
                                color: accentColor,
                                isDark: isDark,
                              ),
                            if (calories != null)
                              _MetricTile(
                                icon: Icons.local_fire_department_outlined,
                                label: 'Calories',
                                value: '${_formatNum(calories)} kcal',
                                color: const Color(0xFFF97316),
                                isDark: isDark,
                              ),
                            if (steps != null)
                              _MetricTile(
                                icon: Icons.directions_walk_outlined,
                                label: 'Steps',
                                value: _formatNum(steps),
                                color: const Color(0xFF22C55E),
                                isDark: isDark,
                              ),
                            if (distance != null)
                              _MetricTile(
                                icon: Icons.straighten_outlined,
                                label: 'Distance',
                                value: '${((distance as num) / 1000.0).toStringAsFixed(2)} km',
                                color: const Color(0xFF8B5CF6),
                                isDark: isDark,
                              ),
                            if (avgHR != null)
                              _MetricTile(
                                icon: Icons.favorite_outline,
                                label: 'Avg HR',
                                value: '$avgHR bpm',
                                color: const Color(0xFFEF4444),
                                isDark: isDark,
                              ),
                            if (maxHR != null)
                              _MetricTile(
                                icon: Icons.favorite,
                                label: 'Max HR',
                                value: '$maxHR bpm',
                                color: const Color(0xFFEF4444),
                                isDark: isDark,
                              ),
                            if (minHR != null)
                              _MetricTile(
                                icon: Icons.favorite_border,
                                label: 'Min HR',
                                value: '$minHR bpm',
                                color: const Color(0xFFEF4444),
                                isDark: isDark,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Workout info card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Type', _capitalize(workout.type ?? 'General'), textPrimary, textMuted),
                        if (workout.scheduledDate != null) ...[
                          Divider(height: 24, color: cardBorder),
                          _buildInfoRow('Date', _formatDate(workout.scheduledDate!), textPrimary, textMuted),
                        ],
                        Divider(height: 24, color: cardBorder),
                        _buildInfoRow('Status', workout.isCompleted == true ? 'Completed' : 'Recorded', textPrimary, textMuted),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),

          // Floating top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                      borderRadius: BorderRadius.circular(22),
                      border: isDark ? null : Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title pill
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                      borderRadius: BorderRadius.circular(22),
                      border: isDark ? null : Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        workout.name ?? 'Imported Workout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  String _formatNum(dynamic val) {
    if (val == null) return '';
    final n = num.tryParse(val.toString()) ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(0);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;

    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: textMuted)),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildInfoRow(String label, String value, Color textPrimary, Color textMuted) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 14, color: textMuted)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
    ],
  );
}
