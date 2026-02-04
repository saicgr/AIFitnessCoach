import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

/// Feature Showcase Screen - Simple list of key app features before paywall
///
/// Displayed after Fitness Assessment and before Paywall Features.
/// Clean, minimal design showing 5 key features.
class FeatureShowcaseScreen extends ConsumerWidget {
  const FeatureShowcaseScreen({super.key});

  /// Features to showcase
  static const List<_FeatureData> _features = [
    _FeatureData(
      icon: Icons.link,
      title: 'Supersets',
      description: 'Drag exercises together for combo sets',
      color: Color(0xFF9B59B6),
    ),
    _FeatureData(
      icon: Icons.playlist_add_check,
      title: 'Exercise Queue',
      description: 'Add exercises to your next workout',
      color: Color(0xFF00BCD4),
    ),
    _FeatureData(
      icon: Icons.push_pin,
      title: 'Staple Exercises',
      description: 'Pin lifts AI always includes',
      color: Color(0xFFFF9500),
    ),
    _FeatureData(
      icon: Icons.local_fire_department,
      title: 'Hell Mode',
      description: 'Regenerate with max intensity',
      color: Color(0xFFE74C3C),
    ),
    _FeatureData(
      icon: Icons.layers,
      title: 'Advanced Sets',
      description: 'Track drop sets, warmups & more',
      color: Color(0xFF2ECC71),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final bgColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 40,
                    color: AppColors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Powerful Features',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tools that set FitWiz apart',
                    style: TextStyle(
                      fontSize: 15,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // Feature list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: feature.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              feature.icon,
                              color: feature.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feature.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  feature.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Checkmark
                          Icon(
                            Icons.check_circle,
                            color: feature.color,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (100 + index * 80).ms).fadeIn().slideX(begin: 0.05);
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.go('/paywall-features');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ).animate(delay: 500.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

/// Data class for feature information
class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
