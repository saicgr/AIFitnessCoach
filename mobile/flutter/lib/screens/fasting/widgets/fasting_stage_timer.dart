import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';
import 'fasting_stage_model.dart';

import '../../../l10n/generated/app_localizations.dart';
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

  /// Drives the tap-triggered tooltip on the goal marker so we can call
  /// `ensureTooltipVisible()` imperatively (Tooltips are long-press by default).
  final GlobalKey<TooltipState> _goalTooltipKey = GlobalKey<TooltipState>();

  /// Human-readable goal label, e.g. "16h", "16h 30m", "45m". Appends
  /// " · reached" once the live fast has met or exceeded the goal.
  String _goalTooltipMessage() {
    final goalMinutes = widget.goalMinutes;
    final h = goalMinutes ~/ 60;
    final m = goalMinutes % 60;
    final String duration;
    if (h > 0 && m > 0) {
      duration = '${h}h ${m}m';
    } else if (h > 0) {
      duration = '${h}h';
    } else {
      duration = '${m}m';
    }
    final reached = widget.elapsedSeconds >= goalMinutes * 60;
    return 'Fasting goal: $duration${reached ? ' · reached' : ''}';
  }

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

    // Fixed-span ring: scale the ring to a stable hour window that is wide
    // enough to hold the goal AND the live elapsed position, so the dot
    // never wraps back to the top once the fast passes its goal. A 24h
    // minimum keeps the metabolic-stage arcs (Fed → Autophagy) laid out on
    // a steady scale.
    final elapsedHoursCeil = elapsedHours.ceilToDouble();
    final spanHours =
        math.max(24.0, math.max(goalHours, elapsedHoursCeil));

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
                        elapsedHours: elapsedHours * entry,
                        goalHours: goalHours,
                        spanHours: spanHours,
                        currentStage: widget.stage,
                        stroke: stroke,
                        trackColor: colors.cardBorder.withValues(alpha: 0.4),
                        goalMarkerColor: colors.textPrimary,
                        isActive: widget.isActive,
                      ),
                    ),
                  ),
                  // Center content.
                  _buildCenter(colors, stageColor, size),
                  // Tappable goal-marker hit target — sits ON the ring at the
                  // goal angle, using the SAME angle math the painter uses, so
                  // tapping the visible tick/badge surfaces a tooltip. Only
                  // present while a fast is active and a real goal is set.
                  if (widget.isActive && widget.goalMinutes > 0)
                    ..._buildGoalMarkerTapTarget(colors, size, stroke),
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
            AppLocalizations.of(context).fastingStageTimerReadyToFast,
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
        const SizedBox(height: 2),
        // Unambiguous: the big number above is ELAPSED time, not remaining.
        Text(
          AppLocalizations.of(context).fastingStageTimerElapsed,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
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

  /// Builds the transparent ~36×36 tap target centered on the goal marker.
  ///
  /// The painter draws the marker at ring angle `startTop + (goalHours /
  /// spanHours) * fullSweep` on the ring radius `(size - stroke) / 2`. We
  /// reproduce that math here so the tap target tracks the visible marker on
  /// both ring sizes (232 / 276) and at any goal/span. Returned as a list so
  /// it can be spread into the Stack only when active.
  List<Widget> _buildGoalMarkerTapTarget(
      ThemeColors colors, double size, double stroke) {
    final goalHours = widget.goalMinutes / 60.0;
    final elapsedHours = widget.elapsedSeconds / 3600.0;
    final elapsedHoursCeil = elapsedHours.ceilToDouble();
    final spanHours = math.max(24.0, math.max(goalHours, elapsedHoursCeil));

    // Marker is never drawn past the span — skip the tap target too.
    if (goalHours <= 0 || goalHours > spanHours) return const [];

    // Same angle math as _StageRingPainter.angleFor / paint.
    const startTop = -math.pi / 2;
    const fullSweep = 2 * math.pi;
    final goalAngle =
        startTop + (goalHours / spanHours).clamp(0.0, 1.0) * fullSweep;
    final radius = (size - stroke) / 2;
    final center = size / 2;

    const double target = 36.0;
    final markerX = center + radius * math.cos(goalAngle);
    final markerY = center + radius * math.sin(goalAngle);

    return [
      Positioned(
        left: markerX - target / 2,
        top: markerY - target / 2,
        width: target,
        height: target,
        child: Tooltip(
          key: _goalTooltipKey,
          message: _goalTooltipMessage(),
          triggerMode: TooltipTriggerMode.manual,
          preferBelow: false,
          decoration: BoxDecoration(
            color: colors.elevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.cardBorder.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          child: GestureDetector(
            // Tap-only — does not claim drags, so the ring/page stays
            // scrollable and other gestures elsewhere are unaffected.
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.light();
              _goalTooltipKey.currentState?.ensureTooltipVisible();
            },
            child: const SizedBox(width: target, height: target),
          ),
        ),
      ),
    ];
  }
}

