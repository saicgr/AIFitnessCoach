import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';

/// AI Settings storage provider
final aiSettingsProvider = StateNotifierProvider<AISettingsNotifier, AISettings>((ref) {
  return AISettingsNotifier();
});

/// AI Settings model
class AISettings {
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

  // Privacy & Data
  final bool saveChatHistory;
  final bool useRAG;

  const AISettings({
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
    this.saveChatHistory = true,
    this.useRAG = true,
  });

  AISettings copyWith({
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
    bool? saveChatHistory,
    bool? useRAG,
  }) {
    return AISettings(
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
      saveChatHistory: saveChatHistory ?? this.saveChatHistory,
      useRAG: useRAG ?? this.useRAG,
    );
  }
}

/// AI Settings state notifier
class AISettingsNotifier extends StateNotifier<AISettings> {
  AISettingsNotifier() : super(const AISettings());

  void updateCoachingStyle(String style) {
    state = state.copyWith(coachingStyle: style);
  }

  void updateCommunicationTone(String tone) {
    state = state.copyWith(communicationTone: tone);
  }

  void updateEncouragementLevel(double level) {
    state = state.copyWith(encouragementLevel: level);
  }

  void updateResponseLength(String length) {
    state = state.copyWith(responseLength: length);
  }

  void toggleEmojis() {
    state = state.copyWith(useEmojis: !state.useEmojis);
  }

  void toggleIncludeTips() {
    state = state.copyWith(includeTips: !state.includeTips);
  }

  void setDefaultAgent(AgentType agent) {
    state = state.copyWith(defaultAgent: agent);
  }

  void toggleAgent(AgentType agent) {
    final newEnabledAgents = Map<AgentType, bool>.from(state.enabledAgents);
    newEnabledAgents[agent] = !(newEnabledAgents[agent] ?? true);
    state = state.copyWith(enabledAgents: newEnabledAgents);
  }

  void toggleFormReminders() {
    state = state.copyWith(formReminders: !state.formReminders);
  }

  void toggleRestDaySuggestions() {
    state = state.copyWith(restDaySuggestions: !state.restDaySuggestions);
  }

  void toggleNutritionMentions() {
    state = state.copyWith(nutritionMentions: !state.nutritionMentions);
  }

  void toggleInjurySensitivity() {
    state = state.copyWith(injurySensitivity: !state.injurySensitivity);
  }

  void toggleSaveChatHistory() {
    state = state.copyWith(saveChatHistory: !state.saveChatHistory);
  }

  void toggleUseRAG() {
    state = state.copyWith(useRAG: !state.useRAG);
  }
}

/// AI Settings Screen
class AISettingsScreen extends ConsumerWidget {
  const AISettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
          'AI Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              _AIHeaderCard().animate().fadeIn().slideY(begin: 0.1),

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
      ),
    );
  }
}

/// AI Header Card
class _AIHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withOpacity(0.2),
            AppColors.purple.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Coach Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize how your AI coach interacts with you',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 1.5,
      ),
    );
  }
}

/// Personality Section
class _PersonalitySection extends StatelessWidget {
  final AISettings settings;
  final WidgetRef ref;

