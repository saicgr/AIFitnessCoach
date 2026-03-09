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
    final sourceApp = metadata['source_app_name'] as String? ?? 'Health Connect';
    final calories = metadata['calories_burned'];
    final avgHR = metadata['avg_heart_rate'];
    final maxHR = metadata['max_heart_rate'];
    final distance = metadata['distance_meters'];
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = BorderSide(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColorsLight.background,
      appBar: AppBar(
        title: Text(
          workout.name ?? 'Synced Workout',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Source app badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync_rounded, size: 14, color: textMuted),
                const SizedBox(width: 6),
                Text(
                  'Synced from $sourceApp',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Health data summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder.color),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    if (workout.durationMinutes != null)
                      _buildMetricTile(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: '${workout.durationMinutes} min',
                        isDark: isDark,
                      ),
                    if (calories != null)
                      _buildMetricTile(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Calories',
                        value: '$calories kcal',
                        isDark: isDark,
                      ),
                    if (avgHR != null)
                      _buildMetricTile(
                        icon: Icons.favorite_outline,
                        label: 'Avg HR',
                        value: '$avgHR bpm',
                        isDark: isDark,
                      ),
                    if (maxHR != null)
                      _buildMetricTile(
                        icon: Icons.favorite,
                        label: 'Max HR',
                        value: '$maxHR bpm',
                        isDark: isDark,
                      ),
                    if (distance != null)
                      _buildMetricTile(
                        icon: Icons.straighten_outlined,
                        label: 'Distance',
                        value: '${(distance / 1000.0).toStringAsFixed(2)} km',
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Workout type + date info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder.color),
            ),
            child: Column(
              children: [
                _buildInfoRow('Type', workout.type ?? 'General', textPrimary, textMuted),
                if (workout.scheduledDate != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Date', workout.scheduledDate!, textPrimary, textMuted),
                ],
                if (workout.isCompleted == true) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Status', 'Completed', textPrimary, textMuted),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Exercises section
          if (workout.exercises.isNotEmpty) ...[
            Text(
              'Exercises',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...workout.exercises.map((exercise) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder.color),
              ),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, size: 18, color: textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder.color),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 32, color: textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'No exercise details available',
                      style: TextStyle(fontSize: 14, color: textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This workout was synced without exercise data',
                      style: TextStyle(fontSize: 12, color: textMuted.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? AppColors.accent : AppColorsLight.accent),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
}
