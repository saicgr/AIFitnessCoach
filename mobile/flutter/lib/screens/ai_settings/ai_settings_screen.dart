import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/coach_persona.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/notification_service.dart';
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

  const AISettings({
    this.coachPersonaId,
    this.coachName,
    this.isCustomCoach = false,
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
  });

  AISettings copyWith({
    String? coachPersonaId,
    String? coachName,
    bool? isCustomCoach,
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
  }) {
    return AISettings(
      coachPersonaId: coachPersonaId ?? this.coachPersonaId,
      coachName: coachName ?? this.coachName,
      isCustomCoach: isCustomCoach ?? this.isCustomCoach,
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
    );
  }

  /// Convert to JSON for API requests (matches backend AISettings model)
  Map<String, dynamic> toJson() {
    return {
      'coach_persona_id': coachPersonaId,
      'coach_name': coachName,
      'is_custom_coach': isCustomCoach,
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
  bool _isSaving = false;

  AISettingsNotifier(this._apiClient) : super(const AISettings());

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
        debugPrint('✅ [AISettings] Loaded settings: ${state.coachingStyle}, ${state.communicationTone}');
      }
    } catch (e) {
      debugPrint('❌ [AISettings] Error loading settings: $e');
      // Keep default settings on error
    }
  }

  /// Save settings to API (debounced)
  Future<void> _saveSettings() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        debugPrint('🤖 [AISettings] No user ID, cannot save');
        return;
      }

      debugPrint('🤖 [AISettings] Saving settings for user: $userId');
      final response = await _apiClient.put(
        '${ApiConstants.aiSettings}/$userId',
        data: {
          ...state.toJson(),
          'change_source': 'app',
          'device_platform': Platform.isIOS ? 'ios' : 'android',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [AISettings] Settings saved successfully');
      }
    } catch (e) {
      debugPrint('❌ [AISettings] Error saving settings: $e');
    } finally {
      _isSaving = false;
    }
  }

  void updateCoachingStyle(String style) {
    state = state.copyWith(coachingStyle: style);
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

  void toggleUseRAG() {
    state = state.copyWith(useRAG: !state.useRAG);
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
    NotificationService.cacheCoachId(coach.id, coachingStyle: coach.coachingStyle);
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
    NotificationService.cacheCoachId('custom', coachingStyle: coachingStyle);
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
  @override
  void initState() {
    super.initState();
    // Load settings from API on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiSettingsProvider.notifier).loadSettings();
    });
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
              // Header card
              _AIHeaderCard().animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Coach Persona
              _SectionHeader(title: 'YOUR COACH'),
              const SizedBox(height: 12),
              _CoachPersonaSection(settings: settings, ref: ref)
                  .animate().fadeIn(delay: 50.ms),

              const SizedBox(height: 24),

              // Personality & Tone
              _SectionHeader(title: 'PERSONALITY & TONE'),
              const SizedBox(height: 12),
              _PersonalitySection(settings: settings, ref: ref)
                  .animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // Response Preferences
              _SectionHeader(title: 'RESPONSE PREFERENCES'),
              const SizedBox(height: 12),
              _ResponsePreferencesSection(settings: settings, ref: ref)
                  .animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // AI Agents
              _SectionHeader(title: 'AI AGENTS'),
              const SizedBox(height: 12),
              _AgentsSection(settings: settings, ref: ref)
                  .animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // Fitness Coaching
              _SectionHeader(title: 'FITNESS COACHING'),
              const SizedBox(height: 12),
              _FitnessCoachingSection(settings: settings, ref: ref)
                  .animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 24),

              // Privacy & Data
              _SectionHeader(title: 'PRIVACY & DATA'),
              const SizedBox(height: 12),
              _PrivacySection(settings: settings, ref: ref)
                  .animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 100),
            ],
          ),
        ),
    );
  }
}
