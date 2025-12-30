import 'package:flutter/material.dart';

/// Shared FitWiz watermark widget for share templates
/// Uses the actual app icon (wizard hat + dumbbell)
class AppWatermark extends StatelessWidget {
  final Color? backgroundColor;
  final List<Color>? gradientColors;

  const AppWatermark({
    super.key,
    this.backgroundColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon - wizard hat with dumbbell
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'FitWiz',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [const Color(0xFF00D9FF), const Color(0xFF9D4EDD)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.fitness_center,
        size: 14,
        color: Colors.white,
      ),
    );
  }
}
