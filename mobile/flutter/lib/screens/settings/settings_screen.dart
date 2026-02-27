import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
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
import '../../widgets/glass_back_button.dart';
import 'beast_mode_unlock_dialog.dart';
import 'sections/sections.dart';
import 'widgets/widgets.dart';

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

/// A single row in the settings screen
class _SettingsRow {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? value;
  final String route;
  final List<String> sectionKeys;
  final bool isThemeRow;

  const _SettingsRow({
    required this.icon,
    this.iconColor,
    required this.title,
    this.value,
    required this.route,
    required this.sectionKeys,
    this.isThemeRow = false,
  });
}

/// A labeled group of rows
class _SettingsSection {
  final String label;
  final List<_SettingsRow> rows;

  const _SettingsSection({required this.label, required this.rows});

  List<String> get allSectionKeys =>
      rows.expand((r) => r.sectionKeys).toList();
}

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

  Set<String> _computeMatchingSections(String query) {
    if (query.isEmpty) return {};

    final matches = <String>{};
    final queryWords = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    for (final entry in _settingsSearchIndex.entries) {
      final sectionKey = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        final keywordLower = keyword.toLowerCase();

        if (keywordLower.contains(query) || query.contains(keywordLower)) {
          matches.add(sectionKey);
          break;
        }

        if (queryWords.length > 1) {
          int matchedWords = 0;
          for (final word in queryWords) {
            if (keywordLower.contains(word) || word.length > 2 && keywords.any((k) => k.toLowerCase().contains(word))) {
              matchedWords++;
            }
          }
          if (matchedWords >= (queryWords.length * 0.6).ceil()) {
            matches.add(sectionKey);
            break;
          }
        }
      }
    }

    return matches;
  }

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

  Widget _buildSearchFAB(bool isDark) {
    final accentColor = ref.colors(context).accent;

    return GestureDetector(
      key: const ValueKey('search_fab'),
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isSearchExpanded = true;
        });
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
              Icon(
                Icons.auto_awesome,
                color: textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
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
      default:
        return split.replaceAll('_', ' ');
    }
  }

  // --- Section label ---
  Widget _buildSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // --- Group card containing rows ---
  Widget _buildGroupCard(
    List<_SettingsRow> rows,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
    ThemeMode themeMode,
  ) {
    // Filter rows based on search
    final visibleRows = _searchQuery.isEmpty
        ? rows
        : rows.where((r) => r.sectionKeys.any((k) => _matchingSections.contains(k))).toList();

    if (visibleRows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < visibleRows.length; i++) ...[
            _buildRow(visibleRows[i], isDark, textPrimary, textMuted, themeMode),
            if (i < visibleRows.length - 1)
              Divider(
                height: 1,
                indent: 52,
                color: cardBorder,
              ),
          ],
        ],
      ),
    );
  }

  // --- Single row ---
  Widget _buildRow(
    _SettingsRow row,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    ThemeMode themeMode,
  ) {
    final iconBg = (row.iconColor ?? (isDark ? AppColors.cyan : AppColorsLight.cyan))
        .withValues(alpha: 0.15);
    final iconFg = row.iconColor ?? (isDark ? AppColors.cyan : AppColorsLight.cyan);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(row.route);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(row.icon, color: iconFg, size: 18),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                row.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
            // Theme selector or value text
            if (row.isThemeRow)
              InlineThemeSelector(
                currentMode: themeMode,
                onChanged: (mode) {
                  HapticFeedback.selectionClick();
                  ref.read(themeModeProvider.notifier).setTheme(mode);
                },
              )
            else if (row.value != null) ...[
              Flexible(
                flex: 0,
                child: Text(
                  row.value!,
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: textMuted, size: 18),
            ] else
              Icon(Icons.chevron_right, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  // --- User card at top ---
  Widget _buildUserCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final userName = user?.name ?? user?.username ?? 'User';
    final userEmail = user?.email ?? '';
    final photoUrl = user?.photoUrl;

    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.cyan : AppColorsLight.cyan).withValues(alpha: 0.15),
                image: photoUrl != null && photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: photoUrl == null || photoUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // --- Delete account dialog ---
  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Text(
              'Delete Account?',
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will permanently delete:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            DialogBulletPoint(
              text: 'Your account and profile',
              color: AppColors.error,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'All workout history',
              color: AppColors.error,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'All saved preferences',
              color: AppColors.error,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Text(
              'You will need to sign up again to use the app.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context, ref);
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null || userId.isEmpty) {
        throw Exception('User not found');
      }

      final response = await apiClient.delete(
        '${ApiConstants.users}/$userId/reset',
      );

      navigator.pop();

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        ref.read(onboardingStateProvider.notifier).reset();
        await ref.read(authStateProvider.notifier).signOut();
        router.go('/stats-welcome');
      } else {
        throw Exception('Failed to delete account: ${response.statusCode}');
      }
    } catch (e) {
      try {
        navigator.pop();
      } catch (_) {}

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onVersionTap() {
    final now = DateTime.now();
    final isBeastModeUnlocked = ref.read(beastModeProvider);

    if (isBeastModeUnlocked) {
      AppSnackBar.info(context, 'Beast Mode is already unlocked!');
      return;
    }

    // Reset counter if more than 3 seconds since last tap
    if (_lastVersionTap != null &&
        now.difference(_lastVersionTap!).inSeconds >= 3) {
      _versionTapCount = 0;
    }
    _lastVersionTap = now;
    _versionTapCount++;

    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      _unlockBeastMode();
    } else if (_versionTapCount >= 3) {
      final remaining = 7 - _versionTapCount;
      AppSnackBar.info(context, '$remaining taps away from Beast Mode...');
      HapticService.light();
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
        label: 'COMMUNITY',
        rows: [
          _SettingsRow(
            icon: Icons.lightbulb_outline,
            iconColor: isDark ? AppColors.yellow : AppColors.yellow,
            title: 'Feature Requests',
            value: 'Vote & suggest features',
            route: '/features',
            sectionKeys: const ['feature_requests'],
          ),
          _SettingsRow(
            icon: Icons.rocket_launch_outlined,
            iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
            title: 'Coming Soon',
            value: 'See what\'s next',
            route: '/coming-soon',
            sectionKeys: const ['coming_soon'],
          ),
        ],
      ),
    ];

    // Standalone "About" section (no label)
    final aboutRow = _SettingsRow(
      icon: Icons.info_outline,
      iconColor: textMuted,
      title: 'About & Support',
      route: '/settings/about-support',
      sectionKeys: const ['support', 'app_info', 'research', 'shop'],
    );

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
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 80 + bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User card
                  _buildUserCard(context, ref, isDark, elevated, cardBorder, textPrimary, textMuted),
                  const SizedBox(height: 24),

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

                  // About standalone row
                  if (_searchQuery.isEmpty ||
                      aboutRow.sectionKeys.any((k) => _matchingSections.contains(k))) ...[
                    _buildGroupCard(
                      [aboutRow],
                      isDark,
                      elevated,
                      cardBorder,
                      textPrimary,
                      textMuted,
                      themeMode,
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
