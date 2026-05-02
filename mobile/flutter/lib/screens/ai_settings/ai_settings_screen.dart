import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/coach_persona.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/tts_service.dart';
import '../../widgets/pill_app_bar.dart';

part 'ai_settings_screen_part_a_i_header_card.dart';


/// AI Settings storage provider - loads from API when user is authenticated
final aiSettingsProvider = StateNotifierProvider<AISettingsNotifier, AISettings>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final notifier = AISettingsNotifier(apiClient);

  // Auto-load settings when provider is first accessed
  Future.microtask(() => notifier.loadSettings());

  return notifier;
});

/// AI Settings model
class AISettings {
  // Coach Persona
  final String? coachPersonaId; // 'coach_mike', 'dr_sarah', 'custom', etc.
  final String? coachName; // Display name for the coach
  final bool isCustomCoach; // Whether using custom coach configuration
  final String coachVoiceId; // 'default' | 'coach_voice_chad' | 'coach_voice_serena'

  // Personality & Tone
  final String coachingStyle; // "motivational", "professional", "friendly", "tough-love"
  final String communicationTone; // "casual", "formal", "encouraging"
  final double encouragementLevel; // 0.0 - 1.0

  // Response Preferences
  final String responseLength; // "concise", "detailed", "balanced"
  final bool useEmojis;
  final bool includeTips;

  // Agents
  final AgentType defaultAgent;
  final Map<AgentType, bool> enabledAgents;

  // Fitness Coaching Specifics
  final bool formReminders;
  final bool restDaySuggestions;
  final bool nutritionMentions;
  final bool injurySensitivity;
  final bool showAICoachDuringWorkouts;

  // Privacy & Data
  final bool saveChatHistory;
  final bool useRAG;
  // Server-enforced master switch. When false, the backend refuses to
  // process outbound coaching requests for this user. Wired through
  // user_ai_settings.ai_data_processing_enabled.
  final bool aiDataProcessingEnabled;
  // GDPR Art. 9 explicit consent for special-category health data.
  final bool healthDataConsent;

  const AISettings({
    this.coachPersonaId,
    this.coachName,
    this.isCustomCoach = false,
    this.coachVoiceId = 'default',
    this.coachingStyle = 'motivational',
    this.communicationTone = 'encouraging',
    this.encouragementLevel = 0.7,
    this.responseLength = 'balanced',
    this.useEmojis = true,
    this.includeTips = true,
    this.defaultAgent = AgentType.coach,
    this.enabledAgents = const {
      AgentType.coach: true,
      AgentType.nutrition: true,
      AgentType.workout: true,
      AgentType.injury: true,
      AgentType.hydration: true,
    },
    this.formReminders = true,
    this.restDaySuggestions = true,
    this.nutritionMentions = true,
    this.injurySensitivity = true,
    this.showAICoachDuringWorkouts = true,
    this.saveChatHistory = true,
    this.useRAG = true,
    this.aiDataProcessingEnabled = true,
    this.healthDataConsent = false,
  });

