import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/services/notification_service.dart';
import '../../../screens/ai_settings/ai_settings_screen.dart';
import '../../../widgets/coach_avatar.dart';
import '../../../widgets/coach_voice_picker.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/main_shell.dart';
import '../sections/sections.dart';

import '../../../l10n/generated/app_localizations.dart';
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
    final tc = ThemeColors.of(context);
    final backgroundColor = tc.background;
    final textPrimary = tc.textPrimary;
    final textMuted = tc.textMuted;
    final textSecondary = tc.textSecondary;
    final cardBorder = tc.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ZealovaAppBar(title: AppLocalizations.of(context).authIntroAiCoach),
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
  ///
  /// Signature hairline composition — Barlow kicker, the intensity segmented
  /// control on a hairline, then hairline-divided toggle rows. No boxed card.
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
        ZealovaSectionKicker(
          AppLocalizations.of(context).aiCoachCoachNotifications,
          padding: const EdgeInsetsDirectional.only(start: 2, bottom: 8),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).aiCoachNudgeIntensity,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).aiCoachHowMuchYourAi,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'gentle', label: Text(AppLocalizations.of(context).aiCoachGentle, style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'balanced', label: Text(AppLocalizations.of(context).quizProgressionConstraintsBalanced, style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'tough_love', label: Text(AppLocalizations.of(context).aiCoachTough, style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'off', label: Text(AppLocalizations.of(context).programBuilderPartOff, style: TextStyle(fontSize: 11))),
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
        const ZealovaRule(),
        _coachToggle(
          icon: Icons.auto_awesome,
          title: AppLocalizations.of(context).aiCoachAiPersonalizedMessages,
          subtitle: AppLocalizations.of(context).aiCoachMatchYourCoachS,
          value: prefs.aiPersonalizedNudges,
          onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setAiPersonalizedNudges(v),
        ),
        _coachToggle(
          icon: Icons.alarm,
          title: AppLocalizations.of(context).aiCoachMissedWorkoutNudge,
          subtitle: AppLocalizations.of(context).aiCoachRemindByEveningIf,
          value: prefs.missedWorkoutNudge,
          onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setMissedWorkoutNudge(v),
          isLast: true,
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
        ZealovaSectionKicker(
          AppLocalizations.of(context).aiCoachOtherNotifications,
          padding: const EdgeInsetsDirectional.only(start: 2, bottom: 8),
        ),
        _coachToggle(
          icon: Icons.lunch_dining,
          title: AppLocalizations.of(context).aiCoachPostWorkoutMeal,
          subtitle: AppLocalizations.of(context).aiCoachRefuelReminderAfterTraining,
          value: prefs.postWorkoutMealReminder,
          onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setPostWorkoutMealReminder(v),
        ),
        _coachToggle(
          icon: Icons.checklist,
          title: AppLocalizations.of(context).aiCoachHabitReminders,
          subtitle: AppLocalizations.of(context).aiCoachEveningCheckInFor,
          value: prefs.habitReminders,
          onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setHabitReminders(v),
        ),
        _coachToggle(
          icon: Icons.celebration,
          title: AppLocalizations.of(context).aiCoachStreakCelebrations,
          subtitle: AppLocalizations.of(context).aiCoachCelebrateStreakMilestones,
          value: prefs.streakCelebration,
          onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setStreakCelebration(v),
        ),
        _coachToggle(
          icon: Icons.card_giftcard,
          title: 'Daily Crate Reminders',
          subtitle: AppLocalizations.of(context).aiCoachGetNotifiedWhenYour,
          value: prefs.dailyCrateReminders,
          onChanged: (v) => ref.read(notificationPreferencesProvider.notifier).setDailyCrateReminders(v),
        ),
        ZealovaListRow(
          icon: Icons.beach_access_rounded,
          label: 'Vacation Mode',
          value: 'Pause all non-critical notifications',
          hairline: false,
          onTap: () => context.push('/settings/vacation-mode'),
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
    final tc = ThemeColors.of(context);

    return ZealovaCard(
      variant: ZealovaCardVariant.hero,
      onTap: () {
        HapticFeedback.selectionClick();
        GoRouter.of(context).push('/ai-settings');
      },
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
                color: tc.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.record_voice_over, color: tc.accent, size: 24),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach?.name ?? AppLocalizations.of(context).aiCoachCoachVoicePersonality,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  coach != null
                      ? AppLocalizations.of(context)!.aiCoachPageTapToChange(coach.tagline)
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
    );
  }

  Widget _coachToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Builder(
      builder: (context) {
        final tc = ThemeColors.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: isLast
              ? null
              : const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.hairline)),
                ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15,
                    color: value ? tc.accent : tc.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(fontSize: 14, color: tc.textPrimary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 11, color: tc.textMuted, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ZealovaToggle(value: value, onChanged: onChanged),
            ],
          ),
        );
      },
    );
  }

  /// Floating chat-bubble toggle — Signature hairline toggle row (v2 `.st-row`).
  Widget _buildEdgeHandleToggle({
    required WidgetRef ref,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
  }) {
    final isEnabled = ref.watch(edgeHandleEnabledProvider);
    return _coachToggle(
      icon: Icons.chat_bubble_outline,
      title: AppLocalizations.of(context).aiCoachFloatingAiChatBubble,
      subtitle: AppLocalizations.of(context).aiCoachShowFloatingBubbleFor,
      value: isEnabled,
      onChanged: (value) {
        HapticFeedback.lightImpact();
        ref.read(edgeHandleEnabledProvider.notifier).setEnabled(value);
      },
      isLast: true,
    );
  }
}

/// Switch row that hides power-user options behind a single toggle.
/// State is owned by the parent page (persisted to SharedPreferences).
class _AdvancedToggleRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textPrimary;
  final Color textSecondary;

  const _AdvancedToggleRow({
    required this.value,
    required this.onChanged,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    // Signature hairline toggle row — framed glyph + label/value + toggle,
    // sitting on a hairline (no boxed card). Reuses the .st-row archetype.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune, size: 15,
                color: value ? tc.accent : tc.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).aiSettingsAdvancedSettings,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).aiCoachShowFloatingChatBubble,
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ZealovaToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
