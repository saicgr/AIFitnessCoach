import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/subscription_provider.dart';

/// Paywall Screen 1: Feature Highlights
/// Shows the key features users get with premium
class PaywallFeaturesScreen extends ConsumerWidget {
  const PaywallFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use ref.colors(context) to get dynamic accent color from provider
    final colors = ref.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Empty space where X button would be (removed per user request)
            const SizedBox(height: 24),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // App Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: colors.accentGradient,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.fitness_center,
                            size: 36,
                            color: colors.accentContrast,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Unlock the full',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'AI Coach experience',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.accent,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Feature list - Key differentiators (ordered by impact)
                    _FeatureItem(
                      icon: Icons.auto_fix_high,
                      iconColor: colors.purple,
                      title: 'Unlimited AI workout generation',
                      subtitle: '23+ equipment types with personalized weights',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _FeatureItem(
                      icon: Icons.location_on_outlined,
                      iconColor: colors.electricBlue,
                      title: 'Workout environment aware',
                      subtitle: 'Gym, home, hotel, outdoors - adapts to your space',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _FeatureItem(
                      icon: Icons.star_outline,
                      iconColor: colors.accent,
                      title: 'Staple & avoided exercises',
                      subtitle: 'Always include favorites, never see exercises you hate',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _FeatureItem(
                      icon: Icons.camera_alt_outlined,
                      iconColor: colors.orange,
                      title: 'AI food photo scanning',
                      subtitle: 'Snap a photo, get instant calories & macros',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _FeatureItem(
                      icon: Icons.text_fields,
                      iconColor: colors.electricBlue,
                      title: 'Text to calories',
                      subtitle: 'Type what you ate, AI estimates instantly',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _FeatureItem(
                      icon: Icons.restaurant_menu_outlined,
                      iconColor: colors.cyan,
                      title: 'Calorie & macro tracking',
                      subtitle: 'Log meals, hit daily targets, track progress',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _FeatureItem(
                      icon: Icons.healing_outlined,
                      iconColor: colors.coral,
                      title: 'Injury tracking & body part exclusion',
                      subtitle: 'Report injuries, auto-adapt workouts safely',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _FeatureItem(
                      icon: Icons.elderly,
                      iconColor: colors.teal,
                      title: 'Age-aware & comeback mode',
                      subtitle: 'Safe return after breaks, senior adjustments',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _FeatureItem(
                      icon: Icons.fitness_center,
                      iconColor: colors.success,
                      title: '52 skill progressions',
                      subtitle: 'Wall pushups → one-arm, dragon squats & more',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _FeatureItem(
                      icon: Icons.self_improvement,
                      iconColor: colors.accent,
                      title: 'Hormonal health optimization',
                      subtitle: 'Cycle-aware workouts & diet recommendations',
                      colors: colors,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Fixed bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.push('/paywall-timeline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.accentContrast,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Learn More',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _skipToFree(BuildContext context, WidgetRef ref) async {
    await ref.read(subscriptionProvider.notifier).skipToFree();
    if (context.mounted) {
      // Navigate to calibration intro (correct flow: Paywall → Calibration → Workout Gen → Home)
      context.go('/calibration/intro', extra: {'fromOnboarding': true});
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final ThemeColors colors;

  const _FeatureItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
