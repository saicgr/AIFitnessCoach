import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/theme_colors.dart';
import 'fasting_stage_model.dart';

/// Live ticking circular fasting timer with a segmented metabolic-stage arc.
///
/// - The big H:MM:SS timer ticks live (parent rebuilds it every second via
///   `fastingTimerProvider`); the seconds digit pulses subtly.
/// - The ring is split into colored stage segments; the current stage is
///   highlighted and a progress dot tracks the live position.
/// - The center icon swaps per stage with an animated cross-fade.
class FastingStageTimer extends StatefulWidget {
  /// Elapsed seconds of the active fast (live). 0 when not fasting.
  final int elapsedSeconds;

  /// Goal duration in minutes.
  final int goalMinutes;

  /// Whether a fast is currently active.
  final bool isActive;

  /// Current metabolic stage (drives center icon + accents).
  final FastingStage stage;

  const FastingStageTimer({
    super.key,
    required this.elapsedSeconds,
    required this.goalMinutes,
    required this.isActive,
    required this.stage,
  });

  @override
  State<FastingStageTimer> createState() => _FastingStageTimerState();
}

class _FastingStageTimerState extends State<FastingStageTimer>
    with TickerProviderStateMixin {
  late final AnimationController _secondsPulse;
  late final AnimationController _ringEntry;
  int _lastSecond = -1;

  @override
  void initState() {
    super.initState();
    _secondsPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _ringEntry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant FastingStageTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pulse the seconds digit each time the second changes.
    final sec = widget.elapsedSeconds % 60;
    if (widget.isActive && sec != _lastSecond) {
      _lastSecond = sec;
      _secondsPulse
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _secondsPulse.dispose();
    _ringEntry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final stageColor = widget.stage.color;

    final elapsedHours = widget.elapsedSeconds / 3600.0;
    final goalHours = widget.goalMinutes / 60.0;
    final progress = goalHours <= 0
        ? 0.0
        : (elapsedHours / goalHours).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final size = screenWidth < 380 ? 232.0 : 276.0;
        const stroke = 14.0;

        return SizedBox(
          width: size,
          height: size,
          child: AnimatedBuilder(
            animation: _ringEntry,
            builder: (context, _) {
              final entry = Curves.easeOutCubic.transform(_ringEntry.value);
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Ambient stage glow.
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: stageColor.withValues(
                              alpha: 0.22 * entry),
                          blurRadius: 36,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Segmented stage ring.
                  SizedBox(
                    width: size,
                    height: size,
                    child: CustomPaint(
                      painter: _StageRingPainter(
                        progress: progress * entry,
                        goalHours: goalHours,
                        currentStage: widget.stage,
                        stroke: stroke,
                        trackColor: colors.cardBorder.withValues(alpha: 0.4),
                        isActive: widget.isActive,
                      ),
                    ),
                  ),
                  // Center content.
                  _buildCenter(colors, stageColor, size),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCenter(ThemeColors colors, Color stageColor, double size) {
    final s = widget.elapsedSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;

    if (!widget.isActive) {
      // Idle state — invite to start.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bedtime_outlined, size: 44, color: colors.textMuted),
          const SizedBox(height: 10),
          Text(
            'Ready to fast',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      );
    }

    // Time until the next metabolic stage begins.
    final next = widget.stage.next;
    final String nextLabel;
    if (next == null) {
      nextLabel = 'Final stage';
    } else {
      final toNext = widget.stage.endHour * 3600 - widget.elapsedSeconds;
      if (toNext <= 0) {
        nextLabel = 'Next · ${next.name}';
      } else {
        final nh = toNext ~/ 3600;
        final nm = (toNext % 3600) ~/ 60;
        nextLabel =
            'Next · ${next.name}  ${nh > 0 ? '${nh}h ' : ''}${nm}m';
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Per-stage icon — cross-fades + scales when the stage changes.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Container(
            key: ValueKey(widget.stage),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stageColor.withValues(alpha: 0.16),
            ),
            child: Icon(widget.stage.icon, color: stageColor, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        // Current stage name — the stage is integrated INTO the timer so
        // the user sees it without scrolling to a separate card.
        Text(
          widget.stage.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: stageColor,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        // Live H:MM:SS — seconds digit pulses each tick.
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${h.toString().padLeft(2, '0')}:'
              '${m.toString().padLeft(2, '0')}:',
              style: TextStyle(
                fontSize: size < 250 ? 30 : 36,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                letterSpacing: -1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            AnimatedBuilder(
              animation: _secondsPulse,
              builder: (context, child) {
                // Subtle scale + fade pop on each new second.
                final t = Curves.easeOut.transform(_secondsPulse.value);
                final scale = 1.0 + 0.10 * (1.0 - t);
                final opacity = 0.55 + 0.45 * t;
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Text(
                sec.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: size < 250 ? 30 : 36,
                  fontWeight: FontWeight.bold,
                  color: stageColor,
                  letterSpacing: -1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          'elapsed',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: colors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        // Next-stage hint — keeps the stage progression glanceable in-ring.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            nextLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the metabolic-stage ring: faded stage segments behind, a brightly
/// filled progress arc through completed stages, and a tracking dot.
class _StageRingPainter extends CustomPainter {
  final double progress; // 0..1 of goal
  final double goalHours;
  final FastingStage currentStage;
  final double stroke;
  final Color trackColor;
  final bool isActive;

  _StageRingPainter({
    required this.progress,
    required this.goalHours,
    required this.currentStage,
    required this.stroke,
    required this.trackColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final goal = goalHours <= 0 ? 16.0 : goalHours;

    const startTop = -math.pi / 2;
    const fullSweep = 2 * math.pi;

    double angleFor(double hours) =>
        startTop + (hours / goal).clamp(0.0, 1.0) * fullSweep;

    // 1. Base track.
    canvas.drawArc(
      rect,
      0,
      fullSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = trackColor,
    );

    // 2. Faded stage segments (only those that fall within the goal window).
    for (final stage in FastingStage.values) {
      if (stage.startHour >= goal) break;
      final segStart = angleFor(stage.startHour.toDouble());
      final segEndHour = math.min(stage.endHour.toDouble(), goal);
      final segSweep = angleFor(segEndHour) - segStart;
      if (segSweep <= 0) continue;
      canvas.drawArc(
        rect,
        segStart + 0.012,
        segSweep - 0.024,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = stage.color.withValues(alpha: 0.22),
      );
    }

    if (!isActive || progress <= 0) return;

    // 3. Filled progress arc — colored per stage up to live position.
    final progressHours = (progress * goal).clamp(0.0, goal);
    for (final stage in FastingStage.values) {
      if (stage.startHour >= progressHours) break;
      if (stage.startHour >= goal) break;
      final segStart = stage.startHour.toDouble();
      final segEnd =
          math.min(stage.endHour.toDouble(), math.min(progressHours, goal));
      if (segEnd <= segStart) continue;

      final a0 = angleFor(segStart);
      final sweep = angleFor(segEnd) - a0;
      final isCurrent = stage == currentStage;

      if (isCurrent) {
        // Glow under the current stage segment.
        canvas.drawArc(
          rect,
          a0,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke + 6
            ..strokeCap = StrokeCap.round
            ..color = stage.color.withValues(alpha: 0.32)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      canvas.drawArc(
        rect,
        a0,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = stage.color
              .withValues(alpha: isCurrent ? 1.0 : 0.78),
      );
    }

    // 4. Tracking dot at the live position.
    final dotAngle = startTop + progress * fullSweep;
    final dot = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );
    canvas.drawCircle(
      dot,
      stroke * 0.85,
      Paint()
        ..color = currentStage.color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      dot,
      stroke * 0.55,
      Paint()..color = currentStage.color,
    );
    canvas.drawCircle(
      dot,
      stroke * 0.26,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _StageRingPainter old) =>
      old.progress != progress ||
      old.currentStage != currentStage ||
      old.goalHours != goalHours ||
      old.isActive != isActive;
}
