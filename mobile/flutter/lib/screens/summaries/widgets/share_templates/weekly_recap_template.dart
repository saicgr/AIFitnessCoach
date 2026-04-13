import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Instagram-Story template: "Week Recap"
/// Dominant circular completion ring + 3-up supporting stats + optional
/// AI summary teaser. Designed to fit a 320x440 card that the base sheet
/// scales into a 1080x1920 Instagram Story canvas.
class WeeklyRecapTemplate extends StatelessWidget {
  final String dateRangeLabel;
  final int workoutsCompleted;
  final int workoutsScheduled;
  final int totalTimeMinutes;
  final int currentStreak;
  final int prsAchieved;
  final String? aiSummaryPreview;
  final bool showWatermark;

  const WeeklyRecapTemplate({
    super.key,
    required this.dateRangeLabel,
    required this.workoutsCompleted,
    required this.workoutsScheduled,
    required this.totalTimeMinutes,
    required this.currentStreak,
    required this.prsAchieved,
    this.aiSummaryPreview,
    this.showWatermark = true,
  });

  double get _completionRate =>
      workoutsScheduled > 0 ? (workoutsCompleted / workoutsScheduled) : 0.0;

  Color get _ringColor {
    final pct = _completionRate * 100;
    if (pct >= 80) return const Color(0xFF22C55E);
    if (pct >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _timeLabel {
    if (totalTimeMinutes >= 60) {
      final h = totalTimeMinutes ~/ 60;
      final m = totalTimeMinutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${totalTimeMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1220),
            Color(0xFF1E1B4B),
            Color(0xFF0B1220),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GlowPainter(_ringColor))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WEEK',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 6,
                  ),
                ),
                const Text(
                  'RECAP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateRangeLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _CompletionRing(
                    progress: _completionRate,
                    color: _ringColor,
                    completed: workoutsCompleted,
                    scheduled: workoutsScheduled,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        icon: Icons.timer_rounded,
                        value: _timeLabel,
                        label: 'TIME',
                        color: const Color(0xFF60A5FA),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.emoji_events_rounded,
                        value: '$prsAchieved',
                        label: 'PRs',
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.local_fire_department_rounded,
                        value: '$currentStreak',
                        label: 'STREAK',
                        color: const Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (aiSummaryPreview != null &&
                    aiSummaryPreview!.trim().isNotEmpty)
                  _SummaryBubble(text: aiSummaryPreview!),
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

class _CompletionRing extends StatelessWidget {
  final double progress;
  final Color color;
  final int completed;
  final int scheduled;

  const _CompletionRing({
    required this.progress,
    required this.color,
    required this.completed,
    required this.scheduled,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).round();

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                color: color,
                background: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pct%',
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completed / $scheduled',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'WORKOUTS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBubble extends StatelessWidget {
  final String text;
  const _SummaryBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFF60A5FA), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color background;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bg = Paint()
      ..color = background
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          color.withValues(alpha: 0.6),
          color,
          color.withValues(alpha: 0.9),
        ],
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _GlowPainter extends CustomPainter {
  final Color color;
  _GlowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.38),
        radius: size.width * 0.6,
      ));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
