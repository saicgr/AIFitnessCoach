import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/feature_provider.dart';
import '../../models/feature_request.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/segmented_tab_bar.dart';
import '../features/widgets/suggest_feature_sheet.dart';

class ComingSoonScreen extends ConsumerStatefulWidget {
  const ComingSoonScreen({super.key});

  @override
  ConsumerState<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends ConsumerState<ComingSoonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Coming Soon',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            tabs: const [
              SegmentedTabItem(label: 'Roadmap'),
              SegmentedTabItem(label: 'Popular Requests'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RoadmapTab(),
                const _PopularRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Roadmap Tab (existing content) ──────────────────────────────────────────

class _RoadmapTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'Features we\'re working on next',
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Social
        _buildSectionLabel('SOCIAL', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          features: [
            _Feature(Icons.person_search_outlined, AppColors.purple, 'Friend Profiles', 'View detailed friend profiles and stats'),
            _Feature(Icons.emoji_events_outlined, AppColors.orange, 'Community Challenges', 'Create and host public fitness challenges'),
            _Feature(Icons.leaderboard_outlined, AppColors.yellow, 'Exercise Leaderboard', 'Compare lifts with friends'),
          ],
        ),

        const SizedBox(height: 24),

        // AI Features
        _buildSectionLabel('AI FEATURES', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          features: [
            _Feature(Icons.smart_toy_outlined, AppColors.purple, 'Custom AI Coach', 'Personalize your coach\'s personality & style'),
            _Feature(Icons.accessibility_new_outlined, AppColors.cyan, 'AI Pose Detection', 'Auto-verify form from progress photos'),
            _Feature(Icons.memory_outlined, AppColors.teal, 'On-Device AI', 'AI coaching without internet'),
          ],
        ),

        const SizedBox(height: 24),

        // Nutrition
        _buildSectionLabel('NUTRITION', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          features: [
            _Feature(Icons.restaurant_outlined, AppColors.purple, 'AI Meal Plans', 'Personalized daily meal plans based on your macros & goals'),
            _Feature(Icons.menu_book_outlined, AppColors.orange, 'AI Recipe Suggestions', 'Get recipe ideas that fit your diet, culture & eating window'),
            _Feature(Icons.store_outlined, AppColors.green, 'Restaurant Chain Menus', 'Request your favorite restaurant chains & foods to be added'),
          ],
        ),

        const SizedBox(height: 24),

        // Training
        _buildSectionLabel('TRAINING', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          features: [
            _Feature(Icons.fitness_center_outlined, AppColors.orange, 'Branded Programs', 'Follow structured training programs'),
            _Feature(Icons.trending_up_outlined, AppColors.limeGreen, 'Skill Progressions', 'Track bodyweight skill mastery'),
            _Feature(Icons.add_circle_outline, AppColors.coral, 'Custom Exercises', 'Create your own exercises'),
            _Feature(Icons.event_outlined, AppColors.magenta, 'Event-Based Training', 'Train for marathons, Hyrox, etc.'),
          ],
        ),

        const SizedBox(height: 24),

        // Analytics
        _buildSectionLabel('ANALYTICS', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          features: [
            _Feature(Icons.show_chart_outlined, AppColors.green, 'Inline Progress Charts', 'Exercise progress in workout view'),
            _Feature(Icons.trending_flat_outlined, AppColors.info, 'Plateau Detection', 'Detect and break through plateaus'),
            _Feature(Icons.science_outlined, AppColors.cyan, 'Exercise Science Insights', 'Evidence-based training recommendations'),
          ],
        ),

        const SizedBox(height: 24),

        // Health
        _buildSectionLabel('HEALTH', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          features: [
            _Feature(Icons.bloodtype_outlined, AppColors.error, 'Diabetes Dashboard', 'Track glucose and insulin levels'),
            _Feature(Icons.directions_walk_outlined, AppColors.green, 'Daily Activity (NEAT)', 'Non-exercise activity tracking'),
            _Feature(Icons.healing_outlined, AppColors.orange, 'Injury Tracker', 'Log and manage active injuries'),
            _Feature(Icons.shield_outlined, AppColors.warning, 'Strain Prevention', 'Prevent overtraining and strain'),
          ],
        ),

        const SizedBox(height: 24),

        // Platform
        _buildSectionLabel('PLATFORM', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          features: [
            _Feature(Icons.cloud_off_outlined, AppColors.teal, 'Offline Mode', 'Train without internet connection'),
            _Feature(Icons.watch_outlined, AppColors.info, 'Wear OS', 'Full smartwatch integration'),
            _Feature(Icons.child_care_outlined, AppColors.green, 'Kids Mode', 'Age-appropriate fitness tracking'),
            _Feature(Icons.location_on_outlined, AppColors.magenta, 'Custom Environments', 'Save training locations with equipment'),
            _Feature(Icons.map_outlined, AppColors.orange, 'Gym Location Map', 'Map-based gym location picker'),
            _Feature(Icons.translate_outlined, AppColors.purple, 'More Languages', 'Additional language support'),
          ],
        ),

        const SizedBox(height: 32),

        // CTA
        Center(
          child: TextButton.icon(
            onPressed: () => context.push('/features'),
            icon: Icon(
              Icons.lightbulb_outline,
              color: AppColors.orange,
              size: 20,
            ),
            label: Text(
              'Have a feature idea? Vote & suggest',
              style: TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFeatureGroup({
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required List<_Feature> features,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < features.length; i++) ...[
            _buildFeatureRow(features[i], textPrimary, textSecondary),
            if (i < features.length - 1)
              Divider(height: 1, indent: 56, color: borderColor),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureRow(_Feature feature, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: feature.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(feature.icon, color: feature.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 15,
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
        ],
      ),
    );
  }
}

// ─── Popular Requests Tab ────────────────────────────────────────────────────

class _PopularRequestsTab extends ConsumerWidget {
  const _PopularRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final featuresAsync = ref.watch(featuresProvider);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return featuresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: textMuted),
              const SizedBox(height: 16),
              Text(
                'Failed to load feature requests',
                style: TextStyle(fontSize: 16, color: textPrimary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(featuresProvider.notifier).refresh(),
                child: Text(
                  'Retry',
                  style: TextStyle(color: AppColors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (features) {
        final voting = features.where((f) => f.isVoting).toList()
          ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

        if (voting.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 56, color: textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No feature requests yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to suggest a feature!',
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showSuggestSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Suggest a Feature'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(featuresProvider.notifier).refresh(),
          color: AppColors.orange,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: voting.length + 1, // +1 for suggest CTA
            itemBuilder: (context, index) {
              if (index == voting.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: () => _showSuggestSheet(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Suggest a Feature'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final feature = voting[index];
              return _buildFeatureCard(
                context,
                ref,
                feature,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    WidgetRef ref,
    FeatureRequest feature, {
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + category badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                ),
                child: Text(
                  feature.categoryDisplayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            feature.description,
            style: TextStyle(fontSize: 14, color: textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Vote row
          Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(featuresProvider.notifier).toggleVote(feature.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: feature.userHasVoted
                        ? AppColors.cyan.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: feature.userHasVoted
                          ? AppColors.cyan
                          : textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        feature.userHasVoted
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 16,
                        color: feature.userHasVoted ? AppColors.cyan : textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${feature.voteCount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: feature.userHasVoted ? AppColors.cyan : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSuggestSheet(BuildContext context) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => const GlassSheet(
        child: SuggestFeatureSheet(),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _Feature(this.icon, this.iconColor, this.title, this.description);
}
