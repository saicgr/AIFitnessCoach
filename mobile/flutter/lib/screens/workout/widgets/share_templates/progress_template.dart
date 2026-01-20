import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'app_watermark.dart';

/// Progress Template - Shows workout progression and milestone achievements
/// Great for celebrating fitness journey milestones
class ProgressTemplate extends StatelessWidget {
  final String workoutName;
  final int durationSeconds;
  final int exercisesCount;
  final int? totalWorkouts;
  final int? currentStreak;
  final int? weeklyWorkouts;
  final int? monthlyWorkouts;
  final double? totalVolumeLifted; // Total volume in career/program
  final double? sessionVolume;
  final int? prsThisMonth;
  final DateTime completedAt;
  final bool showWatermark;

  const ProgressTemplate({
    super.key,
    required this.workoutName,
    required this.durationSeconds,
    required this.exercisesCount,
    this.totalWorkouts,
    this.currentStreak,
    this.weeklyWorkouts,
    this.monthlyWorkouts,
    this.totalVolumeLifted,
    this.sessionVolume,
    this.prsThisMonth,
    required this.completedAt,
    this.showWatermark = true,
  });

  String get _formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get _milestoneText {
    final total = totalWorkouts ?? 1;
    if (total >= 1000) return '🏆 LEGENDARY: 1000+ WORKOUTS';
    if (total >= 500) return '👑 MASTER: 500+ WORKOUTS';
    if (total >= 365) return '🌟 DEDICATED: 1 YEAR OF GAINS';
    if (total >= 200) return '💪 COMMITTED: 200+ WORKOUTS';
    if (total >= 100) return '🔥 CENTURY CLUB: 100 WORKOUTS';
    if (total >= 50) return '⚡ HALFWAY THERE: 50 WORKOUTS';
    if (total >= 25) return '🚀 BUILDING MOMENTUM';
    if (total >= 10) return '✨ GETTING STARTED';
    return '🌱 EVERY REP COUNTS';
  }

  String get _formattedTotalVolume {
    if (totalVolumeLifted == null) return '--';
    if (totalVolumeLifted! >= 1000000) {
      return '${(totalVolumeLifted! / 1000000).toStringAsFixed(1)}M kg';
    }
    if (totalVolumeLifted! >= 1000) {
      return '${(totalVolumeLifted! / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolumeLifted!.toStringAsFixed(0)} kg';
  }

  @override
  Widget build(BuildContext context) {
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
            Color(0xFF1A2634),
            Color(0xFF0F1922),
            Color(0xFF0A0F14),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _ProgressPatternPainter(),
              ),
            ),

            // Main content - wrapped in FittedBox to prevent overflow
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 320,
                  height: 440,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Milestone badge at top
                        _buildMilestoneBadge(),

                        const SizedBox(height: 10),

                        // Big number - total workouts
                        _buildTotalWorkoutsDisplay(),

                        const SizedBox(height: 10),

                        // Progress stats grid - fixed height
                        _buildProgressGrid(),

                        const SizedBox(height: 8),

                        // Today's workout
                        _buildTodaysWorkout(),

                        if (showWatermark) ...[
                          const SizedBox(height: 10),
                          const AppWatermark(),
                        ] else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.3),
            AppColors.purple.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        _milestoneText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTotalWorkoutsDisplay() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.cyan, AppColors.purple],
          ).createShader(bounds),
          child: Text(
            '${totalWorkouts ?? 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'TOTAL WORKOUTS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressGrid() {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildStatCard(
                  icon: Icons.local_fire_department_rounded,
                  value: '${currentStreak ?? 0}',
                  label: 'Day Streak',
                  color: AppColors.orange,
                )),
                const SizedBox(height: 6),
                Expanded(child: _buildStatCard(
                  icon: Icons.calendar_month_rounded,
                  value: '${weeklyWorkouts ?? 0}',
                  label: 'This Week',
                  color: AppColors.cyan,
                )),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildStatCard(
                  icon: Icons.trending_up_rounded,
                  value: '${prsThisMonth ?? 0}',
                  label: 'PRs This Month',
                  color: AppColors.success,
                )),
                const SizedBox(height: 6),
                Expanded(child: _buildStatCard(
                  icon: Icons.scale_rounded,
                  value: _formattedTotalVolume,
                  label: 'Total Lifted',
                  color: AppColors.purple,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 7,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysWorkout() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              workoutName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formattedDuration,
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for progress template background
class _ProgressPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradient circles for depth
    final paint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.8),
        radius: 0.8,
        colors: [
          AppColors.cyan.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.1),
      size.width * 0.5,
      paint1,
    );

    final paint2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 0.5),
        radius: 0.6,
        colors: [
          AppColors.purple.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.6),
      size.width * 0.4,
      paint2,
    );

    // Horizontal lines for progress feel
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;

    for (double y = 40; y < size.height; y += 40) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
