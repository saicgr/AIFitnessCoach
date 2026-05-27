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

    final l10n = AppLocalizations.of(context);

    switch (mode) {
      case WorkoutCardMode.loading:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillLoading,
          pillColor: accent.withValues(alpha: 0.4),
          body: l10n.heroModesBodyLoading,
          primary: const _PrimaryButton(label: '—'),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
          dimmed: true,
        );

      case WorkoutCardMode.error:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillOffline,
          pillColor: AppColors.error,
          body: l10n.heroModesBodyOffline,
          primary: _PrimaryButton(
            label: l10n.heroModesActionRetry,
            onTap: () {
              HapticService.medium();
              ref
                  .read(todayWorkoutProvider.notifier)
                  .invalidateAndRefresh();
            },
            accent: accent,
          ),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.inProgress:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillLive,
          pillColor: AppColors.error,
          body:
              '${workout.exerciseCount} exercises · ${workout.formattedDurationShort}',
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardResume,
            icon: Icons.play_arrow,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            accent: accent,
          ),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.vacationOrPaused:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillPaused,
          pillColor: AppColors.textMuted,
          body: l10n.heroModesBodyPaused,
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardResumeNow,
            onTap: () {
              HapticService.medium();
              context.push('/settings/vacation-mode');
            },
            accent: accent,
            outline: true,
          ),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
          dimmed: true,
        );

      case WorkoutCardMode.windDown:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillWindDown,
          pillColor: accent.withValues(alpha: 0.5),
          body: l10n.heroModesBodyWindDown,
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardSeeTomorrowSPlan,
            onTap: () {
              HapticService.selection();
              context.push('/workouts');
            },
            accent: accent,
            outline: true,
          ),
          secondary: _SecondaryGhost(
            label: l10n.suggestedReplyChipsStartAnyway,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            isDark: isDark,
          ),
          askCoach: _modeAskCoach(workout, 'windDown'),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
          dimmed: true,
        );

      case WorkoutCardMode.recoveryLighter:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillLighter,
          pillColor: AppColors.warning,
          body: l10n.heroModesBodyLighter,
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
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.cycleAdjusted:
        // Falls through to the default illustrated card render — which
        // already shows `_PhaseRecommendationChip` ("Luteal · moderate")
        // on the today card via the `showPhaseChip` logic in
        // hero_workout_card.dart. Prior override replaced the whole card
        // with a near-empty advice surface + a "Switch to moderate" button
        // that only fired a "coming soon" snackbar — dishonest CTA + hid
        // the actual workout. Re-introduce the override only when a real
        // variant-swap backend is wired.
        return null;

      case WorkoutCardMode.equipmentMismatch:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillEquipmentGap,
          pillColor: AppColors.orange,
          body: l10n.heroModesBodyEquipmentGap,
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardBodyweightVariant,
            onTap: () => _showVariantPending(context, 'bodyweight'),
            accent: accent,
          ),
          secondary: _SecondaryGhost(
            label: l10n.heroWorkoutCardSwitchGymProfile,
            onTap: () {
              HapticService.selection();
              context.push('/settings/equipment');
            },
            isDark: isDark,
          ),
          askCoach: _modeAskCoach(workout, 'equipmentMismatch'),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.fastingActive:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillFasted,
          pillColor: AppColors.info,
          body: l10n.heroModesBodyFasted,
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardStartFasted,
            icon: Icons.play_arrow,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            accent: accent,
          ),
          secondary: _SecondaryGhost(
            label: l10n.heroWorkoutCardDelayUntilFastEnds,
            onTap: () {
              HapticService.selection();
              context.push('/fasting');
            },
            isDark: isDark,
          ),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.preWorkoutFuelGap:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillFuelGap,
          pillColor: AppColors.warning,
          body: l10n.heroModesBodyFuelGap,
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardLogASnack,
            onTap: () {
              HapticService.selection();
              context.push('/nutrition');
            },
            accent: accent,
            outline: true,
          ),
          secondary: _SecondaryFilled(
            label: l10n.suggestedReplyChipsStartAnyway,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            accent: accent,
            isDark: isDark,
          ),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.comebackSession:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillComeback,
          pillColor: accent,
          body: l10n.heroModesBodyComeback,
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardStartLighter,
            onTap: () => _showVariantPending(context, 'lighter'),
            accent: accent,
          ),
          secondary: _SecondaryGhost(
            label: l10n.heroWorkoutCardStartAsPlanned2,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            isDark: isDark,
          ),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.prOpportunityToday:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillPrWindow,
          pillColor: AppColors.warning,
          chip: l10n.heroModesPillPrWindow,
          body: l10n.heroModesBodyPrWindow,
          primary: _PrimaryButton(
            label: l10n.heroModesActionStart,
            icon: Icons.play_arrow,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            accent: accent,
          ),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.overtrainingAlert:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillBodyAsksRest,
          pillColor: AppColors.error,
          body: l10n.heroModesBodyBodyAsksRest,
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardTakeRest,
            onTap: () => _markRestDay(context),
            accent: accent,
          ),
          secondary: _SecondaryGhost(
            label: l10n.suggestedReplyChipsStartAnyway,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
            isDark: isDark,
          ),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.postWorkoutRefuel:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillRefuelWindow,
          pillColor: AppColors.success,
          body: l10n.heroModesBodyRefuelWindow,
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardLogPostWorkoutMeal,
            onTap: () {
              HapticService.selection();
              context.push('/nutrition');
            },
            accent: accent,
          ),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
        );

      case WorkoutCardMode.bonus:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillBonus,
          pillColor: accent.withValues(alpha: 0.6),
          body: l10n.heroModesBodyBonus,
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardQuickWorkout,
            onTap: () {
              HapticService.medium();
              // Reuse the existing quick workout sheet path via /workouts;
              // no dedicated standalone route.
              context.push('/workouts');
            },
            accent: accent,
            outline: true,
          ),
          background: _buildBackground(isDark),
          inCarousel: widget.inCarousel,
          dimmed: true,
        );

      case WorkoutCardMode.yesterdayMissedRecovery:
        return _HeroBase(
          isDark: isDark,
          pill: l10n.heroModesPillYesterday,
          pillColor: AppColors.warning,
          body: l10n.heroModesBodyYesterday,
          primary: _PrimaryButton(
            label: l10n.heroWorkoutCardMoveToToday,
            onTap: () {
              HapticService.medium();
              context.push('/workouts');
            },
            accent: accent,
          ),
          secondary: _SecondaryGhost(
            label: l10n.onboardingSkip,
            onTap: () {
              HapticService.selection();
            },
            isDark: isDark,
          ),
          askCoach: _modeAskCoach(workout, 'yesterdayMissedRecovery'),
          background: _buildBackground(isDark),
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
        content: Text(AppLocalizations.of(context)!.heroWorkoutCardModesVariantComingWithThe(which)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsetsDirectional.only(bottom: 120, start: 16, end: 16),
      ),
    );
  }

  Future<void> _markRestDay(BuildContext context) async {
    HapticService.medium();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).heroWorkoutCardMarkedAsARest),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsetsDirectional.only(bottom: 120, start: 16, end: 16),
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

  /// Optional illustrated backdrop — feed `_buildBackground(isDark)` from
  /// the host card state so smart-mode cards (luteal, fasting, equipment
  /// mismatch, etc.) keep the same workout illustration the default card
  /// shows. When null, falls back to a solid tinted surface.
  final Widget? background;

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
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    // Tighter gaps + smaller minHeight: prior values (minHeight 220, 24/20/8
    // inner gaps) felt bloated for what is fundamentally a 2-line message +
    // 2 buttons. New rhythm matches the rest of the home cards.
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pill,
                  style: const TextStyle(
                    fontSize: 11,
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
          const SizedBox(height: 14),
          Text(
            body,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          primary,
          if (secondary != null) ...[
            const SizedBox(height: 6),
            secondary!,
          ],
        ],
      ),
    );

    // Solid-surface fallback (no illustration available).
    final surfaceColor = isDark
        ? Colors.black.withValues(alpha: dimmed ? 0.55 : 0.4)
        : Colors.white.withValues(alpha: dimmed ? 0.7 : 0.9);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final borderRadius = BorderRadius.circular(24);

    Widget card;
    if (background != null) {
      // Illustrated path — backdrop layered behind a readability gradient,
      // mirroring the default card render in hero_workout_card.dart so
      // smart-mode cards stop looking like a separate widget family.
      card = Container(
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            children: [
              Positioned.fill(child: background!),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      // Match the lighter gradient used by the default
                      // illustrated card render (hero_workout_card.dart)
                      // so the workout figure stays visible. Prior stops
                      // (0.55/0.75/0.92 light-mode) were washing the
                      // illustration out to plain white.
                      colors: isDark
                          ? [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.black.withValues(alpha: 0.3),
                              Colors.black.withValues(alpha: 0.85),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.5),
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0.9),
                            ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              content,
            ],
          ),
        ),
      );
    } else {
      card = Container(
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: borderRadius,
          border: Border.all(color: borderColor),
        ),
        child: content,
      );
    }

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
