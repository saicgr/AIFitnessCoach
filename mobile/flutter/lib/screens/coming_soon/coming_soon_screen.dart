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

        // ── Phase 1: Q2 2026 ──
        _buildPhaseHeader('Q2 2026', 'Apr \u2013 Jun', AppColors.green, textPrimary, textMuted),
        const SizedBox(height: 12),

        _buildSectionLabel('PLATFORM', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.watch_outlined, AppColors.info, 'Wear OS & Apple Watch', 'Log workouts, track heart rate & get rest timers from your wrist', eta: 'Q2 2026'),
            _Feature(Icons.web_outlined, AppColors.cyan, 'Web App', 'Plan & review workouts from your browser', eta: 'Q2 2026'),
            _Feature(Icons.cloud_off_outlined, AppColors.teal, 'Offline Mode', 'Train without internet connection', eta: 'Q2 2026'),
          ],
        ),

        const SizedBox(height: 16),

        _buildSectionLabel('NUTRITION', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.timer_outlined, AppColors.teal, 'Intermittent Fasting', 'Track fasting windows, get AI insights & monitor your fasting streaks', eta: 'Q2 2026'),
            _Feature(Icons.restaurant_outlined, AppColors.purple, 'AI Meal Plans', 'Personalized daily meal plans based on your macros & goals', eta: 'Q2 2026'),
            _Feature(Icons.menu_book_outlined, AppColors.orange, 'AI Recipe Suggestions', 'Get recipe ideas that fit your diet, culture & eating window', eta: 'Q2 2026'),
          ],
        ),

        const SizedBox(height: 16),

        _buildSectionLabel('TRAINING', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.add_circle_outline, AppColors.coral, 'Custom Exercises', 'Create your own exercises with custom tracking', eta: 'Q2 2026'),
            _Feature(Icons.show_chart_outlined, AppColors.green, 'Inline Progress Charts', 'Exercise progress graphs inside workout view', eta: 'Q2 2026'),
          ],
        ),

        const SizedBox(height: 32),

        // ── Phase 2: Q3 2026 ──
        _buildPhaseHeader('Q3 2026', 'Jul \u2013 Sep', AppColors.orange, textPrimary, textMuted),
        const SizedBox(height: 12),

        _buildSectionLabel('SOCIAL', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.person_search_outlined, AppColors.purple, 'Friend Profiles', 'View detailed friend profiles and stats', eta: 'Q3 2026'),
            _Feature(Icons.leaderboard_outlined, AppColors.yellow, 'Exercise Leaderboard', 'Compare lifts with friends', eta: 'Q3 2026'),
            _Feature(Icons.emoji_events_outlined, AppColors.orange, 'Community Challenges', 'Create and host public fitness challenges', eta: 'Q3 2026'),
          ],
        ),

        const SizedBox(height: 16),

        _buildSectionLabel('AI FEATURES', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.smart_toy_outlined, AppColors.purple, 'Custom AI Coach', 'Personalize your coach\'s personality & style', eta: 'Q3 2026'),
            _Feature(Icons.memory_outlined, AppColors.teal, 'On-Device AI', 'AI coaching without internet', eta: 'Q3 2026'),
          ],
        ),

        const SizedBox(height: 16),

        _buildSectionLabel('HEALTH', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.healing_outlined, AppColors.orange, 'Injury Tracker', 'Log and manage active injuries', eta: 'Q3 2026'),
            _Feature(Icons.directions_walk_outlined, AppColors.green, 'Daily Activity (NEAT)', 'Non-exercise activity tracking', eta: 'Q3 2026'),
            _Feature(Icons.trending_flat_outlined, AppColors.info, 'Plateau Detection', 'Detect and break through plateaus', eta: 'Q3 2026'),
          ],
        ),

        const SizedBox(height: 32),

        // ── Phase 3: Q4 2026+ ──
        _buildPhaseHeader('Q4 2026+', 'Oct onward', AppColors.purple, textPrimary, textMuted),
        const SizedBox(height: 12),

        _buildSectionLabel('TRAINING', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.fitness_center_outlined, AppColors.orange, 'Branded Programs', 'Follow structured training programs', eta: 'Q4 2026'),
            _Feature(Icons.trending_up_outlined, AppColors.limeGreen, 'Skill Progressions', 'Track bodyweight skill mastery', eta: 'Q4 2026'),
            _Feature(Icons.event_outlined, AppColors.magenta, 'Event-Based Training', 'Train for marathons, Hyrox, etc.', eta: 'Q4 2026'),
            _Feature(Icons.store_outlined, AppColors.green, 'Restaurant Chain Menus', 'Your favorite restaurant chains & foods', eta: 'Q4 2026'),
          ],
        ),

        const SizedBox(height: 16),

        _buildSectionLabel('ADVANCED', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.accessibility_new_outlined, AppColors.cyan, 'AI Pose Detection', 'Auto-verify form from progress photos', eta: 'Q4 2026'),
            _Feature(Icons.science_outlined, AppColors.cyan, 'Exercise Science Insights', 'Evidence-based training recommendations', eta: 'Q4 2026'),
            _Feature(Icons.shield_outlined, AppColors.warning, 'Strain Prevention', 'Prevent overtraining and strain', eta: 'Q4 2026'),
          ],
        ),

        const SizedBox(height: 16),

        _buildSectionLabel('FUTURE', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.star_outline, AppColors.yellow, 'Rate & Review', 'Rate FitWiz on the App Store & Play Store', eta: 'After Launch'),
            _Feature(Icons.bloodtype_outlined, AppColors.error, 'Diabetes Dashboard', 'Track glucose and insulin levels', eta: '2027'),
            _Feature(Icons.accessibility_new_outlined, AppColors.purple, 'Senior Mode', 'Simplified interface with larger text & easier navigation', eta: '2027'),
            _Feature(Icons.child_care_outlined, AppColors.green, 'Kids Mode', 'Age-appropriate fitness tracking', eta: '2027'),
            _Feature(Icons.location_on_outlined, AppColors.magenta, 'Custom Environments', 'Save training locations with equipment', eta: '2027'),
            _Feature(Icons.map_outlined, AppColors.orange, 'Gym Location Map', 'Map-based gym location picker', eta: '2027'),
            _Feature(Icons.translate_outlined, AppColors.purple, 'More Languages', 'Additional language support', eta: '2027'),
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

  Widget _buildPhaseHeader(String phase, String dateRange, Color accentColor, Color textPrimary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            phase,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            dateRange,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
            ),
          ),
        ],
      ),
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
    required Color textMuted,
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
            _buildFeatureRow(features[i], textPrimary, textSecondary, textMuted),
            if (i < features.length - 1)
              Divider(height: 1, indent: 56, color: borderColor),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureRow(_Feature feature, Color textPrimary, Color textSecondary, Color textMuted) {
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        feature.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (feature.eta != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: feature.iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          feature.eta!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: feature.iconColor,
                          ),
                        ),
                      ),
                    ],
                  ],
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
  final String? eta;

  const _Feature(this.icon, this.iconColor, this.title, this.description, {this.eta});
}
