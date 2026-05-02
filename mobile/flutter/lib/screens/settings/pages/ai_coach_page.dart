import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/services/notification_service.dart';
import '../../../screens/ai_settings/ai_settings_screen.dart';
import '../../../widgets/coach_avatar.dart';
import '../../../widgets/coach_voice_picker.dart';
import '../../../widgets/main_shell.dart';
import '../../../widgets/pill_app_bar.dart';
import '../sections/sections.dart';

/// Sub-page for AI Coach settings: voice, edge handle, privacy.
///
/// Layout: essentials (Coach card, voice, nudge intensity + AI-personalized
/// + missed-workout) are always visible. Power-user toggles (floating chat
/// bubble, niche notifications, privacy) collapse behind an Advanced
/// settings switch persisted in SharedPreferences.
class AiCoachPage extends ConsumerStatefulWidget {
  const AiCoachPage({super.key});

  @override
  ConsumerState<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends ConsumerState<AiCoachPage> {
  static const _kAdvancedKey = 'ai_coach_page_advanced_enabled';
  bool _advancedEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAdvancedPref();
  }

  Future<void> _loadAdvancedPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_kAdvancedKey) ?? false;
      if (!mounted) return;
      setState(() => _advancedEnabled = v);
    } catch (_) {}
  }

  Future<void> _setAdvanced(bool value) async {
    setState(() => _advancedEnabled = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAdvancedKey, value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'AI Coach'),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoachCard(
                context: context,
                ref: ref,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cardBorder: cardBorder,
              ),
              const SizedBox(height: 16),
              const CoachVoicePicker(),
              const SizedBox(height: 16),
              _buildEssentialNudgeSection(
                ref: ref,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cardBorder: cardBorder,
              ),
              const SizedBox(height: 16),
              _AdvancedToggleRow(
                value: _advancedEnabled,
                onChanged: _setAdvanced,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              if (_advancedEnabled) ...[
                const SizedBox(height: 16),
                _buildEdgeHandleToggle(
                  ref: ref,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cardBorder: cardBorder,
                ),
                const SizedBox(height: 16),
                _buildAdvancedNotificationsSection(
                  ref: ref,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cardBorder: cardBorder,
                ),
                const SizedBox(height: 16),
                const AIPrivacySection(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
    );
  }

  /// Essentials: nudge intensity + the two notification toggles users care
  /// about most (AI-personalized + missed workout). Other toggles move
  /// behind Advanced.
  Widget _buildEssentialNudgeSection({
    required WidgetRef ref,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
  }) {
    final prefs = ref.watch(notificationPreferencesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'COACH NOTIFICATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nudge Intensity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How much your AI coach pushes you',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'gentle', label: Text('Gentle', style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: 'balanced', label: Text('Balanced', style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: 'tough_love', label: Text('Tough', style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: 'off', label: Text('Off', style: TextStyle(fontSize: 11))),
                        ],
                        selected: {prefs.accountabilityIntensity},
                        onSelectionChanged: (values) {
                          HapticFeedback.selectionClick();
                          ref.read(notificationPreferencesProvider.notifier).setAccountabilityIntensity(values.first);
                        },
                        style: ButtonStyle(visualDensity: VisualDensity.compact),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cardBorder),
              _coachToggle(
                icon: Icons.auto_awesome,
                iconColor: AppColors.purple,
                title: 'AI-Personalized Messages',
                subtitle: "Match your coach's personality",
                value: prefs.aiPersonalizedNudges,
                onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setAiPersonalizedNudges(v),
                cardBorder: cardBorder,
              ),
              _coachToggle(
                icon: Icons.alarm,
                iconColor: AppColors.error,
                title: 'Missed Workout Nudge',
                subtitle: 'Remind by evening if you skip',
                value: prefs.missedWorkoutNudge,
                onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setMissedWorkoutNudge(v),
                cardBorder: cardBorder,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Advanced notifications: post-workout meal, habit reminders, streak
  /// celebrations, daily crate reminders, vacation mode escape hatch.
  Widget _buildAdvancedNotificationsSection({
    required WidgetRef ref,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
  }) {
    final prefs = ref.watch(notificationPreferencesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'OTHER NOTIFICATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              _coachToggle(
                icon: Icons.lunch_dining,
                iconColor: AppColors.success,
                title: 'Post-Workout Meal',
                subtitle: 'Refuel reminder after training',
                value: prefs.postWorkoutMealReminder,
                onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setPostWorkoutMealReminder(v),
                cardBorder: cardBorder,
              ),
              _coachToggle(
                icon: Icons.checklist,
                iconColor: AppColors.cyan,
                title: 'Habit Reminders',
                subtitle: 'Evening check-in for habits',
                value: prefs.habitReminders,
                onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setHabitReminders(v),
                cardBorder: cardBorder,
              ),
              _coachToggle(
                icon: Icons.celebration,
                iconColor: AppColors.warning,
                title: 'Streak Celebrations',
                subtitle: 'Celebrate streak milestones',
                value: prefs.streakCelebration,
                onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setStreakCelebration(v),
                cardBorder: cardBorder,
              ),
              _coachToggle(
                icon: Icons.card_giftcard,
                iconColor: const Color(0xFFFFB300),
                title: 'Daily Crate Reminders',
                subtitle: 'Get notified when your crate is ready',
                value: prefs.dailyCrateReminders,
                onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setDailyCrateReminders(v),
                cardBorder: cardBorder,
              ),
              Divider(height: 1, color: cardBorder),
              Builder(
                builder: (context) => ListTile(
                  leading: const Icon(Icons.beach_access_rounded, color: Color(0xFF4FC3F7), size: 20),
                  title: const Text('Vacation Mode', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Pause all non-critical notifications', style: TextStyle(fontSize: 11)),
                  trailing: Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  onTap: () => context.push('/settings/vacation-mode'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoachCard({
    required BuildContext context,
    required WidgetRef ref,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
  }) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        GoRouter.of(context).push('/ai-settings');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            if (coach != null)
              CoachAvatar(
                coach: coach,
                size: 48,
                showBorder: true,
                borderWidth: 2,
                showShadow: false,
                enableTapToView: false,
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.record_voice_over, color: AppColors.info, size: 24),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach?.name ?? 'Coach Voice & Personality',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coach != null
                        ? '${coach.tagline} · Tap to change'
                        : 'Change AI voice and style',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _coachToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color cardBorder,
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(icon, color: value ? iconColor : Colors.grey, size: 20),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          value: value,
          activeColor: AppColors.cyan,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          onChanged: onChanged,
        ),
        if (!isLast) Divider(height: 1, color: cardBorder, indent: 50),
      ],
    );
  }

  Widget _buildEdgeHandleToggle({
    required WidgetRef ref,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
  }) {
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
            Icons.chat_bubble_outline,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Floating AI Chat Bubble',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Show floating bubble for quick AI Coach access',
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
}

/// Switch row that hides power-user options behind a single toggle.
/// State is owned by the parent page (persisted to SharedPreferences).
class _AdvancedToggleRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _AdvancedToggleRow({
    required this.value,
    required this.onChanged,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, size: 18, color: textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced settings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Show floating chat bubble, niche notifications, and privacy controls',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
