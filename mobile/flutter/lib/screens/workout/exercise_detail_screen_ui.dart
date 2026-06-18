part of 'exercise_detail_screen.dart';

/// UI builder methods extracted from _ExerciseDetailScreenState
extension _ExerciseDetailScreenStateUI on _ExerciseDetailScreenState {

  Widget _buildStatsTabContent(Color textMuted) {
    final exerciseName = widget.exercise.name;
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseName));
    final prsAsync = ref.watch(exercisePRsProvider(exerciseName));
    final timeRange = ref.watch(exerciseHistoryTimeRangeProvider);
    final chartType = ref.watch(exerciseChartTypeProvider);

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Error loading stats: $error')),
      ),
      data: (history) {
        if (!history.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.timeline_outlined, size: 48, color: textMuted),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).exerciseDetailScreenNoStatsForThis,
                    style: TextStyle(color: textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).exerciseDetailScreenCompleteAWorkoutTo,
                    style: TextStyle(color: textMuted.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExerciseTimeRangeSelector(
              selected: timeRange,
              onChanged: (value) {
                ref.read(exerciseHistoryTimeRangeProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),

            // Prominent headline stats (Gravl-parity): Projected 1RM, Max
            // weight, Max volume, Max reps — computed from logged sessions.
            _buildPrStatPills(history),
            const SizedBox(height: 16),

            if (history.summary != null)
              ExerciseSummaryCard(summary: history.summary!),
            const SizedBox(height: 16),

            ExerciseChartTypeSelector(
              selected: chartType,
              onChanged: (value) {
                ref.read(exerciseChartTypeProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 12),

            ExerciseProgressionChart(
              history: history,
              chartType: chartType,
            ),
            const SizedBox(height: 24),

            prsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (prs) {
                if (prs.isEmpty) return const SizedBox.shrink();
                return ExercisePersonalRecordsSection(records: prs);
              },
            ),
          ],
        );
      },
    );
  }


  /// Four headline stat pills (Projected 1RM / Max weight / Max volume / Max
  /// reps) shown prominently atop the Stats tab — the per-exercise analytics
  /// the competitor surfaces. Values come straight from logged sessions and
  /// reuse the session model's unit-aware formatters; a stat with no data
  /// shows "—" rather than a fabricated zero.
  Widget _buildPrStatPills(ExerciseHistoryData history) {
    final colors = ThemeColors.of(context);
    final accent = colors.accent;
    final useLbs = !ref.watch(useKgForWorkoutProvider);
    final sessions = history.sessions;

    ExerciseWorkoutSession? byMax(double Function(ExerciseWorkoutSession) f) {
      ExerciseWorkoutSession? best;
      double bestVal = -1;
      for (final s in sessions) {
        final v = f(s);
        if (v > bestVal) {
          bestVal = v;
          best = s;
        }
      }
      return best;
    }

    final wSes = byMax((s) => s.weightKg);
    final vSes = byMax((s) => s.totalVolumeKg);
    final rmSes = byMax((s) => s.estimated1rmKg ?? 0);
    final maxReps = sessions.fold<int>(0, (m, s) => s.reps > m ? s.reps : m);

    final pills = <List<String>>[
      [
        'Proj. 1RM',
        (rmSes != null && (rmSes.estimated1rmKg ?? 0) > 0)
            ? rmSes.formatted1rmFor(useLbs: useLbs)
            : '—',
      ],
      ['Max weight', wSes != null ? wSes.formattedWeightFor(useLbs: useLbs) : '—'],
      ['Max volume', vSes != null ? vSes.formattedVolumeFor(useLbs: useLbs) : '—'],
      ['Max reps', maxReps > 0 ? '$maxReps' : '—'],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          for (final p in pills)
            Container(
              width: 104,
              margin: const EdgeInsetsDirectional.only(end: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.elevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 13, color: accent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          p[0],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p[1],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  /// FORM TAB — the per-exercise counterpart to chat form analysis. Shows a
  /// prominent "Analyze my form" CTA that opens the Form Analysis sheet for
  /// THIS exercise, plus every past analysis for it (newest first), each
  /// rendered with the shared [FormAnalysisGaugeCard].
  Widget _buildFormTabContent(Color textMuted) {
    final exerciseName = widget.exercise.name;
    final accent = ref.colors(context).accent;
    final analysesAsync =
        ref.watch(exerciseFormAnalysesProvider(exerciseName));

    Future<void> openSheet() async {
      HapticFeedback.lightImpact();
      await showFormAnalysisSheet(context, exerciseName: exerciseName);
      // Refresh history when the sheet closes — a new analysis may have landed.
      if (mounted) ref.invalidate(exerciseFormAnalysesProvider(exerciseName));
    }

    final analyzeButton = Material(
      color: accent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: openSheet,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          height: 52,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_gymnastics_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Analyze my form',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        analyzeButton,
        const SizedBox(height: 20),
        analysesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Could not load your form history.',
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.video_camera_back_outlined,
                          size: 48, color: textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No form check yet',
                        style: TextStyle(color: textMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Record a set above and track your form over time.',
                        style: TextStyle(
                          color: textMuted.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${items.length} FORM CHECK${items.length == 1 ? '' : 'S'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in items)
                  FormAnalysisGaugeCard(
                    result: item.result,
                    analyzedAt: item.analyzedAt,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }


  Widget _buildActionRow(WorkoutExercise exercise, Color elevated, Color cardBorder, Color textMuted, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favState = ref.watch(favoritesProvider);
    final stapleState = ref.watch(staplesProvider);
    final queueState = ref.watch(exerciseQueueProvider);
    final avoidState = ref.watch(avoidedProvider);

    final name = exercise.name;
    final isFav = favState.isFavorite(name);
    final isStaple = stapleState.isStaple(name);
    final isQueued = queueState.isQueued(name);
    final isAvoided = avoidState.isAvoided(name);

    final red = isDark ? AppColors.error : AppColorsLight.error;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    // Signature v2 orange-once: the screen's single orange is the focal PR
    // point on the History chart, so the "queued" state uses green instead.
    final queuedColor = isDark ? AppColors.green : AppColorsLight.green;

    Widget actionButton({
      required IconData icon,
      required IconData activeIcon,
      required String label,
      required bool active,
      required Color activeColor,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  active ? activeIcon : icon,
                  key: ValueKey(active),
                  color: active ? activeColor : textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? activeColor : textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          actionButton(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            label: AppLocalizations.of(context).recipeDetailFavorite,
            active: isFav,
            activeColor: red,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(favoritesProvider.notifier).toggleFavorite(name, exerciseId: exercise.exerciseId);
            },
          ),
          actionButton(
            icon: Icons.push_pin_outlined,
            activeIcon: Icons.push_pin,
            label: AppLocalizations.of(context).expandedExerciseCardStaple,
            active: isStaple,
            activeColor: cyan,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(staplesProvider.notifier).toggleStaple(
                name,
                libraryId: exercise.libraryId,
                muscleGroup: exercise.muscleGroup ?? exercise.primaryMuscle,
              );
            },
          ),
          actionButton(
            icon: Icons.queue_outlined,
            activeIcon: Icons.queue,
            label: AppLocalizations.of(context).myExercisesQueue,
            active: isQueued,
            activeColor: queuedColor,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(exerciseQueueProvider.notifier).toggleQueue(
                name,
                exerciseId: exercise.exerciseId,
                targetMuscleGroup: exercise.muscleGroup ?? exercise.primaryMuscle,
              );
            },
          ),
          actionButton(
            icon: Icons.block_outlined,
            activeIcon: Icons.block,
            label: AppLocalizations.of(context).menuFilterAvoid,
            active: isAvoided,
            activeColor: textMuted,
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(avoidedProvider.notifier).toggleAvoided(name, exerciseId: exercise.exerciseId);
            },
          ),
        ],
      ),
    );
  }


  Widget _buildCoachingCuesSection(WorkoutExercise exercise, Color elevated, Color cardBorder, Color textPrimary, Color textSecondary, Color textMuted, Color accentColor) {
    final cues = <_CueItem>[];

    if (exercise.formCue != null && exercise.formCue!.isNotEmpty) {
      cues.add(_CueItem(icon: Icons.sports_gymnastics, label: AppLocalizations.of(context).workoutAiCoachForm, text: exercise.formCue!));
    }
    if (exercise.breathingCue != null && exercise.breathingCue!.isNotEmpty) {
      cues.add(_CueItem(icon: Icons.air, label: AppLocalizations.of(context).workoutUiBuildersBreathing, text: exercise.breathingCue!));
    }
    if (exercise.setup != null && exercise.setup!.isNotEmpty) {
      cues.add(_CueItem(icon: Icons.tune, label: AppLocalizations.of(context).inlineExerciseInfoSetup, text: exercise.setup!));
    }
    if (exercise.tempo != null && exercise.tempo!.isNotEmpty) {
      cues.add(_CueItem(icon: Icons.speed, label: AppLocalizations.of(context).stapleChoiceTempo, text: exercise.tempo!));
    }

    if (cues.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).exerciseDetailScreenCoachingCues,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < cues.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(cues[i].icon, color: accentColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cues[i].label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cues[i].text,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < cues.length - 1)
                  Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }


  Widget _buildExerciseInfoSection(WorkoutExercise exercise, Color elevated, Color cardBorder, Color textPrimary, Color textSecondary, Color textMuted, Color accentColor) {
    final items = <_CueItem>[];

    if (exercise.difficulty != null && exercise.difficulty!.isNotEmpty) {
      items.add(_CueItem(icon: Icons.signal_cellular_alt, label: AppLocalizations.of(context).workoutSummaryGeneralDifficulty, text: exercise.difficulty!));
    }

    // Secondary muscles
    final secondaryMuscles = exercise.secondaryMuscles;
    String? musclesText;
    if (secondaryMuscles is List && secondaryMuscles.isNotEmpty) {
      musclesText = secondaryMuscles.map((m) => m.toString()).join(', ');
    } else if (secondaryMuscles is String && secondaryMuscles.isNotEmpty) {
      musclesText = secondaryMuscles;
    }
    if (musclesText != null) {
      items.add(_CueItem(icon: Icons.accessibility_new, label: AppLocalizations.of(context).exerciseDetailsSheetSecondaryMuscles, text: musclesText));
    }

    if (exercise.substitution != null && exercise.substitution!.isNotEmpty) {
      items.add(_CueItem(icon: Icons.swap_horiz, label: AppLocalizations.of(context).exerciseDetailScreenAlternative, text: exercise.substitution!));
    }
    if (exercise.notes != null && exercise.notes!.isNotEmpty) {
      items.add(_CueItem(icon: Icons.sticky_note_2_outlined, label: AppLocalizations.of(context).syncedWorkoutDetailNotes, text: exercise.notes!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).exerciseDetailScreenExerciseInfo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(items[i].icon, color: textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              items[i].text,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }


  Widget _buildTableRow({
    required String setLabel,
    required bool isWarmup,
    PreviousSetData? previousData,
    required bool hasPrevious,
    double? targetWeight,
    int? targetReps,
    int? targetRir,
    required bool isLast,
    required Color cardBorder,
    required Color textPrimary,
    required Color textMuted,
    required Color textSecondary,
  }) {
    final previousDisplay = _formatPreviousSet(previousData);

    // Format target display
    String targetDisplay = '-';
    if (targetWeight != null && targetReps != null) {
      targetDisplay = '${targetWeight.toInt()} × $targetReps';
    } else if (targetReps != null) {
      targetDisplay = '× $targetReps';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: cardBorder.withValues(alpha: 0.2),
                ),
              ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : null,
      ),
      child: Row(
        children: [
          // Set badge
          SizedBox(
            width: 36,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isWarmup
                    ? textMuted.withValues(alpha: 0.15)
                    : textPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  setLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isWarmup ? textMuted : textPrimary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Previous column - weight × reps + RIR
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight x Reps
                Text(
                  previousDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: previousDisplay == '-' ? textMuted : textSecondary,
                    fontWeight: previousDisplay != '-' ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                // RIR pill (if available)
                if (previousData?.rir != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRirColor(previousData!.rir!).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RIR ${previousData.rir}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _getRirColor(previousData.rir!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Target column - weight × reps + RIR
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target weight x reps
                Text(
                  targetDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: targetDisplay == '-' ? textMuted : textPrimary,
                    fontWeight: targetDisplay != '-' ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                // Target RIR pill
                if (targetRir != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRirColor(targetRir).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RIR $targetRir',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _getRirColor(targetRir),
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

}
