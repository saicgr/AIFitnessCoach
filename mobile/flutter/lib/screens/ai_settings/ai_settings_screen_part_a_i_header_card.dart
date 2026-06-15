part of 'ai_settings_screen.dart';


/// AI Header Card — Signature v2 Anton masthead. The boxed cyan/purple
/// gradient is replaced by a flat masthead: an Anton "AI SETTINGS" title with
/// a Barlow descriptor kicker beneath, on the dark Signature surface.
class _AIHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)
              .aiSettingsScreenAiCoachSettings
              .toUpperCase(),
          style: ZType.disp(34, color: tc.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).aiSettingsScreenCustomizeHowYourAi,
          style: ZType.lbl(
            12,
            weight: FontWeight.w600,
            color: tc.textMuted,
            letterSpacing: 1.4,
          ),
        ),
      ],
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
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final cardBorder = tc.cardBorder;
    final accent = tc.accent;

    // Get current coach
    final coach = widget.ref.read(aiSettingsProvider.notifier).getCurrentCoach();
    final coachName = _displayName();
    final coachIcon = coach?.icon ?? Icons.smart_toy;
    // Persona glyph stays a NEUTRAL framed icon (not color-flooded) per the
    // Signature spec — one accent per screen is reserved for selection state.
    final coachColor = accent;
    final personalityBadge = coach?.personalityBadge ?? 'Default';

    return Container(
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Coach avatar — tap navigates to full coach selection.
            // Neutral framed glyph: hairline border, no gradient flood.
            GestureDetector(
              onTap: _editingName
                  ? null
                  : () => context.push('/coach-selection?fromSettings=true'),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tc.elevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Icon(coachIcon, color: textPrimary, size: 26),
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
                              hintText: coach?.name ?? AppLocalizations.of(context).aiSettingsScreenCoachName,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: coachColor, size: 22),
                          onPressed: _saveName,
                          tooltip: AppLocalizations.of(context).buttonSave,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: textSecondary, size: 22),
                          onPressed: _cancelEditing,
                          tooltip: AppLocalizations.of(context).buttonCancel,
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
                                fontWeight: FontWeight.w700,
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
                        // Neutral framed personality pill (hairline, no accent
                        // flood — accent is reserved for selection state).
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Text(
                            personalityBadge.toUpperCase(),
                            style: ZType.lbl(
                              9,
                              weight: FontWeight.w600,
                              color: textSecondary,
                              letterSpacing: 1.2,
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
                          ? AppLocalizations.of(context).aiSettingsScreenRenameYourCoachPreset
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
    final tc = ThemeColors.of(context);
    final textSecondary = tc.textSecondary;
    final textMuted = tc.textMuted;
    final cardBorder = tc.cardBorder;
    final accent = tc.accent;

    final styles = [
      ('motivational', 'Motivational'),
      ('professional', 'Professional'),
      ('friendly', 'Friendly'),
      ('tough-love', 'Tough Love'),
      ('drill-sergeant', 'Drill Sergeant'),
      ('college-coach', 'College Coach'),
      ('zen-master', 'Zen Master'),
      ('hype-beast', 'Hype Beast'),
      ('scientist', 'Scientist'),
      ('comedian', 'Comedian'),
      ('old-school', 'Old School'),
    ];

    final tones = [
      ('casual', 'Casual'),
      ('encouraging', 'Encouraging'),
      ('formal', 'Formal'),
      ('gen-z', 'Gen Z'),
      ('sarcastic', 'Sarcastic'),
      ('roast-mode', 'Roast Mode'),
      ('pirate', 'Pirate'),
      ('british', 'British'),
      ('surfer', 'Surfer'),
      ('anime', 'Anime'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiny uppercase sub-label
          Text(
            AppLocalizations.of(context)
                .customCoachFormCoachingStyle
                .toUpperCase(),
            style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: styles.map((style) {
              final isSelected = settings.coachingStyle == style.$1;
              return ZealovaChip(
                label: style.$2,
                selected: isSelected,
                onTap: () => ref
                    .read(aiSettingsProvider.notifier)
                    .updateCoachingStyle(style.$1),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          ZealovaRule(margin: const EdgeInsets.symmetric(vertical: 2)),
          const SizedBox(height: 16),

          Text(
            AppLocalizations.of(context)
                .customCoachFormCommunicationTone
                .toUpperCase(),
            style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tones.map((tone) {
              final isSelected = settings.communicationTone == tone.$1;
              return ZealovaChip(
                label: tone.$2,
                selected: isSelected,
                onTap: () => ref
                    .read(aiSettingsProvider.notifier)
                    .updateCommunicationTone(tone.$1),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          ZealovaRule(margin: const EdgeInsets.symmetric(vertical: 2)),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)
                    .customCoachFormEncouragementLevel
                    .toUpperCase(),
                style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.6),
              ),
              Text(
                '${(settings.encouragementLevel * 100).toInt()}%',
                style: ZType.data(14, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: cardBorder,
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: settings.encouragementLevel,
              onChanged: (value) => ref.read(aiSettingsProvider.notifier).updateEncouragementLevel(value),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context).notificationsMinimal, style: TextStyle(fontSize: 11, color: textSecondary)),
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
    final tc = ThemeColors.of(context);
    final textSecondary = tc.textSecondary;
    final textMuted = tc.textMuted;
    final cardBorder = tc.cardBorder;
    final accent = tc.accent;

    final lengths = [
      ('concise', 'Concise', 'Short, to-the-point'),
      ('balanced', 'Balanced', 'Moderate detail'),
      ('detailed', 'Detailed', 'Comprehensive'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)
                .aiSettingsScreenResponseLength
                .toUpperCase(),
            style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.6),
          ),
          const SizedBox(height: 12),
          Row(
            children: lengths.map((length) {
              final isSelected = settings.responseLength == length.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(aiSettingsProvider.notifier).updateResponseLength(length.$1),
                  child: Container(
                    margin: EdgeInsetsDirectional.only(end: length.$1 != 'detailed' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accent : cardBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          length.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? accent : textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          length.$3,
                          textAlign: TextAlign.center,
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
          ZealovaRule(margin: const EdgeInsets.symmetric(vertical: 2)),
          const SizedBox(height: 8),

          _ToggleItem(
            title: AppLocalizations.of(context).aiSettingsScreenUseEmojis,
            subtitle: AppLocalizations.of(context).aiSettingsScreenAddEmojisToAi,
            value: settings.useEmojis,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleEmojis(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: AppLocalizations.of(context).aiSettingsScreenIncludeTips,
            subtitle: AppLocalizations.of(context).aiSettingsScreenAddHelpfulTipsIn,
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
    final tc = ThemeColors.of(context);
    final textSecondary = tc.textSecondary;
    final textMuted = tc.textMuted;
    final cardBorder = tc.cardBorder;
    final accent = tc.accent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)
                .aiSettingsScreenDefaultAgent
                .toUpperCase(),
            style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.6),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).aiSettingsScreenThisAgentRespondsWhen,
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 12),

          // Default agent selector — neutral framed chips, accent on selected.
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
                    color: isSelected ? accent.withValues(alpha: 0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? accent : cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(config.icon, size: 16, color: isSelected ? accent : textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        config.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? accent : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          ZealovaRule(margin: const EdgeInsets.symmetric(vertical: 2)),
          const SizedBox(height: 16),

          Text(
            AppLocalizations.of(context)
                .aiSettingsScreenAvailableAgents
                .toUpperCase(),
            style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.6),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).aiSettingsScreenEnableOrDisableAgents,
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
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final cardBorder = tc.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tc.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          // Neutral framed agent glyph (no color flood).
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tc.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cardBorder),
            ),
            child: Icon(agent.icon, size: 18, color: textPrimary),
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
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.aiSettingsScreenPartAIHeaderCardValue(agent.name),
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (_) => onChanged(),
            activeThumbColor: tc.accent,
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
    final tc = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.cardBorder),
      ),
      child: Column(
        children: [
          _ToggleItem(
            title: AppLocalizations.of(context).aiSettingsScreenFormReminders,
            subtitle: AppLocalizations.of(context).aiSettingsScreenGetRemindersAboutProper,
            value: settings.formReminders,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleFormReminders(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: AppLocalizations.of(context).aiSettingsScreenRestDaySuggestions,
            subtitle: AppLocalizations.of(context).aiSettingsScreenGetSuggestionsForRest,
            value: settings.restDaySuggestions,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleRestDaySuggestions(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: AppLocalizations.of(context).aiSettingsScreenNutritionMentions,
            subtitle: AppLocalizations.of(context).aiSettingsScreenIncludeNutritionAdviceIn,
            value: settings.nutritionMentions,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleNutritionMentions(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: AppLocalizations.of(context).aiSettingsScreenInjurySensitivity,
            subtitle: AppLocalizations.of(context).aiSettingsScreenConsiderYourInjuriesWhen,
            value: settings.injurySensitivity,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleInjurySensitivity(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: AppLocalizations.of(context).aiSettingsScreenAiCoachDuringWorkouts,
            subtitle: AppLocalizations.of(context).aiSettingsScreenShowAiCoachAssistant,
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
    final tc = ThemeColors.of(context);
    final textSecondary = tc.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.cardBorder),
      ),
      child: Column(
        children: [
          _ToggleItem(
            title: AppLocalizations.of(context).aiSettingsScreenSaveChatHistory,
            subtitle: AppLocalizations.of(context).aiSettingsScreenStoreConversationsForContex,
            value: settings.saveChatHistory,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleSaveChatHistory(),
          ),
          const SizedBox(height: 12),
          _ToggleItem(
            title: AppLocalizations.of(context).aiSettingsScreenUsePreviousConversations,
            subtitle: AppLocalizations.of(context).aiSettingsScreenAiLearnsFromPast,
            value: settings.useRAG,
            onChanged: () => ref.read(aiSettingsProvider.notifier).toggleUseRAG(),
          ),
          const SizedBox(height: 16),
          const ZealovaRule(margin: EdgeInsets.symmetric(vertical: 2)),
          const SizedBox(height: 12),

          // Clear history button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showClearHistoryDialog(context, widgetRef),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              label: Text(AppLocalizations.of(context).chatScreenExtClearChatHistory, style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).aiSettingsScreenThisWillDeleteAll,
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
        title: Text(AppLocalizations.of(context).chatClearChatHistory),
        content: Text(
          AppLocalizations.of(context).aiSettingsScreenThisWillPermanentlyDelete,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).buttonCancel,
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
                SnackBar(
                  content: Text(AppLocalizations.of(context).aiSettingsScreenChatHistoryCleared),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(AppLocalizations.of(context).vacationModeClear, style: TextStyle(color: AppColors.error)),
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
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;

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
                  fontWeight: FontWeight.w600,
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
          activeThumbColor: tc.accent,
        ),
      ],
    );
  }
}

