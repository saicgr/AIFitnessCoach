import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Model representing a single tour step
class TourStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final Color color;
  final bool showDemoButton;
  final String? deepLinkRoute;
  final String? deepLinkLabel;

  const TourStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.color,
    this.showDemoButton = false,
    this.deepLinkRoute,
    this.deepLinkLabel,
  });
}

/// Card widget showing a single tour step with animated elements
class TourFeatureCard extends StatelessWidget {
  final TourStep step;
  final VoidCallback? onDemoTap;
  final VoidCallback? onDeepLinkTap;

  const TourFeatureCard({
    super.key,
    required this.step,
    this.onDemoTap,
    this.onDeepLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // Animated icon with gradient background and glow
          _buildAnimatedIcon(isDark),

          const SizedBox(height: 32),

          // Title
          Text(
            step.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 8),

          // Subtitle in step color
          Text(
            step.subtitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: step.color,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Features list container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cardBorder.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: step.features.asMap().entries.map((entry) {
                final index = entry.key;
                final feature = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < step.features.length - 1 ? 12 : 0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: step.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: step.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 500 + (index * 100)),
                      duration: 300.ms,
                    )
                    .slideX(
                      begin: 0.1,
                      delay: Duration(milliseconds: 500 + (index * 100)),
                      duration: 300.ms,
                      curve: Curves.easeOutCubic,
                    );
              }).toList(),
            ),
          )
              .animate()
              .fadeIn(delay: 450.ms, duration: 400.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                delay: 450.ms,
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 24),

          // Demo button (if enabled)
          if (step.showDemoButton && onDemoTap != null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onDemoTap,
                icon: Icon(
                  Icons.play_circle_outline_rounded,
                  color: step.color,
                ),
                label: Text(
                  'Try Demo Workout',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: step.color,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: step.color, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 300.ms)
                .slideY(begin: 0.2, delay: 700.ms, duration: 300.ms),

          // Deep link button (if enabled)
          if (step.deepLinkRoute != null && onDeepLinkTap != null) ...[
            if (step.showDemoButton) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton.icon(
                onPressed: onDeepLinkTap,
                icon: Icon(
                  Icons.explore_outlined,
                  color: textSecondary,
                  size: 20,
                ),
                label: Text(
                  step.deepLinkLabel ?? 'Explore',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 300.ms),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(bool isDark) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            step.color,
            step.color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: step.color.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: step.color.withOpacity(0.2),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Icon(
        step.icon,
        size: 56,
        color: Colors.white,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 2.seconds,
          curve: Curves.easeInOut,
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }
}
