part of 'ai_settings_screen.dart';


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


/// Coach Persona Section - Shows current coach with option to change
class _CoachPersonaSection extends StatefulWidget {
  final AISettings settings;
  final WidgetRef ref;

  const _CoachPersonaSection({required this.settings, required this.ref});

  @override
  State<_CoachPersonaSection> createState() => _CoachPersonaSectionState();
}

class _CoachPersonaSectionState extends State<_CoachPersonaSection> {
  bool _editingName = false;
  late TextEditingController _nameController;
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _displayName());
  }

  @override
  void didUpdateWidget(covariant _CoachPersonaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the controller in sync when persona changes (e.g., user picked a
    // new preset on the Coach Selection screen and came back).
    if (!_editingName) {
      final fresh = _displayName();
      if (_nameController.text != fresh) {
        _nameController.text = fresh;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  String _displayName() {
    // Source of truth = settings.coachName (which the user may have renamed),
    // falling back to the preset's canonical name.
    final stored = widget.settings.coachName?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    final coach = widget.ref.read(aiSettingsProvider.notifier).getCurrentCoach();
    return coach?.name ?? 'No Coach Selected';
  }

  void _startEditing() {
    HapticFeedback.selectionClick();
    setState(() {
      _editingName = true;
      _nameController.text = _displayName();
      _nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _nameController.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    setState(() => _editingName = false);
    await widget.ref
        .read(aiSettingsProvider.notifier)
        .setCoachDisplayName(newName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coach renamed to ${_displayName()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _cancelEditing() {
    setState(() {
      _editingName = false;
      _nameController.text = _displayName();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get current coach
    final coach = widget.ref.read(aiSettingsProvider.notifier).getCurrentCoach();
    final coachName = _displayName();
    final coachIcon = coach?.icon ?? Icons.smart_toy;
    final coachColor = coach?.primaryColor ?? AppColors.cyan;
    final coachAccentColor = coach?.accentColor ?? AppColors.purple;
    final personalityBadge = coach?.personalityBadge ?? 'Default';

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Coach avatar — tap navigates to full coach selection
            GestureDetector(
              onTap: _editingName
                  ? null
                  : () => context.push('/coach-selection?fromSettings=true'),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [coachColor, coachAccentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(coachIcon, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(width: 14),

            // Coach info — name area is editable in place; rest navigates
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_editingName)
                    // Inline editor: TextField + ✓ + ✗
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            autofocus: true,
                            maxLength: 24,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _saveName(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: coachColor.withOpacity(0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: coachColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: coachColor, width: 1.5),
                              ),
                              hintText: coach?.name ?? 'Coach name',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: coachColor, size: 22),
                          onPressed: _saveName,
                          tooltip: 'Save',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: textSecondary, size: 22),
                          onPressed: _cancelEditing,
                          tooltip: 'Cancel',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: _startEditing,
                            child: Text(
                              coachName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _startEditing,
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: coachColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            personalityBadge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: coachColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _editingName
                        ? null
                        : () =>
                            context.push('/coach-selection?fromSettings=true'),
                    child: Text(
                      _editingName
                          ? 'Rename your coach — preset stays the same'
                          : 'Tap name to rename · tap row to change coach',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (!_editingName)
              GestureDetector(
                onTap: () =>
                    context.push('/coach-selection?fromSettings=true'),
                child: Icon(
                  Icons.chevron_right,
                  color: textSecondary,
                ),
              ),
          ],
        ),
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
      ('motivational', 'Motivational', Icons.emoji_emotions),
      ('professional', 'Professional', Icons.business),
      ('friendly', 'Friendly', Icons.favorite),
      ('tough-love', 'Tough Love', Icons.fitness_center),
      ('drill-sergeant', 'Drill Sergeant', Icons.military_tech),
      ('college-coach', 'College Coach', Icons.sports_football),
      ('zen-master', 'Zen Master', Icons.spa),
      ('hype-beast', 'Hype Beast', Icons.celebration),
      ('scientist', 'Scientist', Icons.science),
      ('comedian', 'Comedian', Icons.theater_comedy),
      ('old-school', 'Old School', Icons.sports_gymnastics),
    ];

    final tones = [
      ('casual', 'Casual', Icons.chat_bubble_outline),
      ('encouraging', 'Encouraging', Icons.thumb_up),
      ('formal', 'Formal', Icons.school),
      ('gen-z', 'Gen Z', Icons.trending_up),
      ('sarcastic', 'Sarcastic', Icons.sentiment_satisfied_alt),
      ('roast-mode', 'Roast Mode', Icons.local_fire_department),
      ('pirate', 'Pirate', Icons.sailing),
      ('british', 'British', Icons.local_cafe),
      ('surfer', 'Surfer', Icons.surfing),
      ('anime', 'Anime', Icons.auto_awesome),
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
                    color: isSelected ? AppColors.cyan.withValues(alpha: 0.2) : Colors.transparent,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tones.map((tone) {
              final isSelected = settings.communicationTone == tone.$1;
              return GestureDetector(
                onTap: () => ref.read(aiSettingsProvider.notifier).updateCommunicationTone(tone.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.purple.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.purple : cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tone.$3, size: 16, color: isSelected ? AppColors.purple : textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        tone.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColors.purple : textSecondary,
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
            activeThumbColor: agent.primaryColor,
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
          const SizedBox(height: 12),
          _ToggleItem(
            title: 'AI Coach During Workouts',
            subtitle: 'Show AI coach assistant while exercising',
            value: settings.showAICoachDuringWorkouts,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleShowAICoachDuringWorkouts(),
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
          activeThumbColor: AppColors.cyan,
        ),
      ],
    );
  }
}