/// Paints the metabolic-stage ring on a FIXED hour span (not the goal), so
/// the live dot never wraps: faded stage segments behind, a brightly filled
/// progress arc through completed stages, a goal notch, and a tracking dot.
class _StageRingPainter extends CustomPainter {
  /// Live elapsed hours of the fast.
  final double elapsedHours;

  /// The user's goal in hours (drives the goal notch position).
  final double goalHours;

  /// The fixed hour window the whole ring is scaled to — wide enough to
  /// hold both the goal and the current elapsed position, so nothing wraps.
  final double spanHours;

  final FastingStage currentStage;
  final double stroke;
  final Color trackColor;

  /// Theme-aware color for the goal notch / check (textPrimary).
  final Color goalMarkerColor;
  final bool isActive;

  _StageRingPainter({
    required this.elapsedHours,
    required this.goalHours,
    required this.spanHours,
    required this.currentStage,
    required this.stroke,
    required this.trackColor,
    required this.goalMarkerColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final span = spanHours <= 0 ? 24.0 : spanHours;

    const startTop = -math.pi / 2;
    const fullSweep = 2 * math.pi;

    // Every hour value maps onto the SAME fixed span — never the goal —
    // so the dot and the stage arcs share one stable scale.
    double angleFor(double hours) =>
        startTop + (hours / span).clamp(0.0, 1.0) * fullSweep;

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

    // 2. Faded stage segments — laid out across the fixed span. Every stage
    //    up to the span fits, including Autophagy / Deep Autophagy past the
    //    goal, so the path ahead of the dot is always visible.
    for (final stage in FastingStage.values) {
      if (stage.startHour >= span) break;
      final segStart = angleFor(stage.startHour.toDouble());
      final segEndHour = math.min(stage.endHour.toDouble(), span);
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

    // 3. Filled progress arc — colored per stage up to the live position.
    final progressHours = elapsedHours.clamp(0.0, span);
    if (isActive && progressHours > 0) {
      for (final stage in FastingStage.values) {
        if (stage.startHour >= progressHours) break;
        if (stage.startHour >= span) break;
        final segStart = stage.startHour.toDouble();
        final segEnd = math.min(
            stage.endHour.toDouble(), math.min(progressHours, span));
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
            ..color =
                stage.color.withValues(alpha: isCurrent ? 1.0 : 0.78),
        );
      }
    }

    // 4. Goal marker — a radial tick on the ring at the goal position. Once
    //    elapsed ≥ goal it becomes a filled "done" dot with a check, so
    //    "goal reached" is obvious on the ring (the dot itself never resets).
    if (goalHours > 0 && goalHours <= span) {
      final goalAngle = angleFor(goalHours);
      final goalReached = isActive && elapsedHours >= goalHours;
      final cos = math.cos(goalAngle);
      final sin = math.sin(goalAngle);

      if (goalReached) {
        // Filled "done" badge sitting on the ring.
        final badge = Offset(
          center.dx + radius * cos,
          center.dy + radius * sin,
        );
        // Glow + filled badge in the stage color — white check reads
        // clearly on it in both light and dark themes.
        canvas.drawCircle(
          badge,
          stroke * 0.85,
          Paint()
            ..color = currentStage.color.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(
          badge,
          stroke * 0.62,
          Paint()..color = currentStage.color,
        );
        // Check mark drawn in the badge.
        final cm = stroke * 0.30;
        final checkPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.16
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white;
        final path = Path()
          ..moveTo(badge.dx - cm * 0.95, badge.dy + cm * 0.05)
          ..lineTo(badge.dx - cm * 0.20, badge.dy + cm * 0.78)
          ..lineTo(badge.dx + cm * 1.00, badge.dy - cm * 0.70);
        canvas.drawPath(path, checkPaint);
      } else {
        // Radial tick crossing the ring, plus a small flag dot.
        final inner = radius - stroke * 0.85;
        final outer = radius + stroke * 0.85;
        canvas.drawLine(
          Offset(center.dx + inner * cos, center.dy + inner * sin),
          Offset(center.dx + outer * cos, center.dy + outer * sin),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round
            ..color = goalMarkerColor.withValues(alpha: 0.85),
        );
        canvas.drawCircle(
          Offset(center.dx + outer * cos, center.dy + outer * sin),
          3.2,
          Paint()..color = goalMarkerColor.withValues(alpha: 0.85),
        );
      }
    }

    if (!isActive || progressHours <= 0) return;

    // 5. Tracking dot at the live position — mapped on the fixed span, so it
    //    always sits inside the current stage's arc and never wraps.
    final dotAngle = angleFor(elapsedHours);
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
      old.elapsedHours != elapsedHours ||
      old.currentStage != currentStage ||
      old.goalHours != goalHours ||
      old.spanHours != spanHours ||
      old.isActive != isActive;
}
