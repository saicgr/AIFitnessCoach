// Easy tier — AI-coach secondary chip.
//
// Small accent-OUTLINED chip — intentionally visually lighter than the
// primary Log-set CTA so the two don't compete. Tap opens the shared
// `CoachSheet` with beginner-tuned quick replies. Streaming pipeline,
// LangGraph Workout-agent routing, and `action_data` handlers (swap
// exercise, adjust weight, add/remove set) are shared with Advanced —
// no divergence.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/models/exercise.dart';
import '../../shared/coach_sheet.dart'
    show showCoachSheet, kEasyCoachQuickReplies;

/// Re-exported for callers that want to reference the beginner copy list
/// (tests, analytics taxonomy).
const List<String> easyBeginnerQuickReplies = kEasyCoachQuickReplies;

class EasyChatPill extends ConsumerWidget {
  final WorkoutExercise currentExercise;
  final int currentSetNumber;
  final int totalSets;

  const EasyChatPill({
    super.key,
    required this.currentExercise,
    required this.currentSetNumber,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Semantics(
      label: 'Ask your coach',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticService.instance.tap();
            showCoachSheet(
              context: context,
              exercise: currentExercise,
              quickReplies: kEasyCoachQuickReplies,
            );
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_outlined, color: accent, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Ask coach',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
