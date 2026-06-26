// Visual set-logging dial (Dr-Yaad audit #9) — a compact horizontal track that
// shows, at a glance, the engine's GOAL (yellow), what you did LAST session
// (blue), an optional target BAND (boxed), and where you ARE now (filled). His
// set screen puts these under each metric so logging is "read the dial, swipe".
//
// Pure presentation: give it the four numbers + a unit and it self-scales.
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SetDial extends StatelessWidget {
  final double current;
  final double? goal; // engine target (yellow)
  final double? last; // last session (blue)
  final double? bandMin; // optional target band (e.g. rep range)
  final double? bandMax;
  final String unit; // 'kg' | 'reps' | 's'
  final String label; // 'LOAD' | 'REPS'

  const SetDial({
    super.key,
    required this.current,
    required this.label,
    required this.unit,
    this.goal,
    this.last,
    this.bandMin,
    this.bandMax,
  });

  static const _goalColor = Color(0xFFF5C518); // yellow
  static const _lastColor = Color(0xFF3B9EFF); // blue

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Scale bounds across every value we plot, padded so end markers aren't
    // clipped. Guard against a degenerate single-value range.
    final vals = <double>[
      current,
      if (goal != null) goal!,
      if (last != null) last!,
      if (bandMin != null) bandMin!,
      if (bandMax != null) bandMax!,
    ];
    double lo = vals.reduce((a, b) => a < b ? a : b);
    double hi = vals.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1e-6) {
      lo = lo - 1;
      hi = hi + 1;
    }
    final span = (hi - lo) * 1.15;
    final pad = (hi - lo) * 0.075;
    final base = lo - pad;
    double frac(double v) => ((v - base) / span).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: muted)),
            const Spacer(),
            if (goal != null) _legendDot('goal', _goalColor),
            if (last != null) ...[
              const SizedBox(width: 8),
              _legendDot('last', _lastColor),
            ],
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 14,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              const markerW = 2.5;
              double x(double v) =>
                  (frac(v) * (w - markerW)).clamp(0.0, w - markerW);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Baseline track.
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: track,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Target band (rep range), if provided.
                  if (bandMin != null && bandMax != null)
                    Positioned(
                      left: x(bandMin!),
                      top: 3,
                      child: Container(
                        width: (x(bandMax!) - x(bandMin!)).clamp(2.0, w),
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: AppColors.cyan.withOpacity(0.5),
                              width: 0.6),
                        ),
                      ),
                    ),
                  // Last-session tick.
                  if (last != null) _tick(x(last!), _lastColor, 12),
                  // Goal tick.
                  if (goal != null) _tick(x(goal!), _goalColor, 12),
                  // Current filled marker.
                  Positioned(
                    left: x(current),
                    top: 1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.cyan,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isDark ? Colors.black : Colors.white,
                            width: 1.5),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tick(double left, Color color, double height) {
    return Positioned(
      left: left,
      top: (14 - height) / 2,
      child: Container(
        width: 2.5,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
  }

  Widget _legendDot(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