  AISettings copyWith({
    String? coachPersonaId,
    String? coachName,
    bool? isCustomCoach,
    String? coachVoiceId,
    String? coachingStyle,
    String? communicationTone,
    double? encouragementLevel,
    String? responseLength,
    bool? useEmojis,
    bool? includeTips,
    AgentType? defaultAgent,
    Map<AgentType, bool>? enabledAgents,
    bool? formReminders,
    bool? restDaySuggestions,
    bool? nutritionMentions,
    bool? injurySensitivity,
    bool? showAICoachDuringWorkouts,
    bool? saveChatHistory,
    bool? useRAG,
    bool? aiDataProcessingEnabled,
    bool? healthDataConsent,
  }) {
    return AISettings(
      coachPersonaId: coachPersonaId ?? this.coachPersonaId,
      coachName: coachName ?? this.coachName,
      isCustomCoach: isCustomCoach ?? this.isCustomCoach,
      coachVoiceId: coachVoiceId ?? this.coachVoiceId,
      coachingStyle: coachingStyle ?? this.coachingStyle,
      communicationTone: communicationTone ?? this.communicationTone,
      encouragementLevel: encouragementLevel ?? this.encouragementLevel,
      responseLength: responseLength ?? this.responseLength,
      useEmojis: useEmojis ?? this.useEmojis,
      includeTips: includeTips ?? this.includeTips,
      defaultAgent: defaultAgent ?? this.defaultAgent,
      enabledAgents: enabledAgents ?? this.enabledAgents,
      formReminders: formReminders ?? this.formReminders,
      restDaySuggestions: restDaySuggestions ?? this.restDaySuggestions,
      nutritionMentions: nutritionMentions ?? this.nutritionMentions,
      injurySensitivity: injurySensitivity ?? this.injurySensitivity,
      showAICoachDuringWorkouts: showAICoachDuringWorkouts ?? this.showAICoachDuringWorkouts,
      saveChatHistory: saveChatHistory ?? this.saveChatHistory,
      useRAG: useRAG ?? this.useRAG,
      aiDataProcessingEnabled: aiDataProcessingEnabled ?? this.aiDataProcessingEnabled,
      healthDataConsent: healthDataConsent ?? this.healthDataConsent,
    );
  }

  /// Convert to JSON for API requests (matches backend AISettings model)
  Map<String, dynamic> toJson() {
    return {
      'coach_persona_id': coachPersonaId,
      'coach_name': coachName,
      'is_custom_coach': isCustomCoach,
      'coach_voice_id': coachVoiceId,
      'coaching_style': coachingStyle,
      'communication_tone': communicationTone,
      'encouragement_level': encouragementLevel,
      'response_length': responseLength,
      'use_emojis': useEmojis,
      'include_tips': includeTips,
      'form_reminders': formReminders,
      'rest_day_suggestions': restDaySuggestions,
      'nutrition_mentions': nutritionMentions,
      'injury_sensitivity': injurySensitivity,
      'show_ai_coach_during_workouts': showAICoachDuringWorkouts,
      'save_chat_history': saveChatHistory,
      'use_rag': useRAG,
      'ai_data_processing_enabled': aiDataProcessingEnabled,
      'health_data_consent': healthDataConsent,
      'default_agent': defaultAgent.name,
      'enabled_agents': enabledAgents.map((k, v) => MapEntry(k.name, v)),
    };
  }

  /// Create from JSON response
  factory AISettings.fromJson(Map<String, dynamic> json) {
    // Parse enabled_agents from JSON
    Map<AgentType, bool> parseEnabledAgents(dynamic value) {
      if (value == null) {
        return {
          AgentType.coach: true,
          AgentType.nutrition: true,
          AgentType.workout: true,
          AgentType.injury: true,
          AgentType.hydration: true,
        };
      }
      final map = value as Map<String, dynamic>;
      return {
        AgentType.coach: map['coach'] ?? true,
        AgentType.nutrition: map['nutrition'] ?? true,
        AgentType.workout: map['workout'] ?? true,
        AgentType.injury: map['injury'] ?? true,
        AgentType.hydration: map['hydration'] ?? true,
      };
    }

    // Parse default_agent from string
    AgentType parseDefaultAgent(dynamic value) {
      if (value == null) return AgentType.coach;
      final str = value.toString();
      return AgentType.values.firstWhere(
        (e) => e.name == str,
        orElse: () => AgentType.coach,
      );
    }

    return AISettings(
      coachPersonaId: json['coach_persona_id'] as String?,
      coachName: json['coach_name'] as String?,
      isCustomCoach: json['is_custom_coach'] as bool? ?? false,
      coachVoiceId: json['coach_voice_id'] as String? ?? 'default',
      coachingStyle: json['coaching_style'] as String? ?? 'motivational',
      communicationTone: json['communication_tone'] as String? ?? 'encouraging',
      encouragementLevel: (json['encouragement_level'] as num?)?.toDouble() ?? 0.7,
      responseLength: json['response_length'] as String? ?? 'balanced',
      useEmojis: json['use_emojis'] as bool? ?? true,
      includeTips: json['include_tips'] as bool? ?? true,
      formReminders: json['form_reminders'] as bool? ?? true,
      restDaySuggestions: json['rest_day_suggestions'] as bool? ?? true,
      nutritionMentions: json['nutrition_mentions'] as bool? ?? true,
      injurySensitivity: json['injury_sensitivity'] as bool? ?? true,
      showAICoachDuringWorkouts: json['show_ai_coach_during_workouts'] as bool? ?? true,
      saveChatHistory: json['save_chat_history'] as bool? ?? true,
      useRAG: json['use_rag'] as bool? ?? true,
      aiDataProcessingEnabled: json['ai_data_processing_enabled'] as bool? ?? true,
      healthDataConsent: json['health_data_consent'] as bool? ?? false,
      defaultAgent: parseDefaultAgent(json['default_agent']),
      enabledAgents: parseEnabledAgents(json['enabled_agents']),
    );
  }

