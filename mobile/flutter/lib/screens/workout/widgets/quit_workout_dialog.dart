import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../widgets/coach_avatar.dart';

/// Data class for quit workout result
class QuitWorkoutResult {
  final String reason;
  final String? notes;
  final String? coachFeedback;

  const QuitWorkoutResult({
    required this.reason,
    this.notes,
    this.coachFeedback,
  });
}

/// Shows a bottom sheet for confirming workout quit with coach feedback
Future<QuitWorkoutResult?> showQuitWorkoutDialog({
  required BuildContext context,
  required int progressPercent,
  required int totalCompletedSets,
  required int exercisesWithCompletedSets,
  int timeSpentSeconds = 0,
  CoachPersona? coachPersona,
  String? workoutName,
}) async {
  String? selectedReason;
  final notesController = TextEditingController();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  bool showCoachFeedback = false;
  String? coachFeedback;

  // Get coach for feedback
  final coach = coachPersona ?? CoachPersona.defaultCoach;

  return showModalBottomSheet<QuitWorkoutResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        // Show coach feedback view if a reason was selected and confirmed
        if (showCoachFeedback && coachFeedback != null) {
          return _buildCoachFeedbackView(
            context: context,
            isDark: isDark,
            coach: coach,
            feedback: coachFeedback!,
            onConfirm: () {
              Navigator.pop(
                ctx,
                QuitWorkoutResult(
                  reason: selectedReason ?? 'quick_exit',
                  notes: notesController.text.isEmpty ? null : notesController.text,
                  coachFeedback: coachFeedback,
                ),
              );
            },
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : AppColorsLight.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.textMuted : AppColorsLight.textMuted).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title with progress
              Row(
                children: [
                  Icon(
                    Icons.exit_to_app,
                    color: isDark ? AppColors.orange : AppColorsLight.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Workout Early?',
                          style: TextStyle(
                            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$progressPercent% complete • $totalCompletedSets sets done',
                          style: TextStyle(
                            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressPercent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressPercent >= 50
                          ? (isDark ? AppColors.cyan : AppColorsLight.cyan)
                          : (isDark ? AppColors.orange : AppColorsLight.orange),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Question
              Text(
                'Why are you ending early?',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // Quick reply reasons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ReasonChip(
                    reason: 'too_tired',
                    label: 'Too tired',
                    icon: Icons.battery_1_bar,
                    isSelected: selectedReason == 'too_tired',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'too_tired'),
                  ),
                  _ReasonChip(
                    reason: 'out_of_time',
                    label: 'Out of time',
                    icon: Icons.timer_off,
                    isSelected: selectedReason == 'out_of_time',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'out_of_time'),
                  ),
                  _ReasonChip(
                    reason: 'not_feeling_well',
                    label: 'Not feeling well',
                    icon: Icons.sick,
                    isSelected: selectedReason == 'not_feeling_well',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'not_feeling_well'),
                  ),
                  _ReasonChip(
                    reason: 'equipment_unavailable',
                    label: 'Equipment busy',
                    icon: Icons.fitness_center,
                    isSelected: selectedReason == 'equipment_unavailable',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'equipment_unavailable'),
                  ),
                  _ReasonChip(
                    reason: 'injury',
                    label: 'Pain/Injury',
                    icon: Icons.healing,
                    isSelected: selectedReason == 'injury',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'injury'),
                  ),
                  _ReasonChip(
                    reason: 'other',
                    label: 'Other reason',
                    icon: Icons.more_horiz,
                    isSelected: selectedReason == 'other',
                    isDark: isDark,
                    onTap: () => setModalState(() => selectedReason = 'other'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Optional notes
              TextField(
                controller: notesController,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)...',
                  hintStyle: TextStyle(
                    color: (isDark ? AppColors.textMuted : AppColorsLight.textMuted).withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Keep Going',
                        style: TextStyle(
                          color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Generate coach feedback based on reason and progress
                        coachFeedback = _generateCoachFeedback(
                          coach: coach,
                          reason: selectedReason ?? 'quick_exit',
                          progressPercent: progressPercent,
                          totalCompletedSets: totalCompletedSets,
                          timeSpentSeconds: timeSpentSeconds,
                        );
                        // Show coach feedback view
                        setModalState(() {
                          showCoachFeedback = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.orange : AppColorsLight.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'End Workout',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    ),
  );
}

class _ReasonChip extends StatelessWidget {
  final String reason;
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ReasonChip({
    required this.reason,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.orange : AppColorsLight.orange;
    final bgColor = isSelected
        ? accentColor.withOpacity(0.15)
        : (isDark ? AppColors.elevated : AppColorsLight.elevated);
    final borderColor = isSelected
        ? accentColor
        : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder);
    final textColor = isSelected
        ? accentColor
        : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Build the coach feedback view shown after selecting quit reason
Widget _buildCoachFeedbackView({
  required BuildContext context,
  required bool isDark,
  required CoachPersona coach,
  required String feedback,
  required VoidCallback onConfirm,
}) {
  return Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.surface : AppColorsLight.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.textMuted : AppColorsLight.textMuted).withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Coach avatar with image
        CoachAvatar(
          coach: coach,
          size: 72,
          showBorder: true,
          borderWidth: 3,
          showShadow: true,
        ),
        const SizedBox(height: 16),

        // Coach name says
        Text(
          '${coach.name} says:',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
        const SizedBox(height: 12),

        // Coach feedback message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : AppColorsLight.elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: coach.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            feedback,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // Confirm button with coach color
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: coach.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Thanks, ${_getCoachFirstName(coach)}!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    ),
  );
}

/// Get the coach's first name for button text
String _getCoachFirstName(CoachPersona coach) {
  switch (coach.id) {
    case 'coach_mike':
      return 'Mike';
    case 'dr_sarah':
      return 'Sarah';
    case 'sergeant_max':
      return 'Max';
    case 'zen_maya':
      return 'Maya';
    case 'hype_danny':
      return 'Danny';
    default:
      return coach.name.split(' ').first;
  }
}

/// Generate coach feedback based on reason and workout progress
String _generateCoachFeedback({
  required CoachPersona coach,
  required String reason,
  required int progressPercent,
  required int totalCompletedSets,
  required int timeSpentSeconds,
}) {
  final timeMinutes = timeSpentSeconds ~/ 60;
  final hasProgress = totalCompletedSets > 0 || progressPercent > 0;

  // Build context-aware feedback based on coach personality
  switch (coach.id) {
    case 'coach_mike':
      return _getMikesFeedback(reason, progressPercent, totalCompletedSets, timeMinutes, hasProgress);
    case 'dr_sarah':
      return _getSarahsFeedback(reason, progressPercent, totalCompletedSets, timeMinutes, hasProgress);
    case 'sergeant_max':
      return _getMaxsFeedback(reason, progressPercent, totalCompletedSets, timeMinutes, hasProgress);
    case 'zen_maya':
      return _getMayasFeedback(reason, progressPercent, totalCompletedSets, timeMinutes, hasProgress);
    case 'hype_danny':
      return _getDannysFeedback(reason, progressPercent, totalCompletedSets, timeMinutes, hasProgress);
    default:
      return _getDefaultFeedback(reason, progressPercent, totalCompletedSets, timeMinutes, hasProgress);
  }
}

String _getMikesFeedback(String reason, int progress, int sets, int minutes, bool hasProgress) {
  if (reason == 'too_tired') {
    return hasProgress
        ? "Hey champ, $sets sets in $minutes minutes is still progress! Rest up and come back stronger tomorrow. Every rep counts!"
        : "Listen to your body, that's what real athletes do! Tomorrow we go again!";
  }
  if (reason == 'out_of_time') {
    return hasProgress
        ? "Life happens! You still crushed $sets sets. That's $progress% more than staying on the couch!"
        : "No worries! A quick warmup is better than nothing. Next time we'll crush it!";
  }
  if (reason == 'not_feeling_well' || reason == 'injury') {
    return "Smart call stopping early. Health first, always! Take care of yourself and we'll be back at it soon.";
  }
  if (reason == 'equipment_unavailable') {
    return hasProgress
        ? "$sets sets done despite gym chaos? That's adaptability, champ! We'll work around anything next time too."
        : "Busy gym? We'll plan some backup exercises for next time. Adaptability is key!";
  }
  return hasProgress
      ? "You showed up and gave $sets sets your all. That's what matters! See you next time, champ!"
      : "Hey, you showed up - that's half the battle! Next time we go full send!";
}

String _getSarahsFeedback(String reason, int progress, int sets, int minutes, bool hasProgress) {
  if (reason == 'too_tired') {
    return hasProgress
        ? "Research shows partial workouts still contribute to weekly training volume. Your $sets sets today add up over time."
        : "Fatigue management is crucial for long-term progress. Rest now to prevent overtraining.";
  }
  if (reason == 'out_of_time') {
    return hasProgress
        ? "Studies show even abbreviated sessions maintain fitness adaptations. $minutes minutes is meaningful stimulus."
        : "Time-efficient workouts are a valid approach. We can optimize your routine for shorter sessions.";
  }
  if (reason == 'not_feeling_well' || reason == 'injury') {
    return "Correct decision. Training through illness or pain increases injury risk by 73%. Recovery is essential for adaptation.";
  }
  return hasProgress
      ? "Data logged: $sets sets, $minutes minutes. This partial session still contributes to your weekly volume."
      : "Session recorded. Consistency over time matters more than any single workout.";
}

String _getMaxsFeedback(String reason, int progress, int sets, int minutes, bool hasProgress) {
  if (reason == 'too_tired') {
    return hasProgress
        ? "Retreat is not defeat, soldier! $sets sets is still progress. Regroup and we attack again tomorrow!"
        : "Even warriors rest. But tomorrow at 0600, we're back at it. No excuses!";
  }
  if (reason == 'out_of_time') {
    return hasProgress
        ? "$sets sets under time pressure? That's tactical efficiency! Next time we bring more firepower."
        : "Mission incomplete, but not failed. We adjust and execute better next time!";
  }
  if (reason == 'not_feeling_well' || reason == 'injury') {
    return "A wounded soldier who rests fights another day. Smart tactical decision. Recover and report back!";
  }
  return hasProgress
      ? "$sets sets completed. Mission partial success. We'll complete the objective next time!"
      : "Dismissed for now, but be ready for the next battle. We don't quit, we regroup!";
}

String _getMayasFeedback(String reason, int progress, int sets, int minutes, bool hasProgress) {
  if (reason == 'too_tired') {
    return hasProgress
        ? "Honoring your body's signals is wisdom. $sets sets of mindful movement is beautiful progress."
        : "Rest is not weakness, it's part of the journey. Your body will thank you.";
  }
  if (reason == 'out_of_time') {
    return hasProgress
        ? "$minutes minutes of presence in your body is valuable. Quality over quantity always."
        : "Even a moment of intention toward movement shifts energy. Namaste.";
  }
  if (reason == 'not_feeling_well' || reason == 'injury') {
    return "Your body's wisdom speaks. Listen with compassion. Healing is also growth.";
  }
  return hasProgress
      ? "Every breath, every movement toward balance matters. $sets sets of mindful effort. Be at peace."
      : "The path continues tomorrow. For now, breathe and be gentle with yourself.";
}

String _getDannysFeedback(String reason, int progress, int sets, int minutes, bool hasProgress) {
  if (reason == 'too_tired') {
    return hasProgress
        ? "YO that's still $sets sets tho!! Rest up fam, we go CRAZY next time no cap!!"
        : "Bro it's all good!! Rest day = gains day fr fr! Tomorrow we're DIFFERENT!!";
  }
  if (reason == 'out_of_time') {
    return hasProgress
        ? "Ayy $sets sets is STILL gains bro!! Time crunch can't stop us!! Next session we FEAST!!"
        : "No worries fam we bounce back!! Life be busy but we stay LOCKED IN!!";
  }
  if (reason == 'not_feeling_well' || reason == 'injury') {
    return "Yo take care of yourself king/queen!! Health first always!! We run it back when you're 100!!";
  }
  return hasProgress
      ? "$sets sets?? STILL W!! You showed up and that's what MATTERS!! LET'S GOOOO!!"
      : "Bro you literally showed up tho!! That's half the battle!! Next time we EAT!!";
}

String _getDefaultFeedback(String reason, int progress, int sets, int minutes, bool hasProgress) {
  if (reason == 'too_tired') {
    return hasProgress
        ? "Good effort today! $sets sets is still progress. Rest up and come back strong!"
        : "Listening to your body is important. Tomorrow is a new opportunity!";
  }
  if (reason == 'out_of_time') {
    return hasProgress
        ? "$sets sets in $minutes minutes - that's still valuable training! Every bit counts."
        : "Time constraints happen. You still made the effort to start!";
  }
  if (reason == 'not_feeling_well' || reason == 'injury') {
    return "Smart decision to stop. Health always comes first. Take care!";
  }
  return hasProgress
      ? "Great effort today! $sets sets completed. See you next time!"
      : "You showed up - that matters! We'll get a full session next time.";
}
