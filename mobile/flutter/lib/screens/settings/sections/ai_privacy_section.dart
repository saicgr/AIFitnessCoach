import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/widgets.dart';

/// SharedPreferences key for AI data processing consent toggle.
const String _kAIProcessingKey = 'ai_data_processing_enabled';

/// The AI Privacy section containing data usage, processing toggle,
/// medical disclaimer, and legal links.
class AIPrivacySection extends StatefulWidget {
  const AIPrivacySection({super.key});

  @override
  State<AIPrivacySection> createState() => _AIPrivacySectionState();
}

class _AIPrivacySectionState extends State<AIPrivacySection> {
  bool _aiProcessingEnabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _aiProcessingEnabled = prefs.getBool(_kAIProcessingKey) ?? true;
        _loaded = true;
      });
    }
  }

  Future<void> _toggleAIProcessing(bool value) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAIProcessingKey, value);
    if (mounted) {
      setState(() {
        _aiProcessingEnabled = value;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'PRIVACY & AI DATA',
          subtitle: 'Control how your data is used',
        ),
        const SizedBox(height: 12),

        // How AI Uses Your Data - navigation tile
        _buildNavigationTile(
          icon: Icons.info_outlined,
          title: 'How AI Uses Your Data',
          subtitle: 'See what data is processed and how',
          color: AppColors.info,
          onTap: () => context.push('/settings/ai-data-usage'),
          textPrimary: textPrimary,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),

        const SizedBox(height: 10),

        // AI Data Processing toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Data Processing',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      _aiProcessingEnabled
                          ? 'AI personalizes your workouts'
                          : 'AI personalization is paused',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_loaded)
                Switch.adaptive(
                  value: _aiProcessingEnabled,
                  onChanged: _toggleAIProcessing,
                  activeColor: AppColors.success,
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Medical Disclaimer - navigation tile
        _buildNavigationTile(
          icon: Icons.medical_information_outlined,
          title: 'Medical Disclaimer',
          subtitle: 'Important health information',
          color: AppColors.warning,
          onTap: () => context.push('/settings/medical-disclaimer'),
          textPrimary: textPrimary,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),

        const SizedBox(height: 10),

        // Privacy Policy & Terms
        _buildNavigationTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          color: textMuted,
          trailing: Icon(Icons.open_in_new, size: 16, color: textMuted),
          onTap: () => _launchUrl('https://fitwiz.app/privacy'),
          textPrimary: textPrimary,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),

        const SizedBox(height: 10),

        _buildNavigationTile(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          subtitle: 'Our terms and conditions',
          color: textMuted,
          trailing: Icon(Icons.open_in_new, size: 16, color: textMuted),
          onTap: () => _launchUrl('https://fitwiz.app/terms'),
          textPrimary: textPrimary,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),
      ],
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
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
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
