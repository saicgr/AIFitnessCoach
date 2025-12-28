import 'package:flutter/material.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/lottie_animations.dart';

/// Modal overlay shown while generating workout plan.
class WorkoutLoadingModal extends StatelessWidget {
  final double progress;
  final String message;

  const WorkoutLoadingModal({
    super.key,
    required this.progress,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.elevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(colors),
              const SizedBox(height: 24),
              _buildTitle(colors),
              const SizedBox(height: 8),
              _buildMessage(colors),
              const SizedBox(height: 24),
              _buildProgressBar(colors),
              const SizedBox(height: 8),
              _buildPercentage(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeColors colors) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.cyanGradient.colors.map((c) => c.withOpacity(0.15)).toList(),
          begin: colors.cyanGradient.begin,
          end: colors.cyanGradient.end,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: LottieLoading(
          size: 70,
          color: colors.cyan,
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeColors colors) {
    return Text(
      'Building Your Workout Plan',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildMessage(ThemeColors colors) {
    return Text(
      message,
      style: TextStyle(
        fontSize: 14,
        color: colors.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildProgressBar(ThemeColors colors) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation(colors.cyan),
        ),
      ),
    );
  }

  Widget _buildPercentage(ThemeColors colors) {
    return Text(
      '${progress.round()}% complete',
      style: TextStyle(
        fontSize: 12,
        color: colors.textMuted,
      ),
    );
  }
}
