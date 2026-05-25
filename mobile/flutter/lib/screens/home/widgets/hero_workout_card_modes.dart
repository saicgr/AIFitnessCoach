part of 'hero_workout_card.dart';

// =============================================================================
// Smart-mode rendering for hero workout card
// =============================================================================
//
// Adds per-`WorkoutCardMode` renderers for the modes added in §1 of the home
// v2 plan. The pre-existing render (gradient + image + title + meta + Play
// button + missed/completed overlays) already serves `scheduledNotStarted`,
// `completedToday`, `noPlan`, `nextWorkoutInFuture`, `nothingScheduled`, and
// `restDayWithCoach` well, so those modes intentionally fall through to it.
//
// The modes handled here are the ones that need a distinct primary CTA,
// pill, body line, or dual-button layout: `inProgress`, `windDown`,
// `recoveryLighter`, `cycleAdjusted`, `equipmentMismatch`, `fastingActive`,
// `preWorkoutFuelGap`, `comebackSession`, `prOpportunityToday`,
// `overtrainingAlert`, `vacationOrPaused`, `postWorkoutRefuel`, `bonus`,
// `yesterdayMissedRecovery`, `error`, `loading`.
//
// Each renderer feeds the shared `_HeroBase` skeleton with:
//   pill / chip / body / primary button / optional secondary button / askCoach
//
// Action wiring keeps to the constraint: real `/app_router` paths only.
// Variant-swap CTAs surface a snackbar today (Agent B owns the backend
// variant generator), per scope instructions.

