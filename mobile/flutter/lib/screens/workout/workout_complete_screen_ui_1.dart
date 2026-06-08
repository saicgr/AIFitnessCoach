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
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final useKg = ref.watch(useKgForWorkoutProvider);

    // PR lookup by exercise name — drives the badge AND the per-set star.
    final prByName = <String, PersonalRecordInfo>{
      for (final pr
          in (widget.personalRecords ?? const <PersonalRecordInfo>[]))
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_list_bulleted_rounded,
                  size: 18, color: textMuted),
              const SizedBox(width: 8),
              Text(
                'Exercises',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in perf)
            () {
              final name = (e['name'] as String?) ?? 'Exercise';
              final key = name.toLowerCase().trim();
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
              );
            }(),
        ],
      ),
    );
  }

  /// Always-visible Gravl-style 2×N stats grid (DISPLAY UPGRADE — Surface 1).
  ///
  /// Replaces the old 3-primary + 3-behind-a-toggle layout: ALL stats are now
  /// glanceable at once via the shared [MetricGrid] (big numbers, strong
  /// hierarchy, no "show all" toggle). Shows Duration, Energy (kcal), Volume,
  /// Exercises, Sets, Reps, Median rest, and Records (PR count). Volume
  /// respects the user's workout weight-unit preference (kg→lb conversion when
  /// `preferredWorkoutWeightUnit=lbs`). Median rest is formatted mm:ss.
  Widget _buildCompactStatsGrid() {
    final useKg = ref.watch(useKgForWorkoutProvider);
    final volumeKg = widget.totalVolumeKg ?? 0;
    final displayVolume = useKg ? volumeKg : WeightUtils.kgToLbs(volumeKg);
    final unit = useKg ? 'kg' : 'lb';
    final c = ThemeColors.of(context);
    final accent = c.accent;

    final prCount = widget.personalRecords?.length ?? 0;
    final medianRest = _effectiveMedianRestSeconds;

    final cells = <MetricCell>[
      MetricCell(
        label: AppLocalizations.of(context).workoutSummaryGeneralDuration,
        value: _formatDuration(widget.duration),
        icon: Icons.timer_outlined,
        accent: accent,
      ),
      MetricCell(
        label: 'Energy',
        value: '${widget.calories}',
        unit: 'kcal',
        icon: Icons.local_fire_department_outlined,
        accent: accent,
      ),
      MetricCell(
        label: AppLocalizations.of(context).workoutSummaryAdvancedVolume,
        value: displayVolume.toStringAsFixed(0),
        unit: unit,
        icon: Icons.fitness_center,
        accent: accent,
      ),
      MetricCell(
        label: AppLocalizations.of(context).authIntroExercises,
        value: '${widget.workout.exercises.length}',
        icon: Icons.format_list_bulleted_rounded,
        accent: accent,
      ),
      MetricCell(
        label: AppLocalizations.of(context).workoutSummaryGeneralSets,
        value: '${widget.totalSets ?? 0}',
        icon: Icons.layers_outlined,
        accent: accent,
      ),
      MetricCell(
        label: AppLocalizations.of(context).workoutSummaryGeneralReps,
        value: '${widget.totalReps ?? 0}',
        icon: Icons.repeat,
        accent: accent,
      ),
      MetricCell(
        label: 'Median rest',
        value: medianRest != null ? _formatMmSs(medianRest) : '--',
        icon: Icons.av_timer_outlined,
        accent: accent,
      ),
      MetricCell(
        label: 'Records',
        value: '$prCount',
        icon: Icons.emoji_events_outlined,
        accent: prCount > 0 ? c.success : accent,
      ),
    ];

    // 2A — page the 8 stats into two swipeable 2×2 grids (shorter screen).
    return _StatsCarousel(cells: cells);
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
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
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
                child: Icon(
                  Icons.favorite,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context).workoutCompleteScreenHeartRateAnalysis,
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
              icon: Icon(Icons.analytics_outlined, size: 18, color: accentColor),
              label: Text(
                AppLocalizations.of(context).workoutCompleteScreenViewAllMetrics,
                style: TextStyle(color: accentColor),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(
                  color: accentColor.withValues(alpha: 0.4),
                ),
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
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
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
                child: Icon(
                  Icons.favorite,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)
                      .workoutCompleteScreenHeartRateAnalysis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              // Source provenance chip.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              icon: Icon(Icons.analytics_outlined, size: 18, color: accentColor),
              label: Text(
                AppLocalizations.of(context).workoutCompleteScreenViewAllMetrics,
                style: TextStyle(color: accentColor),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(
                  color: accentColor.withValues(alpha: 0.4),
                ),
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
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Calculate trophy count
    final newAchievements = (_achievements?['new_achievements'] as List<dynamic>?)?.length ?? 0;
    final totalTrophies = _newPRs.length + newAchievements;
    final streak = _achievements?['streak_days'] as int? ?? 0;
    // Ensure at least 1 since the user just completed a workout
    final totalWorkouts = (_achievements?['total_workouts'] as int? ?? 0).clamp(1, 999999);
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
          gradient: LinearGradient(
            colors: hasAchievements
                ? [
                    AppColors.orange.withOpacity(0.2),
                    AppColors.purple.withOpacity(0.15),
                  ]
                : [
                    AppColors.orange.withOpacity(0.1),
                    AppColors.purple.withOpacity(0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasAchievements
                ? AppColors.orange.withOpacity(0.5)
                : AppColors.orange.withOpacity(0.2),
            width: hasAchievements ? 1.5 : 1,
          ),
          boxShadow: hasAchievements
              ? [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
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
                    gradient: LinearGradient(
                      colors: [AppColors.orange, AppColors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: hasAchievements
                        ? [
                            BoxShadow(
                              color: AppColors.orange.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                )
                    .animate(onPlay: (controller) => hasAchievements ? controller.repeat(reverse: true) : null)
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: hasAchievements ? const Offset(1.08, 1.08) : const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
                if (hasAchievements)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: elevated, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
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
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
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
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD700), AppColors.orange],
                          ).createShader(bounds),
                          child: Text(
                            AppLocalizations.of(context).workoutCompleteScreenTrophiesEarned,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .shimmer(
                              duration: 1500.ms,
                              color: Colors.white.withOpacity(0.3),
                            )
                      else
                        Text(
                          AppLocalizations.of(context).workoutCompleteScreenTrophiesMilestones,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: hasAchievements ? AppColors.orange : textSecondary,
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
                      color: hasAchievements ? AppColors.orange.withOpacity(0.8) : textSecondary,
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
            color: AppColors.orange.withOpacity(0.15),
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
        final elevatedProg = isDarkProg ? AppColors.elevated : AppColorsLight.elevated;
        final textSecondaryProg = isDarkProg ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
                      AppLocalizations.of(context).workoutCompleteScreenReadyToLevelUp,
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
                AppLocalizations.of(context).workoutCompleteScreenYouVeMasteredThese,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondaryProg,
                ),
              ),
              const SizedBox(height: 16),
              ..._progressionSuggestions.map((suggestion) => _buildProgressionCard(suggestion)),
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
        final elevatedCard = isDarkCard ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimaryCard = isDarkCard ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondaryCard = isDarkCard ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: elevatedCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.2),
            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondaryCard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineProgression(suggestion, 'not_ready'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondaryCard,
                        side: BorderSide(color: textSecondaryCard.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context).workoutCompleteScreenNotYet),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptProgression(suggestion),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                      label: Text(AppLocalizations.of(context).workoutCompleteScreenLevelUp),
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
        final textPrimaryPR = isDarkPR ? AppColors.textPrimary : AppColorsLight.textPrimary;

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
                      AppLocalizations.of(context).workoutCompleteScreenNewPersonalRecords,
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
                final celebrationMessage = pr['celebration_message'] as String?;
                final improvementKg = pr['improvement_kg'] as num?;
                final improvementPercent = pr['improvement_percent'] as num?;
                final estimated1rm = pr['estimated_1rm_kg'] as num?;
                final reps = pr['reps'] as int?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.orange, size: 18),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      if (celebrationMessage != null && celebrationMessage.isNotEmpty) ...[
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
    ).animate().fadeIn(delay: 550.ms).scale(
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
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
        final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

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
                      child: Icon(
                        headerIcon,
                        size: 20,
                        color: accentColor,
                      ),
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
                return _buildExerciseComparisonRow(exComp, textPrimary, textSecondary);
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
  });

  @override
  State<_ExpandableExerciseRow> createState() => _ExpandableExerciseRowState();
}

class _ExpandableExerciseRowState extends State<_ExpandableExerciseRow> {
  bool _expanded = false;

  bool get _expandable => widget.perSets.isNotEmpty;

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCD34D),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events_rounded,
                              size: 11, color: Color(0xFF7A5C00)),
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
              Text(summary,
                  style: TextStyle(fontSize: 12, color: widget.textMuted)),
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
        ],
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

