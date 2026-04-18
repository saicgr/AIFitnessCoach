import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/providers/training_preferences_provider.dart';
import '../../data/providers/billing_reminder_provider.dart';
import '../../data/providers/gym_profile_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/providers/beast_mode_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_tour/app_tour_controller.dart';
import '../../widgets/level_up_dialog.dart';
import '../../data/models/user.dart' as app_user;
import '../../data/models/user_xp.dart';
import 'beast_mode_unlock_dialog.dart';
import 'coming_soon_screen.dart';
import 'meal_reminders_settings_screen.dart';
import '../../core/services/posthog_service.dart';
import 'sections/sections.dart';
import 'widgets/widgets.dart';

part 'settings_screen_part_social_icon.dart';

part 'settings_screen_ui.dart';

part 'settings_screen_ext.dart';


/// The main settings screen with iOS Settings-style sub-page navigation.
///
/// Shows a flat list of grouped rows that push to dedicated sub-pages.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

/// Semantic search mapping - maps natural language to settings sections
/// Each section has keywords, synonyms, and related phrases that users might search for
const Map<String, List<String>> _settingsSearchIndex = {
  'preferences': [
    'preferences', 'theme', 'appearance', 'dark mode', 'light mode',
    'color', 'colors', 'look', 'style', 'display',
    'change theme', 'switch theme', 'dark', 'light', 'night mode',
    'how do i change', 'make it dark', 'make it light',
    'background color', 'app color', 'visual', 'looks',
  ],
  'custom_content': [
    'custom', 'content', 'equipment', 'exercises', 'workouts',
    'my equipment', 'my exercises', 'my workouts', 'gym equipment',
    'add equipment', 'add exercise', 'create workout', 'custom workout',
    'what equipment', 'gym gear', 'fitness equipment', 'machines',
    'dumbbells', 'barbells', 'weights', 'bands', 'resistance',
    'home gym', 'available equipment',
  ],
  'haptics': [
    'haptics', 'vibration', 'feedback', 'haptic', 'vibrate',
    'touch feedback', 'tactile',
    'turn off vibration', 'disable vibration', 'phone vibrate',
    'feel', 'buzz', 'buzzing', 'shake',
  ],
  'app_mode': [
    'app mode', 'mode', 'standard', 'senior', 'kids', 'elderly',
    'simple mode', 'easy mode', 'child',
    'change mode', 'make it simpler', 'bigger buttons', 'easier to use',
    'for my parents', 'for children', 'for kids', 'simplified',
    'large text mode', 'accessibility mode',
  ],
  'accessibility': [
    'accessibility', 'font', 'size', 'text', 'readable',
    'font size', 'text size', 'large text', 'small text',
    'make text bigger', 'make text smaller', 'can\'t read', 'too small',
    'increase font', 'decrease font', 'vision', 'see better',
    'readable', 'legibility', 'screen reader',
  ],
  'health_sync': [
    'health', 'sync', 'connect', 'apple health', 'health connect',
    'google fit', 'fitness tracker', 'wearable',
    'connect health app', 'sync with apple', 'sync with google',
    'track steps', 'heart rate', 'calories burned', 'activity data',
    'fitbit', 'garmin', 'samsung health',
    'import health data', 'export to health',
  ],
  'wear_os': [
    'wear os', 'wearos', 'watch', 'smartwatch', 'wearable',
    'watch app', 'wear', 'galaxy watch', 'pixel watch',
    'install watch', 'install on watch', 'connect watch', 'sync watch',
    'watch connection', 'watch status', 'track on watch', 'wrist',
    'workout on watch', 'log from watch',
  ],
  'coming_soon': [
    'coming soon', 'upcoming', 'new features', 'planned', 'roadmap',
    'future', 'widgets', 'home widgets', 'new widgets',
  ],
  'notifications': [
    'notifications', 'reminders', 'alerts', 'notify', 'push',
    'notification', 'reminder', 'alert',
    'turn off notifications', 'stop notifications', 'disable alerts',
    'workout reminder', 'remind me', 'daily reminder',
    'don\'t disturb', 'mute', 'silence', 'annoying',
    'push notifications', 'app notifications',
  ],
  'social_privacy': [
    'social', 'privacy', 'sharing', 'friends', 'profile visibility',
    'public', 'private', 'share', 'followers',
    'who can see', 'hide profile', 'make private', 'share workouts',
    'connect with friends', 'social media', 'post workouts',
    'visible to', 'privacy settings', 'block', 'data privacy',
  ],
  'help_center': [
    'help', 'support', 'help center', 'customer support',
    'get help', 'need help', 'assistance', 'faq',
    'how to', 'guide', 'tutorial', 'support center',
    'ticket', 'tickets', 'support ticket',
  ],
  'report_issue': [
    'report', 'issue', 'bug', 'problem', 'bug report',
    'report bug', 'report issue', 'something broke', 'broken',
    'not working', 'crash', 'error', 'glitch',
  ],
  'about_app': [
    'about', 'app info', 'info', 'version', 'app version',
    'update', 'changelog', 'what\'s new',
    'check version', 'current version', 'app details',
    'licenses', 'credits', 'about app', 'about fitwiz',
  ],
  'privacy_policy': [
    'privacy', 'privacy policy', 'data policy',
    'how we handle data', 'data protection', 'personal data',
  ],
  'terms_of_service': [
    'terms', 'terms of service', 'tos', 'legal',
    'legal documents', 'user agreement', 'legal info',
  ],
  'rate_app': [
    'rate', 'rate app', 'review', 'star', 'stars',
    'app store review', 'play store review', 'feedback',
    'leave review', 'rate us',
  ],
  'support': [
    'legal', 'privacy', 'terms', 'policy', 'service',
    'privacy policy', 'terms of service', 'tos',
    'legal documents', 'read terms', 'read privacy',
    'data policy', 'user agreement', 'legal info',
  ],
  'app_info': [
    'app info', 'info', 'version', 'about', 'app version',
    'update', 'changelog', 'what\'s new',
    'check version', 'current version', 'app details',
    'terms', 'privacy policy', 'licenses', 'credits',
    'about app', 'about fitwiz',
  ],
  'data_management': [
    'data', 'management', 'export', 'import', 'backup',
    'download', 'restore', 'transfer',
    'download my data', 'export data', 'backup data', 'restore backup',
    'transfer data', 'move data', 'save data', 'my information',
    'data portability', 'get my data',
  ],
  'danger_zone': [
    'danger', 'zone', 'delete', 'reset', 'account',
    'remove', 'erase', 'clear',
    'delete account', 'delete my account', 'remove account',
    'reset app', 'start over', 'clear all data', 'erase everything',
    'close account', 'deactivate', 'permanently delete',
  ],
  'logout': [
    'logout', 'log out', 'sign out', 'signout',
    'exit', 'leave', 'switch account', 'change account',
    'sign off', 'log off',
  ],
  'ai_privacy': [
    'ai privacy', 'privacy', 'data usage', 'ai data', 'data processing',
    'medical disclaimer', 'disclaimer', 'anonymized', 'anonymize',
    'personal data', 'data protection',
    'how ai uses data', 'what data', 'my data', 'data safety',
    'ai sees', 'data collection', 'privacy settings', 'medical',
    'health disclaimer', 'not medical advice',
    'privacy policy', 'terms of service',
  ],
  'ai_coach': [
    'ai', 'coach', 'voice', 'ai voice', 'ai coach', 'assistant',
    'personality', 'persona', 'trainer', 'coaching style',
    'change ai voice', 'modify ai', 'ai settings', 'coach voice',
    'change coach', 'different coach', 'coach personality',
    'ai personality', 'trainer voice', 'virtual coach',
    'chatbot', 'bot voice', 'assistant voice',
  ],
  'training': [
    'training', 'progression', 'pace', 'workout type', 'cardio',
    'strength', 'mixed', 'weights', 'weight increase', 'reps',
    'how fast increase weight', 'slow progression', 'fast progression',
    'dont increase weight', 'keep same weight', 'weight too fast',
    'add cardio', 'cardio workouts', 'strength training',
    'mixed workouts', 'progression speed', 'weight jumps',
    'week start', 'monday', 'sunday', 'calendar', 'first day',
    'week starts on', 'start of week',
  ],
  'superset': [
    'superset', 'supersets', 'pair', 'pairs', 'pairing',
    'antagonist', 'compound set', 'back to back', 'circuit',
    'exercise pairs', 'pair exercises', 'superset exercises',
    'combine exercises', 'exercises together', 'no rest between',
    'chest and back', 'biceps triceps', 'save time', 'faster workouts',
    'add superset', 'create superset', 'favorite pairs',
  ],
  'voice_announcements': [
    'voice', 'announcements', 'tts', 'text to speech', 'speak',
    'audio', 'sound', 'speech', 'announce', 'say',
    'voice coach', 'hear exercise', 'speak exercise names',
    'audio announcements', 'workout voice', 'exercise voice',
    'announce next exercise', 'voice during workout',
    'enable voice', 'turn on voice', 'audio guide',
  ],
  'audio_settings': [
    'audio', 'music', 'background', 'spotify', 'ducking', 'volume',
    'sound', 'tts', 'mute', 'silent', 'quiet',
    'background music', 'keep music playing', 'spotify playing',
    'audio ducking', 'lower music', 'music volume', 'voice volume',
    'mute during video', 'music settings', 'sound settings',
    'interrupt music', 'pause music', 'stop music',
  ],
  'warmup_settings': [
    'warmup', 'warm up', 'warm-up', 'stretch', 'stretching', 'cooldown',
    'cool down', 'cool-down', 'duration', 'minutes', 'time',
    'warmup time', 'stretch time', 'warmup duration', 'stretch duration',
    'how long warmup', 'how long stretch', 'warmup length', 'cooldown length',
    'before workout', 'after workout', 'pre workout', 'post workout',
    'longer warmup', 'shorter warmup', 'skip warmup', 'quick warmup',
  ],
  'subscription': [
    'subscription', 'billing', 'payment', 'plan', 'premium', 'upgrade',
    'downgrade', 'cancel', 'pause', 'resume', 'refund', 'price', 'pricing',
    'lifetime', 'monthly', 'yearly', 'annual', 'trial', 'free trial',
    'cancel subscription', 'pause subscription', 'resume subscription',
    'manage subscription', 'change plan', 'upgrade plan', 'downgrade plan',
    'billing history', 'payment history', 'subscription status',
    'cancel membership', 'pause membership', 'renew subscription',
    'subscription price', 'how much', 'cancel auto renew', 'stop billing',
    'request refund', 'get refund', 'money back',
  ],
  'email_preferences': [
    'email', 'emails', 'unsubscribe', 'subscribe', 'subscription',
    'newsletter', 'marketing', 'promotional', 'inbox', 'mail',
    'stop emails', 'unsubscribe from emails', 'email preferences',
    'email settings', 'marketing emails', 'promotional emails',
    'too many emails', 'spam', 'mailing list', 'email notifications',
    'weekly email', 'workout email', 'coach email', 'product email',
    'cant unsubscribe', 'find unsubscribe', 'where unsubscribe',
  ],
  'shop': [
    'shop', 'store', 'merch', 'merchandise', 'apparel', 'gear', 'products',
    'clothing', 'buy', 'purchase', 'order',
    'buy merchandise', 'get gear', 'fitwiz store', 'fitwiz shop',
    'buy clothes', 'buy apparel', 'fitness gear', 'workout gear',
    't-shirt', 'hoodie', 'tank top', 'shorts', 'accessories',
    'bottle', 'shaker', 'bag', 'bands', 'supplements', 'ebook', 'program',
  ],
  'nutrition_fasting': [
    'nutrition', 'fasting', 'intermittent fasting', 'if', 'eating window',
    'fasting protocol', 'eating schedule', 'meal timing', 'time restricted',
    '16:8', '18:6', '12:12', '20:4', 'omad', 'one meal a day',
    'sleep', 'sleep schedule', 'wake time', 'wake up', 'bedtime', 'sleep time',
    'circadian', 'rhythm',
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
  'beast_mode': [
    'beast', 'beast mode', 'power user', 'debug', 'developer',
    'advanced', 'diagnostics', 'algorithm', 'hidden', 'secret', 'easter egg',
  ],
};

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Set<String> _matchingSections = {};
  bool _isSearchExpanded = false;

  // Beast Mode easter egg
  int _versionTapCount = 0;
  DateTime? _lastVersionTap;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'settings_viewed');
    });
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

  // --- Helper: vacation mode subtitle ---
  /// Returns "On (until Apr 25)", "Scheduled Apr 20", "On (open-ended)", or "Off".
  String _vacationModeDisplay(app_user.User? user) {
    if (user == null || user.inVacationMode != true) return 'Off';
    DateTime? start;
    DateTime? end;
    try {
      if (user.vacationStartDate != null && user.vacationStartDate!.isNotEmpty) {
        start = DateTime.parse(user.vacationStartDate!);
      }
      if (user.vacationEndDate != null && user.vacationEndDate!.isNotEmpty) {
        end = DateTime.parse(user.vacationEndDate!);
      }
    } catch (_) {
      // Malformed date — fall through
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (start != null && today.isBefore(start)) {
      return 'Scheduled ${_shortDate(start)}';
    }
    if (end != null) {
      if (today.isAfter(end)) return 'Ended ${_shortDate(end)}';
      return 'On · until ${_shortDate(end)}';
    }
    return 'On · open-ended';
  }

  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _shortDate(DateTime d) => '${_monthsShort[d.month - 1]} ${d.day}';

  // --- Helper: split display name ---
  String _splitDisplayName(String split) {
    switch (split) {
      case 'push_pull_legs':
        return 'PPL';
      case 'upper_lower':
        return 'Upper/Lower';
      case 'full_body':
        return 'Full Body';
      case 'bro_split':
        return 'Bro Split';
      case 'dont_know':
        return 'Auto';
      case 'ai_decide':
        return 'AI Decide';
      default:
        return split.replaceAll('_', ' ');
    }
  }

  void _launchExternalUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _unlockBeastMode() {
    ref.read(beastModeProvider.notifier).unlock();
    showBeastModeUnlockDialog(context, () {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final authState = ref.watch(authStateProvider);
    final trainingPrefs = ref.watch(trainingPreferencesProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Gym profile name
    final gymProfile = ref.watch(activeGymProfileProvider);
    final gymProfileName = gymProfile?.name ?? 'Default';

    // Subscription value
    final renewalAsync = ref.watch(upcomingRenewalProvider);
    final subscriptionValue = renewalAsync.when(
      data: (r) => r.hasUpcomingRenewal ? (r.tier ?? 'Active') : 'Free',
      loading: () => 'Loading...',
      error: (_, __) => 'Manage',
    );

    // Training split + days display
    final splitName = _splitDisplayName(trainingPrefs.trainingSplit);
    final daysPerWeek = authState.user?.workoutsPerWeek ?? 4;

    // Vacation mode subtitle — shows scheduled range, active state, or Off.
    final vacationModeValue = _vacationModeDisplay(authState.user);

    // Build sections
    final sections = [
      _SettingsSection(
        label: 'TRAINING',
        rows: [
          _SettingsRow(
            icon: Icons.speed,
            iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
            title: 'Workout Settings',
            value: '$splitName \u00B7 $daysPerWeek days',
            route: '/settings/workout-settings',
            sectionKeys: const ['training'],
          ),
          _SettingsRow(
            icon: Icons.fitness_center,
            iconColor: isDark ? AppColors.purple : AppColorsLight.purple,
            title: 'Exercise Prefs',
            value: 'Favorites, avoided & queue',
            route: '/settings/my-exercises',
            sectionKeys: const ['custom_content'],
          ),
          _SettingsRow(
            icon: Icons.trending_up,
            iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
            title: 'Training Methods',
            value: 'Set progression & research',
            route: '/settings/training-methods',
            sectionKeys: const ['training'],
          ),
          _SettingsRow(
            icon: Icons.fitness_center,
            iconColor: isDark ? AppColors.success : AppColorsLight.success,
            title: 'Equipment',
            value: gymProfileName,
            route: '/settings/equipment',
            sectionKeys: const ['custom_content', 'warmup_settings', 'superset'],
          ),
        ],
      ),
      _SettingsSection(
        label: 'PERSONALIZATION',
        rows: [
          _SettingsRow(
            icon: Icons.auto_awesome,
            iconColor: isDark ? AppColors.purple : AppColorsLight.purple,
            title: 'AI Coach',
            value: 'Voice & personality',
            route: '/settings/ai-coach',
            sectionKeys: const ['ai_coach', 'ai_privacy'],
          ),
          // ── AI Integrations (MCP) — HIDDEN for v1.0 Play Store submission ──
          // The MCP server, OAuth flow, PAT endpoints, and the AiIntegrationsScreen
          // itself are all live and functional — only this navigation entry is
          // commented out so reviewers don't trip on the yearly-only paywall or
          // the unfamiliar third-party connection concept during launch review.
          //
          // To re-enable in v1.1: uncomment this block. The screen is still
          // registered at the route '/settings/ai-integrations' (see
          // app_router_settings_routes.dart) and reachable via deep link for
          // beta testing.
          // _SettingsRow(
          //   icon: Icons.hub_outlined,
          //   iconColor: isDark ? AppColors.info : AppColorsLight.info,
          //   title: 'AI Integrations',
          //   value: 'Claude, ChatGPT, Cursor',
          //   route: '/settings/ai-integrations',
          //   sectionKeys: const ['ai_integrations', 'mcp', 'claude', 'chatgpt', 'cursor'],
          // ),
          _SettingsRow(
            icon: Icons.palette_outlined,
            iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
            title: 'Appearance',
            route: '/settings/appearance',
            sectionKeys: const ['preferences', 'haptics', 'app_mode', 'accessibility'],
            isThemeRow: true,
          ),
          _SettingsRow(
            icon: Icons.notifications_outlined,
            iconColor: isDark ? AppColors.info : AppColorsLight.info,
            title: 'Sound & Notifs',
            value: 'Voice, audio, reminders',
            route: '/settings/sound-notifications',
            sectionKeys: const ['voice_announcements', 'audio_settings', 'notifications'],
          ),
          _SettingsRow(
            icon: Icons.beach_access_rounded,
            iconColor: const Color(0xFF4FC3F7),
            title: 'Vacation Mode',
            value: vacationModeValue,
            route: '/settings/vacation-mode',
            sectionKeys: const ['vacation', 'pause', 'notifications', 'comeback', 'away'],
          ),
          _SettingsRow(
            icon: Icons.alarm_rounded,
            iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
            title: 'Meal Reminders',
            value: 'Recipe schedules + sharing + versioning',
            sectionKeys: const [
              'meal_reminders', 'recipe_schedules', 'recipe_sharing', 'recipe_versions',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MealRemindersSettingsScreen(isDark: isDark)),
            ),
          ),
          _SettingsRow(
            icon: Icons.rocket_launch_rounded,
            iconColor: isDark ? AppColors.purple : AppColorsLight.purple,
            title: 'Coming Soon',
            value: '24 upcoming features',
            sectionKeys: const ['coming_soon', 'upcoming', 'new_features'],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
            ),
          ),
        ],
      ),
      _SettingsSection(
        label: 'CONNECTIONS',
        rows: [
          _SettingsRow(
            icon: Icons.favorite_outline,
            iconColor: isDark ? AppColors.error : AppColorsLight.error,
            title: 'Health & Devices',
            value: Platform.isIOS ? 'Apple Health' : 'Health Connect',
            route: '/settings/health-devices',
            sectionKeys: const ['nutrition_fasting', 'health_sync', 'wear_os'],
          ),
        ],
      ),
      _SettingsSection(
        label: 'ACCOUNT',
        rows: [
          _SettingsRow(
            icon: Icons.diamond_outlined,
            iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
            title: 'Subscription',
            value: subscriptionValue,
            route: '/subscription-management',
            sectionKeys: const ['subscription'],
          ),
          _SettingsRow(
            icon: Icons.lock_outline,
            iconColor: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            title: 'Privacy & Data',
            value: 'Sharing, export, email',
            route: '/settings/privacy-data',
            sectionKeys: const ['social_privacy', 'email_preferences', 'data_management'],
          ),
        ],
      ),
      _SettingsSection(
        label: 'HELP & SUPPORT',
        rows: [
          _SettingsRow(
            icon: Icons.email_outlined,
            iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
            title: 'Contact Support',
            value: AppLinks.supportEmail,
            sectionKeys: const ['help_center', 'report_issue', 'support'],
            onTap: () => _launchExternalUrl('mailto:${AppLinks.supportEmail}?subject=FitWiz Support Request'),
          ),
          _SettingsRow(
            icon: Icons.play_circle_outline_rounded,
            iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
            title: 'Replay Tutorials',
            value: 'Choose which tour to replay',
            sectionKeys: const ['tutorial', 'help_center'],
            onTap: () => _showReplayTutorialsSheet(context, ref, isDark),
          ),
        ],
      ),
      _SettingsSection(
        label: 'ABOUT',
        rows: [
          _SettingsRow(
            icon: Icons.info_outline,
            iconColor: textMuted,
            title: 'About FitWiz',
            sectionKeys: const ['about_app'],
            onTap: () => _showAboutDialog(context),
          ),
          _SettingsRow(
            icon: Icons.science_outlined,
            iconColor: isDark ? AppColors.info : AppColorsLight.info,
            title: 'Research & Science',
            route: '/settings/research',
            sectionKeys: const ['research'],
          ),
          _SettingsRow(
            icon: Icons.privacy_tip_outlined,
            iconColor: textMuted,
            title: 'Privacy Policy',
            sectionKeys: const ['privacy_policy', 'support'],
            onTap: () => _launchExternalUrl(AppLinks.privacyPolicy),
          ),
          _SettingsRow(
            icon: Icons.description_outlined,
            iconColor: textMuted,
            title: 'Terms of Service',
            sectionKeys: const ['terms_of_service', 'support'],
            onTap: () => _launchExternalUrl(AppLinks.termsOfService),
          ),
          _SettingsRow(
            icon: Icons.star_outline,
            iconColor: isDark ? AppColors.warning : AppColorsLight.warning,
            title: 'Rate App',
            sectionKeys: const ['rate_app'],
            onTap: () => _launchExternalUrl(
              Platform.isIOS
                  ? (AppLinks.appStore.isNotEmpty ? AppLinks.appStore : 'https://apps.apple.com/app/fitwiz')
                  : AppLinks.playStore,
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 72,
                bottom: 80 + bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grouped sections
                  for (final section in sections) ...[
                    // Check if any row in this section matches search
                    if (_searchQuery.isEmpty ||
                        section.rows.any((r) => r.sectionKeys.any((k) => _matchingSections.contains(k)))) ...[
                      _buildSectionLabel(section.label, textMuted),
                      const SizedBox(height: 8),
                      _buildGroupCard(
                        section.rows,
                        isDark,
                        elevated,
                        cardBorder,
                        textPrimary,
                        textMuted,
                        themeMode,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],

                  // ── Debug: Test Level-Up Dialog ──
                  // Developer-only test harness for the level-up celebration
                  // dialog. Hidden from end users; re-enable by flipping the
                  // guard back to `if (true)` (or wire to a debug build flag).
                  // ignore: dead_code
                  if (false) ...[
                    _buildSectionLabel('Developer', textMuted),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.military_tech_rounded, color: Colors.amber),
                            title: Text('Test Level-Up (Level 2→3)', style: TextStyle(color: textPrimary, fontSize: 14)),
                            subtitle: Text('Single level, with crate reward', style: TextStyle(color: textMuted, fontSize: 12)),
                            trailing: Icon(Icons.play_arrow_rounded, color: Colors.green),
                            onTap: () {
                              showLevelUpDialog(
                                context,
                                const LevelUpEvent(
                                  newLevel: 3,
                                  oldLevel: 2,
                                  totalXp: 95,
                                  xpEarned: 40,
                                ),
                                () {},
                                showProgression: false,
                              );
                            },
                          ),
                          Divider(height: 1, color: cardBorder),
                          ListTile(
                            leading: Icon(Icons.stars_rounded, color: Colors.purple),
                            title: Text('Test Level-Up (Level 10→11)', style: TextStyle(color: textPrimary, fontSize: 14)),
                            subtitle: Text('Title change: Beginner → Novice', style: TextStyle(color: textMuted, fontSize: 12)),
                            trailing: Icon(Icons.play_arrow_rounded, color: Colors.green),
                            onTap: () {
                              showLevelUpDialog(
                                context,
                                const LevelUpEvent(
                                  newLevel: 11,
                                  oldLevel: 10,
                                  newTitle: 'Novice',
                                  oldTitle: 'Beginner',
                                  totalXp: 960,
                                  xpEarned: 180,
                                ),
                                () {},
                                showProgression: false,
                              );
                            },
                          ),
                          Divider(height: 1, color: cardBorder),
                          ListTile(
                            leading: Icon(Icons.rocket_launch_rounded, color: Colors.orange),
                            title: Text('Test Multi-Level (1→5)', style: TextStyle(color: textPrimary, fontSize: 14)),
                            subtitle: Text('With cascade overlay + dialog', style: TextStyle(color: textMuted, fontSize: 12)),
                            trailing: Icon(Icons.play_arrow_rounded, color: Colors.green),
                            onTap: () {
                              showLevelUpDialog(
                                context,
                                const LevelUpEvent(
                                  newLevel: 5,
                                  oldLevel: 1,
                                  totalXp: 210,
                                  xpEarned: 210,
                                ),
                                () {},
                                showProgression: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Beast Mode row (only visible when unlocked)
                  if (ref.watch(beastModeProvider) &&
                      (_searchQuery.isEmpty ||
                          _matchingSections.contains('beast_mode'))) ...[
                    _buildGroupCard(
                      [
                        _SettingsRow(
                          icon: Icons.local_fire_department,
                          iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
                          title: 'Beast Mode',
                          value: 'Power user tools',
                          route: '/settings/beast-mode',
                          sectionKeys: const ['beast_mode'],
                        ),
                      ],
                      isDark,
                      elevated,
                      cardBorder,
                      textPrimary,
                      textMuted,
                      themeMode,
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Social Media Icons
                  if (_searchQuery.isEmpty) ...[
                    _buildSocialRow(isDark),
                    const SizedBox(height: 24),
                  ],

                  // Sign Out
                  if (_searchQuery.isEmpty ||
                      _matchingSections.contains('logout') ||
                      _matchingSections.contains('danger_zone')) ...[
                    const LogoutSection(),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => _showDeleteAccountDialog(context, ref),
                        child: Text(
                          'Delete Account',
                          style: TextStyle(
                            color: (isDark ? AppColors.error : AppColorsLight.error)
                                .withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Version (tap 7 times to unlock Beast Mode)
                  Center(
                    child: GestureDetector(
                      onTap: _onVersionTap,
                      child: Text(
                        'FitWiz v1.2.0',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // No results
                  if (_searchQuery.isNotEmpty && _matchingSections.isEmpty)
                    _buildNoResultsMessage(context, textMuted),
                ],
              ),
            ),
          ),

          // Top navigation bar — pill row matching workout detail style
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back button circle
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    context.pop();
                  },
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : elevated,
                      borderRadius: BorderRadius.circular(22),
                      border: isDark
                          ? null
                          : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title pill
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : elevated,
                      borderRadius: BorderRadius.circular(22),
                      border: isDark
                          ? null
                          : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Help button circle — opens email support directly
                GestureDetector(
                  onTap: () => _launchExternalUrl('mailto:${AppLinks.supportEmail}?subject=FitWiz Help'),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : elevated,
                      borderRadius: BorderRadius.circular(22),
                      border: isDark
                          ? null
                          : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ),
              ],
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
