import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/main_shell.dart';
import 'sections/sections.dart';
import 'widgets/widgets.dart';

/// Samsung-style grouped settings model
class _SettingsGroup {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<String> sectionKeys;
  final VoidCallback? onTap;

  const _SettingsGroup({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.sectionKeys,
    this.onTap,
  });
}

/// The main settings screen with Samsung-style grouped layout.
///
/// Shows compact grouped cards that expand to show detailed settings.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

/// Semantic search mapping - maps natural language to settings sections
/// Each section has keywords, synonyms, and related phrases that users might search for
const Map<String, List<String>> _settingsSearchIndex = {
  'preferences': [
    // Direct keywords
    'preferences', 'theme', 'appearance', 'dark mode', 'light mode',
    'color', 'colors', 'look', 'style', 'display',
    // Natural language
    'change theme', 'switch theme', 'dark', 'light', 'night mode',
    'how do i change', 'make it dark', 'make it light',
    'background color', 'app color', 'visual', 'looks',
  ],
  'custom_content': [
    // Direct keywords
    'custom', 'content', 'equipment', 'exercises', 'workouts',
    'my equipment', 'my exercises', 'my workouts', 'gym equipment',
    // Natural language
    'add equipment', 'add exercise', 'create workout', 'custom workout',
    'what equipment', 'gym gear', 'fitness equipment', 'machines',
    'dumbbells', 'barbells', 'weights', 'bands', 'resistance',
    'home gym', 'available equipment',
  ],
  'haptics': [
    // Direct keywords
    'haptics', 'vibration', 'feedback', 'haptic', 'vibrate',
    'touch feedback', 'tactile',
    // Natural language
    'turn off vibration', 'disable vibration', 'phone vibrate',
    'feel', 'buzz', 'buzzing', 'shake',
  ],
  'app_mode': [
    // Direct keywords
    'app mode', 'mode', 'standard', 'senior', 'kids', 'elderly',
    'simple mode', 'easy mode', 'child',
    // Natural language
    'change mode', 'make it simpler', 'bigger buttons', 'easier to use',
    'for my parents', 'for children', 'for kids', 'simplified',
    'large text mode', 'accessibility mode',
  ],
  'accessibility': [
    // Direct keywords
    'accessibility', 'font', 'size', 'text', 'readable',
    'font size', 'text size', 'large text', 'small text',
    // Natural language
    'make text bigger', 'make text smaller', 'can\'t read', 'too small',
    'increase font', 'decrease font', 'vision', 'see better',
    'readable', 'legibility', 'screen reader',
  ],
  'health_sync': [
    // Direct keywords
    'health', 'sync', 'connect', 'apple health', 'health connect',
    'google fit', 'fitness tracker', 'wearable',
    // Natural language
    'connect health app', 'sync with apple', 'sync with google',
    'track steps', 'heart rate', 'calories burned', 'activity data',
    'fitbit', 'garmin', 'samsung health',
    'import health data', 'export to health',
  ],
  'wear_os': [
    // Direct keywords
    'wear os', 'wearos', 'watch', 'smartwatch', 'wearable',
    'watch app', 'wear', 'galaxy watch', 'pixel watch',
    // Natural language
    'install watch', 'install on watch', 'connect watch', 'sync watch',
    'watch connection', 'watch status', 'track on watch', 'wrist',
    'workout on watch', 'log from watch',
  ],
  'notifications': [
    // Direct keywords
    'notifications', 'reminders', 'alerts', 'notify', 'push',
    'notification', 'reminder', 'alert',
    // Natural language
    'turn off notifications', 'stop notifications', 'disable alerts',
    'workout reminder', 'remind me', 'daily reminder',
    'don\'t disturb', 'mute', 'silence', 'annoying',
    'push notifications', 'app notifications',
  ],
  'social_privacy': [
    // Direct keywords
    'social', 'privacy', 'sharing', 'friends', 'profile visibility',
    'public', 'private', 'share', 'followers',
    // Natural language
    'who can see', 'hide profile', 'make private', 'share workouts',
    'connect with friends', 'social media', 'post workouts',
    'visible to', 'privacy settings', 'block', 'data privacy',
  ],
  'support': [
    // Direct keywords (now LEGAL section)
    'legal', 'privacy', 'terms', 'policy', 'service',
    'privacy policy', 'terms of service', 'tos',
    // Natural language
    'legal documents', 'read terms', 'read privacy',
    'data policy', 'user agreement', 'legal info',
  ],
  'app_info': [
    // Direct keywords
    'app info', 'info', 'version', 'about', 'app version',
    'update', 'changelog', 'what\'s new',
    // Natural language
    'check version', 'current version', 'app details',
    'terms', 'privacy policy', 'licenses', 'credits',
    'about app', 'about fitwiz',
  ],
  'data_management': [
    // Direct keywords
    'data', 'management', 'export', 'import', 'backup',
    'download', 'restore', 'transfer',
    // Natural language
    'download my data', 'export data', 'backup data', 'restore backup',
    'transfer data', 'move data', 'save data', 'my information',
    'data portability', 'get my data',
  ],
  'danger_zone': [
    // Direct keywords
    'danger', 'zone', 'delete', 'reset', 'account',
    'remove', 'erase', 'clear',
    // Natural language
    'delete account', 'delete my account', 'remove account',
    'reset app', 'start over', 'clear all data', 'erase everything',
    'close account', 'deactivate', 'permanently delete',
  ],
  'logout': [
    // Direct keywords
    'logout', 'log out', 'sign out', 'signout',
    // Natural language
    'exit', 'leave', 'switch account', 'change account',
    'sign off', 'log off',
  ],
  // AI Privacy - data usage, AI processing, medical disclaimer
  'ai_privacy': [
    // Direct keywords
    'ai privacy', 'privacy', 'data usage', 'ai data', 'data processing',
    'medical disclaimer', 'disclaimer', 'anonymized', 'anonymize',
    'personal data', 'data protection',
    // Natural language
    'how ai uses data', 'what data', 'my data', 'data safety',
    'ai sees', 'data collection', 'privacy settings', 'medical',
    'health disclaimer', 'not medical advice',
    'privacy policy', 'terms of service',
  ],
  // AI Coach specific - this is what the user asked about!
  'ai_coach': [
    // Direct keywords
    'ai', 'coach', 'voice', 'ai voice', 'ai coach', 'assistant',
    'personality', 'persona', 'trainer', 'coaching style',
    // Natural language
    'change ai voice', 'modify ai', 'ai settings', 'coach voice',
    'change coach', 'different coach', 'coach personality',
    'ai personality', 'trainer voice', 'virtual coach',
    'chatbot', 'bot voice', 'assistant voice',
  ],
  // Training preferences - progression pace and workout type
  'training': [
    // Direct keywords
    'training', 'progression', 'pace', 'workout type', 'cardio',
    'strength', 'mixed', 'weights', 'weight increase', 'reps',
    // Natural language
    'how fast increase weight', 'slow progression', 'fast progression',
    'dont increase weight', 'keep same weight', 'weight too fast',
    'add cardio', 'cardio workouts', 'strength training',
    'mixed workouts', 'progression speed', 'weight jumps',
  ],
  // Superset settings
  'superset': [
    // Direct keywords
    'superset', 'supersets', 'pair', 'pairs', 'pairing',
    'antagonist', 'compound set', 'back to back', 'circuit',
    // Natural language
    'exercise pairs', 'pair exercises', 'superset exercises',
    'combine exercises', 'exercises together', 'no rest between',
    'chest and back', 'biceps triceps', 'save time', 'faster workouts',
    'add superset', 'create superset', 'favorite pairs',
  ],
  // Voice announcements - TTS during workouts
  'voice_announcements': [
    // Direct keywords
    'voice', 'announcements', 'tts', 'text to speech', 'speak',
    'audio', 'sound', 'speech', 'announce', 'say',
    // Natural language
    'voice coach', 'hear exercise', 'speak exercise names',
    'audio announcements', 'workout voice', 'exercise voice',
    'announce next exercise', 'voice during workout',
    'enable voice', 'turn on voice', 'audio guide',
  ],
  // Audio settings - background music, ducking, volume
  'audio_settings': [
    // Direct keywords
    'audio', 'music', 'background', 'spotify', 'ducking', 'volume',
    'sound', 'tts', 'mute', 'silent', 'quiet',
    // Natural language
    'background music', 'keep music playing', 'spotify playing',
    'audio ducking', 'lower music', 'music volume', 'voice volume',
    'mute during video', 'music settings', 'sound settings',
    'interrupt music', 'pause music', 'stop music',
  ],
  // Warmup and stretch duration settings
  'warmup_settings': [
    // Direct keywords
    'warmup', 'warm up', 'warm-up', 'stretch', 'stretching', 'cooldown',
    'cool down', 'cool-down', 'duration', 'minutes', 'time',
    // Natural language
    'warmup time', 'stretch time', 'warmup duration', 'stretch duration',
    'how long warmup', 'how long stretch', 'warmup length', 'cooldown length',
    'before workout', 'after workout', 'pre workout', 'post workout',
    'longer warmup', 'shorter warmup', 'skip warmup', 'quick warmup',
  ],
  // Subscription management - billing, plans, cancel, pause
  'subscription': [
    // Direct keywords
    'subscription', 'billing', 'payment', 'plan', 'premium', 'upgrade',
    'downgrade', 'cancel', 'pause', 'resume', 'refund', 'price', 'pricing',
    'lifetime', 'monthly', 'yearly', 'annual', 'trial', 'free trial',
    // Natural language
    'cancel subscription', 'pause subscription', 'resume subscription',
    'manage subscription', 'change plan', 'upgrade plan', 'downgrade plan',
    'billing history', 'payment history', 'subscription status',
    'cancel membership', 'pause membership', 'renew subscription',
    'subscription price', 'how much', 'cancel auto renew', 'stop billing',
    'request refund', 'get refund', 'money back',
  ],
  // Email preferences - unsubscribe from emails
  'email_preferences': [
    // Direct keywords
    'email', 'emails', 'unsubscribe', 'subscribe', 'subscription',
    'newsletter', 'marketing', 'promotional', 'inbox', 'mail',
    // Natural language
    'stop emails', 'unsubscribe from emails', 'email preferences',
    'email settings', 'marketing emails', 'promotional emails',
    'too many emails', 'spam', 'mailing list', 'email notifications',
    'weekly email', 'workout email', 'coach email', 'product email',
    'cant unsubscribe', 'find unsubscribe', 'where unsubscribe',
  ],
  // Shop - merchandise and products
  'shop': [
    // Direct keywords
    'shop', 'store', 'merch', 'merchandise', 'apparel', 'gear', 'products',
    'clothing', 'buy', 'purchase', 'order',
    // Natural language
    'buy merchandise', 'get gear', 'fitwiz store', 'fitwiz shop',
    'buy clothes', 'buy apparel', 'fitness gear', 'workout gear',
    't-shirt', 'hoodie', 'tank top', 'shorts', 'accessories',
    'bottle', 'shaker', 'bag', 'bands', 'supplements', 'ebook', 'program',
  ],
  // Nutrition & Fasting - intermittent fasting, eating window, sleep schedule
  'nutrition_fasting': [
    // Direct keywords
    'nutrition', 'fasting', 'intermittent fasting', 'if', 'eating window',
    'fasting protocol', 'eating schedule', 'meal timing', 'time restricted',
    '16:8', '18:6', '12:12', '20:4', 'omad', 'one meal a day',
    // Sleep related
    'sleep', 'sleep schedule', 'wake time', 'wake up', 'bedtime', 'sleep time',
    'circadian', 'rhythm',
    // Natural language
    'when to eat', 'eating hours', 'fasting hours', 'skip breakfast',
    'intermittent', 'time restricted eating', 'eating pattern',
    'fasting window', 'feeding window', 'fast schedule',
    'change wake time', 'change sleep time', 'when i sleep', 'when i wake',
  ],
  'research': [
    'research', 'science', 'exercise science', 'studies', 'papers',
    'evidence', 'peer reviewed', 'citations', 'references',
    'ACSM', 'NSCA', 'Tabata', 'HIIT', 'progressive overload',
    'superset research', 'antagonist', 'periodization', 'RPE',
    'how it works', 'why', 'based on', 'proof', 'methodology',
  ],
  'offline_mode': [
    'offline', 'offline mode', 'download', 'sync', 'no internet',
    'airplane mode', 'on device', 'on-device', 'local ai', 'local model',
    'rule based', 'cache', 'pre-cache', 'background sync',
    'work without internet', 'no wifi', 'no connection', 'offline workouts',
    'download model', 'ai model', 'llm', 'device storage',
    'download videos', 'offline videos', 'sync status',
    'gemma', 'on device ai', 'rule-based', 'cloud ai',
  ],
};

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // Track which sections match the current search
  Set<String> _matchingSections = {};

  // Track which groups are expanded (Samsung-style collapse/expand)
  final Set<String> _expandedGroups = {};

  // Track if search bar is expanded
  bool _isSearchExpanded = false;

  // Samsung-style settings groups - colors are set dynamically in build
  List<_SettingsGroup> _getSettingsGroups(bool isDark) {
    final iconColor = isDark ? AppColors.textSecondary : AppColorsLight.textPrimary;
    final mutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return [
      _SettingsGroup(
        id: 'ai_coach',
        icon: Icons.auto_awesome,
        title: 'AI Coach',
        subtitle: 'Voice, personality, coaching style',
        color: iconColor,
        sectionKeys: ['ai_coach'],
      ),
      _SettingsGroup(
        id: 'ai_privacy',
        icon: Icons.shield_outlined,
        title: 'Privacy & AI Data',
        subtitle: 'Data usage, AI processing, medical disclaimer',
        color: iconColor,
        sectionKeys: ['ai_privacy'],
      ),
      _SettingsGroup(
        id: 'appearance',
        icon: Icons.palette_outlined,
        title: 'Appearance',
        subtitle: 'Theme, haptics, app mode, accessibility',
        color: iconColor,
        sectionKeys: ['preferences', 'haptics', 'app_mode', 'accessibility'],
      ),
      _SettingsGroup(
        id: 'audio',
        icon: Icons.volume_up_outlined,
        title: 'Sound & Voice',
        subtitle: 'Announcements, music, audio settings',
        color: iconColor,
        sectionKeys: ['voice_announcements', 'audio_settings'],
      ),
      _SettingsGroup(
        id: 'workout_settings',
        icon: Icons.speed,
        title: 'Workout Settings',
        subtitle: 'Progression, intensity, splits, schedule',
        color: iconColor,
        sectionKeys: ['training'],
      ),
      _SettingsGroup(
        id: 'research',
        icon: Icons.science_outlined,
        title: 'Research',
        subtitle: 'Peer-reviewed papers behind your workouts',
        color: iconColor,
        sectionKeys: ['research'],
        onTap: () => context.push('/settings/research'),
      ),
      _SettingsGroup(
        id: 'offline_mode',
        icon: Icons.cloud_off_outlined,
        title: 'Offline Mode',
        subtitle: 'Workout generation, downloads, sync',
        color: iconColor,
        sectionKeys: ['offline_mode'],
      ),
      _SettingsGroup(
        id: 'nutrition_fasting',
        icon: Icons.restaurant_outlined,
        title: 'Nutrition & Fasting',
        subtitle: 'Fasting protocol, eating window, sleep',
        color: iconColor,
        sectionKeys: ['nutrition_fasting'],
      ),
      _SettingsGroup(
        id: 'exercise_preferences',
        icon: Icons.favorite_outline,
        title: 'Exercise Preferences',
        subtitle: 'Favorites, avoided, queue',
        color: iconColor,
        sectionKeys: ['training'],
      ),
      _SettingsGroup(
        id: 'equipment',
        icon: Icons.fitness_center,
        title: 'Equipment & Environment',
        subtitle: 'Equipment, warmup, supersets',
        color: iconColor,
        sectionKeys: ['custom_content', 'warmup_settings', 'superset'],
      ),
      _SettingsGroup(
        id: 'notifications',
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Workout reminders, push notifications',
        color: iconColor,
        sectionKeys: ['notifications'],
      ),
      _SettingsGroup(
        id: 'connections',
        icon: Icons.sync_alt,
        title: 'Connections',
        subtitle: 'Health sync, watch, email',
        color: iconColor,
        sectionKeys: ['health_sync', 'wear_os', 'email_preferences'],
      ),
      _SettingsGroup(
        id: 'shop',
        icon: Icons.storefront,
        title: 'Shop',
        subtitle: 'Apparel, gear & digital products',
        color: iconColor,
        sectionKeys: ['shop'],
      ),
      _SettingsGroup(
        id: 'about',
        icon: Icons.info_outline,
        title: 'About & Support',
        subtitle: 'Legal, version info',
        color: mutedColor,
        sectionKeys: ['support', 'app_info'],
      ),
      _SettingsGroup(
        id: 'subscription',
        icon: Icons.workspace_premium,
        title: 'Subscription',
        subtitle: 'Manage your plan and billing',
        color: isDark ? const Color(0xFFFFD700) : const Color(0xFFB8860B),
        sectionKeys: ['subscription'],
      ),
      _SettingsGroup(
        id: 'account',
        icon: Icons.manage_accounts_outlined,
        title: 'Account',
        subtitle: 'Privacy, data export, delete account',
        color: isDark ? AppColors.error : AppColorsLight.error,
        sectionKeys: ['social_privacy', 'data_management', 'danger_zone', 'logout'],
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase().trim();
      _matchingSections = _computeMatchingSections(_searchQuery);
    });
  }

  /// AI-powered semantic search - finds sections that match user intent
  Set<String> _computeMatchingSections(String query) {
    if (query.isEmpty) return {};

    final matches = <String>{};
    final queryWords = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    for (final entry in _settingsSearchIndex.entries) {
      final sectionKey = entry.key;
      final keywords = entry.value;

      // Check if any keyword contains the query or vice versa
      for (final keyword in keywords) {
        final keywordLower = keyword.toLowerCase();

        // Full query match
        if (keywordLower.contains(query) || query.contains(keywordLower)) {
          matches.add(sectionKey);
          break;
        }

        // Word-by-word match (for multi-word queries)
        if (queryWords.length > 1) {
          int matchedWords = 0;
          for (final word in queryWords) {
            if (keywordLower.contains(word) || word.length > 2 && keywords.any((k) => k.toLowerCase().contains(word))) {
              matchedWords++;
            }
          }
          // If most words match, consider it a match
          if (matchedWords >= (queryWords.length * 0.6).ceil()) {
            matches.add(sectionKey);
            break;
          }
        }
      }
    }

    return matches;
  }

  /// Build no results message when search finds nothing
  Widget _buildNoResultsMessage(BuildContext context, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No settings found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords like "theme", "notifications", or "ai voice"',
            style: TextStyle(
              fontSize: 14,
              color: textMuted.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Check if a group matches the current search
  bool _groupMatches(_SettingsGroup group) {
    if (_searchQuery.isEmpty) return true;
    return group.sectionKeys.any((key) => _matchingSections.contains(key));
  }

  /// Build a Samsung-style settings group card
  Widget _buildSettingsGroupCard({
    required _SettingsGroup group,
    required bool isDark,
    required int index,
  }) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final isExpanded = _expandedGroups.contains(group.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? group.color.withValues(alpha: 0.3) : cardBorder,
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Group header (always visible)
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              // Check if group has custom onTap handler
              if (group.onTap != null) {
                group.onTap!();
                return;
              }
              setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(group.id);
                } else {
                  _expandedGroups.add(group.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: group.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      group.icon,
                      color: group.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse indicator
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: textMuted,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildGroupContent(group),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// Build the expanded content for a group
  Widget _buildGroupContent(_SettingsGroup group) {
    switch (group.id) {
      case 'ai_coach':
        return Column(
          children: [
            _buildNavigationTile(
              icon: Icons.record_voice_over,
              title: 'Coach Voice & Personality',
              subtitle: 'Change AI voice and style',
              color: AppColors.purple,
              onTap: () => context.push('/ai-settings'),
            ),
            const SizedBox(height: 12),
            _buildEdgeHandleToggle(),
          ],
        );
      case 'ai_privacy':
        return const AIPrivacySection();
      case 'appearance':
        return const Column(
          children: [
            PreferencesSection(),
            SizedBox(height: 16),
            HapticsSection(),
            SizedBox(height: 16),
            AppModeSection(),
            SizedBox(height: 16),
            AccessibilitySection(),
          ],
        );
      case 'audio':
        return const Column(
          children: [
            VoiceAnnouncementsSection(),
            SizedBox(height: 16),
            AudioSettingsSection(),
          ],
        );
      case 'workout_settings':
        return const _WorkoutSettingsContent();
      case 'offline_mode':
        return const OfflineModeSection();
      case 'nutrition_fasting':
        return const NutritionFastingSection();
      case 'exercise_preferences':
        return const _ExercisePreferencesContent();
      case 'equipment':
        return const Column(
          children: [
            CustomContentSection(),
            SizedBox(height: 16),
            WarmupSettingsSection(),
            SizedBox(height: 16),
            SupersetSettingsSection(),
          ],
        );
      case 'notifications':
        return const NotificationsSection();
      case 'connections':
        return const Column(
          children: [
            HealthSyncSection(),
            SizedBox(height: 16),
            BleHeartRateSection(),
            SizedBox(height: 16),
            WearOSSection(),
            SizedBox(height: 16),
            EmailPreferencesSection(),
          ],
        );
      case 'shop':
        return Column(
          children: [
            _buildNavigationTile(
              icon: Icons.shopping_bag,
              title: 'Visit FitWiz Store',
              subtitle: 'Browse apparel, accessories & more',
              color: AppColors.success,
              onTap: () async {
                // Main Vercel deployment URL
                const storeUrl = 'https://ai-fitness-coach.vercel.app/store';
                final uri = Uri.parse(storeUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        );
      case 'about':
        return const Column(
          children: [
            SupportSection(),
            SizedBox(height: 16),
            AppInfoSection(),
          ],
        );
      case 'subscription':
        return const SubscriptionSection();
      case 'account':
        return const Column(
          children: [
            SocialPrivacySection(),
            SizedBox(height: 16),
            DataManagementSection(),
            SizedBox(height: 16),
            DangerZoneSection(),
            SizedBox(height: 24),
            LogoutSection(),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Build a navigation tile within a group
  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

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
            Icon(icon, color: color, size: 20),
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
            Icon(Icons.chevron_right, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  /// Build the edge handle toggle for AI Coach access
  Widget _buildEdgeHandleToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final isEnabled = ref.watch(edgeHandleEnabledProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.swipe_left,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edge AI Coach Handle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Swipe from edge to open AI Coach',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(edgeHandleEnabledProvider.notifier).setEnabled(value);
            },
            activeColor: AppColors.info,
          ),
        ],
      ),
    );
  }

  /// Build the collapsed search FAB
  Widget _buildSearchFAB(bool isDark) {
    final accentColor = ref.colors(context).accent;

    return GestureDetector(
      key: const ValueKey('search_fab'),
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isSearchExpanded = true;
        });
        // Focus the text field after expansion
        Future.delayed(const Duration(milliseconds: 300), () {
          _searchFocusNode.requestFocus();
        });
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.search,
            color: isDark ? Colors.black : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Build the expanded search bar
  Widget _buildExpandedSearchBar(bool isDark, Color textPrimary, Color textMuted) {
    return ClipRRect(
      key: const ValueKey('search_bar'),
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              // AI sparkle icon
              Icon(
                Icons.auto_awesome,
                color: textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              // Search field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search settings...',
                    hintStyle: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              // Close button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _searchController.clear();
                  _onSearchChanged('');
                  _searchFocusNode.unfocus();
                  setState(() {
                    _isSearchExpanded = false;
                  });
                },
                child: Container(
                  width: 48,
                  height: 56,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close,
                    color: textMuted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.push('/help'),
            child: Text(
              'Help',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 80 + bottomPadding, // Space for floating search bar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Samsung-style grouped settings cards
                  ..._getSettingsGroups(isDark).asMap().entries.map((entry) {
                    final index = entry.key;
                    final group = entry.value;

                    // Filter groups based on search
                    if (!_groupMatches(group)) return const SizedBox.shrink();

                    // Auto-expand matching groups when searching
                    if (_searchQuery.isNotEmpty && !_expandedGroups.contains(group.id)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _groupMatches(group)) {
                          setState(() {
                            _expandedGroups.add(group.id);
                          });
                        }
                      });
                    }

                    return _buildSettingsGroupCard(
                      group: group,
                      isDark: isDark,
                      index: index,
                    ).animate().fadeIn(delay: Duration(milliseconds: 30 + (index * 20)));
                  }),

                  // Version info at bottom
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'FitWiz v1.0.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textMuted,
                            ),
                      ),
                    ),
                  ],

                  // No results message
                  if (_searchQuery.isNotEmpty && _matchingSections.isEmpty)
                    _buildNoResultsMessage(context, textMuted),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Floating search - FAB when collapsed, full bar when expanded
          Positioned(
            left: _isSearchExpanded ? 16 : null,
            right: 16,
            bottom: bottomPadding + 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    alignment: Alignment.centerRight,
                    child: child,
                  ),
                );
              },
              child: _isSearchExpanded
                  ? _buildExpandedSearchBar(isDark, textPrimary, textMuted)
                  : _buildSearchFAB(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Workout Settings Content - Progression, intensity, splits, schedule
/// Split from the original massive TrainingPreferencesSection
class _WorkoutSettingsContent extends StatelessWidget {
  const _WorkoutSettingsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'WORKOUT SETTINGS',
          subtitle: 'Configure progression and scheduling',
        ),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.speed,
              title: 'My 1RMs',
              subtitle: 'View and edit your max lifts',
              isMyOneRMsScreen: true,
            ),
            SettingItemData(
              icon: Icons.percent,
              title: 'Training Intensity',
              subtitle: 'Work at a percentage of your max',
              isTrainingIntensitySelector: true,
            ),
            SettingItemData(
              icon: Icons.trending_up,
              title: 'Progression Pace',
              subtitle: 'How fast to increase weights',
              isProgressionPaceSelector: true,
            ),
            SettingItemData(
              icon: Icons.fitness_center,
              title: 'Workout Type',
              subtitle: 'Strength, cardio, or mixed',
              isWorkoutTypeSelector: true,
            ),
            SettingItemData(
              icon: Icons.view_week,
              title: 'Training Split',
              subtitle: 'Push/Pull/Legs, Full Body, etc.',
              isTrainingSplitSelector: true,
            ),
            SettingItemData(
              icon: Icons.calendar_month,
              title: 'Workout Days',
              subtitle: 'Which days you train',
              isWorkoutDaysSelector: true,
            ),
            SettingItemData(
              icon: Icons.shuffle,
              title: 'Exercise Consistency',
              subtitle: 'Vary or keep same exercises',
              isConsistencyModeSelector: true,
            ),
            SettingItemData(
              icon: Icons.tune,
              title: 'Weekly Variety',
              subtitle: 'How much exercises change each week',
              isVariationSlider: true,
            ),
            SettingItemData(
              icon: Icons.show_chart,
              title: 'Progress Charts',
              subtitle: 'Visualize strength & volume over time',
              isProgressChartsScreen: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// Exercise Preferences Content - Favorites, avoided, queue
/// Split from the original massive TrainingPreferencesSection
class _ExercisePreferencesContent extends StatelessWidget {
  const _ExercisePreferencesContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'EXERCISE PREFERENCES',
          subtitle: 'Customize which exercises appear in workouts',
        ),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.favorite,
              title: 'Favorite Exercises',
              subtitle: 'AI will prioritize these',
              isFavoriteExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.lock,
              title: 'Staple Exercises',
              subtitle: 'Core lifts that never rotate',
              isStapleExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.queue,
              title: 'Exercise Queue',
              subtitle: 'Queue exercises for next workout',
              isExerciseQueueManager: true,
            ),
            SettingItemData(
              icon: Icons.block,
              title: 'Exercises to Avoid',
              subtitle: 'Skip specific exercises',
              isAvoidedExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.accessibility_new,
              title: 'Muscles to Avoid',
              subtitle: 'Skip or reduce muscle groups',
              isAvoidedMusclesManager: true,
            ),
            SettingItemData(
              icon: Icons.history,
              title: 'Import Workout History',
              subtitle: 'Add past workouts for better AI weights',
              isWorkoutHistoryImport: true,
            ),
          ],
        ),
      ],
    );
  }
}