/// 2A — the 8 completion stats paged into swipeable 2×2 grids with a dot
/// indicator. Uses a page-snapping HORIZONTAL scroll view (not a PageView) so
/// it sizes to its content height — a fixed-height PageView inside the
/// completion screen's vertical scroll view would hit the "unbounded height"
/// white-screen the result-layout test guards against.
class _StatsCarousel extends StatefulWidget {
  final List<MetricCell> cells;
  const _StatsCarousel({required this.cells});

  @override
  State<_StatsCarousel> createState() => _StatsCarouselState();
}

class _StatsCarouselState extends State<_StatsCarousel> {
  final ScrollController _controller = ScrollController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pages of 4 cells → each a 2×2 grid.
    final pages = <List<MetricCell>>[];
    for (var i = 0; i < widget.cells.length; i += 4) {
      final end =
          (i + 4) > widget.cells.length ? widget.cells.length : i + 4;
      pages.add(widget.cells.sublist(i, end));
    }
    // Nothing to page — render a single grid.
    if (pages.length <= 1) {
      return MetricGrid(
        items: widget.cells,
        columns: 2,
        spacing: 10,
        numberSize: StatType.secondary,
      );
    }

    final c = ThemeColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (pageWidth > 0) {
                  final p = (_controller.offset / pageWidth)
                      .round()
                      .clamp(0, pages.length - 1);
                  if (p != _page) setState(() => _page = p);
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                physics: const PageScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final page in pages)
                      SizedBox(
                        width: pageWidth,
                        child: MetricGrid(
                          items: page,
                          columns: 2,
                          spacing: 10,
                          numberSize: StatType.secondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? c.accent
                          : c.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
