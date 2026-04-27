import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../widgets/pill_app_bar.dart';
import 'package:fitwiz/core/constants/branding.dart';

class ComingSoonScreen extends ConsumerStatefulWidget {
  const ComingSoonScreen({super.key});

  @override
  ConsumerState<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends ConsumerState<ComingSoonScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: 'Coming Soon',
        actions: [
          if (AppLinks.hasFeatureRequestLink)
            PillAppBarAction(
              icon: Icons.lightbulb_outline,
              iconColor: AppColors.orange,
              onTap: () async {
                try {
                  await launchUrl(Uri.parse(AppLinks.featureRequests), mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
            ),
        ],
      ),
      body: _RoadmapTab(),
    );
  }
}

// ─── Roadmap Tab (existing content) ──────────────────────────────────────────

class _RoadmapTab extends StatefulWidget {
  @override
  State<_RoadmapTab> createState() => _RoadmapTabState();
}

class _RoadmapTabState extends State<_RoadmapTab> {
  String _searchQuery = '';

  bool _featureMatches(_Feature feature) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return feature.title.toLowerCase().contains(q) ||
        feature.description.toLowerCase().contains(q);
  }

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
        // Search pill
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          height: 44,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search features...',
                    hintStyle: TextStyle(color: textMuted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _searchQuery = ''),
                  child: Icon(Icons.close, size: 18, color: textMuted),
                ),
            ],
          ),
        ),

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
            _Feature(Icons.tune_outlined, AppColors.purple, 'Per-Exercise RIR Ranges', 'Customize RIR targets for individual exercises — override the default goal/equipment-based calculation', eta: 'Q2 2026'),
          ],
        ),

        const SizedBox(height: 16),

        _buildSectionLabel('SOCIAL', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.people_outline, AppColors.purple, 'Social & Challenges', 'Connect with friends, join challenges, and share progress', eta: 'Q3 2026'),
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
            _Feature(Icons.record_voice_over_outlined, AppColors.cyan, 'AI Coach Workout Audio', 'Real-time voice encouragement, form cues, exercise transitions & PR celebrations during workouts', eta: 'Q3 2026'),
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

        _buildSectionLabel('TRAINER FEATURES', textMuted),
        _buildFeatureGroup(
          cardColor: cardColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          features: [
            _Feature(Icons.battery_charging_full, const Color(0xFF22C55E), 'Recovery Score', 'AI-calculated recovery readiness based on training load', eta: 'Q4 2026'),
            _Feature(Icons.bedtime_outlined, const Color(0xFF6366F1), 'Sleep Trend Analysis', 'Track sleep patterns and their impact on performance', eta: 'Q4 2026'),
            _Feature(Icons.local_fire_department, const Color(0xFFF97316), 'Check-in Streaks', 'Build consistency with daily check-in streaks', eta: 'Q4 2026'),
            _Feature(Icons.schedule, const Color(0xFF06B6D4), 'Smart Notification Timing', 'AI-optimized reminder timing based on your habits', eta: 'Q4 2026'),
            _Feature(Icons.monitor_heart_outlined, const Color(0xFFEF4444), 'Wearable HRV Integration', 'Heart rate variability data from your wearable device', eta: 'Q4 2026'),
            _Feature(Icons.speed, const Color(0xFF8B5CF6), 'Tempo Analysis', 'Track set speed and rep tempo patterns across workouts', eta: 'Q3 2026'),
            _Feature(Icons.show_chart, const Color(0xFF14B8A6), 'Work Capacity Trends', 'Monitor total volume and work capacity over time', eta: 'Q3 2026'),
            _Feature(Icons.compress, const Color(0xFFEC4899), 'Training Density', 'Track more work in less time — the ultimate progress metric', eta: 'Q3 2026'),
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
            _Feature(Icons.star_outline, AppColors.yellow, 'Rate & Review', 'Rate ${Branding.appName} on the App Store & Play Store', eta: 'After Launch'),
            _Feature(Icons.bloodtype_outlined, AppColors.error, 'Diabetes Dashboard', 'Track glucose and insulin levels', eta: '2027'),
            _Feature(Icons.accessibility_new_outlined, AppColors.purple, 'Senior Mode', 'Simplified interface with larger text & easier navigation', eta: '2027'),
            _Feature(Icons.child_care_outlined, AppColors.green, 'Kids Mode', 'Age-appropriate fitness tracking', eta: '2027'),
            _Feature(Icons.location_on_outlined, AppColors.magenta, 'Custom Environments', 'Save training locations with equipment', eta: '2027'),
            _Feature(Icons.map_outlined, AppColors.orange, 'Gym Location Map', 'Map-based gym location picker', eta: '2027'),
            _Feature(Icons.translate_outlined, AppColors.purple, 'More Languages', 'Additional language support', eta: '2027'),
          ],
        ),

        const SizedBox(height: 32),
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
    final filtered = features.where(_featureMatches).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < filtered.length; i++) ...[
            _buildFeatureRow(filtered[i], textPrimary, textSecondary, textMuted),
            if (i < filtered.length - 1)
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

class _Feature {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? eta;

  const _Feature(this.icon, this.iconColor, this.title, this.description, {this.eta});
}
