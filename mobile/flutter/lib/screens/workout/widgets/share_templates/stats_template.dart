import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'app_watermark.dart';

/// Stats Template - Shows workout duration, exercises, volume, calories
/// Dark gradient background with bold stats display
class StatsTemplate extends StatelessWidget {
  final String workoutName;
  final int durationSeconds;
  final int? calories;
  final double? totalVolumeKg;
  final int? totalSets;
  final int? totalReps;
  final int exercisesCount;
  final DateTime completedAt;
  final bool showWatermark;

  const StatsTemplate({
    super.key,
    required this.workoutName,
    required this.durationSeconds,
    this.calories,
    this.totalVolumeKg,
    this.totalSets,
    this.totalReps,
    required this.exercisesCount,
    required this.completedAt,
    this.showWatermark = true,
  });

  String get _formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String get _formattedVolume {
    if (totalVolumeKg == null) return '--';
    if (totalVolumeKg! >= 1000) {
      return '${(totalVolumeKg! / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolumeKg!.toStringAsFixed(0)} kg';
  }

  String get _formattedDate {
    final now = DateTime.now();
    if (completedAt.day == now.day &&
        completedAt.month == now.month &&
        completedAt.year == now.year) {
      return 'Today';
    }
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[completedAt.month - 1]} ${completedAt.day}';
  }

  @override
  Widget build(BuildContext context) {
    // Calculate responsive height based on available space
    final screenHeight = MediaQuery.of(context).size.height;
    final templateHeight = (screenHeight * 0.48).clamp(360.0, 480.0);

    return Container(
      width: 320,
      height: templateHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPatternPainter(),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _formattedDate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Workout name
                Text(
                  workoutName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Text(
                  'WORKOUT COMPLETE',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(),

                // Stats grid
                _buildStatsGrid(),

                if (showWatermark) ...[
                  const SizedBox(height: 12),
                  const AppWatermark(),
                ] else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer_outlined,
                value: _formattedDuration,
                label: 'Duration',
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.fitness_center,
                value: '$exercisesCount',
                label: 'Exercises',
                color: AppColors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.scale_outlined,
                value: _formattedVolume,
                label: 'Volume',
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department_outlined,
                value: calories != null ? '$calories' : '--',
                label: 'Calories',
                color: AppColors.coral,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

}

/// Custom painter for background grid pattern
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