extension _HeroSmartModeExt on _HeroWorkoutCardState {
  /// Returns a smart-mode card override, or null if the mode falls through
  /// to the legacy rendering (`scheduledNotStarted` / `completedToday` /
  /// `noPlan` / `nextWorkoutInFuture` / `nothingScheduled` / `restDayWithCoach`).
  Widget? buildSmartCardOverride(BuildContext context, WorkoutCardMode mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        ref.watch(accentColorProvider).getColor(isDark);
    final workout = widget.workout;

    switch (mode) {
      case WorkoutCardMode.loading:
        return _HeroBase(
          isDark: isDark,
          pill: 'LOADING',
          pillColor: accent.withValues(alpha: 0.4),
          body: 'Building today’s plan…',
          primary: const _PrimaryButton(label: '—'),
          inCarousel: widget.inCarousel,
          dimmed: true,
        );

      case WorkoutCardMode.error:
        return _HeroBase(
          isDark: isDark,
          pill: 'OFFLINE',
          pillColor: AppColors.error,
          body: 'Couldn’t load today’s workout. Tap to retry.',
          primary: _PrimaryButton(
            label: 'RETRY',
            onTap: () {
              HapticService.medium();
              ref
                  .read(todayWorkoutProvider.notifier)
                  .invalidateAndRefresh();
            },
            accent: accent,
          ),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.inProgress:
        return _HeroBase(
          isDark: isDark,
          pill: 'LIVE',
          pillColor: AppColors.error,
          body:
              '${workout.exerciseCount} exercises · ${workout.formattedDurationShort}',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardResume,
            icon: Icons.play_arrow,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            accent: accent,
          ),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.vacationOrPaused:
        return _HeroBase(
          isDark: isDark,
          pill: 'PAUSED',
          pillColor: AppColors.textMuted,
          body: 'Plan paused. Resume when you’re ready.',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardResumeNow,
            onTap: () {
              HapticService.medium();
              context.push('/settings/vacation-mode');
            },
            accent: accent,
            outline: true,
          ),
          inCarousel: widget.inCarousel,
          dimmed: true,
        );

      case WorkoutCardMode.windDown:
        return _HeroBase(
          isDark: isDark,
          pill: 'TOMORROW · WIND-DOWN',
          pillColor: accent.withValues(alpha: 0.5),
          body: 'Sleep first. Tomorrow’s session will be waiting.',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardSeeTomorrowSPlan,
            onTap: () {
              HapticService.selection();
              context.push('/workouts');
            },
            accent: accent,
            outline: true,
          ),
          secondary: _SecondaryGhost(
            label: AppLocalizations.of(context).suggestedReplyChipsStartAnyway,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            isDark: isDark,
          ),
          askCoach: _modeAskCoach(workout, 'windDown'),
          inCarousel: widget.inCarousel,
          dimmed: true,
        );

      case WorkoutCardMode.recoveryLighter:
        return _HeroBase(
          isDark: isDark,
          pill: 'LIGHTER SUGGESTED',
          pillColor: Colors.amber.shade700,
          body: 'Sleep was rough. Try a lighter variant today?',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardStartAsPlanned,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            accent: accent,
            outline: true,
          ),
          secondary: _SecondaryFilled(
            label: AppLocalizations.of(context).suggestedReplyChipsSwitchToLighter,
            onTap: () => _showVariantPending(context, 'lighter'),
            accent: accent,
            isDark: isDark,
          ),
          askCoach: _modeAskCoach(workout, 'recoveryLighter'),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.cycleAdjusted:
        return _HeroBase(
          isDark: isDark,
          pill: 'LUTEAL',
          pillColor: Colors.purple.shade400,
          body: 'Luteal phase — moderate intensity may feel better.',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardStartAsPlanned,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            accent: accent,
            outline: true,
          ),
          secondary: _SecondaryFilled(
            label: AppLocalizations.of(context).heroWorkoutCardSwitchToModerate,
            onTap: () => _showVariantPending(context, 'moderate'),
            accent: accent,
            isDark: isDark,
          ),
          askCoach: _modeAskCoach(workout, 'cycleAdjusted'),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.equipmentMismatch:
        return _HeroBase(
          isDark: isDark,
          pill: 'EQUIPMENT GAP',
          pillColor: Colors.orange.shade700,
          body: 'Some equipment isn’t in your current gym profile.',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardBodyweightVariant,
            onTap: () => _showVariantPending(context, 'bodyweight'),
            accent: accent,
          ),
          secondary: _SecondaryGhost(
            label: AppLocalizations.of(context).heroWorkoutCardSwitchGymProfile,
            onTap: () {
              HapticService.selection();
              context.push('/settings/equipment');
            },
            isDark: isDark,
          ),
          askCoach: _modeAskCoach(workout, 'equipmentMismatch'),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.fastingActive:
        return _HeroBase(
          isDark: isDark,
          pill: 'FASTED',
          pillColor: Colors.teal.shade600,
          body:
              'Fasted training is fine — keep intensity moderate, refuel within 30 min after.',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardStartFasted,
            icon: Icons.play_arrow,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            accent: accent,
          ),
          secondary: _SecondaryGhost(
            label: AppLocalizations.of(context).heroWorkoutCardDelayUntilFastEnds,
            onTap: () {
              HapticService.selection();
              context.push('/fasting');
            },
            isDark: isDark,
          ),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.preWorkoutFuelGap:
        return _HeroBase(
          isDark: isDark,
          pill: 'FUEL GAP',
          pillColor: Colors.amber.shade700,
          body: 'Last meal was a while ago — eat ~200kcal carbs?',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardLogASnack,
            onTap: () {
              HapticService.selection();
              context.push('/nutrition');
            },
            accent: accent,
            outline: true,
          ),
          secondary: _SecondaryFilled(
            label: AppLocalizations.of(context).suggestedReplyChipsStartAnyway,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            accent: accent,
            isDark: isDark,
          ),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.comebackSession:
        return _HeroBase(
          isDark: isDark,
          pill: 'COMEBACK',
          pillColor: accent,
          body:
              'First session for this muscle group in a while — ease in.',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardStartLighter,
            onTap: () => _showVariantPending(context, 'lighter'),
            accent: accent,
          ),
          secondary: _SecondaryGhost(
            label: AppLocalizations.of(context).heroWorkoutCardStartAsPlanned2,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            isDark: isDark,
          ),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.prOpportunityToday:
        return _HeroBase(
          isDark: isDark,
          pill: 'PR WINDOW',
          pillColor: Colors.amber.shade700,
          chip: 'PR WINDOW',
          body: 'You’re close on a top lift today — push for it?',
          primary: _PrimaryButton(
            label: 'START',
            icon: Icons.play_arrow,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            accent: accent,
          ),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.overtrainingAlert:
        return _HeroBase(
          isDark: isDark,
          pill: 'BODY ASKS REST',
          pillColor: AppColors.error,
          body:
              '5 hard days, sleep dropping. Today’s an investment in next week.',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardTakeRest,
            onTap: () => _markRestDay(context),
            accent: accent,
          ),
          secondary: _SecondaryGhost(
            label: AppLocalizations.of(context).suggestedReplyChipsStartAnyway,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            isDark: isDark,
          ),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.postWorkoutRefuel:
        return _HeroBase(
          isDark: isDark,
          pill: 'REFUEL WINDOW',
          pillColor: AppColors.success,
          body: '30-min refuel window — protein + carbs locks in the work.',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardLogPostWorkoutMeal,
            onTap: () {
              HapticService.selection();
              context.push('/nutrition');
            },
            accent: accent,
          ),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.bonus:
        return _HeroBase(
          isDark: isDark,
          pill: 'BONUS',
          pillColor: accent.withValues(alpha: 0.6),
          body: 'Got 20 min? Squeeze in a quick session.',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardQuickWorkout,
            onTap: () {
              HapticService.medium();
              // Reuse the existing quick workout sheet path via /workouts —
              // there's no dedicated standalone route.
              context.push('/workouts');
            },
            accent: accent,
            outline: true,
          ),
          inCarousel: widget.inCarousel,
          dimmed: true,
        );

      case WorkoutCardMode.yesterdayMissedRecovery:
        return _HeroBase(
          isDark: isDark,
          pill: 'YESTERDAY',
          pillColor: Colors.amber.shade700,
          body: 'Yesterday’s session is still open. Move it to today?',
          primary: _PrimaryButton(
            label: AppLocalizations.of(context).heroWorkoutCardMoveToToday,
            onTap: () {
              HapticService.medium();
              context.push('/workouts');
            },
            accent: accent,
          ),
          secondary: _SecondaryGhost(
            label: AppLocalizations.of(context).onboardingSkip,
            onTap: () {
              HapticService.selection();
            },
            isDark: isDark,
          ),
          askCoach: _modeAskCoach(workout, 'yesterdayMissedRecovery'),
          inCarousel: widget.inCarousel,
        );

      // Modes that fall through to the legacy rendering — let the existing
      // build path handle them so we don't lose the polished image / gradient
      // / overflow-menu / completed-overlay treatments already shipped.
      case WorkoutCardMode.scheduledNotStarted:
      case WorkoutCardMode.completedToday:
      case WorkoutCardMode.noPlan:
      case WorkoutCardMode.nextWorkoutInFuture:
      case WorkoutCardMode.nothingScheduled:
      case WorkoutCardMode.restDayWithCoach:
        return null;
    }
  }

  Widget _modeAskCoach(Workout workout, String mode) {
    return AskCoachButton(
      contextLabel: 'Workout card · $mode',
      statSnapshot: {
        'mode': mode,
        'workout_id': workout.id,
        'workout_name': workout.name,
      },
    );
  }

  void _showVariantPending(BuildContext context, String which) {
    HapticService.selection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$which variant coming with the backend variant generator'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 120, left: 16, right: 16),
      ),
    );
  }

  Future<void> _markRestDay(BuildContext context) async {
    HapticService.medium();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).heroWorkoutCardMarkedAsARest),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 120, left: 16, right: 16),
      ),
    );
  }
}

