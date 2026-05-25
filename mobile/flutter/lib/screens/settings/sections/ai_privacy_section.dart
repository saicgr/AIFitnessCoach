import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../ai_settings/ai_settings_screen.dart';
import '../widgets/widgets.dart';

import '../../../l10n/generated/app_localizations.dart';
// ════════════════════════════════════════════════════════════════════════
// Cycle-research consent (Phase H — MacroFactor 1.10).
//
// An opt-in, server-enforced consent for contributing anonymised cycle data
// to women's health research. It lives on `user_ai_settings.
// cycle_research_consent` (a Phase-H backend column) but is NOT part of the
// typed `AISettings` model, so it is read/written here through a small
// dedicated provider rather than the shared AI-settings notifier.
//
// Default OFF. The toggle never sends cycle data itself — it only flips the
// server-side flag; `consent_guard` on the backend is what actually gates
// whether any anonymised data may leave the backend.
// ════════════════════════════════════════════════════════════════════════

/// Reads + persists `user_ai_settings.cycle_research_consent`.
class CycleResearchConsentNotifier extends StateNotifier<bool> {
  final Ref _ref;
  bool _loaded = false;

  CycleResearchConsentNotifier(this._ref) : super(false) {
    _load();
  }

  /// Read the current server value. Defaults to OFF on any failure — consent
  /// must never silently default to ON.
  Future<void> _load() async {
    try {
      final api = _ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null) return;
      final resp = await api.get('${ApiConstants.aiSettings}/$userId');
      final data = resp.data;
      if (data is Map && data['cycle_research_consent'] is bool) {
        state = data['cycle_research_consent'] as bool;
      }
      _loaded = true;
    } catch (e) {
      debugPrint('⚠️ [CycleResearchConsent] load failed: $e');
    }
  }

  /// Persist a new consent value. Sends the full AI-settings snapshot merged
  /// with the new flag so a PUT that treats the body as a full document does
  /// not wipe the user's other AI settings.
  Future<void> set(bool value) async {
    final previous = state;
    state = value; // optimistic
    try {
      final api = _ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null) {
        state = previous;
        return;
      }
      final snapshot = _ref.read(aiSettingsProvider).toJson();
      final resp = await api.put(
        '${ApiConstants.aiSettings}/$userId',
        data: {
          ...snapshot,
          'cycle_research_consent': value,
          'change_source': 'app',
          'device_platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
      if (resp.statusCode != 200) {
        throw Exception('Unexpected status ${resp.statusCode}');
      }
      _loaded = true;
    } catch (e) {
      // No silent success — revert so the switch reflects reality and the
      // user can retry.
      debugPrint('❌ [CycleResearchConsent] save failed: $e');
      state = previous;
      rethrow;
    }
  }

  bool get isLoaded => _loaded;
}

/// Process-wide provider for the cycle-research consent flag.
final cycleResearchConsentProvider =
    StateNotifierProvider<CycleResearchConsentNotifier, bool>(
  (ref) => CycleResearchConsentNotifier(ref),
);

/// The Privacy & Data section — surfaces real, server-enforced consent
/// toggles (personalization + chat history + cycle research) plus the
/// medical disclaimer.
///
/// Prior versions wrote to SharedPreferences keys that no code ever read,
/// which made the toggles placebo controls (a GDPR Art. 7(4) dark pattern).
/// All toggles here are now backed by `user_ai_settings` and enforced by
/// `services.consent_guard` on the backend.
class AIPrivacySection extends ConsumerWidget {
  const AIPrivacySection({super.key});

  Future<void> _togglePersonalization(WidgetRef ref, bool value) async {
    HapticFeedback.lightImpact();
    final notifier = ref.read(aiSettingsProvider.notifier);
    await notifier.updateAiDataProcessingEnabled(value);
  }

  Future<void> _toggleSaveChatHistory(WidgetRef ref, bool value) async {
    HapticFeedback.lightImpact();
    final notifier = ref.read(aiSettingsProvider.notifier);
    await notifier.updateSaveChatHistory(value);
  }

  Future<void> _toggleCycleResearch(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(cycleResearchConsentProvider.notifier).set(value);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).aiPrivacyCouldnTUpdateConsent),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final settings = ref.watch(aiSettingsProvider);
    final personalizationEnabled = settings.aiDataProcessingEnabled;
    final saveChatHistory = settings.saveChatHistory;
    final cycleResearchConsent = ref.watch(cycleResearchConsentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: AppLocalizations.of(context).aiSettingsPrivacyData,
          subtitle: AppLocalizations.of(context).aiPrivacyControlHowYourData,
        ),
        const SizedBox(height: 12),

        // Data usage explainer — navigation tile
        _buildNavigationTile(
          icon: Icons.info_outlined,
          title: AppLocalizations.of(context).aiPrivacyHowYourDataIs,
          subtitle: AppLocalizations.of(context).aiPrivacySeeWhatDataIs,
          color: AppColors.info,
          onTap: () => context.push('/settings/ai-data-usage'),
          textPrimary: textPrimary,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),

        const SizedBox(height: 10),

        // Personalization toggle — server-enforced kill switch
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
                      AppLocalizations.of(context).aiPrivacyPersonalization,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      personalizationEnabled
                          ? AppLocalizations.of(context).aiPrivacyYourCoachPersonalizesWorkou
                          : 'Personalization is paused — coach chat is disabled',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: personalizationEnabled,
                onChanged: (v) => _togglePersonalization(ref, v),
                activeColor: AppColors.success,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Save chat history toggle — server-enforced
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
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).aiSettingsScreenSaveChatHistory,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      saveChatHistory
                          ? AppLocalizations.of(context).aiPrivacyMessagesAreStoredSo
                          : 'Messages are discarded after each reply',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: saveChatHistory,
                onChanged: (v) => _toggleSaveChatHistory(ref, v),
                activeColor: AppColors.info,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Cycle-research consent toggle — opt-in, server-enforced, default
        // OFF. Anonymised cycle data only leaves the backend when this is on.
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
                  color: const Color(0xFFE91E63).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volunteer_activism_outlined,
                  color: Color(0xFFE91E63),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).aiPrivacyContributeToWomenS,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      cycleResearchConsent
                          ? 'Anonymised cycle data may be shared to improve '
                              'women\'s health research'
                          : 'Off — your cycle data never leaves your account',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: cycleResearchConsent,
                onChanged: (v) => _toggleCycleResearch(context, ref, v),
                activeColor: const Color(0xFFE91E63),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Medical Disclaimer - navigation tile
        _buildNavigationTile(
          icon: Icons.medical_information_outlined,
          title: AppLocalizations.of(context).medicalDisclaimerMedicalDisclaimer,
          subtitle: AppLocalizations.of(context).aiPrivacyImportantHealthInformation,
          color: AppColors.warning,
          onTap: () => context.push('/settings/medical-disclaimer'),
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
