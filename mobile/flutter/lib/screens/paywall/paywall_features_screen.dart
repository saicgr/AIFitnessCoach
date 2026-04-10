import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/services/posthog_service.dart';
import '../onboarding/widgets/foldable_quiz_scaffold.dart';

/// Paywall Screen 1: Feature Highlights
/// Shows the key features users get with premium
class PaywallFeaturesScreen extends ConsumerWidget {
  const PaywallFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Track paywall features screen view (fire-and-forget, runs once per build)
    Future.microtask(() {
      ref.read(posthogServiceProvider).capture(
        eventName: 'paywall_features_viewed',
      );
    });

    final colors = ref.colors(context);
    final windowState = ref.watch(windowModeProvider);
    final isFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: '',
          headerExtra: _buildPremiumSummary(colors),
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Show title inline only on phone
                if (!isFoldable) ...[
                  const SizedBox(height: 16),
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
                ],

                if (isFoldable) const SizedBox(height: 8),

                const Spacer(),

                // Feature list
                _FeatureItem(icon: Icons.auto_fix_high, iconColor: colors.purple, title: 'Unlimited AI workout generation', subtitle: '23+ equipment types with personalized weights', colors: colors),
                const SizedBox(height: 12),
                _FeatureItem(icon: Icons.chat_bubble_outline, iconColor: colors.electricBlue, title: 'Unlimited AI coach chat', subtitle: 'Ask anything — nutrition, form, recovery, motivation', colors: colors),
                const SizedBox(height: 12),
                _FeatureItem(icon: Icons.camera_alt_outlined, iconColor: colors.orange, title: 'Unlimited food photo scanning', subtitle: 'Snap a photo, get instant calories & macros', colors: colors),
                const SizedBox(height: 12),
                _FeatureItem(icon: Icons.location_on_outlined, iconColor: colors.electricBlue, title: 'Workout environment aware', subtitle: 'Gym, home, hotel, outdoors — adapts to your space', colors: colors),
                const SizedBox(height: 12),
                _FeatureItem(icon: Icons.show_chart_rounded, iconColor: Colors.greenAccent, title: 'Adaptive TDEE & smart suggestions', subtitle: 'Research-grade metabolism tracking that adapts weekly', colors: colors),
                const SizedBox(height: 12),
                _FeatureItem(icon: Icons.fitness_center, iconColor: colors.purple, title: 'Skill progressions', subtitle: '7 chains with 52+ exercises to master', colors: colors),
                const SizedBox(height: 12),
                _FeatureItem(icon: Icons.healing_outlined, iconColor: colors.coral, title: 'Injury tracking & body part exclusion', subtitle: 'Report injuries, auto-adapt workouts safely', colors: colors),
                const SizedBox(height: 12),
                _FeatureItem(icon: Icons.grid_view_rounded, iconColor: Colors.tealAccent, title: 'Muscle heatmap & balance analysis', subtitle: 'Visualize which muscles you train most', colors: colors),
                const SizedBox(height: 12),
                _FeatureItem(icon: Icons.bar_chart_rounded, iconColor: colors.orange, title: 'Advanced charts & analytics', subtitle: 'All-time history with detailed progress trends', colors: colors),
                const SizedBox(height: 12),
                _FeatureItem(icon: Icons.person_outline_rounded, iconColor: colors.purple, title: 'Coach personas', subtitle: '5+ AI personality styles to match your vibe', colors: colors),
                const SizedBox(height: 12),
                _FeatureItem(icon: Icons.local_fire_department, iconColor: const Color(0xFFE74C3C), title: 'Hell Mode', subtitle: 'Regenerate with max intensity — not for the faint-hearted', colors: colors),

                const Spacer(),
              ],
            ),
          ),
          button: Padding(
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
        ),
      ),
    );
  }

  Widget _buildPremiumSummary(ThemeColors colors) {
    final categories = [
      (icon: Icons.fitness_center, label: 'AI Workouts', count: '14+ features'),
      (icon: Icons.restaurant_rounded, label: 'Nutrition', count: '3 tools'),
      (icon: Icons.healing_outlined, label: 'Safety', count: 'Injury-aware'),
      (icon: Icons.trending_up, label: 'Progress', count: '52 skills'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Centered app icon
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: colors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.fitness_center,
                  size: 32,
                  color: colors.accentContrast,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          'Unlock the full',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        Text(
          'AI Coach experience',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.accent,
          ),
        ),
        const SizedBox(height: 20),

        // Feature category cards
        ...categories.map((cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(cat.icon, size: 18, color: colors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      cat.count,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),

        // Trial callout
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.accent.withValues(alpha: 0.1),
                colors.accent.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.accent.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.card_giftcard, size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '7-day free trial\nCancel anytime, no questions asked',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
          child: Icon(icon, color: iconColor, size: 18),
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