// =============================================================================
// Shared skeleton + button primitives
// =============================================================================

class _HeroBase extends StatelessWidget {
  final bool isDark;
  final String pill;
  final Color pillColor;
  final String? chip;
  final String body;
  final _PrimaryButton primary;
  final Widget? secondary;
  final Widget? askCoach;
  final bool inCarousel;
  final bool dimmed;

  const _HeroBase({
    required this.isDark,
    required this.pill,
    required this.pillColor,
    required this.body,
    required this.primary,
    this.chip,
    this.secondary,
    this.askCoach,
    this.inCarousel = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: dimmed ? 0.55 : 0.4)
            : Colors.white.withValues(alpha: dimmed ? 0.7 : 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pill,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              if (chip != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: pillColor.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    chip!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: pillColor,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (askCoach != null) askCoach!,
            ],
          ),
          const SizedBox(height: 24),
          Text(
            body,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          primary,
          if (secondary != null) ...[
            const SizedBox(height: 8),
            secondary!,
          ],
        ],
      ),
    );

    if (inCarousel) return card;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: card,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? accent;
  final bool outline;

  const _PrimaryButton({
    required this.label,
    this.icon,
    this.onTap,
    this.accent,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accent ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: double.infinity,
      child: outline
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: icon == null
                  ? const SizedBox.shrink()
                  : Icon(icon, size: 18),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: icon == null
                  ? const SizedBox.shrink()
                  : Icon(icon, size: 20),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: color.withValues(alpha: 0.4),
              ),
            ),
    );
  }
}

class _SecondaryGhost extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _SecondaryGhost({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _SecondaryFilled extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final bool isDark;

  const _SecondaryFilled({
    required this.label,
    required this.onTap,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
