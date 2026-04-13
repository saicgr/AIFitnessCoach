import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Instagram-Story template: the hero "Report Card" slide.
/// Big {PERIOD} / REPORT CARD title, grade badge (A+/A/B+/B/C/D) driven by
/// completion rate, and a structured list of stat rows. Works for any
/// period — Weekly, Monthly, Quarterly, Half-Year, Yearly, YTD, Custom.
class InsightsReportCardTemplate extends StatelessWidget {
  final String periodName; // "WEEKLY" / "MONTHLY" / "YTD" / "CUSTOM"
  final String dateRangeLabel;
  final int workoutsCompleted;
  final int workoutsScheduled;
  final int totalTimeMinutes;
  final int totalCalories;
  final int totalPrs;
  final int maxStreak;
  final bool showWatermark;

  const InsightsReportCardTemplate({
    super.key,
    required this.periodName,
    required this.dateRangeLabel,
    required this.workoutsCompleted,
    required this.workoutsScheduled,
    required this.totalTimeMinutes,
    required this.totalCalories,
    required this.totalPrs,
    required this.maxStreak,
    this.showWatermark = true,
  });

  double get _completionPercent => workoutsScheduled > 0
      ? (workoutsCompleted / workoutsScheduled * 100).clamp(0, 100).toDouble()
      : 0.0;

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

  String _fmtTime(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${minutes}m';
  }

  String _fmtCalories(int kcal) {
    if (kcal >= 1000) return '${(kcal / 1000).toStringAsFixed(1)}k';
    return '$kcal';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 480,
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
          Positioned.fill(child: CustomPaint(painter: _DottedGridPainter())),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodName,
                  style: const TextStyle(
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
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _gradeColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _gradeColor.withValues(alpha: 0.3),
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
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _ReportRow(
                  label: 'COMPLETED',
                  value: '$workoutsCompleted / $workoutsScheduled',
                ),
                _ReportRow(
                  label: 'COMPLETION',
                  value: '${_completionPercent.toStringAsFixed(0)}%',
                ),
                _ReportRow(
                  label: 'TIME',
                  value: _fmtTime(totalTimeMinutes),
                ),
                _ReportRow(
                  label: 'CALORIES',
                  value: _fmtCalories(totalCalories),
                ),
                _ReportRow(
                  label: 'PRs',
                  value: '$totalPrs',
                ),
                _ReportRow(
                  label: 'MAX STREAK',
                  value: '$maxStreak days',
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
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
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

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
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

class _DottedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
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
