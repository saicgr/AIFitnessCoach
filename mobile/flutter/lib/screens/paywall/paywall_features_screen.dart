import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../data/providers/feature_provider.dart';
import '../../models/feature_request.dart';
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
                _FeatureItem(icon: Icons.camera_alt_outlined, iconColor: colors.orange, title: 'Unlimited food photo scanning', subtitle: 'Snap a photo, get instant calories & macros', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.text_fields, iconColor: colors.electricBlue, title: 'Unlimited text to calories', subtitle: 'Type what you ate, AI estimates instantly', colors: colors),
                const SizedBox(height: 8),
                _FeatureItem(icon: Icons.videocam_outlined, iconColor: colors.coral, title: 'AI form video analysis', subtitle: 'Upload exercise videos for AI form scoring & corrections', colors: colors),
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

                // --- Coming Soon: Roadmap Voting ---
                const SizedBox(height: 24),
                _RoadmapVotingSection(colors: colors),

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

/// Shows top voting features from the roadmap with upvote buttons.
/// Loads from the existing featuresProvider (backend API).
class _RoadmapVotingSection extends ConsumerWidget {
  final ThemeColors colors;

  const _RoadmapVotingSection({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuresAsync = ref.watch(featuresProvider);

    return featuresAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (features) {
        // Show top 5 voting/planned features
        final votingFeatures = features
            .where((f) => f.isVoting || f.isPlanned)
            .take(5)
            .toList();

        if (votingFeatures.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.rocket_launch_outlined, size: 18, color: colors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coming Soon — Vote!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'Shape FitWiz',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Feature vote cards
            ...votingFeatures.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VotableFeatureCard(
                feature: feature,
                colors: colors,
                onVote: () {
                  HapticFeedback.lightImpact();
                  ref.read(featuresProvider.notifier).toggleVote(feature.id);
                },
              ),
            )),
          ],
        );
      },
    );
  }
}

class _VotableFeatureCard extends StatelessWidget {
  final FeatureRequest feature;
  final ThemeColors colors;
  final VoidCallback onVote;

  const _VotableFeatureCard({
    required this.feature,
    required this.colors,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(feature.category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          // Vote button
          GestureDetector(
            onTap: onVote,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: feature.userHasVoted
                    ? colors.accent.withValues(alpha: 0.15)
                    : colors.accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: feature.userHasVoted
                      ? colors.accent
                      : colors.cardBorder,
                  width: feature.userHasVoted ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    feature.userHasVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 14,
                    color: feature.userHasVoted ? colors.accent : colors.textMuted,
                  ),
                  Text(
                    '${feature.voteCount}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: feature.userHasVoted ? colors.accent : colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Feature info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              feature.categoryDisplayName,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: categoryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'workout':
        return const Color(0xFFF97316);
      case 'nutrition':
        return const Color(0xFF00BCD4);
      case 'social':
        return const Color(0xFF9B59B6);
      case 'analytics':
        return const Color(0xFF3B82F6);
      case 'coaching':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
