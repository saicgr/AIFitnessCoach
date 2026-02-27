import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Stats Weekly Report Template - Receipt/report card style
/// Dark navy gradient with structured typographic layout and grade badge
class StatsWeeklyReportTemplate extends StatelessWidget {
  final int weeklyCompleted;
  final int weeklyGoal;
  final int currentStreak;
  final String totalTimeFormatted;
  final String dateRangeLabel;
  final int totalWorkouts;
  final bool showWatermark;

  const StatsWeeklyReportTemplate({
    super.key,
    required this.weeklyCompleted,
    required this.weeklyGoal,
    required this.currentStreak,
    required this.totalTimeFormatted,
    required this.dateRangeLabel,
    required this.totalWorkouts,
    this.showWatermark = true,
  });

  double get _completionPercent =>
      weeklyGoal > 0 ? (weeklyCompleted / weeklyGoal * 100).clamp(0, 100) : 0;

  String get _grade {
    final pct = _completionPercent;
    if (pct >= 100) return 'A+';
    if (pct >= 85) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 55) return 'B';
    if (pct >= 40) return 'C';
    return 'D';
  }

  Color get _gradeColor {
    switch (_grade) {
      case 'A+':
        return const Color(0xFF22C55E);
      case 'A':
        return const Color(0xFF4ADE80);
      case 'B+':
        return const Color(0xFF3B82F6);
      case 'B':
        return const Color(0xFF60A5FA);
      case 'C':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 440,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Subtle dotted grid
          Positioned.fill(
            child: CustomPaint(
              painter: _DottedGridPainter(),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Double-line header
                const Text(
                  'WEEKLY',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 6,
                  ),
                ),
                const Text(
                  'REPORT CARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  dateRangeLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 20),

                // Grade badge centered
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _gradeColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _gradeColor.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _grade,
                        style: TextStyle(
                          color: _gradeColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Stat rows
                _ReportRow(
                  label: 'COMPLETED',
                  value: '$weeklyCompleted / $weeklyGoal',
                ),
                _ReportRow(
                  label: 'COMPLETION',
                  value: '${_completionPercent.toStringAsFixed(0)}%',
                ),
                _ReportRow(
                  label: 'STREAK',
                  value: '$currentStreak days',
                ),
                _ReportRow(
                  label: 'TIME',
                  value: totalTimeFormatted,
                ),
                _ReportRow(
                  label: 'TOTAL',
                  value: '$totalWorkouts workouts',
                  isLast: true,
                ),

                const Spacer(),

                if (showWatermark) const AppWatermark(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _ReportRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DottedLinePainter(),
          ),
      ],
    );
  }
}

/// Dotted separator line painter
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle dotted grid background
class _DottedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;

    for (double x = 10; x < size.width; x += spacing) {
      for (double y = 10; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
