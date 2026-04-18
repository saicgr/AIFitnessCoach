import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/models/mood.dart';
import '../data/models/workout_style.dart';
import '../data/providers/mood_workout_provider.dart';
import '../data/providers/today_workout_provider.dart';
import '../data/repositories/workout_repository.dart';
import '../data/services/context_logging_service.dart';
import '../data/services/haptic_service.dart';
import '../services/mood_workout_presets.dart';
import 'glass_sheet.dart';
import 'main_shell.dart';
import 'replace_or_add_workout_dialog.dart';

/// Shows the mood picker bottom sheet.
void showMoodPickerSheet(BuildContext context, WidgetRef ref) {
  HapticService.light();
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  showGlassSheet(
    context: context,
    useRootNavigator: true,
    builder: (context) => const MoodPickerSheet(),
  ).then((_) {
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

/// Bottom sheet for selecting mood + generating a workout locally.
class MoodPickerSheet extends ConsumerStatefulWidget {
  const MoodPickerSheet({super.key});

  @override
  ConsumerState<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends ConsumerState<MoodPickerSheet> {
  Mood? _selectedMood;
  bool _isLogging = false;
  bool _isGenerating = false;

  // Advanced Options state.
  bool _advancedExpanded = false;
  WorkoutStyle? _selectedStyle;
  String? _selectedDifficulty;
  int? _selectedDuration;
  bool _styleOverridden = false;
  bool _difficultyOverridden = false;
  bool _durationOverridden = false;

  static const _difficulties = ['easy', 'medium', 'hard', 'hell'];

  /// Effective selections, falling back to the current mood's preset.
  WorkoutStyle? get _effectiveStyle {
    if (_selectedStyle != null) return _selectedStyle;
    final m = _selectedMood;
    return m == null ? null : MoodPreset.forMood(m).recommendedStyle;
  }

  String? get _effectiveDifficulty {
    if (_selectedDifficulty != null) return _selectedDifficulty;
    final m = _selectedMood;
    return m == null ? null : MoodPreset.forMood(m).recommendedDifficulty;
  }

  int? get _effectiveDuration {
    if (_selectedDuration != null) return _selectedDuration;
    final m = _selectedMood;
    return m == null ? null : MoodPreset.forMood(m).recommendedDuration;
  }

  bool get _anyOverride =>
      _styleOverridden || _difficultyOverridden || _durationOverridden;

  void _onMoodTap(Mood mood) {
    // Heavier haptics for bigger emotional states.
    if (mood == Mood.angry ||
        mood == Mood.motivated ||
        mood == Mood.great) {
      HapticService.medium();
    } else {
      HapticService.light();
    }
    setState(() {
      _selectedMood = mood;
      // Don't wipe user overrides — respecting agency. The summary pill
      // shows the current (mood-default or overridden) triple either way.
    });
  }

  void _resetToRecommended() {
    setState(() {
      _selectedStyle = null;
      _selectedDifficulty = null;
      _selectedDuration = null;
      _styleOverridden = false;
      _difficultyOverridden = false;
      _durationOverridden = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.1);
    final textColorStrong =
        isDark ? textColor : Colors.black.withValues(alpha: 0.85);
    final textMutedStrong =
        isDark ? textMuted : Colors.black.withValues(alpha: 0.55);

    return GlassSheet(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -------------------- Header --------------------
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.mood, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'How are you feeling?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColorStrong,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close,
                          color: textMutedStrong, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // -------------------- Mood grid --------------------
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: Mood.values.map((mood) {
                      return _MoodButton(
                        mood: mood,
                        isSelected: _selectedMood == mood,
                        onTap: () => _onMoodTap(mood),
                      );
                    }).toList(),
                  ),
                ),

                // -------------------- Advanced Options --------------------
                if (_selectedMood != null) ...[
                  const SizedBox(height: 12),
                  _buildAdvancedOptions(
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textColor: textColorStrong,
                    textMuted: textMutedStrong,
                    accentColor: accentColor,
                    isDark: isDark,
                  ),
                ],

                const SizedBox(height: 18),

                // -------------------- Actions --------------------
                _buildGlassActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Just Log Mood',
                  isLoading: _isLogging,
                  onTap: _selectedMood == null || _isLogging || _isGenerating
                      ? null
                      : _logMoodOnly,
                  isPrimary: true,
                  isDark: isDark,
                  accentColor: _selectedMood?.color ?? accentColor,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColorStrong,
                  textMuted: textMutedStrong,
                ),
                const SizedBox(height: 10),
                _buildGlassActionButton(
                  icon: Icons.fitness_center,
                  label: 'Generate Workout',
                  isLoading: _isGenerating,
                  onTap: _selectedMood == null || _isLogging || _isGenerating
                      ? null
                      : _generateWorkout,
                  isPrimary: false,
                  isDark: isDark,
                  accentColor: _selectedMood?.color ?? accentColor,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textColor: textColorStrong,
                  textMuted: textMutedStrong,
                ),
                const SizedBox(height: 12),

                // View History & Analysis pill
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    Navigator.pop(context);
                    context.push('/mood-history');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insights_outlined,
                            size: 16, color: textMutedStrong),
                        const SizedBox(width: 6),
                        Text(
                          'View History & Analysis',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textMutedStrong,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right,
                            size: 16, color: textMutedStrong),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions({
    required Color cardBg,
    required Color cardBorder,
    required Color textColor,
    required Color textMuted,
    required Color accentColor,
    required bool isDark,
  }) {
    final style = _effectiveStyle!;
    final difficulty = _effectiveDifficulty!;
    final duration = _effectiveDuration!;
    final summary =
        '${style.label} · ${_difficultyLabel(difficulty)} · $duration min';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row (always visible, tap to expand).
          InkWell(
            onTap: () {
              HapticService.light();
              setState(() => _advancedExpanded = !_advancedExpanded);
              if (_advancedExpanded && _selectedMood != null) {
                ref.read(contextLoggingServiceProvider).logMoodAdvancedOpened(
                      mood: _selectedMood!,
                      hadOverrides: _anyOverride,
                    );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _advancedExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Advanced Options',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _anyOverride
                            ? accentColor
                            : textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_advancedExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  _optionLabel('Style', textMuted),
                  const SizedBox(height: 6),
                  _styleChipsRow(accentColor, cardBorder, textColor, textMuted),
                  const SizedBox(height: 14),
                  _optionLabel('Difficulty', textMuted),
                  const SizedBox(height: 6),
                  _difficultyChipsRow(
                      accentColor, cardBorder, textColor, textMuted),
                  const SizedBox(height: 14),
                  _optionLabel('Duration', textMuted),
                  _durationRow(accentColor, textColor, textMuted),
                  if (_anyOverride) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _resetToRecommended,
                        icon: Icon(Icons.restart_alt,
                            size: 16, color: accentColor),
                        label: Text(
                          'Reset to recommended',
                          style:
                              TextStyle(color: accentColor, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _styleChipsRow(Color accent, Color border, Color textColor,
      Color textMuted) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: WorkoutStyle.values.map((s) {
          final isSel = _effectiveStyle == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _chip(
              label: s.label,
              icon: s.icon,
              isSelected: isSel,
              accent: accent,
              border: border,
              textColor: textColor,
              textMuted: textMuted,
              onTap: () {
                HapticService.light();
                final mood = _selectedMood;
                if (mood != null) {
                  final preset = MoodPreset.forMood(mood);
                  if (preset.recommendedStyle != s) {
                    ref.read(contextLoggingServiceProvider).logMoodStyleOverridden(
                          mood: mood,
                          field: 'style',
                          recommended: preset.recommendedStyle.value,
                          chosen: s.value,
                        );
                  }
                }
                setState(() {
                  _selectedStyle = s;
                  _styleOverridden = true;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _difficultyChipsRow(Color accent, Color border, Color textColor,
      Color textMuted) {
    return Row(
      children: _difficulties.map((d) {
        final isSel = _effectiveDifficulty == d;
        final isHell = d == 'hell';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _chip(
              label: _difficultyLabel(d),
              icon: _difficultyIcon(d),
              isSelected: isSel,
              accent: isHell ? AppColors.error : accent,
              border: border,
              textColor: textColor,
              textMuted: textMuted,
              onTap: () {
                // Celebrate Hell with a heavy haptic.
                if (isHell) {
                  HapticService.heavy();
                } else {
                  HapticService.light();
                }
                final mood = _selectedMood;
                if (mood != null) {
                  final preset = MoodPreset.forMood(mood);
                  if (preset.recommendedDifficulty != d) {
                    ref.read(contextLoggingServiceProvider).logMoodStyleOverridden(
                          mood: mood,
                          field: 'difficulty',
                          recommended: preset.recommendedDifficulty,
                          chosen: d,
                        );
                  }
                }
                setState(() {
                  _selectedDifficulty = d;
                  _difficultyOverridden = true;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _durationRow(Color accent, Color textColor, Color textMuted) {
    final d = _effectiveDuration!.toDouble().clamp(10.0, 60.0);
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: d,
              min: 10,
              max: 60,
              divisions: 10,
              activeColor: accent,
              inactiveColor: textMuted.withValues(alpha: 0.3),
              onChanged: (v) {
                setState(() {
                  _selectedDuration = v.round();
                  _durationOverridden = true;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 54,
          child: Text(
            '$_effectiveDuration min',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accent,
    required Color border,
    required Color textColor,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : border,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: isSelected ? accent : textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? accent : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _difficultyLabel(String d) {
    switch (d) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      case 'hell':
        return 'Hell';
    }
    return d;
  }

  IconData _difficultyIcon(String d) {
    switch (d) {
      case 'easy':
        return Icons.sentiment_satisfied_alt;
      case 'medium':
        return Icons.fitness_center;
      case 'hard':
        return Icons.local_fire_department_outlined;
      case 'hell':
        return Icons.whatshot;
    }
    return Icons.circle;
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback? onTap,
    required bool isPrimary,
    required bool isDark,
    required Color accentColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textColor,
    required Color textMuted,
  }) {
    final isDisabled = onTap == null;
    final bgColor = isPrimary
        ? (isDisabled
            ? cardBg
            : accentColor.withValues(alpha: isDark ? 0.2 : 0.12))
        : cardBg;
    final borderCol = isPrimary
        ? (isDisabled
            ? cardBorder
            : accentColor.withValues(alpha: isDark ? 0.4 : 0.3))
        : cardBorder;
    final iconColor = isDisabled ? textMuted : accentColor;
    final labelColor = isDisabled ? textMuted : textColor;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderCol, width: isPrimary ? 1.5 : 1),
          boxShadow: isPrimary && !isDisabled && !isDark
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _logMoodOnly() async {
    if (_selectedMood == null) return;

    setState(() => _isLogging = true);
    HapticService.medium();

    try {
      ref
          .read(contextLoggingServiceProvider)
          .logMoodSelection(mood: _selectedMood!);

      if (mounted) {
        Navigator.pop(context);
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(_selectedMood!.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('Mood logged: ${_selectedMood!.label}'),
              ],
            ),
            backgroundColor: _selectedMood!.color,
            behavior: SnackBarBehavior.floating,
            margin:
                const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLogging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log mood: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _generateWorkout() async {
    final mood = _selectedMood;
    if (mood == null) return;

    setState(() => _isGenerating = true);
    HapticService.medium();

    try {
      // Fire-and-forget mood log (never blocks generation).
      ref.read(contextLoggingServiceProvider).logMoodSelection(mood: mood);

      final notifier = ref.read(moodWorkoutProvider.notifier);
      notifier.selectMood(mood);

      final workout = await notifier.generateMoodWorkout(
        style: _styleOverridden ? _selectedStyle : null,
        difficulty: _difficultyOverridden ? _selectedDifficulty : null,
        duration: _durationOverridden ? _selectedDuration : null,
      );

      if (!mounted || workout == null) {
        if (mounted) {
          final error = ref.read(moodWorkoutProvider).error;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        return;
      }

      // Check if today already has a workout. If so, ask Replace vs Add.
      final existing = await notifier.existingTodayWorkouts();
      bool shouldReplace = false;
      String? replacedId;
      if (existing.isNotEmpty && mounted) {
        final choice = await showReplaceOrAddWorkoutDialog(context);
        if (!mounted) return;
        if (choice == null) {
          // User dismissed → abandon generation (don't persist).
          setState(() => _isGenerating = false);
          return;
        }
        shouldReplace = choice;
        if (shouldReplace) {
          replacedId = existing.first.id;
        }
      }

      // Persist the workout to Drift (+ enqueue sync).
      await notifier.persistWorkout(workout);

      // Hot-patch in-memory caches so the carousel shows the new workout
      // immediately (mirrors the Regenerate flow at
      // `regenerate_workout_sheet_part_regenerate_workout_sheet_state_ext.dart:110-123`).
      if (replacedId != null) {
        WorkoutsNotifier.replaceInCache(replacedId, workout);
      }
      TodayWorkoutNotifier.clearCache();
      ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
      await ref.read(workoutsProvider.notifier).silentRefresh();

      // Log success for analytics with full local-algorithm context.
      final meta = workout.generationMetadata ?? const {};
      ref.read(contextLoggingServiceProvider).logMoodWorkoutGenerated(
            mood: mood,
            workoutId: workout.id ?? '',
            durationMinutes: workout.durationMinutes,
            style: meta['style'] as String?,
            difficulty: meta['difficulty'] as String?,
            wasStyleOverridden: meta['style_was_overridden'] as bool?,
            wasDifficultyOverridden: meta['difficulty_was_overridden'] as bool?,
            wasDurationOverridden: meta['duration_was_overridden'] as bool?,
            latencyMs: meta['latency_ms'] as int?,
            generator: meta['generator'] as String?,
          );

      if (mounted) {
        Navigator.pop(context);
        // If the generated workout includes a breath / grounding prompt
        // (for Anxious / Angry / Stressed), push the pre-start screen
        // which runs the prompt and then replaces itself with the workout.
        final meta = workout.generationMetadata ?? const {};
        if (meta['mood_breath_prompt'] != null) {
          context.push('/workout/mood-pre-start', extra: workout);
        } else {
          context.push('/workout/${workout.id}', extra: workout);
        }
      }
    } catch (e, stack) {
      debugPrint('❌ [MoodPickerSheet] Generate failed: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate workout: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // ALWAYS clear the spinner — no more stuck "Initializing..." overlay.
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}

/// Individual mood tile — 40 px emoji + label.
class _MoodButton extends StatelessWidget {
  final Mood mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${mood.label} mood. ${mood.description}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? mood.color.withValues(alpha: isDark ? 0.2 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? mood.color.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: mood.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  mood.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mood.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? mood.color
                      : (isDark
                          ? AppColors.textMuted
                          : AppColorsLight.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
