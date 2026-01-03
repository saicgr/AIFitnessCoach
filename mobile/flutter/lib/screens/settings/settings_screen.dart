import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'sections/sections.dart';

/// Samsung-style grouped settings model
class _SettingsGroup {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<String> sectionKeys;

  const _SettingsGroup({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.sectionKeys,
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
    'google fit', 'fitness tracker', 'watch', 'wearable',
    // Natural language
    'connect health app', 'sync with apple', 'sync with google',
    'track steps', 'heart rate', 'calories burned', 'activity data',
    'smartwatch', 'fitbit', 'garmin', 'samsung health',
    'import health data', 'export to health',
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
  // App Tour & Demo - interactive walkthrough and demo features
  'app_tour': [
    // Direct keywords
    'tour', 'demo', 'guide', 'walkthrough', 'tutorial', 'help', 'learn',
    'app tour', 'demo workout', 'sample', 'preview', 'how to use',
    // Natural language
    'show me around', 'how to use', 'getting started', 'learn the app',
    'restart tour', 'see demo', 'try demo', 'app guide', 'new user guide',
    'what can this app do', 'feature tour', 'app features', 'explore app',
    'sample workout', 'preview plan', 'try before', 'test app',
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
  // Calibration - strength assessment and baselines
  'calibration': [
    // Direct keywords
    'calibration', 'calibrate', 'test', 'assessment', 'baseline', 'baselines',
    'strength test', 'strength assessment', '1rm', 'one rep max', 'max',
    // Natural language
    'test my strength', 'assess my strength', 'calibrate workout',
    'strength baselines', 'weight suggestions', 'how strong am i',
    'recalibrate', 'redo test', 'strength levels', 'fitness test',
    'workout test', 'test workout', 'calibration workout',
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

  // Samsung-style settings groups
  late final List<_SettingsGroup> _settingsGroups = [
    _SettingsGroup(
      id: 'ai_coach',
      icon: Icons.auto_awesome,
      title: 'AI Coach',
      subtitle: 'Voice, personality, coaching style',
      color: AppColors.purple,
      sectionKeys: ['ai_coach'],
    ),
    _SettingsGroup(
      id: 'appearance',
      icon: Icons.palette_outlined,
      title: 'Appearance',
      subtitle: 'Theme, haptics, app mode, accessibility',
      color: AppColors.cyan,
      sectionKeys: ['preferences', 'haptics', 'app_mode', 'accessibility'],
    ),
    _SettingsGroup(
      id: 'audio',
      icon: Icons.volume_up_outlined,
      title: 'Sound & Voice',
      subtitle: 'Announcements, music, audio settings',
      color: AppColors.orange,
      sectionKeys: ['voice_announcements', 'audio_settings'],
    ),
    _SettingsGroup(
      id: 'training',
      icon: Icons.fitness_center,
      title: 'Training',
      subtitle: 'Progression, warmup, calibration, equipment',
      color: AppColors.success,
      sectionKeys: ['training', 'superset', 'warmup_settings', 'calibration', 'custom_content'],
    ),
    _SettingsGroup(
      id: 'connections',
      icon: Icons.sync_alt,
      title: 'Connections',
      subtitle: 'Health sync, notifications, email, privacy',
      color: AppColors.info,
      sectionKeys: ['health_sync', 'notifications', 'email_preferences', 'social_privacy'],
    ),
    _SettingsGroup(
      id: 'about',
      icon: Icons.info_outline,
      title: 'About & Support',
      subtitle: 'Legal, app tour, version info',
      color: AppColors.textMuted,
      sectionKeys: ['support', 'app_tour', 'app_info'],
    ),
    _SettingsGroup(
      id: 'subscription',
      icon: Icons.workspace_premium,
      title: 'Subscription',
      subtitle: 'Manage your plan and billing',
      color: const Color(0xFFFFD700),
      sectionKeys: ['subscription'],
    ),
    _SettingsGroup(
      id: 'account',
      icon: Icons.manage_accounts_outlined,
      title: 'Account',
      subtitle: 'Data export, reset, delete account',
      color: AppColors.error,
      sectionKeys: ['data_management', 'danger_zone', 'logout'],
    ),
  ];

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
          ],
        );
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
      case 'training':
        return const Column(
          children: [
            TrainingPreferencesSection(),
            SizedBox(height: 16),
            SupersetSettingsSection(),
            SizedBox(height: 16),
            WarmupSettingsSection(),
            SizedBox(height: 16),
            CalibrationSection(),
            SizedBox(height: 16),
            CustomContentSection(),
          ],
        );
      case 'connections':
        return const Column(
          children: [
            HealthSyncSection(),
            SizedBox(height: 16),
            NotificationsSection(),
            SizedBox(height: 16),
            EmailPreferencesSection(),
            SizedBox(height: 16),
            SocialPrivacySection(),
          ],
        );
      case 'about':
        return const Column(
          children: [
            SupportSection(),
            SizedBox(height: 16),
            AppTourSection(),
            SizedBox(height: 16),
            AppInfoSection(),
          ],
        );
      case 'subscription':
        return const SubscriptionSection();
      case 'account':
        return const Column(
          children: [
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
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
            child: const Text(
              'Help',
              style: TextStyle(
                color: Color(0xFFFF3B30), // Red color
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
                  ..._settingsGroups.asMap().entries.map((entry) {
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

          // Floating search bar at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.9),
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
                      const SizedBox(width: 12),
                      // AI sparkle icon
                      Icon(
                        Icons.auto_awesome,
                        color: isDark ? AppColors.purple : AppColorsLight.purple,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      // Always-visible search field
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
                            hintText: 'AI Search · try "dark mode", "ai voice"',
                            hintStyle: TextStyle(
                              color: textMuted,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      // Clear button when searching
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _searchController.clear();
                            _onSearchChanged('');
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
                        )
                      else
                        const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
