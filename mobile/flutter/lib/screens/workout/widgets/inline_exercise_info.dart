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
import '../shared/exercise_instruction_copy.dart';

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

  // Setup + form tips delegate to the shared, equipment-aware helpers in
  // exercise_instruction_copy.dart — passing exercise.equipment so bodyweight
  // and plyometric variants ("Kabaddi Squat Jumps", pistol, sissy, jump
  // squats) don't get routed to barbell-back-squat copy.
  List<String> _getSetupInstructions() => getSetupSteps(
        widget.exercise.name,
        equipment: widget.exercise.equipment,
      );

  List<String> _getFormTips() => getFormTips(
        widget.exercise.name,
        equipment: widget.exercise.equipment,
      );
}
