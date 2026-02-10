/// Inline Exercise Info
///
/// Compact card widget showing exercise details (muscle group, setup
/// instructions, form tips) with collapsible sections.
/// Extracted from exercise_info_sheet.dart for use in foldable layouts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';

/// Compact inline exercise info card with collapsible Setup and Tips sections.
///
/// Designed to be embedded in a ScrollView or pane (e.g. foldable right pane).
/// Does not include video - video is handled separately.
class InlineExerciseInfo extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;

  const InlineExerciseInfo({
    super.key,
    required this.exercise,
  });

  @override
  ConsumerState<InlineExerciseInfo> createState() =>
      _InlineExerciseInfoState();
}

class _InlineExerciseInfoState extends ConsumerState<InlineExerciseInfo> {
  bool _setupExpanded = false;
  bool _tipsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Muscle group badge
        _buildMuscleBadge(isDark, textMuted, accentColor),
        const SizedBox(height: 12),

        // Setup instructions section
        _buildCollapsibleSection(
          title: 'Setup',
          icon: Icons.settings_outlined,
          isExpanded: _setupExpanded,
          onToggle: () => setState(() => _setupExpanded = !_setupExpanded),
          isDark: isDark,
          textPrimary: textPrimary,
          textMuted: textMuted,
          accentColor: accentColor,
          child: _buildSetupContent(isDark, textPrimary, accentColor),
        ),
        const SizedBox(height: 8),

        // Form tips section
        _buildCollapsibleSection(
          title: 'Form Tips',
          icon: Icons.lightbulb_outline,
          isExpanded: _tipsExpanded,
          onToggle: () => setState(() => _tipsExpanded = !_tipsExpanded),
          isDark: isDark,
          textPrimary: textPrimary,
          textMuted: textMuted,
          accentColor: accentColor,
          child: _buildTipsContent(isDark, textPrimary, accentColor),
        ),
      ],
    );
  }

  Widget _buildMuscleBadge(bool isDark, Color textMuted, Color accentColor) {
    final muscles = _getTargetMuscles();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 14,
            color: accentColor,
          ),
          const SizedBox(width: 6),
          Text(
            muscles,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          // Header (always visible, tappable)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content (collapsible)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 12,
              ),
              child: child,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupContent(
      bool isDark, Color textPrimary, Color accentColor) {
    final instructions = _getSetupInstructions();

    return Column(
      children: instructions.asMap().entries.map((entry) {
        final index = entry.key;
        final text = entry.value;

        return Padding(
          padding: EdgeInsets.only(bottom: index < instructions.length - 1 ? 8 : 0),
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
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
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
    );
  }

  Widget _buildTipsContent(
      bool isDark, Color textPrimary, Color accentColor) {
    final tips = _getFormTips();

    return Column(
      children: tips.asMap().entries.map((entry) {
        final index = entry.key;
        final text = entry.value;

        return Padding(
          padding: EdgeInsets.only(bottom: index < tips.length - 1 ? 8 : 0),
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
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
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
    );
  }

  // ---- Data helpers (extracted from exercise_info_sheet.dart) ----

  String _getTargetMuscles() {
    if (widget.exercise.primaryMuscle != null &&
        widget.exercise.primaryMuscle!.isNotEmpty) {
      return widget.exercise.primaryMuscle!;
    } else if (widget.exercise.muscleGroup != null &&
        widget.exercise.muscleGroup!.isNotEmpty) {
      return widget.exercise.muscleGroup!;
    }
    return 'Full Body';
  }

  List<String> _getSetupInstructions() {
    final name = widget.exercise.name.toLowerCase();

    if (name.contains('bench') || name.contains('press')) {
      return [
        'Set up the bench at the appropriate angle (flat, incline, or decline).',
        'Grip the bar slightly wider than shoulder-width.',
        'Plant your feet firmly on the ground.',
        'Retract your shoulder blades and maintain a slight arch in your lower back.',
        'Unrack the weight and position it directly above your chest.',
      ];
    } else if (name.contains('squat')) {
      return [
        'Position the bar on your upper back (not your neck).',
        'Stand with feet shoulder-width apart, toes slightly pointed out.',
        'Brace your core before descending.',
        'Keep your knees tracking over your toes.',
        'Descend until thighs are at least parallel to the floor.',
      ];
    } else if (name.contains('deadlift')) {
      return [
        'Stand with feet hip-width apart, bar over mid-foot.',
        'Grip the bar just outside your legs.',
        'Keep your back flat and chest up.',
        'Take the slack out of the bar before pulling.',
        'Drive through your heels and push hips forward.',
      ];
    } else if (name.contains('row')) {
      return [
        'Hinge at the hips with a slight knee bend.',
        'Keep your back flat and core engaged.',
        'Grip the weight with arms extended.',
        'Pull the weight toward your lower chest/upper abs.',
        'Squeeze your shoulder blades together at the top.',
      ];
    } else if (name.contains('curl')) {
      return [
        'Stand with feet shoulder-width apart.',
        'Grip the weight with palms facing up.',
        'Keep your elbows close to your sides.',
        'Curl the weight toward your shoulders.',
        'Lower with control to full arm extension.',
      ];
    } else if (name.contains('pull') &&
        (name.contains('up') || name.contains('down'))) {
      return [
        'Grip the bar slightly wider than shoulder-width.',
        'Hang with arms fully extended.',
        'Engage your lats before pulling.',
        'Pull your elbows down and back.',
        'Lower with control to full arm extension.',
      ];
    }

    return [
      'Set up your equipment and check your form in a mirror if available.',
      'Warm up with lighter weight first.',
      'Position yourself in the starting position.',
      'Focus on controlled movements throughout.',
      'Breathe consistently - exhale on exertion.',
    ];
  }

  List<String> _getFormTips() {
    final name = widget.exercise.name.toLowerCase();

    if (name.contains('bench') || name.contains('press')) {
      return [
        'Keep your wrists straight and stacked over your elbows.',
        'Lower the bar to your mid-chest with control.',
        'Press through your chest, not just your arms.',
        'Maintain tension at the bottom - no bouncing.',
        'Keep your feet planted and avoid lifting your hips.',
      ];
    } else if (name.contains('squat')) {
      return [
        'Keep your weight in your heels and mid-foot.',
        'Go as deep as your mobility allows with good form.',
        "Don't let your knees cave inward.",
        'Stand up by driving your hips forward.',
        'Keep your core braced throughout the movement.',
      ];
    } else if (name.contains('deadlift')) {
      return [
        'Never round your lower back.',
        'Keep the bar close to your body throughout.',
        "Lock out by squeezing your glutes, not hyperextending.",
        "Lower with control - don't drop the weight.",
        'Reset your position between each rep.',
      ];
    } else if (name.contains('row')) {
      return [
        'Initiate the pull with your back, not your arms.',
        'Keep your core tight to protect your lower back.',
        'Avoid jerky movements - stay controlled.',
        'Focus on the muscle contraction at the top.',
        'Keep your neck neutral - look at the floor.',
      ];
    } else if (name.contains('curl')) {
      return [
        'Keep your upper arms stationary.',
        "Don't swing the weight or use your back.",
        'Squeeze at the top of the movement.',
        'Lower slowly for maximum tension.',
        "Don't fully lock out at the bottom to maintain tension.",
      ];
    }

    return [
      'Focus on mind-muscle connection.',
      'Control the weight through the full range of motion.',
      'Avoid using momentum - let the target muscle do the work.',
      'If form breaks down, reduce the weight.',
      'Take your time and prioritize quality over quantity.',
    ];
  }
}
