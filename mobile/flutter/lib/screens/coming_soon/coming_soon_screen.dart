import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_back_button.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

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
      body: ListView(
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
              _Feature(Icons.emoji_events_outlined, AppColors.orange, 'Create Challenges', 'Challenge friends to fitness competitions'),
              _Feature(Icons.person_search_outlined, AppColors.purple, 'Friend Profiles', 'View detailed friend profiles and stats'),
              _Feature(Icons.sports_kabaddi_outlined, AppColors.coral, 'Direct Challenges', 'Challenge someone from the leaderboard'),
            ],
          ),

          const SizedBox(height: 24),

          // Customization
          _buildSectionLabel('CUSTOMIZATION', textMuted),
          _buildFeatureGroup(
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            features: [
              _Feature(Icons.child_care_outlined, AppColors.green, 'Kids Mode', 'Age-appropriate fitness tracking'),
              _Feature(Icons.watch_outlined, AppColors.info, 'Wear OS', 'Full smartwatch integration'),
              _Feature(Icons.location_on_outlined, AppColors.magenta, 'Custom Environments', 'Save training locations with equipment'),
              _Feature(Icons.smart_toy_outlined, AppColors.purple, 'Custom AI Coach', 'Personalize your coach\'s personality'),
              _Feature(Icons.map_outlined, AppColors.teal, 'Gym Location Map', 'Map-based gym location picker'),
              _Feature(Icons.translate_outlined, AppColors.info, 'More Languages', 'Additional language support'),
            ],
          ),

          const SizedBox(height: 24),

          // Library
          _buildSectionLabel('LIBRARY', textMuted),
          _buildFeatureGroup(
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            features: [
              _Feature(Icons.fitness_center_outlined, AppColors.orange, 'Branded Programs', 'Follow structured training programs'),
              _Feature(Icons.trending_up_outlined, AppColors.limeGreen, 'Skill Progressions', 'Track bodyweight skill mastery'),
              _Feature(Icons.add_circle_outline, AppColors.coral, 'Custom Exercises', 'Create your own exercises'),
            ],
          ),

          const SizedBox(height: 24),

          // Analytics & Insights
          _buildSectionLabel('ANALYTICS & INSIGHTS', textMuted),
          _buildFeatureGroup(
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            features: [
              _Feature(Icons.show_chart_outlined, AppColors.green, 'Inline Progress Charts', 'Exercise progress in workout view'),
              _Feature(Icons.leaderboard_outlined, AppColors.yellow, 'Exercise Leaderboard', 'Compare lifts with friends'),
              _Feature(Icons.event_outlined, AppColors.coral, 'Event-Based Workouts', 'Train for marathons, Hyrox, etc.'),
              _Feature(Icons.science_outlined, AppColors.info, 'Exercise Science Research', 'Evidence-based training insights'),
            ],
          ),

          const SizedBox(height: 24),

          // Tech
          _buildSectionLabel('TECH', textMuted),
          _buildFeatureGroup(
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            features: [
              _Feature(Icons.cloud_off_outlined, AppColors.teal, 'Offline Mode', 'Train without internet connection'),
              _Feature(Icons.memory_outlined, AppColors.purple, 'On-Device AI', 'AI coaching without cloud dependency'),
              _Feature(Icons.sync_outlined, AppColors.orange, 'Data Sync', 'Seamless offline-to-cloud sync'),
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

class _Feature {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _Feature(this.icon, this.iconColor, this.title, this.description);
}