  /// Get the current coach persona from settings
  CoachPersona getCurrentCoach() {
    // If there's a coach persona ID, try to find the predefined coach
    if (coachPersonaId != null && !isCustomCoach) {
      final predefined = CoachPersona.findById(coachPersonaId);
      if (predefined != null) return predefined;
    }

    // Custom coach or fallback
    if (isCustomCoach || coachPersonaId == 'custom') {
      return CoachPersona.custom(
        name: coachName ?? 'My Coach',
        coachingStyle: coachingStyle,
        communicationTone: communicationTone,
        encouragementLevel: encouragementLevel,
      );
    }

    // Default to Coach Mike
    return CoachPersona.defaultCoach;
  }
}

/// AI Settings state notifier with API persistence
class AISettingsNotifier extends StateNotifier<AISettings> {
  final ApiClient _apiClient;
  bool _isLoaded = false;

  // Debounced save with retry. The previous `_isSaving` drop silently
  // swallowed concurrent saves, which caused persona picks to never land
  // server-side (e.g. reviewer account had coach_persona_id=NULL despite
  // picking a coach in the UI). Now: debounce rapid setter calls into one
  // PUT, and retry up to [_maxSaveAttempts] on failure.
  Timer? _saveDebounce;
  int _saveAttempt = 0;
  bool _saveInFlight = false;
  bool _pendingSave = false;
  static const Duration _saveDebounceDelay = Duration(milliseconds: 350);
  static const int _maxSaveAttempts = 4;

  AISettingsNotifier(this._apiClient) : super(const AISettings());

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  /// Load settings from API
  Future<void> loadSettings() async {
    if (_isLoaded) return;

    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        debugPrint('🤖 [AISettings] No user ID, using defaults');
        return;
      }

