part of 'workout_complete_screen.dart';

/// UI builder methods extracted from _WorkoutCompleteScreenState
extension _WorkoutCompleteScreenStateUI1 on _WorkoutCompleteScreenState {
  /// Per-exercise breakdown (2D) — each exercise is a compact tap-to-expand
  /// row: collapsed shows "N×reps · avg weight" + a PR badge; expanded reveals
  /// every set's weight × reps with the PR set starred. Collapsed by default so
  /// the whole list fits without scrolling regardless of phone size. Returns
  /// null when there is no logged performance to show (the level-up moment now
  /// lives inside the merged Coach card).
  Widget? _buildExercisesSection() {
    final perf = widget.exercisesPerformance;
    if (perf == null || perf.isEmpty) return null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final useKg = ref.watch(useKgForWorkoutProvider);

    // PR lookup by exercise name — drives the badge AND the per-set star.
    final prByName = <String, PersonalRecordInfo>{
      for (final pr in (widget.personalRecords ?? const <PersonalRecordInfo>[]))
        pr.exerciseName.toLowerCase().trim(): pr,
    };
    // Per-set rows by exercise name (passed through from the finalizer).
    final setsByName = <String, List<Map<String, dynamic>>>{
      for (final ex in (widget.exerciseSets ?? const <Map<String, dynamic>>[]))
        ((ex['name'] as String?) ?? '').toLowerCase().trim():
            ((ex['sets'] as List?)
                ?.whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList() ??
            const <Map<String, dynamic>>[]),
    };

    // Exercise id + equipment hint by name, sourced from the planned workout
    // models so the thumbnail resolves the exact library row (not a fuzzy
    // name match) and falls back to an equipment-matched icon. Name-only still
    // works when an exercise isn't in this map.
    final metaByName = <String, ({String? id, String? equipment})>{
      for (final ex in widget.workout.exercises)
        ex.name.toLowerCase().trim(): (
          id: (ex.exerciseId?.isNotEmpty == true)
              ? ex.exerciseId
              : (ex.libraryId?.isNotEmpty == true ? ex.libraryId : null),
          equipment: (ex.equipment?.trim().isNotEmpty == true)
              ? ex.equipment!.split(',').first.trim()
              : null,
        ),
    };

    return ZealovaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_list_bulleted_rounded,
                size: 16,
                color: textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Exercises'.toUpperCase(),
                style: ZType.lbl(11, color: textMuted, letterSpacing: 2.0),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const ZealovaRule(),
          const SizedBox(height: 8),
          for (final e in perf)
            () {
              final name = (e['name'] as String?) ?? 'Exercise';
              final key = name.toLowerCase().trim();
              final meta = metaByName[key];
              return _ExpandableExerciseRow(
                name: name,
                sets: (e['sets'] as num?)?.toInt() ?? 0,
                reps: (e['reps'] as num?)?.toInt() ?? 0,
                avgWeightKg: (e['weight_kg'] as num?)?.toDouble() ?? 0,
                pr: prByName[key],
                perSets: setsByName[key] ?? const <Map<String, dynamic>>[],
                useKg: useKg,
                textPrimary: textPrimary,
                textMuted: textMuted,
                exerciseId: meta?.id,
                equipmentHint: meta?.equipment,
              );
            }(),
        ],
      ),
    );
  }

  /// Signature v2 stat ledger (Frame 2).
  ///
  /// The typographic finish lands on a hairline ledger — one row per metric,
  /// a Barlow-Condensed muted key on the left and the value on the right, with
  /// a 1px rule above every row. Time-based readouts (Duration, Median rest)
  /// use Space Mono; counts/volume use the Anton numeral face. No per-row
  /// accent — orange is reserved for the DONE CTA (orange-once rule). Shows
  /// Time · Volume · Sets·Reps · Energy · Median rest · Records. Volume
  /// respects the user's workout weight-unit preference (kg→lb when
  /// `preferredWorkoutWeightUnit=lbs`).
  Widget _buildCompactStatsGrid() {
    final useKg = ref.watch(useKgForWorkoutProvider);
    final volumeKg = widget.totalVolumeKg ?? 0;
    final displayVolume = useKg ? volumeKg : WeightUtils.kgToLbs(volumeKg);
    final unit = useKg ? 'kg' : 'lb';
    final c = ThemeColors.of(context);

    final prCount = widget.personalRecords?.length ?? 0;
    final medianRest = _effectiveMedianRestSeconds;
    final l = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LedgerRow(
          label: l.workoutSummaryGeneralDuration,
          value: _formatDuration(widget.duration),
          mono: true,
        ),
        _LedgerRow(
          label: l.workoutSummaryAdvancedVolume,
          value: displayVolume.toStringAsFixed(0),
          unit: unit,
        ),
        _LedgerRow(
          label:
              '${l.workoutSummaryGeneralSets} · ${l.workoutSummaryGeneralReps}',
          value: '${widget.totalSets ?? 0} · ${widget.totalReps ?? 0}',
        ),
        _LedgerRow(label: 'Energy', value: '${widget.calories}', unit: 'kcal'),
        _LedgerRow(
          label: 'Median rest',
          value: medianRest != null ? _formatMmSs(medianRest) : '--',
          mono: true,
        ),
        _LedgerRow(
          label: 'Records',
          value: '$prCount',
          valueColor: prCount > 0 ? c.success : null,
          last: true,
        ),
      ],
    );
  }

  /// XP + streak two-cell row (Signature v2 Frame 2). Left cell: XP earned
  /// this session (from the last XP-earned event). Right cell: the current
  /// streak with a flame. Renders nothing when neither value is available —
  /// no placeholder/mock numbers. Numerals stay on the text ladder so the
  /// single orange budget remains on the DONE CTA.
  Widget _buildXpStreakRow() {
    final c = ThemeColors.of(context);
    final earnedXp = ref.watch(xpProvider).lastXPEarnedEvent?.xpAmount;
    final streak = _achievements?['streak_days'] as int? ?? 0;

    // Nothing meaningful to show yet — collapse the row entirely.
    if ((earnedXp == null || earnedXp <= 0) && streak <= 0) {
      return const SizedBox.shrink();
    }

    Widget cell(String label, Widget value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: ZType.lbl(10, color: c.textMuted, letterSpacing: 1.8),
          ),
          const SizedBox(height: 5),
          value,
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          if (earnedXp != null && earnedXp > 0)
            cell(
              'Earned',
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '+$earnedXp',
                    style: ZType.disp(24, color: c.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'XP',
                      style: ZType.lbl(
                        11,
                        color: c.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (streak > 0)
            cell(
              'Streak',
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$streak', style: ZType.disp(24, color: c.textPrimary)),
                  const SizedBox(width: 5),
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Heart rate section with enhanced chart, zone breakdown, and fitness metrics
  Widget _buildHeartRateSection(Color elevated) {
    final readings = widget.heartRateReadings!
        .map((r) => r.toReading())
        .toList();

    // Get user age for accurate max HR calculation
    final authState = ref.watch(authStateProvider);
    final userAge = authState.user?.age ?? 30; // Default to 30 if not available
    final maxHR = calculateMaxHR(userAge);

    // Get resting heart rate from daily activity if available
    final activityState = ref.watch(dailyActivityProvider);
    final restingHR = activityState.today?.restingHeartRate;

    // Calculate workout duration in minutes
    final durationMinutes = (widget.duration / 60).round();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.favorite, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(
                  context,
                ).workoutCompleteScreenHeartRateAnalysis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Compact heart rate chart (graph + stats + zone breakdown)
          HeartRateWorkoutChart(
            readings: readings,
            avgBpm: widget.avgHeartRate,
            maxBpm: widget.maxHeartRate,
            minBpm: widget.minHeartRate,
            maxHR: maxHR,
            restingHR: restingHR,
            durationMinutes: durationMinutes,
            totalCalories: widget.calories,
            showZoneBreakdown: true, // Show zones in compact view
            showTrainingEffect: false,
            showVO2Max: false,
            showFatBurnMetrics: false,
          ),
          const SizedBox(height: 12),

          // View All Metrics button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showHeartRateMetricsSheet(
                readings: readings,
                maxHR: maxHR,
                restingHR: restingHR,
                durationMinutes: durationMinutes,
              ),
              icon: Icon(
                Icons.analytics_outlined,
                size: 18,
                color: accentColor,
              ),
              label: Text(
                AppLocalizations.of(
                  context,
                ).workoutCompleteScreenViewAllMetrics,
                style: TextStyle(color: accentColor),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Surface 6c — Heart-rate section rendered from the Apple Health /
  /// Health Connect BACKFILL (when no live BLE/Watch HR was captured during
  /// the workout). Same visual treatment as [_buildHeartRateSection] plus a
  /// provenance chip labeling the source ("From Apple Health" on iOS /
  /// "From Health Connect" on Android), matching Gravl Image #1.
  Widget _buildBackfilledHeartRateSection(
    Color elevated,
    HeartRateBackfillResult backfill,
  ) {
    // Adapt the backfilled samples into the chart's reading model.
    final readings = backfill.series
        .map((s) => HeartRateReading(bpm: s.bpm, timestamp: s.timestamp))
        .toList();

    final authState = ref.watch(authStateProvider);
    final userAge = authState.user?.age ?? 30;
    final maxHR = calculateMaxHR(userAge);

    final activityState = ref.watch(dailyActivityProvider);
    final restingHR = activityState.today?.restingHeartRate;

    final durationMinutes = (widget.duration / 60).round();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with provenance chip ("From Apple Health" / "Health Connect").
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.favorite, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).workoutCompleteScreenHeartRateAnalysis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              // Source provenance chip.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  backfill.sourceLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          HeartRateWorkoutChart(
            readings: readings,
            avgBpm: backfill.avgBpm,
            maxBpm: backfill.maxBpm,
            minBpm: backfill.minBpm,
            maxHR: maxHR,
            restingHR: restingHR,
            durationMinutes: durationMinutes,
            totalCalories: widget.calories,
            showZoneBreakdown: true,
            showTrainingEffect: false,
            showVO2Max: false,
            showFatBurnMetrics: false,
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showHeartRateMetricsSheet(
                readings: readings,
                maxHR: maxHR,
                restingHR: restingHR,
                durationMinutes: durationMinutes,
              ),
              icon: Icon(
                Icons.analytics_outlined,
                size: 18,
                color: accentColor,
              ),
              label: Text(
                AppLocalizations.of(
                  context,
                ).workoutCompleteScreenViewAllMetrics,
                style: TextStyle(color: accentColor),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the trophies section showing PRs and achievements earned
  Widget _buildTrophiesSection(Color elevated) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    // Calculate trophy count
    final newAchievements =
        (_achievements?['new_achievements'] as List<dynamic>?)?.length ?? 0;
    final totalTrophies = _newPRs.length + newAchievements;
    final streak = _achievements?['streak_days'] as int? ?? 0;
    // Ensure at least 1 since the user just completed a workout
    final totalWorkouts = (_achievements?['total_workouts'] as int? ?? 0).clamp(
      1,
      999999,
    );
    final hasAchievements = totalTrophies > 0;

    Widget trophiesCard = GestureDetector(
      onTap: () => showTrophiesEarnedSheet(
        context,
        newPRs: _newPRs,
        achievements: _achievements,
        totalWorkouts: totalWorkouts,
        currentStreak: streak > 0 ? streak : 1, // At least 1 day
        // Cardio PRs from the post-insert enrichment pipeline. Empty
        // list when no cardio PRs landed in the last 5 min — the sheet
        // hides the cardio section in that case.
        cardioPrs: _newCardioPRs.cast<CardioPersonalRecord>(),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ThemeColors.of(context).surface,
          borderRadius: BorderRadius.circular(14),
          // Gold left edge is the sanctioned gamification accent (≤1/screen,
          // distinct from the reserved app accent). Stronger when earned.
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Row(
          children: [
            // Trophy icon with badge - animated when achievements
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: hasAchievements
                            ? AppColors.gamGold.withOpacity(0.15)
                            : ThemeColors.of(context).elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasAchievements
                              ? AppColors.gamGold.withOpacity(0.5)
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: hasAchievements
                            ? AppColors.gamGold
                            : textSecondary,
                        size: 24,
                      ),
                    )
                    .animate(
                      onPlay: (controller) => hasAchievements
                          ? controller.repeat(reverse: true)
                          : null,
                    )
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: hasAchievements
                          ? const Offset(1.08, 1.08)
                          : const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
                if (hasAchievements)
                  Positioned(
                    right: -4,
                    top: -4,
                    child:
                        Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: elevated, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFD700,
                                    ).withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                '$totalTrophies',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .scale(
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(1.15, 1.15),
                              duration: 600.ms,
                              curve: Curves.easeInOut,
                            ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (hasAchievements)
                        Text(
                              AppLocalizations.of(context)
                                  .workoutCompleteScreenTrophiesEarned
                                  .toUpperCase(),
                              style: ZType.lbl(
                                13,
                                color: AppColors.gamGold,
                                letterSpacing: 1.5,
                              ),
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .shimmer(
                              duration: 1500.ms,
                              color: Colors.white.withOpacity(0.3),
                            )
                      else
                        Text(
                          AppLocalizations.of(context)
                              .workoutCompleteScreenTrophiesMilestones
                              .toUpperCase(),
                          style: ZType.lbl(
                            13,
                            color: textPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: hasAchievements
                            ? AppColors.gamGold
                            : textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasAchievements
                        ? '${_newPRs.length} PRs${newAchievements > 0 ? ', $newAchievements badges' : ''} - Tap to view'
                        : streak > 0
                        ? '$streak day streak, $totalWorkouts total workouts'
                        : 'Track your progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasAchievements
                          ? AppColors.gamGold.withOpacity(0.85)
                          : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Add entrance animation and subtle glow pulse for achievements
    if (hasAchievements) {
      return trophiesCard
          .animate()
          .fadeIn(delay: 550.ms, duration: 400.ms)
          .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut)
          .then()
          .shimmer(
            delay: 200.ms,
            duration: 1800.ms,
            color: AppColors.gamGold.withOpacity(0.15),
          );
    }

    return trophiesCard;
  }

  /// Build the exercise progression suggestions section
  /// Shows when user has exercises ready to progress to harder variants
  Widget _buildProgressionSuggestionsSection() {
    return Builder(
      builder: (context) {
        final isDarkProg = Theme.of(context).brightness == Brightness.dark;
        final elevatedProg = isDarkProg
            ? AppColors.elevated
            : AppColorsLight.elevated;
        final textSecondaryProg = isDarkProg
            ? AppColors.textSecondary
            : AppColorsLight.textSecondary;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.purple.withOpacity(0.15),
                AppColors.cyan.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      size: 20,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      ).workoutCompleteScreenReadyToLevelUp,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.purple,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(
                  context,
                ).workoutCompleteScreenYouVeMasteredThese,
                style: TextStyle(fontSize: 13, color: textSecondaryProg),
              ),
              const SizedBox(height: 16),
              ..._progressionSuggestions.map(
                (suggestion) => _buildProgressionCard(suggestion),
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(delay: 525.ms).slideY(begin: 0.1);
  }

  /// Build individual progression suggestion card
  Widget _buildProgressionCard(ProgressionSuggestion suggestion) {
    return Builder(
      builder: (context) {
        final isDarkCard = Theme.of(context).brightness == Brightness.dark;
        final elevatedCard = isDarkCard
            ? AppColors.elevated
            : AppColorsLight.elevated;
        final textPrimaryCard = isDarkCard
            ? AppColors.textPrimary
            : AppColorsLight.textPrimary;
        final textSecondaryCard = isDarkCard
            ? AppColors.textSecondary
            : AppColorsLight.textSecondary;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: elevatedCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.purple.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise progression path
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.exerciseName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimaryCard,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.purple.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                suggestion.suggestedNextVariant,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Difficulty badge
                  if (suggestion.difficultyIncrease != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        suggestion.difficultyIncreaseDescription,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Mastery info
              Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: AppColors.success.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Marked as "too easy" ${suggestion.consecutiveEasySessions}x in a row',
                    style: TextStyle(fontSize: 12, color: textSecondaryCard),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _declineProgression(suggestion, 'not_ready'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondaryCard,
                        side: BorderSide(
                          color: textSecondaryCard.withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).workoutCompleteScreenNotYet,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptProgression(suggestion),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                      label: Text(
                        AppLocalizations.of(
                          context,
                        ).workoutCompleteScreenLevelUp,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewPRsSection() {
    final useKg = ref.watch(useKgForWorkoutProvider);
    return Builder(
          builder: (context) {
            final isDarkPR = Theme.of(context).brightness == Brightness.dark;
            final textPrimaryPR = isDarkPR
                ? AppColors.textPrimary
                : AppColorsLight.textPrimary;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.2),
                    AppColors.orange.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          size: 20,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).workoutCompleteScreenNewPersonalRecords,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._newPRs.map((pr) {
                    final celebrationMessage =
                        pr['celebration_message'] as String?;
                    final improvementKg = pr['improvement_kg'] as num?;
                    final improvementPercent =
                        pr['improvement_percent'] as num?;
                    final estimated1rm = pr['estimated_1rm_kg'] as num?;
                    final reps = pr['reps'] as int?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${pr['exercise_name']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textPrimaryPR,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${WeightUtils.formatWorkoutWeight((pr['weight_kg'] as num).toDouble(), useKg: useKg)}${reps != null ? ' x $reps' : ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (estimated1rm != null)
                                    Text(
                                      '1RM: ${WeightUtils.formatWorkoutWeight(estimated1rm.toDouble(), useKg: useKg)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textPrimaryPR.withOpacity(0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          // Show improvement if available
                          if (improvementKg != null && improvementKg > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const SizedBox(width: 26),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+${WeightUtils.formatWorkoutWeight(improvementKg.toDouble(), useKg: useKg)}${improvementPercent != null ? ' (+${improvementPercent.toStringAsFixed(1)}%)' : ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Show AI celebration message if available
                          if (celebrationMessage != null &&
                              celebrationMessage.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 26),
                              child: Text(
                                celebrationMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: textPrimaryPR.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        )
        .animate()
        .fadeIn(delay: 550.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }

  /// Build the performance comparison section showing improvements/setbacks
  Widget _buildPerformanceComparisonSection() {
    final comparison = widget.performanceComparison;
    if (comparison == null) return const SizedBox.shrink();

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark
            ? AppColors.textPrimary
            : AppColorsLight.textPrimary;
        final textSecondary = isDark
            ? AppColors.textSecondary
            : AppColorsLight.textSecondary;
        final cardBorder = isDark
            ? AppColors.cardBorder
            : AppColorsLight.cardBorder;

        final hasImprovements = comparison.improvedCount > 0;
        final hasDeclines = comparison.declinedCount > 0;

        // Choose accent color based on overall performance
        Color accentColor;
        IconData headerIcon;
        String headerText;

        if (hasImprovements && !hasDeclines) {
          accentColor = AppColors.success;
          headerIcon = Icons.trending_up;
          headerText = 'ALL EXERCISES IMPROVED!';
        } else if (hasDeclines && !hasImprovements) {
          accentColor = AppColors.orange;
          headerIcon = Icons.trending_down;
          headerText = 'PERFORMANCE COMPARED TO LAST SESSION';
        } else if (hasImprovements && hasDeclines) {
          accentColor = AppColors.cyan;
          headerIcon = Icons.compare_arrows;
          headerText = 'PERFORMANCE COMPARISON';
        } else {
          accentColor = AppColors.cyan;
          headerIcon = Icons.analytics;
          headerText = 'PERFORMANCE MAINTAINED';
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(headerIcon, size: 20, color: accentColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (comparison.workoutComparison.hasPrevious)
                            Text(
                              'vs last ${comparison.workoutComparison.previousPerformedAt != null ? _formatRelativeDate(comparison.workoutComparison.previousPerformedAt!) : 'session'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Summary badges
                    Row(
                      children: [
                        if (comparison.improvedCount > 0)
                          _buildCountBadge(
                            count: comparison.improvedCount,
                            icon: Icons.arrow_upward,
                            color: AppColors.success,
                          ),
                        if (comparison.declinedCount > 0) ...[
                          const SizedBox(width: 8),
                          _buildCountBadge(
                            count: comparison.declinedCount,
                            icon: Icons.arrow_downward,
                            color: AppColors.error,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: cardBorder),

              // Exercise comparisons
              ...comparison.exerciseComparisons.map((exComp) {
                return _buildExerciseComparisonRow(
                  exComp,
                  textPrimary,
                  textSecondary,
                );
              }),

              // Overall workout comparison (if has previous)
              if (comparison.workoutComparison.hasPrevious) ...[
                Divider(height: 1, color: cardBorder),
                _buildWorkoutTotalComparison(
                  comparison.workoutComparison,
                  textPrimary,
                  textSecondary,
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 560.ms);
      },
    );
  }

  Widget _buildCountBadge({
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// One tap-to-expand exercise row on the completion screen (2D). Collapsed:
/// name + optional PR badge + chevron, with a one-line "N×reps · avg" summary.
/// Expanded: every working set's weight × reps, with the set that landed the
/// PR starred. Default collapsed so the whole list fits without scrolling.
class _ExpandableExerciseRow extends StatefulWidget {
  final String name;
  final int sets;
  final int reps;
  final double avgWeightKg;
  final PersonalRecordInfo? pr;
  final List<Map<String, dynamic>> perSets;
  final bool useKg;
  final Color textPrimary;
  final Color textMuted;

  /// Library row id (exercise_id ?? library_id) for exact thumbnail resolution.
  final String? exerciseId;

  /// First equipment item — picks a matching fallback icon when no image.
  final String? equipmentHint;

  const _ExpandableExerciseRow({
    required this.name,
    required this.sets,
    required this.reps,
    required this.avgWeightKg,
    required this.pr,
    required this.perSets,
    required this.useKg,
    required this.textPrimary,
    required this.textMuted,
    this.exerciseId,
    this.equipmentHint,
  });

  @override
  State<_ExpandableExerciseRow> createState() => _ExpandableExerciseRowState();
}

class _ExpandableExerciseRowState extends State<_ExpandableExerciseRow> {
  bool _expanded = false;
  // Independent of the per-set expansion: the Gravl-parity records table
  // (Projected 1RM / Max weight / Max reps / Max volume) for this exercise.
  bool _showRecords = false;

  bool get _expandable => widget.perSets.isNotEmpty;

  /// Compute this exercise's session records from the logged sets. Returns
  /// null when there's nothing to compute (no sets with reps) so the toggle is
  /// omitted entirely — never a row of zeros. Warm-up sets are excluded.
  ///   • Projected 1RM — Epley: best of weight × (1 + reps/30)
  ///   • Max weight    — heaviest set
  ///   • Max reps      — highest rep count
  ///   • Max volume    — best of weight × reps
  ({double? oneRmKg, double? maxWeightKg, int? maxReps, double? maxVolumeKg})?
  _records() {
    if (widget.perSets.isEmpty) return null;
    double? best1rm;
    double? maxWeight;
    int? maxReps;
    double? maxVolume;
    var any = false;
    for (final s in widget.perSets) {
      final type = ((s['set_type'] as String?) ?? 'working').toLowerCase();
      if (type == 'warmup' || type == 'warm_up') continue;
      final w = (s['weight_kg'] as num?)?.toDouble() ?? 0;
      final r = (s['reps'] as num?)?.toInt() ?? 0;
      if (r <= 0) continue;
      any = true;
      if (w > 0) {
        final epley = w * (1 + r / 30.0);
        if (best1rm == null || epley > best1rm) best1rm = epley;
        if (maxWeight == null || w > maxWeight) maxWeight = w;
        final vol = w * r;
        if (maxVolume == null || vol > maxVolume) maxVolume = vol;
      }
      if (maxReps == null || r > maxReps) maxReps = r;
    }
    if (!any) return null;
    return (
      oneRmKg: best1rm,
      maxWeightKg: maxWeight,
      maxReps: maxReps,
      maxVolumeKg: maxVolume,
    );
  }

  /// Index of the set that best matches the PR (weight≈ + reps), else the
  /// heaviest set; -1 when this exercise didn't set a PR. Best-effort — per-set
  /// PRs aren't tracked server-side, so we map the exercise-level PR onto a set.
  int get _prSetIndex {
    if (widget.pr == null || widget.perSets.isEmpty) return -1;
    final targetKg = widget.pr!.weightKg;
    final targetReps = widget.pr!.reps;
    int best = -1;
    double bestScore = double.infinity;
    for (var i = 0; i < widget.perSets.length; i++) {
      final w = (widget.perSets[i]['weight_kg'] as num?)?.toDouble() ?? 0;
      final r = (widget.perSets[i]['reps'] as num?)?.toInt() ?? 0;
      // Lower is better: weight delta dominates, reps delta breaks ties.
      final score = (w - targetKg).abs() + (r - targetReps).abs() * 0.01;
      if (score < bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  String _fmtWeightKg(double kg) => kg > 0
      ? WeightUtils.formatWorkoutWeight(kg, useKg: widget.useKg, space: false)
      : 'BW';

  @override
  Widget build(BuildContext context) {
    final avg = widget.avgWeightKg;
    final summary = avg > 0
        ? '${widget.sets}×${widget.reps} · ${_fmtWeightKg(avg)} avg'
        : '${widget.sets}×${widget.reps}';
    final prIdx = _prSetIndex;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Exercise illustration thumbnail (E) — resolves by id when available,
        // falls back to an equipment-matched icon, never a broken-image glyph.
        ExerciseImage(
          exerciseName: widget.name,
          exerciseId: widget.exerciseId,
          equipmentHint: widget.equipmentHint,
          width: 44,
          height: 44,
          borderRadius: 8,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.pr != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCD34D),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 11,
                            color: Color(0xFF7A5C00),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'PR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF7A5C00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                summary,
                style: TextStyle(fontSize: 12, color: widget.textMuted),
              ),
            ],
          ),
        ),
        if (_expandable)
          Icon(
            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            size: 20,
            color: widget.textMuted,
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _expandable
              ? InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: header,
                  ),
                )
              : header,
          if (_expanded && _expandable)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < widget.perSets.length; i++)
                    _SetChip(
                      index: i + 1,
                      label: _setLabel(widget.perSets[i]),
                      isPr: i == prIdx,
                      textPrimary: widget.textPrimary,
                      textMuted: widget.textMuted,
                    ),
                ],
              ),
            ),
          // Gravl-parity records: a "Show records ▾" toggle expanding to the
          // four session records for this exercise (only when computable).
          if (_records() != null) ...[
            _buildRecordsToggle(),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _showRecords
                  ? _buildRecordsTable(_records()!)
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordsToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _showRecords = !_showRecords),
      child: Padding(
        padding: const EdgeInsets.only(top: 6, left: 2),
        child: Row(
          children: [
            Text(
              _showRecords ? 'Hide records' : 'Show records',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showRecords ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: accent,
            ),
            const Spacer(),
            Icon(
              Icons.emoji_events_outlined,
              size: 14,
              color: widget.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsTable(
    ({double? oneRmKg, double? maxWeightKg, int? maxReps, double? maxVolumeKg})
    r,
  ) {
    final rows = <Widget>[];
    void addRow(String label, String value) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: widget.textMuted),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (r.oneRmKg != null) {
      addRow(
        'Projected 1 rep max',
        WeightUtils.formatWorkoutWeight(r.oneRmKg!, useKg: widget.useKg),
      );
    }
    if (r.maxWeightKg != null) {
      addRow(
        'Max weight',
        WeightUtils.formatWorkoutWeight(r.maxWeightKg!, useKg: widget.useKg),
      );
    }
    if (r.maxReps != null) {
      addRow('Max repetitions', '${r.maxReps}');
    }
    if (r.maxVolumeKg != null) {
      addRow(
        'Max volume',
        WeightUtils.formatWorkoutWeight(r.maxVolumeKg!, useKg: widget.useKg),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 2, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  String _setLabel(Map<String, dynamic> s) {
    final kg = (s['weight_kg'] as num?)?.toDouble() ?? 0;
    final reps = (s['reps'] as num?)?.toInt() ?? 0;
    return '${_fmtWeightKg(kg)} × $reps';
  }
}

class _SetChip extends StatelessWidget {
  final int index;
  final String label;
  final bool isPr;
  final Color textPrimary;
  final Color textMuted;

  const _SetChip({
    required this.index,
    required this.label,
    required this.isPr,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'S$index',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        if (isPr) ...[
          const SizedBox(width: 3),
          const Text('🏆', style: TextStyle(fontSize: 11)),
        ],
      ],
    );
  }
}

/// Signature v2 hairline ledger row (Frame 2 completion finish). A 1px rule
/// sits above each row; the Barlow-Condensed muted key is on the left and the
/// value on the right. Time-based values pass `mono: true` for Space Mono;
/// everything else uses the Anton numeral face. The optional `unit` is a small
/// trailing Barlow tag. No accent unless `valueColor` is given (PR green).
class _LedgerRow extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final bool mono;
  final bool last;
  final Color? valueColor;
  const _LedgerRow({
    required this.label,
    required this.value,
    this.unit,
    this.mono = false,
    this.last = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final valColor = valueColor ?? c.textPrimary;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.hairlineStrong, width: 1),
          bottom: last
              ? BorderSide(color: AppColors.hairlineStrong, width: 1)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: ZType.lbl(11, color: c.textMuted, letterSpacing: 1.6),
            ),
          ),
          Text(
            value,
            style: mono
                ? ZType.data(18, color: valColor)
                : ZType.disp(20, color: valColor),
          ),
          if (unit != null) ...[
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                unit!.toUpperCase(),
                style: ZType.lbl(9, color: c.textMuted, letterSpacing: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
