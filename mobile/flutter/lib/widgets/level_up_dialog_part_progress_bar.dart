part of 'level_up_dialog.dart';


/// Animated progress bar between level badges
class _ProgressBar extends StatelessWidget {
  final double progress;
  final double barWidth;

  const _ProgressBar({
    required this.progress,
    required this.barWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            // Green filled portion
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade600,
                      Colors.green.shade400,
                    ],
                  ),
                ),
              ),
            ),
            // Blue marker at the edge
            if (progress > 0.02 && progress < 0.98)
              Positioned(
                left: (progress * (barWidth - 4)).clamp(0.0, barWidth - 4),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade300,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            // Chevron arrows (decorative, like Battlefield)
            if (progress > 0.1)
              ...List.generate(
                (progress * 8).floor().clamp(0, 6),
                (i) => Positioned(
                  left: (i + 1) * (barWidth / 8),
                  top: 2,
                  bottom: 2,
                  child: Icon(
                    Icons.chevron_right,
                    size: 10,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