      debugPrint('🤖 [AISettings] Loading settings for user: $userId');
      final response = await _apiClient.get('${ApiConstants.aiSettings}/$userId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        state = AISettings.fromJson(data);
        _isLoaded = true;
        // Apply the saved voice to the TTS engine so the next workout
        // announcement uses it. Safe to call even on 'default'.
        unawaited(TTSService().applyVoice(state.coachVoiceId));
        debugPrint('✅ [AISettings] Loaded settings: ${state.coachingStyle}, ${state.communicationTone}, voice=${state.coachVoiceId}');
      }
    } catch (e) {
      debugPrint('❌ [AISettings] Error loading settings: $e');
      // Keep default settings on error
    }
  }

  /// Schedule a debounced save. Rapid setter calls collapse into one PUT.
  /// If a save is already in flight, a second save fires after it completes
  /// so the latest state always reaches the server.
  void _saveSettings() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(_saveDebounceDelay, () {
      _saveAttempt = 0;
      _runSave();
    });
  }

  /// Perform the actual PUT. Retries with exponential backoff on failure
  /// so a transient 5xx (cold start, RLS hiccup) doesn't silently drop
  /// the user's persona selection.
  Future<void> _runSave() async {
    if (_saveInFlight) {
      // A save is already running; flag a follow-up so we re-sync the
      // newest state once the current call settles.
      _pendingSave = true;
      return;
    }
    _saveInFlight = true;
    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        debugPrint('🤖 [AISettings] No user ID, cannot save');
        return;
      }

      final snapshot = state.toJson();
      debugPrint(
          '🤖 [AISettings] Saving (attempt ${_saveAttempt + 1}) for user: $userId  style=${state.coachingStyle} persona=${state.coachPersonaId}');
      final response = await _apiClient.put(
        '${ApiConstants.aiSettings}/$userId',
        data: {
          ...snapshot,
          'change_source': 'app',
          'device_platform': Platform.isIOS ? 'ios' : 'android',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [AISettings] Settings saved successfully');
        _saveAttempt = 0;
      } else {
        throw Exception('Unexpected status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [AISettings] Error saving settings: $e');
      _saveAttempt++;
      if (_saveAttempt < _maxSaveAttempts) {
        // Exponential backoff: 500ms, 1s, 2s.
        final delayMs = 500 * (1 << (_saveAttempt - 1));
        debugPrint(
            '🤖 [AISettings] Retrying save in ${delayMs}ms (attempt ${_saveAttempt + 1}/$_maxSaveAttempts)');
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        _saveInFlight = false;
        await _runSave();
        return;
      } else {
        debugPrint('❌ [AISettings] Giving up after $_maxSaveAttempts attempts');
        _saveAttempt = 0;
      }
    } finally {
      _saveInFlight = false;
      if (_pendingSave) {
        _pendingSave = false;
        // State mutated while the last save was running — run one more.
        unawaited(_runSave());
      }
    }
  }

  void updateCoachingStyle(String style) {
    state = state.copyWith(coachingStyle: style);
    _saveSettings();
  }

  void updateCoachVoice(String voiceId) {
    state = state.copyWith(coachVoiceId: voiceId);
    _saveSettings();
  }

  void updateCommunicationTone(String tone) {
    state = state.copyWith(communicationTone: tone);
    _saveSettings();
  }

  void updateEncouragementLevel(double level) {
    state = state.copyWith(encouragementLevel: level);
    _saveSettings();
  }

  void updateResponseLength(String length) {
    state = state.copyWith(responseLength: length);
    _saveSettings();
  }

  void toggleEmojis() {
    state = state.copyWith(useEmojis: !state.useEmojis);
    _saveSettings();
  }

  void toggleIncludeTips() {
    state = state.copyWith(includeTips: !state.includeTips);
    _saveSettings();
  }

  void setDefaultAgent(AgentType agent) {
    state = state.copyWith(defaultAgent: agent);
    _saveSettings();
  }

  void toggleAgent(AgentType agent) {
    final newEnabledAgents = Map<AgentType, bool>.from(state.enabledAgents);
    newEnabledAgents[agent] = !(newEnabledAgents[agent] ?? true);
    state = state.copyWith(enabledAgents: newEnabledAgents);
    _saveSettings();
  }

  void toggleFormReminders() {
    state = state.copyWith(formReminders: !state.formReminders);
    _saveSettings();
  }

  void toggleRestDaySuggestions() {
    state = state.copyWith(restDaySuggestions: !state.restDaySuggestions);
    _saveSettings();
  }

  void toggleNutritionMentions() {
    state = state.copyWith(nutritionMentions: !state.nutritionMentions);
    _saveSettings();
  }

  void toggleInjurySensitivity() {
    state = state.copyWith(injurySensitivity: !state.injurySensitivity);
    _saveSettings();
  }

  void toggleShowAICoachDuringWorkouts() {
    state = state.copyWith(showAICoachDuringWorkouts: !state.showAICoachDuringWorkouts);
    _saveSettings();
  }

  void toggleSaveChatHistory() {
    state = state.copyWith(saveChatHistory: !state.saveChatHistory);
    _saveSettings();
  }

  /// Direct setter for the "Save chat history" toggle in Settings → Privacy.
  /// Returns a future that resolves after the debounced save lands so the
  /// UI can surface a snackbar without racing the backend.
  Future<void> updateSaveChatHistory(bool value) async {
    state = state.copyWith(saveChatHistory: value);
    _saveSettings();
  }

  void toggleUseRAG() {
    state = state.copyWith(useRAG: !state.useRAG);
    _saveSettings();
  }

  /// Server-enforced master kill-switch for personalization. When set to
  /// false, the backend's `consent_guard` refuses to forward chats, food
  /// photos, or form videos to the models.
  Future<void> updateAiDataProcessingEnabled(bool value) async {
    state = state.copyWith(aiDataProcessingEnabled: value);
    _saveSettings();
  }

  /// GDPR Art. 9 explicit consent for special-category health data
  /// (weight, heart rate, sleep, menstrual/hormonal cycle). Captured in a
  /// dedicated opt-in flow, not bundled with general ToS acceptance.
  Future<void> updateHealthDataConsent(bool value) async {
    state = state.copyWith(healthDataConsent: value);
    _saveSettings();
  }

  /// Set a predefined coach persona
  void setCoachPersona(CoachPersona coach) {
    state = state.copyWith(
      coachPersonaId: coach.id,
      coachName: coach.name,
      isCustomCoach: coach.isCustom,
      coachingStyle: coach.coachingStyle,
      communicationTone: coach.communicationTone,
      encouragementLevel: coach.encouragementLevel,
    );
    // Mark as loaded to prevent API from overwriting local selection during onboarding
    _isLoaded = true;
    _saveSettings();
    NotificationServiceScheduled.cacheCoachId(coach.id, coachingStyle: coach.coachingStyle);
  }

  /// Rename the current coach without changing the underlying persona.
  /// Display name only — `coach_persona_id`, `coaching_style`, `tone`, and
  /// `encouragement_level` all stay locked. Empty/whitespace input reverts
  /// to the preset's original name.
  Future<void> setCoachDisplayName(String newName) async {
    final trimmed = newName.trim();
    String? finalName = trimmed.isEmpty ? null : trimmed;

    // If user clears the field on a preset, fall back to the preset's name
    // so we never end up with a blank coach.
    if (finalName == null && state.coachPersonaId != null && !state.isCustomCoach) {
      final preset = CoachPersona.findById(state.coachPersonaId!);
      finalName = preset?.name;
    }
    // For custom coaches that get cleared, default to "My Coach" (matches
    // setCustomCoach fallback).
    finalName ??= 'My Coach';

    // Cap at 24 chars to keep UI bounded.
    if (finalName.length > 24) finalName = finalName.substring(0, 24);

    state = state.copyWith(coachName: finalName);
    _isLoaded = true;
    _saveSettings();
  }

  /// Set a custom coach with user-defined settings
  void setCustomCoach({
    required String name,
    required String coachingStyle,
    required String communicationTone,
    double encouragementLevel = 0.7,
  }) {
    state = state.copyWith(
      coachPersonaId: 'custom',
      coachName: name.isEmpty ? 'My Coach' : name,
      isCustomCoach: true,
      coachingStyle: coachingStyle,
      communicationTone: communicationTone,
      encouragementLevel: encouragementLevel,
    );
    // Mark as loaded to prevent API from overwriting local selection during onboarding
    _isLoaded = true;
    _saveSettings();
    NotificationServiceScheduled.cacheCoachId('custom', coachingStyle: coachingStyle);
  }

  /// Get the current coach persona (reconstructs from settings)
  CoachPersona? getCurrentCoach() {
    final personaId = state.coachPersonaId;
    if (personaId == null) return null;

    // Check if it's a predefined coach
    final predefined = CoachPersona.findById(personaId);
    if (predefined != null) return predefined;

    // Otherwise, reconstruct custom coach from settings
    if (personaId == 'custom' || state.isCustomCoach) {
      return CoachPersona.custom(
        name: state.coachName ?? 'My Coach',
        coachingStyle: state.coachingStyle,
        communicationTone: state.communicationTone,
        encouragementLevel: state.encouragementLevel,
      );
    }

    return null;
  }
}

