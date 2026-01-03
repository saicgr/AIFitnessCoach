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

                    // Feature list - Key differentiators (ordered by impact)
                    _FeatureItem(
                      icon: Icons.auto_fix_high,
                      iconColor: colors.purple,
                      title: 'Unlimited workout generation',
                      subtitle: 'Custom AI plans for 23+ equipment types',
                      colors: colors,
                    ),
                    const SizedBox(height: 16),
                    _FeatureItem(
                      icon: Icons.camera_alt_outlined,
                      iconColor: colors.orange,
                      title: 'AI food photo scanning',
                      subtitle: 'Snap a photo, get instant macros',
                      colors: colors,
                    ),
                    const SizedBox(height: 16),
                    _FeatureItem(
                      icon: Icons.restaurant_menu_outlined,
                      iconColor: colors.cyan,
                      title: 'Full nutrition & macro tracking',
                      subtitle: 'Log meals, track calories & macros',
                      colors: colors,
                    ),
                    const SizedBox(height: 16),
                    _FeatureItem(
                      icon: Icons.library_books_outlined,
                      iconColor: colors.success,
                      title: '1,700+ exercise library',
                      subtitle: 'Video demos & muscle targeting',
                      colors: colors,
                    ),
                    const SizedBox(height: 16),
                    _FeatureItem(
                      icon: Icons.trending_up,
                      iconColor: Colors.amber,
                      title: 'PR tracking & progress charts',
                      subtitle: 'Track strength gains over time',
                      colors: colors,
                    ),
                    const SizedBox(height: 16),
                    _FeatureItem(
                      icon: Icons.healing_outlined,
                      iconColor: colors.coral,
                      title: 'Injury-aware adaptations',
                      subtitle: 'Auto-adjust for injuries & recovery',
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