  const _PersonalitySection({required this.settings, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final styles = [
      ('motivational', 'Motivational', Icons.emoji_emotions, 'Encouraging and uplifting'),
      ('professional', 'Professional', Icons.business, 'Straightforward and efficient'),
      ('friendly', 'Friendly', Icons.favorite, 'Warm and supportive'),
      ('tough-love', 'Tough Love', Icons.fitness_center, 'Challenging and direct'),
    ];

    final tones = [
      ('casual', 'Casual'),
      ('encouraging', 'Encouraging'),
      ('formal', 'Formal'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coaching Style',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: styles.map((style) {
              final isSelected = settings.coachingStyle == style.$1;
              return GestureDetector(
                onTap: () => ref.read(aiSettingsProvider.notifier).updateCoachingStyle(style.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.cyan.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.cyan : cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.$3, size: 16, color: isSelected ? AppColors.cyan : textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        style.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColors.cyan : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Divider(color: cardBorder),
          const SizedBox(height: 16),

          Text(
            'Communication Tone',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: tones.map((tone) {
              final isSelected = settings.communicationTone == tone.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(aiSettingsProvider.notifier).updateCommunicationTone(tone.$1),
                  child: Container(
                    margin: EdgeInsets.only(right: tone.$1 != 'formal' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.purple.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.purple : cardBorder,
                      ),
                    ),
                    child: Text(
                      tone.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.purple : textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Divider(color: cardBorder),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Encouragement Level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                '${(settings.encouragementLevel * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.cyan,
              inactiveTrackColor: cardBorder,
              thumbColor: AppColors.cyan,
              overlayColor: AppColors.cyan.withOpacity(0.2),
            ),
            child: Slider(
              value: settings.encouragementLevel,
              onChanged: (value) => ref.read(aiSettingsProvider.notifier).updateEncouragementLevel(value),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Minimal', style: TextStyle(fontSize: 11, color: textSecondary)),
              Text('Maximum', style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Response Preferences Section
class _ResponsePreferencesSection extends StatelessWidget {
  final AISettings settings;
  final WidgetRef ref;

  const _ResponsePreferencesSection({required this.settings, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final lengths = [
      ('concise', 'Concise', 'Short, to-the-point'),
      ('balanced', 'Balanced', 'Moderate detail'),
      ('detailed', 'Detailed', 'Comprehensive'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Response Length',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: lengths.map((length) {
              final isSelected = settings.responseLength == length.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(aiSettingsProvider.notifier).updateResponseLength(length.$1),
                  child: Container(
                    margin: EdgeInsets.only(right: length.$1 != 'detailed' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.orange.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.orange : cardBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          length.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.orange : textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          length.$3,
                          style: TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          Divider(color: cardBorder),
          const SizedBox(height: 8),

          _ToggleItem(
            title: 'Use Emojis',
            subtitle: 'Add emojis to AI responses',
            value: settings.useEmojis,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleEmojis(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: 'Include Tips',
            subtitle: 'Add helpful tips in responses',
            value: settings.includeTips,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleIncludeTips(),
          ),
        ],
      ),
    );
  }
}

/// AI Agents Section
class _AgentsSection extends StatelessWidget {
  final AISettings settings;
  final WidgetRef ref;

  const _AgentsSection({required this.settings, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Agent',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This agent responds when you don\'t @mention a specific one',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 12),

          // Default agent selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AgentType.values.map((agent) {
              final config = AgentConfig.forType(agent);
              final isSelected = settings.defaultAgent == agent;
              return GestureDetector(
                onTap: () => ref.read(aiSettingsProvider.notifier).setDefaultAgent(agent),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? config.primaryColor.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? config.primaryColor : cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(config.icon, size: 16, color: isSelected ? config.primaryColor : textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        config.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? config.primaryColor : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Divider(color: cardBorder),
          const SizedBox(height: 16),

          Text(
            'Available Agents',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enable or disable agents you can @mention',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 12),

          ...AgentType.values.map((agent) {
            final config = AgentConfig.forType(agent);
            final isEnabled = settings.enabledAgents[agent] ?? true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AgentToggleItem(
                agent: config,
                isEnabled: isEnabled,
                onChanged: () => ref.read(aiSettingsProvider.notifier).toggleAgent(agent),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Agent Toggle Item
class _AgentToggleItem extends StatelessWidget {
  final AgentConfig agent;
  final bool isEnabled;
  final VoidCallback onChanged;

  const _AgentToggleItem({
    required this.agent,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: agent.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(agent.icon, size: 18, color: agent.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '@${agent.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: agent.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (_) => onChanged(),
            activeColor: agent.primaryColor,
          ),
        ],
      ),
    );
  }
}

/// Fitness Coaching Section
class _FitnessCoachingSection extends StatelessWidget {
  final AISettings settings;
  final WidgetRef ref;

  const _FitnessCoachingSection({required this.settings, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _ToggleItem(
            title: 'Form Reminders',
            subtitle: 'Get reminders about proper exercise form',
            value: settings.formReminders,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleFormReminders(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: 'Rest Day Suggestions',
            subtitle: 'Get suggestions for rest and recovery',
            value: settings.restDaySuggestions,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleRestDaySuggestions(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: 'Nutrition Mentions',
            subtitle: 'Include nutrition advice in workout discussions',
            value: settings.nutritionMentions,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleNutritionMentions(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: 'Injury Sensitivity',
            subtitle: 'Consider your injuries when giving advice',
            value: settings.injurySensitivity,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleInjurySensitivity(),
          ),
        ],
      ),
    );
  }
}

/// Privacy Section
class _PrivacySection extends ConsumerWidget {
  final AISettings settings;
  final WidgetRef ref;

  const _PrivacySection({required this.settings, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _ToggleItem(
            title: 'Save Chat History',
            subtitle: 'Store conversations for context',
            value: settings.saveChatHistory,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleSaveChatHistory(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: 'Use Previous Conversations',
            subtitle: 'AI learns from past interactions (RAG)',
            value: settings.useRAG,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleUseRAG(),
          ),
          const SizedBox(height: 16),
          Divider(color: cardBorder),
          const SizedBox(height: 12),

          // Clear history button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showClearHistoryDialog(context, widgetRef),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              label: const Text('Clear Chat History', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This will delete all your chat history',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will permanently delete all your conversations with the AI coach. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatMessagesProvider.notifier).clearHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat history cleared'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Toggle Item
class _ToggleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onChanged;

  const _ToggleItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      children: [
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
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (_) => onChanged(),
          activeColor: AppColors.cyan,
        ),
      ],
    );
  }
}
