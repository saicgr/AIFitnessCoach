import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../onboarding/widgets/foldable_quiz_scaffold.dart';

/// Paywall Screen 1: Feature Highlights
/// Shows the key features users get with premium
class PaywallFeaturesScreen extends ConsumerWidget {
  const PaywallFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final windowState = ref.watch(windowModeProvider);
    final isFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: '',
          headerExtra: _buildPremiumSummary(colors),
          content: SingleChildScrollView(
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

                // Feature list - same size on both phone and foldable
                _FeatureItem(icon: Icons.auto_fix_high, iconColor: colors.purple, title: 'Unlimited AI workout generation', subtitle: '23+ equipment types with personalized weights', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.link, iconColor: const Color(0xFF9B59B6), title: 'Supersets', subtitle: 'Drag exercises together for combo sets', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.layers, iconColor: colors.success, title: 'Advanced sets', subtitle: 'Track drop sets, warmups & more', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.local_fire_department, iconColor: const Color(0xFFE74C3C), title: 'Hell Mode', subtitle: 'Regenerate with max intensity', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.playlist_add_check, iconColor: colors.cyan, title: 'Exercise queue', subtitle: 'Add exercises to your next workout', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.location_on_outlined, iconColor: colors.electricBlue, title: 'Workout environment aware', subtitle: 'Gym, home, hotel, outdoors - adapts to your space', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.star_outline, iconColor: colors.accent, title: 'Staple & avoided exercises', subtitle: 'Always include favorites, never see exercises you hate', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.camera_alt_outlined, iconColor: colors.orange, title: 'AI food photo scanning', subtitle: 'Snap a photo, get instant calories & macros', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.text_fields, iconColor: colors.electricBlue, title: 'Text to calories', subtitle: 'Type what you ate, AI estimates instantly', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.restaurant_menu_outlined, iconColor: const Color(0xFF00BCD4), title: 'Calorie & macro tracking', subtitle: 'Log meals, hit daily targets, track progress', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.healing_outlined, iconColor: colors.coral, title: 'Injury tracking & body part exclusion', subtitle: 'Report injuries, auto-adapt workouts safely', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.elderly, iconColor: colors.teal, title: 'Age-aware & comeback mode', subtitle: 'Safe return after breaks, senior adjustments', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.fitness_center, iconColor: colors.success, title: '52 skill progressions', subtitle: 'Wall pushups → one-arm, dragon squats & more', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.self_improvement, iconColor: colors.accent, title: 'Hormonal health optimization', subtitle: 'Cycle-aware workouts & diet recommendations', colors: colors),

                const SizedBox(height: 24),
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
