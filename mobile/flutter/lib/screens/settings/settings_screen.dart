import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'sections/sections.dart';

/// The main settings screen that composes all settings sections.
///
/// This screen provides access to all app settings including:
/// - Preferences (theme, system settings)
/// - Haptics configuration
/// - Accessibility options
/// - Health sync integration
/// - Notification preferences
/// - Social & Privacy settings
/// - Support links
/// - App info
/// - Data management (import/export)
/// - Danger zone (reset/delete account)
/// - Logout
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

  bool _sectionMatches(String sectionKey) {
    if (_searchQuery.isEmpty) return true;
    return _matchingSections.isEmpty || _matchingSections.contains(sectionKey);
  }

  /// Build AI Coach settings section - navigates to AI settings
  Widget _buildAICoachSection(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: purple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome, color: purple, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Coach',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // AI Coach settings tile
          ListTile(
            leading: Icon(Icons.record_voice_over, color: purple),
            title: Text(
              'Coach Voice & Personality',
              style: TextStyle(color: textPrimary),
            ),
            subtitle: Text(
              'Change your AI coach\'s voice and style',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, color: textMuted),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/ai-settings');
            },
          ),
        ],
      ),
    );
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

  /// Build the "Popular Settings" quick access section
  Widget _buildPopularSettingsSection(BuildContext context, bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              'POPULAR SETTINGS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Frequently used settings for quick adjustments',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        // Quick access grid
        Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              _buildQuickAccessTile(
                context: context,
                icon: Icons.fitness_center,
                title: 'My Equipment',
                subtitle: 'Set available gear',
                color: AppColors.cyan,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to equipment selector or scroll to training section
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Scroll down to Training section'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: elevated,
                    ),
                  );
                },
              ),
              Divider(height: 1, color: cardBorder, indent: 56),
              _buildQuickAccessTile(
                context: context,
                icon: Icons.notifications_outlined,
                title: 'Workout Reminders',
                subtitle: 'Set notification times',
                color: AppColors.orange,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Scroll down to Notifications section'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: elevated,
                    ),
                  );
                },
              ),
              Divider(height: 1, color: cardBorder, indent: 56),
              _buildQuickAccessTile(
                context: context,
                icon: Icons.trending_up,
                title: 'Progression Pace',
                subtitle: 'How fast weights increase',
                color: AppColors.purple,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Scroll down to Training section'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: elevated,
                    ),
                  );
                },
              ),
              Divider(height: 1, color: cardBorder, indent: 56),
              _buildQuickAccessTile(
                context: context,
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                subtitle: 'Light or dark mode',
                color: AppColors.success,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Scroll down to Preferences section'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: elevated,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a quick access tile
  Widget _buildQuickAccessTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Build a section group header with description
  Widget _buildSectionGroupHeader({
    required String title,
    required String description,
    required bool isDark,
  }) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
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
                  // Popular Settings section (only when not searching)
                  if (_searchQuery.isEmpty)
                    _buildPopularSettingsSection(context, isDark)
                        .animate()
                        .fadeIn(delay: 30.ms),

                  if (_searchQuery.isEmpty)
                    const SizedBox(height: 32),

                  // AI Coach section (shown when searching for AI-related terms)
                  if (_sectionMatches('ai_coach'))
                    _buildAICoachSection(context, isDark, textPrimary, textMuted)
                        .animate()
                        .fadeIn(delay: 45.ms),

                  if (_sectionMatches('ai_coach'))
                    const SizedBox(height: 24),

                  // --- APPEARANCE & EXPERIENCE GROUP ---
                  if (_searchQuery.isEmpty || _sectionMatches('preferences') || _sectionMatches('haptics') || _sectionMatches('voice_announcements') || _sectionMatches('audio_settings') || _sectionMatches('app_mode') || _sectionMatches('accessibility'))
                    _buildSectionGroupHeader(
                      title: 'Appearance & Experience',
                      description: 'Customize how the app looks and feels',
                      isDark: isDark,
                    ).animate().fadeIn(delay: 48.ms),

                  // Preferences section
                  if (_sectionMatches('preferences'))
                    const PreferencesSection().animate().fadeIn(delay: 50.ms),

                  if (_sectionMatches('preferences'))
                    const SizedBox(height: 24),

                  // Haptics section
                  if (_sectionMatches('haptics'))
                    const HapticsSection().animate().fadeIn(delay: 55.ms),

                  if (_sectionMatches('haptics'))
                    const SizedBox(height: 24),

                  // Voice Announcements section
                  if (_sectionMatches('voice_announcements'))
                    const VoiceAnnouncementsSection().animate().fadeIn(delay: 56.ms),

                  if (_sectionMatches('voice_announcements'))
                    const SizedBox(height: 24),

                  // Audio Settings section (background music, ducking, volume)
                  if (_sectionMatches('audio_settings'))
                    const AudioSettingsSection().animate().fadeIn(delay: 56.5.ms),

                  if (_sectionMatches('audio_settings'))
                    const SizedBox(height: 24),

                  // App Mode section (Standard, Senior, Kids)
                  if (_sectionMatches('app_mode'))
                    const AppModeSection().animate().fadeIn(delay: 56.ms),

                  if (_sectionMatches('app_mode'))
                    const SizedBox(height: 24),

                  // Accessibility section
                  if (_sectionMatches('accessibility'))
                    const AccessibilitySection().animate().fadeIn(delay: 57.ms),

                  if (_sectionMatches('accessibility'))
                    const SizedBox(height: 32),

                  // --- WORKOUT & TRAINING GROUP ---
                  if (_searchQuery.isEmpty || _sectionMatches('training') || _sectionMatches('warmup_settings') || _sectionMatches('custom_content') || _sectionMatches('calibration'))
                    _buildSectionGroupHeader(
                      title: 'Workout & Training',
                      description: 'Configure how workouts are generated',
                      isDark: isDark,
                    ).animate().fadeIn(delay: 50.ms),

                  // Training Preferences section (progression pace, workout type)
                  if (_sectionMatches('training'))
                    const TrainingPreferencesSection().animate().fadeIn(delay: 51.ms),

                  if (_sectionMatches('training'))
                    const SizedBox(height: 24),

                  // Superset Settings section
                  if (_sectionMatches('superset'))
                    const SupersetSettingsSection().animate().fadeIn(delay: 51.2.ms),

                  if (_sectionMatches('superset'))
                    const SizedBox(height: 24),

                  // Warmup & Cooldown Settings section
                  if (_sectionMatches('warmup_settings'))
                    const WarmupSettingsSection().animate().fadeIn(delay: 51.5.ms),

                  if (_sectionMatches('warmup_settings'))
                    const SizedBox(height: 24),

                  // Calibration section (strength assessment and baselines)
                  if (_sectionMatches('calibration'))
                    const CalibrationSection().animate().fadeIn(delay: 51.8.ms),

                  if (_sectionMatches('calibration'))
                    const SizedBox(height: 24),

                  // My Custom Content section (equipment, exercises, workouts)
                  if (_sectionMatches('custom_content'))
                    const CustomContentSection().animate().fadeIn(delay: 52.ms),

                  if (_sectionMatches('custom_content'))
                    const SizedBox(height: 32),

                  // --- CONNECTIONS & DATA GROUP ---
                  if (_searchQuery.isEmpty || _sectionMatches('health_sync') || _sectionMatches('notifications') || _sectionMatches('email_preferences') || _sectionMatches('social_privacy'))
                    _buildSectionGroupHeader(
                      title: 'Connections & Data',
                      description: 'Manage integrations and privacy',
                      isDark: isDark,
                    ).animate().fadeIn(delay: 58.ms),

                  // Health Connect / Apple Health section
                  if (_sectionMatches('health_sync'))
                    const HealthSyncSection().animate().fadeIn(delay: 60.ms),

                  if (_sectionMatches('health_sync'))
                    const SizedBox(height: 24),

                  // Notifications section
                  if (_sectionMatches('notifications'))
                    const NotificationsSection().animate().fadeIn(delay: 75.ms),

                  if (_sectionMatches('notifications'))
                    const SizedBox(height: 24),

                  // Email Preferences section
                  if (_sectionMatches('email_preferences'))
                    const EmailPreferencesSection().animate().fadeIn(delay: 80.ms),

                  if (_sectionMatches('email_preferences'))
                    const SizedBox(height: 24),

                  // Social & Privacy section
                  if (_sectionMatches('social_privacy'))
                    const SocialPrivacySection().animate().fadeIn(delay: 85.ms),

                  if (_sectionMatches('social_privacy'))
                    const SizedBox(height: 32),

                  // --- ABOUT & SUPPORT GROUP ---
                  if (_searchQuery.isEmpty || _sectionMatches('support') || _sectionMatches('app_tour') || _sectionMatches('app_info'))
                    _buildSectionGroupHeader(
                      title: 'About & Support',
                      description: 'Help, legal info, and app details',
                      isDark: isDark,
                    ).animate().fadeIn(delay: 95.ms),

                  // Support section
                  if (_sectionMatches('support'))
                    const SupportSection().animate().fadeIn(delay: 100.ms),

                  if (_sectionMatches('support'))
                    const SizedBox(height: 24),

                  // App Tour & Demo section
                  if (_sectionMatches('app_tour'))
                    const AppTourSection().animate().fadeIn(delay: 125.ms),

                  if (_sectionMatches('app_tour'))
                    const SizedBox(height: 24),

                  // App Info section
                  if (_sectionMatches('app_info'))
                    const AppInfoSection().animate().fadeIn(delay: 150.ms),

                  if (_sectionMatches('app_info'))
                    const SizedBox(height: 32),

                  // --- SUBSCRIPTION GROUP ---
                  if (_searchQuery.isEmpty || _sectionMatches('subscription'))
                    _buildSectionGroupHeader(
                      title: 'Subscription',
                      description: 'Manage your plan and billing',
                      isDark: isDark,
                    ).animate().fadeIn(delay: 160.ms),

                  // Subscription section
                  if (_sectionMatches('subscription'))
                    const SubscriptionSection().animate().fadeIn(delay: 165.ms),

                  if (_sectionMatches('subscription'))
                    const SizedBox(height: 32),

                  // --- DATA & ACCOUNT GROUP ---
                  if (_searchQuery.isEmpty || _sectionMatches('data_management') || _sectionMatches('danger_zone') || _sectionMatches('logout'))
                    _buildSectionGroupHeader(
                      title: 'Data & Account',
                      description: 'Export data, reset, or delete account',
                      isDark: isDark,
                    ).animate().fadeIn(delay: 170.ms),

                  // Data Management section
                  if (_sectionMatches('data_management'))
                    const DataManagementSection().animate().fadeIn(delay: 175.ms),

                  if (_sectionMatches('data_management'))
                    const SizedBox(height: 24),

                  // Danger Zone section
                  if (_sectionMatches('danger_zone'))
                    const DangerZoneSection().animate().fadeIn(delay: 200.ms),

                  if (_sectionMatches('danger_zone'))
                    const SizedBox(height: 32),

                  // Logout button
                  if (_sectionMatches('logout'))
                    const LogoutSection().animate().fadeIn(delay: 250.ms),

                  if (_sectionMatches('logout'))
                    const SizedBox(height: 16),

                  // Version
                  if (_searchQuery.isEmpty)
                    Text(
                      'FitWiz v1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textMuted,
                          ),
                    ),

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
