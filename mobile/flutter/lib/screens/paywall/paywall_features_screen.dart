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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Empty space where X button would be (removed per user request)
            const SizedBox(height: 56),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // Logo/Mascot
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.cyan,
                            colors.cyanDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Unlock the full',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'AI Coach experience',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colors.cyan,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Feature list
                    _FeatureItem(
                      icon: Icons.chat_bubble_outline,
                      iconColor: colors.cyan,
                      title: 'Unlimited AI conversations',
                      colors: colors,
                    ),
                    const SizedBox(height: 20),
                    _FeatureItem(
                      icon: Icons.camera_alt_outlined,
                      iconColor: colors.orange,
                      title: 'AI food photo scanning',
                      colors: colors,
                    ),
                    const SizedBox(height: 20),
                    _FeatureItem(
                      icon: Icons.fitness_center,
                      iconColor: colors.purple,
                      title: 'Personalized workout plans',
                      colors: colors,
                    ),
                    const SizedBox(height: 20),
                    _FeatureItem(
                      icon: Icons.insights,
                      iconColor: colors.success,
                      title: 'Progress tracking & analytics',
                      colors: colors,
                    ),
                    const SizedBox(height: 20),
                    _FeatureItem(
                      icon: Icons.emoji_events_outlined,
                      iconColor: Colors.amber,
                      title: 'Achievements & streaks',
                      colors: colors,
                    ),

                    const Spacer(flex: 2),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.push('/paywall-timeline'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.cyan,
                          foregroundColor: Colors.white,
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

                    const SizedBox(height: 32),
                  ],
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
      context.go('/home');
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final ThemeColors colors;

  const _FeatureItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
