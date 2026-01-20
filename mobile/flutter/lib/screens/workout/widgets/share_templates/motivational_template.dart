import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'app_watermark.dart';

/// Motivational Template - Workout name and streak with inspiring design
/// Bold typography, dynamic colors, and streak celebration
class MotivationalTemplate extends StatelessWidget {
  final String workoutName;
  final int? currentStreak;
  final int totalWorkouts;
  final int durationSeconds;
  final DateTime completedAt;
  final bool showWatermark;

  const MotivationalTemplate({
    super.key,
    required this.workoutName,
    this.currentStreak,
    required this.totalWorkouts,
    required this.durationSeconds,
    required this.completedAt,
    this.showWatermark = true,
  });

  String get _motivationalQuote {
    if (currentStreak != null && currentStreak! >= 30) {
      return 'UNSTOPPABLE';
    } else if (currentStreak != null && currentStreak! >= 14) {
      return 'ON FIRE';
    } else if (currentStreak != null && currentStreak! >= 7) {
      return 'CRUSHING IT';
    } else if (totalWorkouts >= 100) {
      return 'LEGEND';
    } else if (totalWorkouts >= 50) {
      return 'WARRIOR';
    } else if (totalWorkouts >= 25) {
      return 'RISING STAR';
    }
    return 'GETTING STRONGER';
  }

  List<Color> get _gradientColors {
    if (currentStreak != null && currentStreak! >= 30) {
      return [
        const Color(0xFFFF6B6B),
        const Color(0xFFFF8E53),
        const Color(0xFFFFC93C),
      ];
    } else if (currentStreak != null && currentStreak! >= 14) {
      return [
        const Color(0xFFF093FB),
        const Color(0xFFF5576C),
      ];
    } else if (currentStreak != null && currentStreak! >= 7) {
      return [
        AppColors.cyan,
        AppColors.purple,
      ];
    }
    return [
      const Color(0xFF667EEA),
      const Color(0xFF764BA2),
    ];
  }

  String get _formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes MIN';
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _gradientColors.first.withValues(alpha: 0.3),
            Colors.black,
            Colors.black,
          ],
          stops: const [0.0, 0.5, 1.0],
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
                painter: _DynamicPatternPainter(colors: _gradientColors),
              ),
            ),

            // Main content - wrapped in FittedBox to prevent overflow
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 320,
                  height: 440,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top section with date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDateBadge(),
                            if (currentStreak != null && currentStreak! > 0)
                              _buildStreakBadge(),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Main motivational text
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: _gradientColors,
                          ).createShader(bounds),
                          child: Text(
                            _motivationalQuote,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Workout name
                        Text(
                          workoutName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 12),

                        // Stats row
                        _buildQuickStats(),

                        const SizedBox(height: 40),

                        // Watermark
                        if (showWatermark) const AppWatermark(),
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

  Widget _buildDateBadge() {
    final now = DateTime.now();
    String dateText;
    if (completedAt.day == now.day &&
        completedAt.month == now.month &&
        completedAt.year == now.year) {
      dateText = 'Today';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      dateText = '${months[completedAt.month - 1]} ${completedAt.day}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        dateText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStreakBadge() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _gradientColors.first.withValues(alpha: 0.3),
              _gradientColors.last.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _gradientColors.first.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: _gradientColors.first,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$currentStreak Day',
                style: TextStyle(
                  color: _gradientColors.first,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: _gradientColors.first,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'COMPLETED',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 16,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.timer_outlined,
            color: Colors.white.withValues(alpha: 0.7),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            _formattedDuration,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}

/// Custom painter for dynamic background pattern
class _DynamicPatternPainter extends CustomPainter {
  final List<Color> colors;

  _DynamicPatternPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    // Large gradient circle top-left
    final paint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.6),
        radius: 1.0,
        colors: [
          colors.first.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.2),
      size.width * 0.6,
      paint1,
    );

    // Smaller accent circle bottom-right
    final paint2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 0.6),
        radius: 0.6,
        colors: [
          colors.last.withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.8),
      size.width * 0.4,
      paint2,
    );

    // Subtle diagonal lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width + size.height; i += 60) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
