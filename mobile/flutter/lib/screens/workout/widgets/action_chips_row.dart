/// Action Chips Row Widget
///
/// Horizontal scrollable row of action chips for the active workout screen.
/// Inspired by MacroFactor Workouts 2026 design.
///
/// Chips include: AI (with notification dot), Info, Warm Up, Targets, Swap, Note, Superset, L/R
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/workout_design.dart';

/// Data for an action chip
class ActionChipData {
  final String id;
  final String label;
  final IconData? icon;
  final bool hasNotification;
  final bool isToggle;
  final bool isActive;

  const ActionChipData({
    required this.id,
    required this.label,
    this.icon,
    this.hasNotification = false,
    this.isToggle = false,
    this.isActive = false,
  });

  ActionChipData copyWith({
    String? id,
    String? label,
    IconData? icon,
    bool? hasNotification,
    bool? isToggle,
    bool? isActive,
  }) {
    return ActionChipData(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      hasNotification: hasNotification ?? this.hasNotification,
      isToggle: isToggle ?? this.isToggle,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Horizontal scrollable row of action chips
class ActionChipsRow extends StatelessWidget {
  /// List of chip configurations
  final List<ActionChipData> chips;

  /// Callback when a chip is tapped
  final void Function(String chipId) onChipTapped;

  /// Whether to show the AI chip with special styling
  final bool showAiChip;

  /// Whether AI has a pending suggestion (shows notification dot)
  final bool hasAiNotification;

  /// Callback for AI chip tap
  final VoidCallback? onAiChipTapped;

  const ActionChipsRow({
    super.key,
    required this.chips,
    required this.onChipTapped,
    this.showAiChip = true,
    this.hasAiNotification = false,
    this.onAiChipTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WorkoutDesign.chipHeight + 8, // Add padding
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: WorkoutDesign.paddingMedium,
          vertical: 4,
        ),
        itemCount: chips.length + (showAiChip ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          // First chip is AI if enabled
          if (showAiChip && index == 0) {
            return _AiChip(
              hasNotification: hasAiNotification,
              onTap: onAiChipTapped,
            );
          }

          final chipIndex = showAiChip ? index - 1 : index;
          final chip = chips[chipIndex];

          return _ActionChip(
            data: chip,
            onTap: () => onChipTapped(chip.id),
          );
        },
      ),
    );
  }
}

/// Individual action chip widget
class _ActionChip extends StatelessWidget {
  final ActionChipData data;
  final VoidCallback onTap;

  const _ActionChip({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = data.isActive;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: WorkoutDesign.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? WorkoutDesign.surface : Colors.white),
          borderRadius: BorderRadius.circular(WorkoutDesign.radiusRound),
          border: Border.all(
            color: isDark ? WorkoutDesign.border : WorkoutDesign.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.icon != null) ...[
              Icon(
                data.icon,
                size: 16,
                color: isActive
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark
                        ? WorkoutDesign.textSecondary
                        : WorkoutDesign.textSecondaryLight),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              data.label,
              style: WorkoutDesign.chipStyle.copyWith(
                color: isActive
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark
                        ? WorkoutDesign.textPrimary
                        : WorkoutDesign.textPrimaryLight),
              ),
            ),
            if (data.hasNotification) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: WorkoutDesign.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Special AI chip with sparkle icon and notification dot
class _AiChip extends StatelessWidget {
  final bool hasNotification;
  final VoidCallback? onTap;

  const _AiChip({
    required this.hasNotification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        height: WorkoutDesign.chipHeight,
        width: WorkoutDesign.chipHeight, // Square chip for icon only
        decoration: BoxDecoration(
          color: isDark ? WorkoutDesign.surface : Colors.white,
          borderRadius: BorderRadius.circular(WorkoutDesign.radiusRound),
          border: Border.all(
            color: isDark ? WorkoutDesign.border : WorkoutDesign.borderLight,
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 18,
              color: isDark
                  ? WorkoutDesign.textSecondary
                  : WorkoutDesign.textSecondaryLight,
            ),
            if (hasNotification)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: WorkoutDesign.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pre-configured chips for common workout actions
class WorkoutActionChips {
  static const info = ActionChipData(
    id: 'info',
    label: 'Info',
    icon: Icons.bar_chart,
  );

  static const warmUp = ActionChipData(
    id: 'warmup',
    label: 'Warm Up',
    icon: Icons.whatshot_outlined,
  );

  static const targets = ActionChipData(
    id: 'targets',
    label: 'Targets',
    icon: Icons.track_changes,
  );

  static const swap = ActionChipData(
    id: 'swap',
    label: 'Swap',
    icon: Icons.swap_horiz,
  );

  static const note = ActionChipData(
    id: 'note',
    label: 'Note',
    icon: Icons.sticky_note_2_outlined,
  );

  static const superset = ActionChipData(
    id: 'superset',
    label: 'Superset',
    icon: Icons.repeat,
  );

  static const equipment = ActionChipData(
    id: 'equipment',
    label: 'Equipment',
    icon: Icons.fitness_center,
  );

  static const timer = ActionChipData(
    id: 'timer',
    label: 'Timer',
    icon: Icons.timer_outlined,
  );

  static const history = ActionChipData(
    id: 'history',
    label: 'History',
    icon: Icons.history,
  );

  static const video = ActionChipData(
    id: 'video',
    label: 'Video',
    icon: Icons.play_circle_outline,
  );

  static const increments = ActionChipData(
    id: 'increments',
    label: 'Increments',
    icon: Icons.tune,
  );

  static const reorder = ActionChipData(
    id: 'reorder',
    label: 'Reorder',
    icon: Icons.swap_vert,
  );

  /// 3-dot "More" menu for History, Increments, etc.
  static const more = ActionChipData(
    id: 'more',
    label: '',
    icon: Icons.more_horiz,
  );

  static ActionChipData leftRight({bool isActive = false}) => ActionChipData(
        id: 'lr',
        label: 'L/R',
        icon: Icons.swap_vert,
        isToggle: true,
        isActive: isActive,
      );

  /// Get default chips list
  /// Order: Superset, Reorder, Info, then others
  /// Note is now in the bottom quick actions row
  static List<ActionChipData> defaultChips({bool showLR = false}) => [
        superset,
        reorder,
        info,
        warmUp,
        targets,
        swap,
        history,
        increments,
        if (showLR) leftRight(),
      ];
}
