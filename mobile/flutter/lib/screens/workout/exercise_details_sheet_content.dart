part of 'active_workout_screen_refactored.dart';

/// Exercise Details Sheet Content - Hybrid approach
/// Shows static data immediately, then loads AI insights in the background
class _ExerciseDetailsSheetContent extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;

  const _ExerciseDetailsSheetContent({
    required this.exercise,
  });

  @override
  ConsumerState<_ExerciseDetailsSheetContent> createState() =>
      _ExerciseDetailsSheetContentState();
}

class _ExerciseDetailsSheetContentState
    extends ConsumerState<_ExerciseDetailsSheetContent> {
  ExerciseInsights? _aiInsights;
  bool _isLoadingInsights = true;

  @override
  void initState() {
    super.initState();
    _loadAiInsights();
  }

  Future<void> _loadAiInsights() async {
    try {
      final service = ref.read(exerciseInfoServiceProvider);
      final insights = await service.getExerciseInsights(
        exerciseName: widget.exercise.name,
        primaryMuscle: widget.exercise.primaryMuscle ?? widget.exercise.muscleGroup,
        equipment: widget.exercise.equipment,
        difficulty: widget.exercise.difficulty,
      );
      if (mounted) {
        setState(() {
          _aiInsights = insights;
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInsights = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use AppColors for consistent theming
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final exercise = widget.exercise;

    // Get dynamic accent color
    final accentEnum = AccentColorScope.of(context);
    final accentColor = accentEnum.getColor(isDark);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.glassSurface.withValues(alpha: 0.95)
                : AppColorsLight.glassSurface.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColorsLight.cardBorder,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              // (drag handle is rendered by the GlassSheet wrapper — do not duplicate here)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Exercise Info',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise name with action pills
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Video pill
                          _buildActionPill(
                            context: context,
                            icon: Icons.play_circle_outline,
                            label: 'Video',
                            onTap: () {
                              Navigator.pop(context);
                              showExerciseInfoSheet(
                                context: context,
                                exercise: exercise,
                              );
                            },
                            accentColor: accentColor,
                            isDark: isDark,
                            textMuted: textMuted,
                          ),
                          const SizedBox(width: 8),
                          // Breathing pill
                          _buildActionPill(
                            context: context,
                            icon: Icons.air,
                            label: 'Breathing',
                            onTap: () {
                              Navigator.pop(context);
                              showBreathingGuide(
                                context: context,
                                exercise: exercise,
                              );
                            },
                            accentColor: accentColor,
                            isDark: isDark,
                            textMuted: textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // === EXERCISE DETAILS ===
                      _buildSectionHeader('Details', Icons.list_alt_rounded, accentColor, textPrimary),
                      const SizedBox(height: 12),

                      // Details card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Primary Muscle
                            _buildDetailRow(
                              icon: Icons.fitness_center,
                              label: 'Primary Muscle',
                              value: exercise.primaryMuscle ?? exercise.muscleGroup ?? 'Not specified',
                              color: accentColor,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),

                            // Secondary Muscles (if available)
                            if (exercise.secondaryMuscles != null)
                              Builder(
                                builder: (context) {
                                  final secondary = exercise.secondaryMuscles;
                                  String value;
                                  if (secondary is List) {
                                    value = secondary.join(', ');
                                  } else if (secondary is String && secondary.isNotEmpty) {
                                    value = secondary;
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                  return _buildDetailRow(
                                    icon: Icons.accessibility_new,
                                    label: 'Secondary Muscles',
                                    value: value,
                                    color: accentColor,
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  );
                                },
                              ),

                            // Equipment
                            _buildDetailRow(
                              icon: Icons.hardware,
                              label: 'Equipment',
                              value: exercise.equipment ?? 'Bodyweight',
                              color: accentColor,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),

                            // "Don't have this equipment?" link (only for non-bodyweight)
                            if (exercise.equipment != null &&
                                exercise.equipment!.isNotEmpty &&
                                !exercise.equipment!.toLowerCase().contains('bodyweight') &&
                                !exercise.equipment!.toLowerCase().contains('body weight') &&
                                exercise.equipment!.toLowerCase() != 'none')
                              Padding(
                                padding: const EdgeInsets.only(left: 40, top: 2, bottom: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      this.context,
                                      MaterialPageRoute(
                                        builder: (_) => const EnvironmentListScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Don't have this equipment?",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: accentColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                            // Difficulty (if available)
                            if (exercise.difficulty != null)
                              _buildDetailRow(
                                icon: Icons.speed,
                                label: 'Difficulty',
                                value: exercise.difficulty!,
                                color: accentColor,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                isLast: true,
                              ),
                          ],
                        ),
                      ),

                      // === SETUP & INSTRUCTIONS ===
                      const SizedBox(height: 24),
                      _buildSectionHeader('Setup', Icons.checklist_rounded, accentColor, textPrimary),
                      const SizedBox(height: 12),
                      _buildSetupInstructionsList(exercise, isDark, textPrimary, accentColor, cardBackground),

                      const SizedBox(height: 24),

                      // === AI COACH TIPS (loaded in background) ===
                      _buildAiInsightsSection(isDark, textPrimary, textSecondary, accentColor, cardBackground),

                      // Tip about Video button
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 20,
                              color: accentColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap "Video" to watch form demonstration',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build section header with icon
  Widget _buildSectionHeader(String title, IconData icon, Color accentColor, Color textPrimary) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build a detail row for exercise info
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightsSection(bool isDark, Color textPrimary, Color textSecondary, Color accentColor, Color cardBackground) {
    if (_isLoadingInsights) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading AI coach tips...',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (_aiInsights == null || _aiInsights!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildSectionHeader('AI Coach Tips', Icons.auto_awesome, accentColor, textPrimary),
        const SizedBox(height: 12),

        // Tips card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Cues
              if (_aiInsights!.formCues != null) ...[
                _buildInsightItem(
                  icon: Icons.check_circle_outline,
                  title: 'Form Cues',
                  content: _aiInsights!.formCues!,
                  color: const Color(0xFF22C55E), // Green for success
                  isDark: isDark,
                  textPrimary: textPrimary,
                ),
                const SizedBox(height: 16),
              ],

              // Common Mistakes
              if (_aiInsights!.commonMistakes != null) ...[
                _buildInsightItem(
                  icon: Icons.warning_amber_outlined,
                  title: 'Watch Out For',
                  content: _aiInsights!.commonMistakes!,
                  color: const Color(0xFFF59E0B), // Amber for warnings
                  isDark: isDark,
                  textPrimary: textPrimary,
                ),
                const SizedBox(height: 16),
              ],

              // Pro Tip
              if (_aiInsights!.proTip != null)
                _buildInsightItem(
                  icon: Icons.lightbulb_outline,
                  title: 'Pro Tip',
                  content: _aiInsights!.proTip!,
                  color: accentColor,
                  isDark: isDark,
                  textPrimary: textPrimary,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required bool isDark,
    required Color textPrimary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build an action pill button (Video, Breathing, etc.)
  Widget _buildActionPill({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
    required bool isDark,
    required Color textMuted,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build setup instructions list with numbered steps
  Widget _buildSetupInstructionsList(
    WorkoutExercise exercise,
    bool isDark,
    Color textPrimary,
    Color accentColor,
    Color cardBackground,
  ) {
    final instructions = _getSetupInstructions(exercise.name);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        children: instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < instructions.length - 1 ? 12 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      instruction,
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Get setup instructions based on exercise type
  List<String> _getSetupInstructions(String exerciseName) {
    final name = exerciseName.toLowerCase();

    if (name.contains('bench') || name.contains('press')) {
      return [
        'Set up the bench at the appropriate angle (flat, incline, or decline)',
        'Grip the bar slightly wider than shoulder-width',
        'Plant your feet firmly on the ground',
        'Retract your shoulder blades and maintain a slight arch',
        'Unrack and position the weight above your chest',
      ];
    } else if (name.contains('squat')) {
      return [
        'Position the bar on your upper back (not your neck)',
        'Stand with feet shoulder-width apart, toes slightly out',
        'Brace your core before descending',
        'Keep your knees tracking over your toes',
        'Descend until thighs are parallel to the floor',
      ];
    } else if (name.contains('deadlift')) {
      return [
        'Stand with feet hip-width apart, bar over mid-foot',
        'Grip the bar just outside your legs',
        'Keep your back flat and chest up',
        'Take the slack out of the bar before pulling',
        'Drive through your heels and push hips forward',
      ];
    } else if (name.contains('row')) {
      return [
        'Hinge at the hips with a slight knee bend',
        'Keep your back flat and core engaged',
        'Grip the weight with arms extended',
        'Pull the weight toward your lower chest',
        'Squeeze your shoulder blades together at the top',
      ];
    } else if (name.contains('curl')) {
      return [
        'Stand with feet shoulder-width apart',
        'Grip the weight with palms facing up',
        'Keep your elbows close to your sides',
        'Curl the weight toward your shoulders',
        'Lower with control to full extension',
      ];
    } else if (name.contains('pull') && (name.contains('up') || name.contains('down'))) {
      return [
        'Grip the bar slightly wider than shoulder-width',
        'Hang with arms fully extended',
        'Engage your lats before pulling',
        'Pull your elbows down and back',
        'Lower with control to full extension',
      ];
    } else if (name.contains('fly') || name.contains('flye')) {
      return [
        'Lie on a flat or incline bench',
        'Hold dumbbells above your chest, palms facing',
        'Keep a slight bend in your elbows',
        'Lower the weights in an arc to the sides',
        'Squeeze your chest to bring weights back up',
      ];
    } else if (name.contains('lunge')) {
      return [
        'Stand with feet hip-width apart',
        'Step forward or backward into position',
        'Lower until your back knee nearly touches the ground',
        'Keep your front knee over your ankle',
        'Push through your front heel to return',
      ];
    }

    // Default generic instructions
    return [
      'Set up your equipment and check form',
      'Warm up with lighter weight first',
      'Position yourself in the starting position',
      'Focus on controlled movements throughout',
      'Breathe consistently - exhale on exertion',
    ];
  }
}