/// AI Settings Screen
class AISettingsScreen extends ConsumerStatefulWidget {
  const AISettingsScreen({super.key});

  @override
  ConsumerState<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends ConsumerState<AISettingsScreen> {
  // Per-section expanded state, persisted across visits via SharedPreferences.
  // Defaults reflect the most-used sections being open. Power-user sections
  // (AI Agents, Fitness Coaching, Privacy) are folded behind the Advanced
  // toggle so the screen fits without long scrolling for most users.
  static const _kAdvancedKey = 'ai_settings_advanced_enabled';
  static const _kSectionPrefix = 'ai_settings_section_expanded_';

  bool _advancedEnabled = false;
  final Map<String, bool> _expanded = {
    'coach': true,
    'personality': true,
    'response': false,
    'agents': false,
    'coaching': false,
    'privacy': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiSettingsProvider.notifier).loadSettings();
    });
    _loadExpansionPrefs();
  }

  Future<void> _loadExpansionPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final advanced = prefs.getBool(_kAdvancedKey) ?? false;
      final updated = <String, bool>{};
      for (final entry in _expanded.entries) {
        final stored = prefs.getBool('$_kSectionPrefix${entry.key}');
        updated[entry.key] = stored ?? entry.value;
      }
      if (!mounted) return;
      setState(() {
        _advancedEnabled = advanced;
        _expanded
          ..clear()
          ..addAll(updated);
      });
    } catch (_) {
      // Non-fatal — defaults are perfectly usable.
    }
  }

  Future<void> _setExpanded(String key, bool value) async {
    setState(() => _expanded[key] = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_kSectionPrefix$key', value);
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
    final settings = ref.watch(aiSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'AI Settings'),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AIHeaderCard().animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Always-visible essentials.
              _CollapsibleSection(
                title: 'YOUR COACH',
                expanded: _expanded['coach']!,
                onChanged: (v) => _setExpanded('coach', v),
                child: _CoachPersonaSection(settings: settings, ref: ref),
              ),
              _CollapsibleSection(
                title: 'PERSONALITY & TONE',
                expanded: _expanded['personality']!,
                onChanged: (v) => _setExpanded('personality', v),
                child: _PersonalitySection(settings: settings, ref: ref),
              ),
              _CollapsibleSection(
                title: 'RESPONSE PREFERENCES',
                expanded: _expanded['response']!,
                onChanged: (v) => _setExpanded('response', v),
                child: _ResponsePreferencesSection(settings: settings, ref: ref),
              ),

              const SizedBox(height: 8),
              _AdvancedToggleRow(
                value: _advancedEnabled,
                onChanged: _setAdvanced,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 8),

              if (_advancedEnabled) ...[
                _CollapsibleSection(
                  title: 'AI AGENTS',
                  expanded: _expanded['agents']!,
                  onChanged: (v) => _setExpanded('agents', v),
                  child: _AgentsSection(settings: settings, ref: ref),
                ),
                _CollapsibleSection(
                  title: 'FITNESS COACHING',
                  expanded: _expanded['coaching']!,
                  onChanged: (v) => _setExpanded('coaching', v),
                  child: _FitnessCoachingSection(settings: settings, ref: ref),
                ),
                _CollapsibleSection(
                  title: 'PRIVACY & DATA',
                  expanded: _expanded['privacy']!,
                  onChanged: (v) => _setExpanded('privacy', v),
                  child: _PrivacySection(settings: settings, ref: ref),
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
    );
  }
}

/// Wraps a section header + body in a Material `ExpansionTile`. Keeps the
/// section's title styling consistent with the existing `_SectionHeader`
/// look so the screen reads as one design language.
class _CollapsibleSection extends StatelessWidget {
  final String title;
  final bool expanded;
  final ValueChanged<bool> onChanged;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.expanded,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Theme(
      // ExpansionTile draws default dividers via the outer ListTileTheme;
      // strip them so adjacent sections stack cleanly.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey<String>('ai_section_$title'),
        initiallyExpanded: expanded,
        onExpansionChanged: onChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: textMuted,
          ),
        ),
        children: [child],
      ),
    );
  }
}

/// Single toggle that collapses the power-user sections behind a single
/// switch. Persists to SharedPreferences via `_setAdvanced`.
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
                  'Show AI agents, fitness coaching toggles, and privacy controls',
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
