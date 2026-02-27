import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

/// Glassmorphic bottom sheet previewing the Event-Based Workout feature.
class EventWorkoutComingSoonSheet extends StatelessWidget {
  const EventWorkoutComingSoonSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ThemeColors.of(context).accent;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon with gradient circle
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.25),
                        accentColor.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 44,
                        color: accentColor,
                      ),
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: Icon(
                          Icons.local_fire_department,
                          size: 22,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Center(
                child: Text(
                  'Event-Based Workouts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Center(
                child: Text(
                  'Train smarter for your big moments',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Example event card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💒', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Wedding Prep',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'June 15, 2026  •  183 days left',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.65,
                        minHeight: 8,
                        backgroundColor: cardBorder,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '65%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTag('Intensity: High', accentColor),
                        const SizedBox(width: 8),
                        _buildTag('5 days/wk', accentColor),
                        const SizedBox(width: 8),
                        _buildTag('Notify: 3mo', accentColor),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Feature list header
              Text(
                'What you\'ll be able to do:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              _buildFeatureItem(
                icon: Icons.event_rounded,
                text: 'Set any life event as your training deadline',
                accentColor: accentColor,
                textColor: textSecondary,
              ),
              _buildFeatureItem(
                icon: Icons.trending_up_rounded,
                text: 'Choose intensity ramp-up (gradual, aggressive, or custom)',
                accentColor: accentColor,
                textColor: textSecondary,
              ),
              _buildFeatureItem(
                icon: Icons.add_circle_outline_rounded,
                text: 'Optionally increase workout days as event nears',
                accentColor: accentColor,
                textColor: textSecondary,
              ),
              _buildFeatureItem(
                icon: Icons.notifications_active_outlined,
                text: 'Get notified when event prep activates',
                accentColor: accentColor,
                textColor: textSecondary,
              ),
              _buildFeatureItem(
                icon: Icons.auto_awesome_rounded,
                text: 'AI adjusts your workouts to peak for your event',
                accentColor: accentColor,
                textColor: textSecondary,
              ),
              _buildFeatureItem(
                icon: Icons.timer_outlined,
                text: 'Track countdown and readiness score',
                accentColor: accentColor,
                textColor: textSecondary,
              ),

              const SizedBox(height: 24),

              // Got it! button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.8),
                              accentColor.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Got it!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: bottomPadding + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required Color accentColor,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
